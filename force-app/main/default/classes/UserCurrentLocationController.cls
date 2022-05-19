/*******************************************************
 * Description : This class will get the StoreName for of current location and current logged in user profile details SPTSLSATT-591.
 * Return type : UserDetails(Wrapper class)
 * Created date: 10-15-2021
 * Created By  : Narasimha Dara
 * *****************************************************/


public without Sharing class UserCurrentLocationController {
    
    @AuraEnabled
    public static UserDetails getUserCurrentLocation(){
        
        //Getting current logged in user name
        String Name = UserInfo.getName(); 
        
        //Getting currentUserID
        string userId = UserInfo.getUserId();
        
        //Getting current logged in user profile
        String profileId = UserInfo.getProfileId();
        
        //Getting profile information
        Profile profile = [SELECT Id, Name FROM Profile WHERE Id =:profileId];
        
        //Getting employe record related to current user
        Employee__c employee = [SELECT id, HomeStoreLocation__c, HomeStoreLocation__r.Name, NumberOfAssociatedStores__c
                                FROM Employee__c
                                WHERE User__c = :userId LIMIT 1];
        
        //Checking when employee number of assosiated store count is more than 1 
        if(employee != null && employee.NumberOfAssociatedStores__c != null && employee.NumberOfAssociatedStores__c > 1){
            
            //Getting User based UserCurrentLocation__c details to pass store name to component.
            list<UserCurrentLocation__c> ucList =  [SELECT StoreName__c FROM UserCurrentLocation__c where SetupOwner.Name=:Name limit 1];    
            
            try{
                //Preparing wrapper class
                UserDetails ud = new UserDetails();
                ud.storename = ucList[0].StoreName__c;
                ud.userProfile = profile.Name;
                
                system.debug('Wrapper result for checked in store===--->'+ud);
                
                //Returning StoreName
                return ud;  
            }
            catch(Exception e){
                throw new AuraHandledException(e.getMessage()); 
            }
        }
        
        //Checking when employee number of assosiated store count is equal to 1 
        else if(employee != null && employee.NumberOfAssociatedStores__c != null && employee.NumberOfAssociatedStores__c == 1){
            if(employee.HomeStoreLocation__c != null) {
                
                try{
                    //Preparing wrapper class
                    UserDetails ud = new UserDetails();
                    ud.storename = employee.HomeStoreLocation__r.Name;
                    ud.userProfile = profile.Name;
                    
                    system.debug('Wrapper result for home store===--->'+ud);
                    
                    //Returning StoreName
                    return ud;  
                }
                catch(Exception e){
                    throw new AuraHandledException(e.getMessage()); 
                }
                
            }
        }
        return null;
        
        
                        
    }
    
    //Wrapper class 
    public class UserDetails{
        
        @AuraEnabled
        public string storename {set;get;}
        
        @AuraEnabled
        public string userProfile {set;get;}
    }
    
}
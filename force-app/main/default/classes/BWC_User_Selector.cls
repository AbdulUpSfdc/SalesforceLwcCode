/* ================================================
* @class name: BWC_User_Selector
* @author: Salesforce Inc.
* @purpose: Selector layer apex class
* @created date (mm/dd/yyyy) :  10/22/2021
================================================*/ 
public without sharing class BWC_User_Selector {

    public static User getUserById(String uId) {
        // FLS Not needed, results not returned to user
		list<User> returnValue = [SELECT Id, Name, ManagerId, Profile.Name, ProfileId 
                                  FROM User 
                                  WHERE Id =: uId 
                                  LIMIT 1];
        
        return returnValue.IsEmpty() ? null : returnValue[0];            
    }
    
}
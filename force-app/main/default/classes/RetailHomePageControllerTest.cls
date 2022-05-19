@isTest
public class RetailHomePageControllerTest {
    @TestSetup
    static void setupData(){
        //create retailcustom settings for welcome onboarding leads
        List<RetailCustomSetting__c> customSettList = new List<RetailCustomSetting__c>();
        RetailCustomSetting__c settings1 = new RetailCustomSetting__c();
        settings1.Name = 'DueTodayListViewRep';
        settings1.KeyValue__c = 'ContactToday';
        customSettList.add(settings1);
        RetailCustomSetting__c settings2 = new RetailCustomSetting__c();
        settings2.Name = 'DueTodayListViewManager';
        settings2.KeyValue__c = 'ContactTodayMGR';
        customSettList.add(settings2);        
        insert customSettList;
    	
    }

    
    
    /**
     * This method tests the scenarios for getLoggedInUserInfo method
    */
    @IsTest
    static void getLoggedInUserInfoTest() {  
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        Test.startTest();
        System.runAs ( thisUser ) {
               
                RetailDTO.LoggedInUserInfoDTO userInfoDTO = RetailHomePageController.getLoggedInUserInfo();
                system.assert(userInfoDTO != null);
               
            
        }
        User testUser; 
        List<Profile> retailRepProfile = [SELECT Id, Name FROM Profile WHERE Name = 'Retail RSC Rep'];
        if(retailRepProfile.size()>0){

                Id profileID = retailRepProfile[0].Id;
                testUser = new User(firstname='Test Rep',lastname ='User',Username ='john@att.com',ProfileId = profileID, email='attrep@att.com', alias='testrep',TimeZoneSidKey = 'America/Los_Angeles' , LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US' );
                System.runAs ( testUser ) {
                  
                    RetailDTO.LoggedInUserInfoDTO userInfoDTO = RetailHomePageController.getLoggedInUserInfo();
                    system.assert(userInfoDTO != null);
                   
                
                }
            }
         Test.stopTest();
   }
}
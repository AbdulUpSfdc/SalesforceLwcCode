/*
* Author : Anand Tiwari
* Purpose: This is test class for scheduler class UserMasterDealerUpdateScheduler
* 
*
* Modifications Log 
* Ver   Date         Author
* 1.0   07-01-2021   Anand 
*/
@isTest
private class UserMasterDealerUpdateSchedulerTest { 
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    Public static list<Lead> leads = new list<Lead>();
    
    @TestSetup
    static void makeData(){
        dataFactoryWrap = dataFactory.createTestData(3,'Empl');
        
        Store__c dealerStore = dataFactoryWrap.lstStore[0];
        dealerStore.MasterDealer__c = 'TestName';
        dealerStore.MasterDealerID__c = '58';
        dealerStore.ChannelType__c = 'AGENT';
        
        update dealerStore;
        
        Employee__c emp = dataFactoryWrap.lstAllEmployees[0];
        emp.HomeStoreLocation__c = dealerStore.Id;
        update emp;
       
        Lead Ld1= new Lead(LastName = 'strUnique',
                        Company = 'Test',
                        Store__c = dealerStore.id,
                        LeadSource = RetailConstants.LEAD_SOURCE_ONLINE,
                        MobilePhone = '2002342000', 
                        firstName = 'Test',
                        owner__c = userinfo.getUserId(),
                        PreferredMethodofContact__c = 'Call', 
                       // ATT_Products__c = 'Video',
                        recordTypeId =RetailConstants.CONSUMER_RECORDTYPEID,
                        Status = 'Contacted'
                      );
    
		leads.add(Ld1); 
        INSERT Leads;
   
       
    }
    /*
    static testMethod void UserUpdateTest() { 
  
       test.starttest();
        list<Lead> Leads= [select id,RecordTypeId,LeadSource,Owner__c,OwnerId,MobilePhone from Lead where LastName ='strUnique'];
        List<MessagingRequest> lstWelcomeSMS = LeadTriggerHelper.checkOnlineandStoreLeadForSMS(Leads);  
        MessagingRequestHandler.sendOutboundSMS(lstWelcomeSMS, 'WelcomeSMS', RetailConstants.WELCOME_FLOW);
        UserMasterDealerUpdateScheduler userScheduler = new UserMasterDealerUpdateScheduler();   
        String cron = '0 0 3 * * ?';        
        system.schedule('Test Lead Closure Scheduler', cron, userScheduler);
        test.stopTest(); 
    }
    */
}
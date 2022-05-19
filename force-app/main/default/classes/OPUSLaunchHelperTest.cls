@isTest
/*
* This class is used to test various test cases of OPUSLaunchHelper apex
* Author: Anand Tiwari
Last Modified: Victoria Lasarte 8/18/2021
*/
public  class OPUSLaunchHelperTest 
{
    public static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    public static TestDataFactory dataFactory = new TestDataFactory();
    /* 
    *This method is used to setup test data of employee,employee store retail,leads and stores
    */
    @TestSetup
    static void makeData(){
      dataFactoryWrap = dataFactory.createTestData(1,'Retail');
      RetailCheckinQueue__c retailCheckInRecord = new RetailCheckinQueue__c();

      retailCheckInRecord.Store__c = dataFactoryWrap.lstStore[0].id;        
      retailCheckInRecord.Lead__c = dataFactoryWrap.lstLead[0].id;
        
        Insert retailCheckInRecord;
    }
    @IsTest
    static void testOPUSLaunchHelper()
    {
    RetailCheckinQueue__c retailCheckInRecord = [Select Id,DCIBOPISOrder__c,Store__r.OpusId__c,Lead__r.LastName,Lead__r.FirstName,Lead__r.Email,Lead__r.MobilePhone from RetailCheckinQueue__c limit 1 ];          
     retailCheckInRecord.Lead__r.DCIBOPISOrder__c = '2';
     retailCheckInRecord.Lead__r.LastName = 'Testing';
     retailCheckInRecord.Lead__r.FirstName = 'Test';
     retailCheckInRecord.Lead__r.Email = 'test@testing.com';
     retailCheckInRecord.Lead__r.MobilePhone = '3051112222';
     update retailCheckInrecord;

     BWC_LIC_OpusMsgRequest.OPUSInitRequest req = new BWC_LIC_OpusMsgRequest.OPUSInitRequest(); 
     req.orderID = retailCheckInRecord.DCIBOPISOrder__c;
     
     BWC_LIC_OpusMsgRequest.SfCustomerInfo custInfo = new BWC_LIC_OpusMsgRequest.SfCustomerInfo();
     custInfo.customerLastName = retailCheckInRecord.Lead__r.LastName;
     custInfo.customerFirstName = retailCheckInRecord.Lead__r.FirstName;
     custInfo.email = retailCheckInRecord.Lead__r.Email ;
     custInfo.cbr = retailCheckInRecord.Lead__r.MobilePhone;
     custInfo.CTN  = retailCheckInRecord.Lead__r.MobilePhone;
   
   
     // Data needed from LeadForm.getHomeStore
     Store__c store = [SELECT id, OpusId__c FROM Store__c LIMIT 1];
     Store__c store2 = [SELECT id, OpusId__c FROM Store__c  WHERE id != :store.id LIMIT 1];
     Employee__c homeStore = new Employee__c(HomeStoreLocation__c  = store.id, 
                                             User__c = UserInfo.getUserId() );
     insert homeStore;
     insert new RetailCustomSetting__c(Name='testValue', Key__c = 'testValue',KeyValue__c='testValue');
     
     test.startTest();
     String testResult1 = OPUSLaunchHelper.postToOPUS(retailCheckInRecord.Id, 'Customer Search');
   //  String testResult2 = OPUSLaunchHelper.postToOPUS(retailCheckInRecord.Id,'BOPIS');
     String testResult3 = OPUSLaunchHelper.getRetailCustomSettings('testValue');
     String testResult7 = OPUSLaunchHelper.getRetailCustomSettings('');
     Boolean testResult4 = OPUSLaunchHelper.isRecordEngaged(retailCheckInRecord.Id);
     Boolean testResult5 = OPUSLaunchHelper.isRecordEngaged(null);
     retailCheckInRecord.Status__c = DCIConstants.ACTIVE;
     update retailCheckInRecord;
     Boolean testResult6 = OPUSLaunchHelper.isRecordEngaged(retailCheckInRecord.Id);
     
     
     System.assertEquals(retailCheckInRecord.Lead__r.LastName,custInfo.customerLastName);
     System.assertEquals(retailCheckInRecord.Lead__r.Email,custInfo.email);
     System.assertEquals(retailCheckInRecord.Lead__r.MobilePhone,custInfo.cbr);
     System.assertEquals(retailCheckInRecord.Lead__r.MobilePhone, custInfo.CTN);
     System.assertEquals(retailCheckInRecord.Lead__r.FirstName,custInfo.customerFirstName);
     System.assertEquals(retailCheckInRecord.DCIBOPISOrder__c, req.orderID);
      try{
           OPUSLaunchHelper.postToOPUS(null, 'Bill Pay-Unverified');    
     }catch(Exception ex){
    
     }
     try{
         OPUSLaunchHelper.postToOPUS(null, 'Sell Item');
     }catch(Exception ex){
    
     }
   
     test.stopTest();
      
    }
     
}
@isTest
public class DCIRepUtilTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();

    /* 
    *This method is used to setup test data 
    */
    @testSetup static void setup() {  
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            system.debug('dataFactoryWrap TEST STUP CALLED:::');
            dataFactoryWrap = dataFactory.createTestData(1,'DCILead');
            system.debug('dataFactoryWrap TEST STUP Ended:::');
            Store__c leadStore =  dataFactoryWrap.lstStore[0];
            Group leadStoreQueue = DCILeadUtil.getStoreQueue(leadStore.Id,leadStore.Name); //fetch queue for store Owner
            if(leadStoreQueue == null){ 
                system.debug('Queue Creation'+leadStore.Name);
                Group g = new Group(Type='Queue', Name=leadStore.Name);
                insert g;
                QueueSObject q1 = new QueueSObject(SobjectType='Lead', QueueId=g.Id);
                insert q1;
                QueueSObject q2 = new QueueSObject(SobjectType='RetailCheckinQueue__c', QueueId=g.Id);
                insert q2;
                system.debug('Queue Creation Ended');
            }
        }     
   }

   /**
     * This method tests the codebase and scenarios for testUpdateRepStatus method
    */
    @IsTest
    static void testUpdateRepStatus(){
        system.debug('testUpdateRepStatus started');
        Store__c leadStore; 
        List<Store__c> leadStoreList = [Select ID,Name,DCIStoreRepCurrentCapacity__c,DCIStoreRepActiveCapacity__c from Store__c where Name = 'DCILeadstore0'];
        if(leadStoreList.size()>0)
            leadStore = leadStoreList.get(0);
        system.debug('leadStore'+leadStore);
        Lead dciLeadApi = new Lead();
        dciLeadApi.store__c = leadStore.Id;
        dciLeadApi.firstname = 'Test';
        dciLeadApi.lastname = 'DCI Lead';
        dciLeadApi.mobilephone = '9898989898';
        dciLeadApi.reasonForLeaving__c = 'Shop for accessories';
        dciLeadApi.RecordTypeId = RetailConstants.DIGITALCHECKIN_RECORDTYPEID;
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.preferredMethodofContact__c = 'SMS';
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.smsConsent__c = 'Yes';
        RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
        newCheckinDci.Status__c = 'Arrived';
        List<EmployeeStoreRetail__c> empStoreList = [Select ID,Name,Store__c from EmployeeStoreRetail__c where Store__r.Name = 'DCILeadstore0'];
        if(empStoreList.size()>0){
            Test.startTest();
            DCILeadUtil.createDCILead(dciLeadApi,newCheckinDci,leadStore);
            DCIRepUtil.updateRepStatus(empStoreList.get(0),'Online');
            DCIRepUtil.updateRepStatusBulkify(empStoreList,  'Rep went online');
            Test.stopTest();
        }
    }

    /**
     * This method tests the codebase and scenarios for testassign method
    */
    @IsTest
    static void testassign(){
        system.debug('testUpdateRepStatus started');
        Store__c leadStore; 
        List<Store__c> leadStoreList = [Select ID,Name,DCIStoreRepCurrentCapacity__c,DCIStoreRepActiveCapacity__c from Store__c where Name = 'DCILeadstore0'];
        if(leadStoreList.size()>0)
            leadStore = leadStoreList.get(0);
        system.debug('leadStore'+leadStore);
        Lead dciLeadApi = new Lead();
        dciLeadApi.store__c = leadStore.Id;
        dciLeadApi.firstname = 'Test';
        dciLeadApi.lastname = 'DCI Lead';
        dciLeadApi.mobilephone = '9898989898';
        dciLeadApi.reasonForLeaving__c = 'Shop for accessories';
        dciLeadApi.RecordTypeId = RetailConstants.DIGITALCHECKIN_RECORDTYPEID;
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.preferredMethodofContact__c = 'SMS';
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.smsConsent__c = 'Yes';
        RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
        newCheckinDci.Status__c = 'Arrived';
        List<EmployeeStoreRetail__c> empStoreList = [Select ID,Name,Store__c from EmployeeStoreRetail__c where Store__r.Name = 'DCILeadstore0'];
        if(empStoreList.size()>0){
            
            User smUser = TestData_User.generateUser('Retail SM');
            PermissionSet RetailDCI = [SELECT Id FROM PermissionSet WHERE Name = 'RetailDCI'];
            insert new PermissionSetAssignment(AssigneeId = smUser.id, PermissionSetId = RetailDCI.Id);
            
            Test.startTest();
            system.runAs(smUser){
            DCILeadUtil.createDCILead(dciLeadApi,newCheckinDci,leadStore);
            DCIRepUtil.assign(empStoreList.get(0));
            }
            Test.stopTest();
        }
        
    }

    //Sowmiya
	@IsTest
    static void testassign1(){
        system.debug('testUpdateRepStatus started');
        Store__c leadStore; 
        List<Store__c> leadStoreList = [Select ID,Name,DCIStoreRepCurrentCapacity__c,DCIStoreRepActiveCapacity__c from Store__c where Name = 'DCILeadstore0'];
        if(leadStoreList.size()>0)
            leadStore = leadStoreList.get(0);
        system.debug('leadStore'+leadStore);
        Lead dciLeadApi = new Lead();
        dciLeadApi.store__c = leadStore.Id;
        dciLeadApi.firstname = 'Test';
        dciLeadApi.lastname = 'DCI Lead';
        dciLeadApi.mobilephone = '9898989898';
        dciLeadApi.reasonForLeaving__c = 'Shop for accessories';
        dciLeadApi.RecordTypeId = RetailConstants.DIGITALCHECKIN_RECORDTYPEID;
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.preferredMethodofContact__c = 'SMS';
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.smsConsent__c = 'Yes';
        RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
        newCheckinDci.Status__c = 'Arrived';
        List<EmployeeStoreRetail__c> empStoreList = [Select ID,Name,Store__c from EmployeeStoreRetail__c where Store__r.Name = 'DCILeadstore0'];
        if(empStoreList.size()>0){
                       
            User repUser = TestData_User.generateUser('Retail RSC Rep');
            PermissionSet RetailDCIRep = [SELECT Id FROM PermissionSet WHERE Name = 'RetailDCIRep'];
            insert new PermissionSetAssignment(AssigneeId = repUser.id, PermissionSetId = RetailDCIRep.Id);
            
            Test.startTest();
            system.runAs(repUser){
            DCILeadUtil.createDCILead(dciLeadApi,newCheckinDci,leadStore);
            DCIRepUtil.assign(empStoreList.get(0));
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testAssignWhenPending(){
        Store__c leadStore; 
        List<Store__c> leadStoreList = [Select ID,Name,DCIStoreRepCurrentCapacity__c,DCIStoreRepActiveCapacity__c from Store__c where Name = 'DCILeadstore0'];
        if(leadStoreList.size()>0)
            leadStore = leadStoreList.get(0);        
            
        Lead dciLeadApi1 = new Lead();
        dciLeadApi1.store__c = leadStore.Id;
        dciLeadApi1.firstname = 'Test';
        dciLeadApi1.lastname = 'DCI Lead';
        dciLeadApi1.mobilephone = '9898989898';
        dciLeadApi1.reasonForLeaving__c = 'Shop for accessories';
        dciLeadApi1.RecordTypeId = RetailConstants.DIGITALCHECKIN_RECORDTYPEID;
        dciLeadApi1.smsConsent__c = 'Yes';
        dciLeadApi1.preferredMethodofContact__c = 'SMS';
        dciLeadApi1.smsConsent__c = 'Yes';
        dciLeadApi1.smsConsent__c = 'Yes';
        dciLeadApi1.smsConsent__c = 'Yes';
        Lead dciLeadApi2 = new Lead();
        dciLeadApi2.store__c = leadStore.Id;
        dciLeadApi2.firstname = 'Test';
        dciLeadApi2.lastname = 'DCI Lead';
        dciLeadApi2.mobilephone = '9898589898';
        dciLeadApi2.reasonForLeaving__c = 'Shop for accessories';
        dciLeadApi2.RecordTypeId = RetailConstants.DIGITALCHECKIN_RECORDTYPEID;
        dciLeadApi2.smsConsent__c = 'Yes';
        dciLeadApi2.preferredMethodofContact__c = 'SMS';
        dciLeadApi2.smsConsent__c = 'Yes';
        dciLeadApi2.smsConsent__c = 'Yes';
        dciLeadApi2.smsConsent__c = 'Yes';

        RetailCheckinQueue__c newCheckinDci1= new RetailCheckinQueue__c();
        newCheckinDci1.Status__c = 'Pending';
        RetailCheckinQueue__c newCheckinDci2= new RetailCheckinQueue__c();
        newCheckinDci2.Status__c = 'Arrived';
        List<EmployeeStoreRetail__c> empStoreList = [Select ID,Name,Store__c from EmployeeStoreRetail__c where Store__r.Name = 'DCILeadstore0'];
        if(empStoreList.size()>0){
            Test.startTest();
            DCILeadUtil.createDCILead(dciLeadApi1,newCheckinDci1,leadStore);
            DCILeadUtil.createDCILead(dciLeadApi2,newCheckinDci2,leadStore);
            DCIRepUtil.assign(empStoreList.get(0));
            Test.stopTest();
        }
    }
}
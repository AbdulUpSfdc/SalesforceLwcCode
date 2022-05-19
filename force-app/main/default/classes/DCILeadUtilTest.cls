@isTest
public class DCILeadUtilTest {
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
     * This method tests the codebase and scenarios for testCreateDCILead method
    */
    @IsTest
    static void testCreateDCILead(){
        system.debug('testCreateDCILead started');
        Store__c leadStore; 
        List<Store__c> leadStoreList = [Select ID,Name,DCIStoreRepCurrentCapacity__c,DCIStoreRepActiveCapacity__c from Store__c where Name = 'DCILeadstore0'];
        if(leadStoreList.size()>0)
            leadStore = leadStoreList.get(0);
        system.debug('leadStore'+leadStore);
        String str = string.valueof(Math.abs(Crypto.getRandomLong()));
        String randomNumber = str.substring(0, 10);
        RetailDTO.DCIResponseDTO respDTO;
        Lead dciLeadApi = new Lead();
        dciLeadApi.store__c = leadStore.Id;
        dciLeadApi.firstname = 'Test';
        dciLeadApi.lastname = 'DCI Lead';
        dciLeadApi.mobilephone = '5555555555';
        dciLeadApi.reasonForLeaving__c = 'Shop for accessories';
        dciLeadApi.RecordTypeId = RetailConstants.DIGITALCHECKIN_RECORDTYPEID;
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.preferredMethodofContact__c = 'SMS';
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.smsConsent__c = 'Yes';
        RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
        newCheckinDci.Status__c = 'Pending';
        
        User repUser = TestData_User.generateUser('Retail RSC Rep');
        PermissionSet RetailDCIRep = [SELECT Id FROM PermissionSet WHERE Name = 'RetailDCIRep'];
        insert new PermissionSetAssignment(AssigneeId = repUser.id, PermissionSetId = RetailDCIRep.Id);

        Test.startTest();
        System.runAs(repUser){
            system.debug('leadStore private '+leadStore);
            respDTO = DCILeadUtil.createDCILead(dciLeadApi,newCheckinDci,leadStore);
        }
        Test.stopTest();

        System.assertNotEquals(null, respDTO);
    }
    @IsTest
    static void testCreateDCILeadonHelp(){
        system.debug('testCreateDCILead started');
        Store__c leadStore; 
        List<Store__c> leadStoreList = [Select ID,Name,DCIStoreRepCurrentCapacity__c,DCIStoreRepActiveCapacity__c,LocationId__c from Store__c where Name = 'DCILeadstore0'];
        if(leadStoreList.size()>0)
            leadStore = leadStoreList.get(0);
        system.debug('leadStore'+leadStore);
        String str = string.valueof(Math.abs(Crypto.getRandomLong()));
        String randomNumber = str.substring(0, 10);
        RetailDTO.DCIResponseDTO respDTO;
        Lead dciLeadApi = new Lead();
        dciLeadApi.store__c = leadStore.Id;
        dciLeadApi.firstname = 'Test';
        dciLeadApi.lastname = 'DCI Lead';
        dciLeadApi.mobilephone = randomNumber;
        dciLeadApi.reasonForLeaving__c = 'Shop for accessories';
        dciLeadApi.RecordTypeId = RetailConstants.DIGITALCHECKIN_RECORDTYPEID;
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.preferredMethodofContact__c = 'SMS';
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.smsConsent__c = 'Yes';
        RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
        newCheckinDci.Status__c = 'Pending';
        Test.startTest();
        system.debug('leadStore private '+leadStore);

        User smUser = TestData_User.generateUser('Retail SM');
        PermissionSet RetailDCI = [SELECT Id FROM PermissionSet WHERE Name = 'RetailDCI'];
        insert new PermissionSetAssignment(AssigneeId = smUser.id, PermissionSetId = RetailDCI.Id);

        try{
            System.runAs(smUser){
                respDTO = DCILeadUtil.createDCILeadOnHelp(dciLeadApi,newCheckinDci,leadStore);
            }
        }
        catch(exception e){
            
        }
        Test.stopTest();
    }

    /**
     * This method tests the codebase and scenarios for testCheckIfDCILeadExists method
    */
    @IsTest
    static void testCheckIfDCILeadExists(){
        system.debug('testCheckIfDCILeadExists started');
        String DCI_RECORDTYPEID = TriggerHelper.getRecordTypeIdFromName('DigitalCheckIn' , 'lead');
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

        User smUser = TestData_User.generateUser('Retail SM');
        PermissionSet RetailDCI = [SELECT Id FROM PermissionSet WHERE Name = 'RetailDCI'];
        insert new PermissionSetAssignment(AssigneeId = smUser.id, PermissionSetId = RetailDCI.Id);

        Test.startTest();
        System.runAs(smUser){
            DCILeadUtil.checkIfDCILeadExists(dciLeadApi,leadStore);
        }
        Test.stopTest();

    }

     /**
     * This method tests the codebase and scenarios for testCheckIfDCILeadExists method
    */
    @IsTest
    static void testCheckifCustomerCheckedIn(){
        system.debug('checkifCustomerCheckedIn started');
        String DCI_RECORDTYPEID = TriggerHelper.getRecordTypeIdFromName('DigitalCheckIn' , 'lead');
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
        Test.startTest();
        DCILeadUtil.checkifCustomerCheckedIn(dciLeadApi,leadStore);
        Test.stopTest();

    }
    /**
     * This method tests the codebase and scenarios for testGetStorebyLocationID method
    */
    @IsTest
    static void testGetStorebyLocationID(){
        Store__c leadStore; 
        List<Store__c> leadStoreList = [Select ID,Name,LocationId__c,DCIStoreRepCurrentCapacity__c,DCIStoreRepActiveCapacity__c from Store__c where Name = 'DCILeadstore0'];
        if(leadStoreList.size()>0)
            leadStore = leadStoreList.get(0);
        system.debug('leadStore'+leadStore);

        User smUser = TestData_User.generateUser('Retail SM');
        PermissionSet RetailDCI = [SELECT Id FROM PermissionSet WHERE Name = 'RetailDCI'];
        insert new PermissionSetAssignment(AssigneeId = smUser.id, PermissionSetId = RetailDCI.Id);

        Test.startTest();
        System.runAs(smUser){
            DCILeadUtil.getStorebyLocationID(leadStore.LocationId__c);
        }
        Test.stopTest();
    }

    /**
     * This method tests the codebase and scenarios for testGetStoreQueue method
    */
    @IsTest
    static void testGetStoreQueue(){
        Store__c leadStore; 
        List<Store__c> leadStoreList = [Select ID,Name,LocationId__c,DCIStoreRepCurrentCapacity__c,DCIStoreRepActiveCapacity__c from Store__c where Name = 'DCILeadstore0'];
        if(leadStoreList.size()>0)
            leadStore = leadStoreList.get(0);
        system.debug('leadStore'+leadStore);

        User smUser = TestData_User.generateUser('Retail SM');
        PermissionSet RetailDCI = [SELECT Id FROM PermissionSet WHERE Name = 'RetailDCI'];
        insert new PermissionSetAssignment(AssigneeId = smUser.id, PermissionSetId = RetailDCI.Id);

        Test.startTest();
        System.runAs(smUser){
            DCILeadUtil.getStoreQueue(leadStore.Id,leadStore.Name);
        }
        Test.stopTest();
    }
       
     /**
     * This method tests the codebase and scenarios for sendAutoResponseSMS method
    */
    @IsTest
    static void testSendAutoResponseSMS(){
        Store__c leadStore; 
        String DCI_RECORDTYPEID = TriggerHelper.getRecordTypeIdFromName('DigitalCheckIn' , 'lead');
        List<Store__c> leadStoreList = [Select ID,Name,DCIStoreRepCurrentCapacity__c,DCIStoreRepActiveCapacity__c from Store__c where Name = 'DCILeadstore0'];
        if(leadStoreList.size()>0)
            leadStore = leadStoreList.get(0);
        system.debug('leadStore'+leadStore);
        RetailDTO.DCIResponseDTO respDTO;
        Lead dciLeadApi = new Lead();
        dciLeadApi.store__c = leadStore.Id;
        dciLeadApi.firstname = 'Test';
        dciLeadApi.lastname = 'DCI Lead';
        dciLeadApi.mobilephone = '9898989898';
        dciLeadApi.reasonForLeaving__c = 'Shop for accessories';
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.preferredMethodofContact__c = 'SMS';
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.smsConsent__c = 'Yes';
        dciLeadApi.recordtypeid = DCI_RECORDTYPEID;
        RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
        newCheckinDci.Status__c = DCIConstants.ACTIVE;

        User smUser = TestData_User.generateUser('Retail SM');
        PermissionSet RetailDCI = [SELECT Id FROM PermissionSet WHERE Name = 'RetailDCI'];
        insert new PermissionSetAssignment(AssigneeId = smUser.id, PermissionSetId = RetailDCI.Id);

        Test.startTest(); 
        System.runAs(smUser){
            respDTO = DCILeadUtil.createDCILead(dciLeadApi, newCheckinDci, leadStore);
            // DCILeadUtil.sendAutoResponseSMS(dciLeadApi,newCheckinDci);  
        }
        Test.stopTest();
    }   
    @IsTest
    static void testCheckBOPISNotification(){
        system.debug('testCreateDCILead started');
        Store__c leadStore; 
        List<Store__c> leadStoreList = [Select ID,Name,DCIStoreRepCurrentCapacity__c,DCIStoreRepActiveCapacity__c from Store__c where Name = 'DCILeadstore0'];
        if(leadStoreList.size()>0)
            leadStore = leadStoreList.get(0);
        system.debug('leadStore'+leadStore);
        
        /*User uTemp=[Select id from user where isActive=true order by Name Desc Limit 1 ];
        Employee__c e1=new Employee__c();
        e1.User__c=uTemp.id;
        e1.HomeStoreLocation__c =leadStore.id;
        e1.isActive__c =true;
        e1.SFProfileId__c =RetailConstants.MGR_POSITION;
        insert e1;*/
        
        RetailDTO.DCIResponseDTO respDTO;
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
        dciLeadApi.DCIBOPISOrder__c= '123456';
        dciLeadApi.DCICheckinType__c='BOPIS';
        RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
        newCheckinDci.Status__c = DCIConstants.INSTORE;

        User repUser = TestData_User.generateUser('Retail RSC Rep');
        PermissionSet RetailDCIRep = [SELECT Id FROM PermissionSet WHERE Name = 'RetailDCIRep'];
        insert new PermissionSetAssignment(AssigneeId = repUser.id, PermissionSetId = RetailDCIRep.Id);

        Test.startTest();
        System.runAs(repUser){
            system.debug('leadStore private '+leadStore);
            respDTO = DCILeadUtil.createDCILead(dciLeadApi,newCheckinDci,leadStore);
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testCheckDCICheckInType(){
        system.debug('testCreateDCILead started');
        Store__c leadStore; 
        List<Store__c> leadStoreList = [Select ID,Name,DCIStoreRepCurrentCapacity__c,DCIStoreRepActiveCapacity__c from Store__c where Name = 'DCILeadstore0'];
        if(leadStoreList.size()>0)
            leadStore = leadStoreList.get(0);
        system.debug('leadStore'+leadStore);
        
        /*User uTemp=[Select id from user where isActive=true order by Name Desc Limit 1 ];
        Employee__c e1=new Employee__c();
        e1.User__c=uTemp.id;
        e1.HomeStoreLocation__c =leadStore.id;
        e1.isActive__c =true;
        e1.SFProfileId__c =RetailConstants.MGR_POSITION;
        insert e1;*/
        
        RetailDTO.DCIResponseDTO respDTO;
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
        dciLeadApi.DCIBOPISOrder__c= '123456';
        dciLeadApi.DCICheckinType__c=DCIConstants.FUTURE;
        RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
        newCheckinDci.Status__c = DCIConstants.INSTORE;

        User repUser = TestData_User.generateUser('Retail RSC Rep');
        PermissionSet RetailDCIRep = [SELECT Id FROM PermissionSet WHERE Name = 'RetailDCIRep'];
        insert new PermissionSetAssignment(AssigneeId = repUser.id, PermissionSetId = RetailDCIRep.Id);

        Test.startTest();
        System.runAs(repUser){
            system.debug('leadStore private '+leadStore);
            respDTO = DCILeadUtil.createDCILead(dciLeadApi,newCheckinDci,leadStore);
        }
        Test.stopTest();
    }

    /**
     * Create and add a DCI lead to existing Queue
     */
    @isTest
    static void createDCILeadToExistingQueue() {
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
        newCheckinDci2.Status__c = 'Pending';
        List<EmployeeStoreRetail__c> empStoreList = [Select ID,Name,Store__c from EmployeeStoreRetail__c where Store__r.Name = 'DCILeadstore0'];
        
        User repUser = TestData_User.generateUser('Retail RSC Rep');
        PermissionSet RetailDCIRep = [SELECT Id FROM PermissionSet WHERE Name = 'RetailDCIRep'];
        insert new PermissionSetAssignment(AssigneeId = repUser.id, PermissionSetId = RetailDCIRep.Id);

        System.runAs(repUser){
            if(empStoreList.size()>0){
                DCILeadUtil.createDCILead(dciLeadApi1,newCheckinDci1,leadStore);
                Test.startTest();
                DCILeadUtil.createDCILead(dciLeadApi2,newCheckinDci2,leadStore);
                Test.stopTest();
            }
        }
    }

    /**
     * Check for validation error if a duplicate check record is created
     */
    @IsTest
    static void testValidationErrorIfDCILeadExists() {
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
        dciLeadApi2.mobilephone = '9898989898';
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

        User repUser = TestData_User.generateUser('Retail RSC Rep');
        PermissionSet RetailDCIRep = [SELECT Id FROM PermissionSet WHERE Name = 'RetailDCIRep'];
        insert new PermissionSetAssignment(AssigneeId = repUser.id, PermissionSetId = RetailDCIRep.Id);

        System.runAs(repUser){
            Test.startTest();
            DCILeadUtil.createDCILead(dciLeadApi1, newCheckinDci1, leadStore);
            try {
                DCILeadUtil.createDCILead(dciLeadApi2, newCheckinDci2, leadStore);
            } catch (Exception e) {
                Boolean expectedExceptionThrown =  e.getMessage().contains(DCIConstants.VALIDATION_EXP) ? true : false;
                System.AssertEquals(expectedExceptionThrown, true); 
            }
            Test.stopTest();
        }
    }
}
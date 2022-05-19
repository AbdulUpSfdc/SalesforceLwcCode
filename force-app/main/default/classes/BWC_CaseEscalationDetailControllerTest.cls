@IsTest
public with sharing class BWC_CaseEscalationDetailControllerTest {


    @IsTest
    static void getCaseActionFieldSetTest(){

        Test.startTest();

        Account acct = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('', acct);
        Case cs = TestData_Case.generateCase();
        cs.Type = 'Billing | Inquiry';
        cs.CaseAction__c = 'System Issues | Wireless';
        cs.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('Escalation').ID;

        update cs;

        String fieldsetInfo = BWC_CaseEscalationDetailController.getCaseActionFieldSet(cs.Id, cs.CaseAction__c);

        Test.stopTest();

    }

    @IsTest
    static void getCaseActionFieldSetTestNegative(){

        Test.startTest();
        Account acct = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('', acct);
        Case cs = TestData_Case.generateCase();
        cs.Type = 'Billing | Inquiry';
        cs.CaseAction__c = 'System Issues | Wireless';
        cs.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('Escalation').ID;

        update cs;

        try{
            String fieldsetInfo = BWC_CaseEscalationDetailController.getCaseActionFieldSet(cs.Id, 'Fake case action');
        }catch(AuraHandledException e){

        }
        Test.stopTest();
    }

    @IsTest
    static void getCaseDescribeResultTest(){

        Test.startTest();
        Account acct = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('', acct);
        Case cs = TestData_Case.generateCase();
        cs.Type = 'Billing | Inquiry';
        cs.CaseAction__c = 'System Issues | Wireless';
        cs.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('Escalation').ID;

        update cs;

        String fieldsetInfo = BWC_CaseEscalationDetailController.getCaseActionFieldSet(cs.Id, cs.CaseAction__c);

        Schema.DescribeSObjectResult firstInstance = BWC_CaseEscalationDetailController.getCaseDescribeResult();
        Test.stopTest();

    }

    @IsTest
    static void getUserAccessToCaseTest(){
        Test.startTest();
        Account acct = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('', acct);
        Case cs = TestData_Case.generateCase();
        cs.Type = 'Billing | Inquiry';
        cs.CaseAction__c = 'System Issues | Wireless';
        cs.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('Escalation').ID;

        update cs;

        Boolean userHasAccess = BWC_CaseEscalationDetailController.getUserAccessToCase(cs.Id);

        System.assert(userHasAccess);
        Test.stopTest();
    }
}
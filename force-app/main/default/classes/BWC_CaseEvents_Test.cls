@IsTest
public with sharing class BWC_CaseEvents_Test {
    
    @IsTest
    static void publishCreateEvent() {
        Billing_Account__c billingAccount = new Billing_Account__c(Billing_Account_Number__c = '123456890', External_Id__c = 'Consumer|534194767882', Account_Type__c = 'wireless', Billing_Market__c = 'DLS');
       	insert billingAccount;
        
        Id escalationRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Escalation').getRecordTypeId();
        
        Test.startTest();
		Case testCase = new Case(Type = CaseConstants.CASE_TYPE_BILLING_ADJUSTMENT, RecordTypeId = escalationRecordTypeId, Billing_Account__c = billingAccount.Id);
		insert testCase;
        
        Update New Case(Id = testCase.Id, Status='Closed', CloseNotes__c = 'Some Close Notes', Resolution__c = 'No Action');
        Test.stopTest();
    }
}
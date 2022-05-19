@IsTest
public without sharing class BWC_CreateInteractionTest {

    @TestSetup
    static void makeData(){

        Account acc = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('Wireless', acc);
        billAcc.Billing_Account_Number__c = '287273122837';
        update billAcc;
    }

    @IsTest
    static void createInteractionFromCasesTest(){

        Test.startTest();

        Account acc = [SELECT Id FROM Account];
        Billing_Account__c billAcc = [SELECT Id FROM Billing_Account__c];

        // This will create the case. Trigger Helper will call methods from BWC_createInteraction
        Case cs = new Case();
        cs.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
        cs.AccountId = acc.Id;
        cs.Billing_Account__c = billAcc.Id;
        cs.City__c = 'City';
        cs.Country__c = 'United States';
        cs.State__c = 'California';
        cs.ServiceCustFirstName__c = 'First';
        cs.ServiceCustLastName__c = 'Last';
        cs.ServicePhone__c = '9995551212';
        cs.StreetName__c = '123 Main St';
        cs.ZipPostalCode__c = '55555';
        insert cs;
        Test.stopTest();

        Case updatedcase = [SELECT ID, First_Interaction__c FROM Case WHERE Id=:cs.Id];
        System.assert(updatedcase.First_Interaction__c!=null, 'First Interaction on Case was not populated');

        Interaction__c interaction = [SELECT Id FROM Interaction__c WHERE Id=:updatedcase.First_Interaction__c];

    }

    @IsTest
    static void updateInteractionsFromCases(){

        Test.startTest();

        Account acc = [SELECT Id FROM Account];
        Billing_Account__c billAcc = [SELECT Id FROM Billing_Account__c];

        // This will create the case. Trigger Helper will call methods from BWC_createInteraction
        Case cs = new Case();
        cs.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
        cs.City__c = 'City';
        cs.Country__c = 'United States';
        cs.State__c = 'California';
        cs.ServiceCustFirstName__c = 'First';
        cs.ServiceCustLastName__c = 'Last';
        cs.ServicePhone__c = '9995551212';
        cs.StreetName__c = '123 Main St';
        cs.ZipPostalCode__c = '55555';
        insert cs;

        Test.stopTest();

        cs.AccountId = acc.Id;
        cs.Billing_Account__c = billAcc.Id;
        update cs;

        Case updatedCase = [SELECT Id, AccountId, Billing_Account__c, First_Interaction__c, Last_Interaction__c FROM Case WHERE Id=:cs.Id];
        Interaction__c interaction = [SELECT Id, Billing_Account__c, Customer__c FROM Interaction__c WHERE Id=:updatedCase.Last_Interaction__c];

        System.assert(updatedCase.Last_Interaction__c == interaction.Id, 'The retrieved Interaction is not the one the case is related to');
        System.assert(updatedCase.AccountId == interaction.Customer__c, 'The Account is not the same on Case and Interaction');
        System.assert(updatedCase.Billing_Account__c == interaction.Billing_Account__c, 'The Billing Account is not the same on Case and Interaction');

    }

}
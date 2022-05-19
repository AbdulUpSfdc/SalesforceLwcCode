@IsTest
public with sharing class BWC_UpdateAccountsBatch_Test {


    @TestSetup
    static void makeData(){

        Account acc = BWC_TestDataFactory.createAccount();
        Account acc1 = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('wireless', acc);

        CG_Data_Sync__c dataSync = new CG_Data_Sync__c();
        dataSync.Customer__c = acc.Id;
        dataSync.Individual_ID__c = 'testIndividualId';
        dataSync.Associated_BANS__c = billAcc.Billing_Account_Number__c;
        dataSync.First_Name__c = 'Tester';
        dataSync.Last_Name__c = 'Test';
        dataSync.Person_Email__c = 'test@est.com';
        dataSync.Phone__c = '3333332222';

        insert dataSync;

    }

    @IsTest
    static void testBatch(){

        Test.startTest();
        Id batchId = Database.executeBatch(new BWC_UpdateAccountsBatch('SELECT Customer__c, Individual_ID__c, Status__c, Associated_BANS__c, Primary_BAN__c, First_Name__c, Last_Name__c, Person_Email__c, Phone__c FROM CG_Data_Sync__c ORDER BY Individual_ID__c'));
        Test.stopTest();

    }

    @IsTest
    static void testScript(){

        Test.startTest();
        try {
            List<CG_Data_Sync__c> dataSyncLst = [SELECT Customer__c, Individual_ID__c, Status__c, Associated_BANS__c, Primary_BAN__c,
            First_Name__c, Last_Name__c, Person_Email__c, Phone__c FROM CG_Data_Sync__c ];

            testScriptUpdate.processCGData(dataSyncLst);
        } catch (Exception e) {

        }
        Test.stopTest();

    }



}
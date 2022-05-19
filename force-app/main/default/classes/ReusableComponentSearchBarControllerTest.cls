@isTest
public without sharing class ReusableComponentSearchBarControllerTest {
    @TestSetup
    static void makeData(){
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.BillingStreet = '123 A Street';
        insert acc;
    }

    @isTest
    static void testSOSL(){
        /*Test.startTest();

        List<String> fields = new List<String>{'Name'};
        List<Account> soslList = ReusableComponentSearchBarController.search('Account', fields, '123');
        Account first = soslList.get(0);

        system.assertEquals('Test Account', first.name);
        
        Test.stopTest();*/
    }
}
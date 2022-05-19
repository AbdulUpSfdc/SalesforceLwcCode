/**********************************************************************************************

* @author : Shoukat khan
* @group : Product Search      
* @description :  Test class for BWC_EquipmentGroupSortUtil
================================================*/ 
@isTest
public with sharing class BWC_EquipmentGroupSortUtil_Test {
    public BWC_EquipmentGroupSortUtil_Test() {

    }

    static testMethod void groupSortTest() {  
         
        Account acctObj = BWC_TestDataFactory.createAccount();
        Billing_Account__c biilAcctObj = BWC_TestDataFactory.createBillingAccount('Wireless',acctObj);

        List<Asset> listEquipments = new List<Asset>();
        Asset equipment;

        // create non primary in group 987
        equipment = BWC_TestDataFactory.createEquipment(null, acctObj, biilAcctObj, null);
        equipment.Group_ID__c = '987';
        equipment.Is_Primary__c = false;
        equipment.Phone_Number__c = '4052224444';
        equipment.Name = equipment.Phone_Number__c;
        update equipment;
        listEquipments.add(equipment);

        // create primary in group 123
        equipment = BWC_TestDataFactory.createEquipment(null, acctObj, biilAcctObj, null);
        equipment.Group_ID__c = '123';
        equipment.Phone_Number__c = '4052229999';
        equipment.Name = equipment.Phone_Number__c;
        update equipment;
        listEquipments.add(equipment);

        // create non primary in group 123
        equipment = BWC_TestDataFactory.createEquipment(null, acctObj, biilAcctObj, null);
        equipment.Group_ID__c = '123';
        equipment.Is_Primary__c = false;
        equipment.Phone_Number__c = '4052228888';
        equipment.Name = equipment.Phone_Number__c;
        update equipment;
        listEquipments.add(equipment);

        // create non primary in group 987
        equipment = BWC_TestDataFactory.createEquipment(null, acctObj, biilAcctObj, null);
        equipment.Group_ID__c = '987';
        equipment.Is_Primary__c = false;
        equipment.Phone_Number__c = '4052223333';
        equipment.Name = equipment.Phone_Number__c;
        update equipment;
        listEquipments.add(equipment);

        // create non primary in group 987
        equipment = BWC_TestDataFactory.createEquipment(null, acctObj, biilAcctObj, null);
        equipment.Group_ID__c = '987';
        equipment.Is_Primary__c = false;
        equipment.Phone_Number__c = '4052225555';
        equipment.Name = equipment.Phone_Number__c;
        update equipment;
        listEquipments.add(equipment);
        
        Test.startTest(); 
        BWC_EquipmentGroupSortUtil utils = new BWC_EquipmentGroupSortUtil();
        listEquipments = BWC_EquipmentGroupSortUtil.groupSort(listEquipments);
        Test.stopTest();

        // Primary should be first
        System.assertEquals('4052229999', listEquipments[0].Phone_Number__c);
        // Non Primary in the Primary Group should be second
        System.assertEquals('4052228888', listEquipments[1].Phone_Number__c);

        // Non Primary  Group equipments should be sorted by phone
        System.assertEquals('4052223333', listEquipments[2].Phone_Number__c);
        System.assertEquals('4052224444', listEquipments[3].Phone_Number__c);
        System.assertEquals('4052225555', listEquipments[4].Phone_Number__c);
    }

    static testMethod void groupSortNullPhoneTest() {  
         
        Account acctObj = BWC_TestDataFactory.createAccount();
        Billing_Account__c biilAcctObj = BWC_TestDataFactory.createBillingAccount('Wireless',acctObj);

        List<Asset> listEquipments = new List<Asset>();
        Asset equipment;

        // create non primary in group 987
        equipment = BWC_TestDataFactory.createEquipment(null, acctObj, biilAcctObj, null);
        equipment.Group_ID__c = '987';
        equipment.Is_Primary__c = false;
        equipment.Phone_Number__c = '4052223333';
        equipment.Name = equipment.Phone_Number__c;
        update equipment;
        listEquipments.add(equipment);

        // create non primary in group 987 with null Phone
        equipment = BWC_TestDataFactory.createEquipment(null, acctObj, biilAcctObj, null);
        equipment.Group_ID__c = '987';
        equipment.Is_Primary__c = false;
        equipment.Phone_Number__c = null;
        update equipment;
        listEquipments.add(equipment);

        // create non primary in group 987 with null Phone
        equipment = BWC_TestDataFactory.createEquipment(null, acctObj, biilAcctObj, null);
        equipment.Group_ID__c = '987';
        equipment.Is_Primary__c = false;
        equipment.Phone_Number__c = null;
        update equipment;
        listEquipments.add(equipment);
        
        // create non primary in group 987
        equipment = BWC_TestDataFactory.createEquipment(null, acctObj, biilAcctObj, null);
        equipment.Group_ID__c = '987';
        equipment.Is_Primary__c = false;
        equipment.Phone_Number__c = '4052224444';
        equipment.Name = equipment.Phone_Number__c;
        update equipment;
        listEquipments.add(equipment);

        Test.startTest(); 
        listEquipments = BWC_EquipmentGroupSortUtil.groupSort(listEquipments);
        Test.stopTest();

        // null should be first
        System.assertEquals(null, listEquipments[2].Phone_Number__c);
    }
}
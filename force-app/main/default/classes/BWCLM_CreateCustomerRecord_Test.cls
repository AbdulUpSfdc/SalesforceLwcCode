/*
Test class to test BWCLM_CreateCustomerRecord class
*/
@isTest
public with sharing class BWCLM_CreateCustomerRecord_Test {
@isTest
private static void createCustomerJson() {
Test.startTest();
BWCLM_CreateCustomerRecord.Addresses testAddr = new BWCLM_CreateCustomerRecord.Addresses();
testAddr.addressType = 'test';
//BWCLM_CreateCustomerRecord createCustomerJson= new BWCLM_CreateCustomerRecord();
//createCustomerJson.lastName = 'George';
Test.stopTest();
}
}
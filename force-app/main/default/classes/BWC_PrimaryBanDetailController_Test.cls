@isTest
private class BWC_PrimaryBanDetailController_Test {

    @isTest static void testgetPrimaryBanDetailsPositive() {
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj = 
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        biilAcctObj.Billing_Account_Number__c = acctObj.Primary_BAN__c;
        update biilAcctObj;
        String jsonData = BWC_PrimaryBanDetailController.getPrimaryBanDetails(acctObj.Id);
        BWC_PrimaryBanDetailController.RecordDetailsWrapper primBanDt = 
            (BWC_PrimaryBanDetailController.RecordDetailsWrapper) JSON.deserialize(jsonData,BWC_PrimaryBanDetailController.RecordDetailsWrapper.class);
        System.assertEquals(biilAcctObj.Language_Preference__c,primBanDt.recordDetails.langPref);
    }
    
    @isTest static void testgetPrimaryBanDetailsPositiveNull() {
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj = 
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj);
                    
        biilAcctObj.Customer_Since__c = null;
        biilAcctObj.Billing_Address_Line_2__c = null;
        biilAcctObj.Service_Address_Line_2__c = null;
        biilAcctObj.Service_City__c = null;
        biilAcctObj.Billing_Account_Number__c = acctObj.Primary_BAN__c; 
        update biilAcctObj;
        String jsonData = BWC_PrimaryBanDetailController.getPrimaryBanDetails(acctObj.Id);
        BWC_PrimaryBanDetailController.RecordDetailsWrapper primBanDt = 
            (BWC_PrimaryBanDetailController.RecordDetailsWrapper) JSON.deserialize(jsonData,BWC_PrimaryBanDetailController.RecordDetailsWrapper.class);
        System.assertEquals(biilAcctObj.Language_Preference__c,primBanDt.recordDetails.langPref);
    }

    @isTest static void testgetPrimaryBanDetailsNegative() {
        String jsonData = BWC_PrimaryBanDetailController.getPrimaryBanDetails(null);
        BWC_PrimaryBanDetailController.RecordDetailsWrapper primBanDt = 
            (BWC_PrimaryBanDetailController.RecordDetailsWrapper) JSON.deserialize(jsonData,BWC_PrimaryBanDetailController.RecordDetailsWrapper.class);
        System.assertEquals(null,primBanDt.recordDetails);   
    }


    
}
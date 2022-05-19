@isTest
private class BWC_PlanDetailController_Test {
    
    @isTest static void testgetBillingAccountPositive() {
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj = BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        String recDet = BWC_PlanDetailController.getBillingAccount(biilAcctObj.Id);
        BWC_PlanDetailController.RecordDetails rd = 
            (BWC_PlanDetailController.RecordDetails)JSON.deserialize(recDet,BWC_PlanDetailController.RecordDetails.class);
        System.assertEquals(biilAcctObj.Id,rd.recordId);
    }

    @isTest static void testgetBillingNegativeNegative() {
        String recDet = BWC_PlanDetailController.getBillingAccount(null);
        BWC_PlanDetailController.RecordDetails rd = 
            (BWC_PlanDetailController.RecordDetails)JSON.deserialize(recDet,BWC_PlanDetailController.RecordDetails.class);
        System.assertEquals(null,rd.recordId);
    }
}
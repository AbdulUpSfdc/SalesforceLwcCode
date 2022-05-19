@isTest
private class BWC_PlanDetailControllerTest {
    
    @isTest static void testgetBillingAccountPositive() {
        Account acctObj = BWC_TestDataFactory.createAccount();
        Billing_Account__c biilAcctObj = BWC_TestDataFactory.createBillingAccount('Wireless',acctObj);
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

        recDet = BWC_PlanDetailController.getBillingAccount('123');
    }
}
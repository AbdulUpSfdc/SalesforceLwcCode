@isTest
private class BWC_PlanPkgsDetailController_Test {
    
    @isTest static void testgetPlanPkgsDetailPositive() {
        //Create dummy data
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj = 
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Plan__c planObj = 
                    BWC_TestDataFactory.createPlan(recType,biilAcctObj);  
        String planJson = 
        BWC_PlanPkgsDetailController.getPlanPkgsDetail(biilAcctObj.Id);
        BWC_PlanPkgsDetailController.RecordDetailsWrapper result = 
            (BWC_PlanPkgsDetailController.RecordDetailsWrapper)JSON.deserialize(planJson, BWC_PlanPkgsDetailController.RecordDetailsWrapper.class);
        
        System.assertEquals(true, result.success);
        System.assertEquals(planObj.Id, result.recordDetails[0].recordId);
    }

    @isTest static void testgetPlanPkgsDetailNegative() {
        //Create dummy data 
        try {
            String planJson = 
                BWC_PlanPkgsDetailController.getPlanPkgsDetail(null);
        } catch (Exception e){
            System.assertEquals(BWC_Constants.NO_DATA,e.getMessage());
        }
    }

    @isTest static void testgetPlanPkgsDetailNegativeNoPlan() {
        //Create dummy data 
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj = 
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        try {
            String planJson = 
                BWC_PlanPkgsDetailController.getPlanPkgsDetail(biilAcctObj.Id);
        } catch (Exception e){
            System.assertEquals(BWC_Constants.NO_DATA,e.getMessage());
        }
    }
}
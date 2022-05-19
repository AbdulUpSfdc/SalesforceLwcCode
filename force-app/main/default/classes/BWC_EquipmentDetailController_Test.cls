@isTest
private class BWC_EquipmentDetailController_Test {
    
    @isTest static void testgetEquipmentDetailsPositive() {
        //Create dummy data
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj = 
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Asset equipmentObj = 
                    BWC_TestDataFactory.createEquipment(recType, acctObj, biilAcctObj, null);  
        String equipmentJson = 
            BWC_EquipmentDetailController.getEquipmentDetails(biilAcctObj.Id);
        BWC_EquipmentDetailController.RecordDetailsWrapper rdLstWrapper = 
            (BWC_EquipmentDetailController.RecordDetailsWrapper)JSON.deserialize(equipmentJson,BWC_EquipmentDetailController.RecordDetailsWrapper.class);
        System.assertEquals(equipmentObj.Id,rdLstWrapper.recordDetails[0].recordId);
    }

    @isTest static void testgetEquipmentDetailsNegative() {
        //Create dummy data
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj = 
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj); 
        try {
        String equipmentJson = 
            BWC_EquipmentDetailController.getEquipmentDetails(biilAcctObj.Id);
        } catch (Exception e){
            system.debug('equipmentJson :'+e.getMessage ());
            System.assertEquals(BWC_Constants.NO_DATA,e.getMessage());
        }

        BWC_EquipmentDetailController.getEquipmentDetails('12');
    }

    @isTest static void testgetEquipmentSummaryDetailsPositive() {
        //Create dummy data
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj = 
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Asset equipmentObj = 
                    BWC_TestDataFactory.createEquipment(recType,acctObj, biilAcctObj, null);  
        List<Asset> equipLst = 
            BWC_EquipmentDetailController.getEquipmentSummaryDetails(biilAcctObj.Id);
        System.assertEquals(equipmentObj.Id,equipLst[0].Id);
    }

    @isTest static void testgetEquipmentSummaryDetailsNegative() {
        //Create dummy data
        List<Asset> equipLst = 
            BWC_EquipmentDetailController.getEquipmentSummaryDetails(null);
        System.assertEquals(null,equipLst);
    }
}
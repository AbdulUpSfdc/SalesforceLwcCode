@isTest
private class  BWC_ServiceSummary_Test {

    @isTest static void testgetServiceDetailsPositive() {

        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj =
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        biilAcctObj.Billing_Account_Number__c = acctObj.Primary_BAN__c;
        update biilAcctObj;
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acctObj);
        BWC_AuthorizationCallout.AuthorizationStatusContent authorizationContent = new BWC_AuthorizationCallout.AuthorizationStatusContent();
        BWC_AuthorizationCallout.AssociatedAccount associatedAccount = new BWC_AuthorizationCallout.AssociatedAccount();
        associatedAccount.accountBan = acctObj.Primary_BAN__c;
        associatedAccount.authorizationLevel='L1';
        associatedAccount.accountType='Wireless';

        authorizationContent.associatedAccounts = new List<BWC_AuthorizationCallout.AssociatedAccount>{associatedAccount};

        interaction.Authorization_Json__c = JSON.serialize(authorizationContent, true);

        update interaction;

        String jsonData = BWC_ServiceSummary.getServiceDetails(interaction.Id);
        BWC_ServiceSummary.ServiceSummaryWrapper ssDt =
            (BWC_ServiceSummary.ServiceSummaryWrapper) JSON.deserialize(jsonData,BWC_ServiceSummary.ServiceSummaryWrapper.class);

        System.assertEquals(biilAcctObj.Account_Type__c.toLowerCase(),ssDt.services[0].lob);
    }

    @isTest static void testgetServiceDetailsPositiveMaskBan() {

        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj =
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        biilAcctObj.Billing_Account_Number__c = acctObj.Primary_BAN__c;
        update biilAcctObj;
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acctObj);
        BWC_AuthorizationCallout.AuthorizationStatusContent authorizationContent = new BWC_AuthorizationCallout.AuthorizationStatusContent();
        BWC_AuthorizationCallout.AssociatedAccount associatedAccount = new BWC_AuthorizationCallout.AssociatedAccount();
        associatedAccount.accountBan = acctObj.Primary_BAN__c;
        associatedAccount.authorizationLevel='L0';
        associatedAccount.accountType='Wireless';

        authorizationContent.associatedAccounts = new List<BWC_AuthorizationCallout.AssociatedAccount>{associatedAccount};

        interaction.Authorization_Json__c = JSON.serialize(authorizationContent, true);

        update interaction;

        String jsonData = BWC_ServiceSummary.getServiceDetails(interaction.Id);
        BWC_ServiceSummary.ServiceSummaryWrapper ssDt =
            (BWC_ServiceSummary.ServiceSummaryWrapper) JSON.deserialize(jsonData,BWC_ServiceSummary.ServiceSummaryWrapper.class);

        System.assertEquals(biilAcctObj.Account_Type__c.toLowerCase(),ssDt.services[0].lob);
    }

    @isTest static void testgetServiceDetailsNegative() {
        Boolean exceptionThrown = false;
        try {
            String jsonData = BWC_ServiceSummary.getServiceDetails(null);
        } catch (Exception ex) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown);
    }

}
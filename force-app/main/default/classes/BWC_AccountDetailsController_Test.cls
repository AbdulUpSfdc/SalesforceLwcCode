@IsTest
public with sharing class BWC_AccountDetailsController_Test {

    @IsTest
    static void test_accountDetails(){

        Test.startTest();

        Account testAccount = BWC_TestDataFactory.createAccount();
        testAccount.Individual_ID__c = 'TestIndividualId';

        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);

        BWC_AuthorizationCallout.AuthorizationStatusContent authorizationContent = new BWC_AuthorizationCallout.AuthorizationStatusContent();
        BWC_AuthorizationCallout.AssociatedAccount associatedAccount = new BWC_AuthorizationCallout.AssociatedAccount();
        associatedAccount.accountBan = billingAccount.Billing_Account_Number__c;
        associatedAccount.authorizationLevel='L1';
        associatedAccount.accountType='Wireless';

        authorizationContent.associatedAccounts = new List<BWC_AuthorizationCallout.AssociatedAccount>{associatedAccount};

        interaction.Authorization_Json__c = JSON.serialize(authorizationContent, true);

        update interaction;

        List<String> billingAccountIds = new List<String>{billingAccount.Billing_Account_Number__c};
        String billingAccountIdsJson = JSON.serialize(billingAccountIds);

        System.Continuation continuation =
            (System.Continuation) BWC_AccountDetailsController.accountDetailsCont(interaction.Id, billingAccountIdsJson, testAccount.Individual_ID__c);

        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AccountDetailsCallout.API_ACCOUNT_DETAILS, 'UT_AccountDetails');

        String responseJson = BWC_AccountDetailsController.accountDetailsResp(null, BWC_Callout.lastContinuationState);

        BWC_AccountDetails.AccountDetailsResponse response = (BWC_AccountDetails.AccountDetailsResponse) JSON.deserialize(responseJson, BWC_AccountDetails.AccountDetailsResponse.class);

        BWC_ApiMock.setTestApiMock(BWC_AccountDetailsCallout.API_ACCOUNT_DETAILS, 'UT_AccountDetails');

        responseJson = (String) BWC_AccountDetailsController.accountDetailsCont(interaction.Id, billingAccountIdsJson, testAccount.Individual_ID__c);
        response = (BWC_AccountDetails.AccountDetailsResponse) JSON.deserialize(responseJson, BWC_AccountDetails.AccountDetailsResponse.class);

        Test.stopTest();

    }

    @IsTest
    static void test_accountDetailsNegative(){

        Test.startTest();

        Account testAccount = BWC_TestDataFactory.createAccount();
        testAccount.Individual_ID__c = 'TestIndividualId';

        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);

        BWC_AuthorizationCallout.AuthorizationStatusContent authorizationContent = new BWC_AuthorizationCallout.AuthorizationStatusContent();
        BWC_AuthorizationCallout.AssociatedAccount associatedAccount = new BWC_AuthorizationCallout.AssociatedAccount();
        associatedAccount.accountBan = billingAccount.Billing_Account_Number__c;
        associatedAccount.authorizationLevel='L1';
        associatedAccount.accountType='Wireless';

        authorizationContent.associatedAccounts = new List<BWC_AuthorizationCallout.AssociatedAccount>{associatedAccount};

        interaction.Authorization_Json__c = JSON.serialize(authorizationContent, true);

        update interaction;

        List<String> billingAccountIds = new List<String>{billingAccount.Billing_Account_Number__c};
        String billingAccountIdsJson = JSON.serialize(billingAccountIds);

        try {
            System.Continuation continuation =
                (System.Continuation) BWC_AccountDetailsController.accountDetailsCont(interaction.Id, billingAccountIdsJson, testAccount.Individual_ID__c);

            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AccountDetailsCallout.API_ACCOUNT_DETAILS, 'UT_AccountDetails_ServerError');

            String responseJson = BWC_AccountDetailsController.accountDetailsResp(null, BWC_Callout.lastContinuationState);

            BWC_AccountDetails.AccountDetailsResponse response = (BWC_AccountDetails.AccountDetailsResponse) JSON.deserialize(responseJson, BWC_AccountDetails.AccountDetailsResponse.class);

            BWC_ApiMock.setTestApiMock(BWC_AccountDetailsCallout.API_ACCOUNT_DETAILS, 'UT_AccountDetails_ServerError');

            responseJson = (String) BWC_AccountDetailsController.accountDetailsCont(interaction.Id, billingAccountIdsJson, testAccount.Individual_ID__c);
            response = (BWC_AccountDetails.AccountDetailsResponse) JSON.deserialize(responseJson, BWC_AccountDetails.AccountDetailsResponse.class);

            System.assert(false, 'Exception was not thrown');
        } catch (Exception e) {
            System.assert(true);
        }

        Test.stopTest();

    }
}
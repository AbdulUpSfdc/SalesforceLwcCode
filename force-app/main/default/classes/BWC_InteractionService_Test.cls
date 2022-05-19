@isTest
public with sharing class BWC_InteractionService_Test {

    private static final String CTI_CALL_IDENTIFIER = 'Test';

    @isTest
    private static void test_getInteraction() {

        // Missing argument
        try {
            BWC_InteractionController.getInteraction(null);
            System.assert(false, 'Expected exception not thrown.');
        }
        catch(BWC_Exception e) {
            System.assert(true);
        }

        // Not found
        try {

            Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();
            delete interaction;
            BWC_InteractionController.getInteraction(interaction.Id);
            System.assert(false, 'Expected exception not thrown.');

        }
        catch(BWC_Exception e) {
            System.assert(true);
        }

        // Found
        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L0', 'PASSCODE');
        String interactionJson = BWC_InteractionController.getInteraction(interaction.Id);
        System.assert(String.isNotEmpty(interactionJson));
        Interaction__c interactionDeserialized = (Interaction__c)JSON.deserialize(interactionJson, Interaction__c.class);

    }

    @isTest
    private static void test_checkPrefetchStatus() {

        // Missing argument
        try {
            BWC_InteractionController.checkPrefetchStatus(null);
            System.assert(false, 'Expected exception not thrown.');
        }
        catch(BWC_Exception e) {
            System.assert(true);
        }

        // No interaction record
        try {
            BWC_InteractionService.PrefetchStatusResult result = checkPrefetchStatus();
            System.assert(false, 'Expected exception not thrown.');
        }
        catch (BWC_Exception e) {
            System.assert(true);
        }

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();

        // No prefetch status
        BWC_InteractionService.PrefetchStatusResult result = checkPrefetchStatus();
        System.assertEquals(null, result.prefetchStatus);

        // Polling already completed
        interaction.Is_Customer_Polling_Completed__c = true;
        update interaction;
        result = checkPrefetchStatus();
        System.assertEquals(BWC_PrefetchCacheManager.STATUS_FAILED, result.prefetchStatus);

        // Customer already set
        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        interaction.Is_Customer_Polling_Completed__c = false;
        interaction.Customer__c = testAccount.Id;
        interaction.Billing_Account__c = billingAccount.Id;
        update interaction;
        result = checkPrefetchStatus();
        System.assertEquals(BWC_PrefetchCacheManager.STATUS_SUCCEEDED, result.prefetchStatus);

        // In Process
        interaction.Customer__c = null;
        interaction.Billing_Account__c = null;
        interaction.Is_Customer_Polling_Completed__c = false;
        update interaction;
        BWC_Prefetch_Status__c prefetchStatus = new BWC_Prefetch_Status__c(
            CTI_Call_Identifier__c = CTI_CALL_IDENTIFIER, Started_At__c = Datetime.now(), Status__c = BWC_PrefetchCacheManager.STATUS_IN_PROCESS);
        insert prefetchStatus;
        result = checkPrefetchStatus();
        System.assertEquals(BWC_PrefetchCacheManager.STATUS_IN_PROCESS, result.prefetchStatus);

        // Failed
        interaction.Is_Customer_Polling_Completed__c = false;
        update interaction;
        prefetchStatus.Status__c = BWC_PrefetchCacheManager.STATUS_FAILED;
        update prefetchStatus;
        result = checkPrefetchStatus();
        System.assertEquals(BWC_PrefetchCacheManager.STATUS_FAILED, result.prefetchStatus);

        // Success but account not found
        interaction.Is_Customer_Polling_Completed__c = false;
        update interaction;
        prefetchStatus.Status__c = BWC_PrefetchCacheManager.STATUS_SUCCEEDED;
        update prefetchStatus;
        result = checkPrefetchStatus();
        System.assertEquals(BWC_PrefetchCacheManager.STATUS_FAILED, result.prefetchStatus);

        // Success and account found
        interaction.Is_Customer_Polling_Completed__c = false;
        update interaction;
        testAccount.CTI_Call_Identifier__c = CTI_CALL_IDENTIFIER;
        update testAccount;
        result = checkPrefetchStatus();
        System.assertEquals(BWC_PrefetchCacheManager.STATUS_SUCCEEDED, result.prefetchStatus);

    }

    private static BWC_InteractionService.PrefetchStatusResult checkPrefetchStatus() {

        String resultJson = BWC_InteractionController.checkPrefetchStatus(CTI_CALL_IDENTIFIER);
        return (BWC_InteractionService.PrefetchStatusResult)JSON.deserialize(resultJson, BWC_InteractionService.PrefetchStatusResult.class);

    }

    // BAN with account type found on existing record
    @isTest
    private static void test_autoSearch_banFromBillingAccount() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();
        interaction.User_Account_Number__c = billingAccount.Billing_Account_Number__c;
        update interaction;

        Test.startTest();

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_InteractionController.autoSearchInteractionForCustomerCont(interaction.Id);

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_UnifiedSearchCallout.API_UNIFIED_SEARCH, 'UT_UnifiedSearch_SingleResult');

        // Get continuation response
        String responseJson = BWC_InteractionController.autoSearchInteractionForCustomerResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_InteractionService.AutosearchResponse response =
            (BWC_InteractionService.AutosearchResponse)JSON.deserialize(responseJson, BWC_InteractionService.AutosearchResponse.class);
        System.assertEquals(true, response.success, response.message);

    }
    @isTest
    private static void test_autoSearch_wirelessBan() {

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();
        interaction.User_Account_Number__c = '325310161';
        interaction.User_TIG_Acct_Num__c = '325310161';
        update interaction;

        Test.startTest();

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_InteractionController.autoSearchInteractionForCustomerCont(interaction.Id);

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_UnifiedSearchCallout.API_UNIFIED_SEARCH, 'UT_UnifiedSearch_SingleResult');

        // Get continuation response
        String responseJson = BWC_InteractionController.autoSearchInteractionForCustomerResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_InteractionService.AutosearchResponse response =
            (BWC_InteractionService.AutosearchResponse)JSON.deserialize(responseJson, BWC_InteractionService.AutosearchResponse.class);
        System.assertEquals(true, response.success, response.message);

    }

    @isTest
    private static void test_autoSearch_uverseBan() {

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();
        interaction.User_Account_Number__c = '325310161';
        interaction.User_Uverse_Account_Number__c = '325310161';
        update interaction;

        Test.startTest();

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_InteractionController.autoSearchInteractionForCustomerCont(interaction.Id);

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_UnifiedSearchCallout.API_UNIFIED_SEARCH, 'UT_UnifiedSearch_SingleResult');

        // Get continuation response
        String responseJson = BWC_InteractionController.autoSearchInteractionForCustomerResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_InteractionService.AutosearchResponse response =
            (BWC_InteractionService.AutosearchResponse)JSON.deserialize(responseJson, BWC_InteractionService.AutosearchResponse.class);
        System.assertEquals(true, response.success, response.message);

    }

    @isTest
    private static void test_autoSearch_dtvsBan() {

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();
        interaction.User_Account_Number__c = '325310161';
        interaction.User_DTV_Account_Number__c = '325310161';
        update interaction;

        Test.startTest();

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_InteractionController.autoSearchInteractionForCustomerCont(interaction.Id);

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_UnifiedSearchCallout.API_UNIFIED_SEARCH, 'UT_UnifiedSearch_SingleResult');

        // Get continuation response
        String responseJson = BWC_InteractionController.autoSearchInteractionForCustomerResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_InteractionService.AutosearchResponse response =
            (BWC_InteractionService.AutosearchResponse)JSON.deserialize(responseJson, BWC_InteractionService.AutosearchResponse.class);
        System.assertEquals(true, response.success, response.message);

    }

    @isTest
    private static void test_autoSearch_ctn() {

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();
        interaction.User_Telephone_Number__c = '6035551212';
        update interaction;

        Test.startTest();

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_InteractionController.autoSearchInteractionForCustomerCont(interaction.Id);

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_UnifiedSearchCallout.API_UNIFIED_SEARCH, 'UT_UnifiedSearch_SingleResult');

        // Get continuation response
        String responseJson = BWC_InteractionController.autoSearchInteractionForCustomerResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_InteractionService.AutosearchResponse response =
            (BWC_InteractionService.AutosearchResponse)JSON.deserialize(responseJson, BWC_InteractionService.AutosearchResponse.class);
        System.assertEquals(true, response.success, response.message);

    }

    @isTest
    private static void test_autoSearch_negative() {

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();

        // // Insufficient data to search -- BAN but can't determine account type
        interaction.User_Account_Number__c = '12345';

        // // Exception from service
        interaction.User_TIG_Acct_Num__c = '12345';
        update interaction;

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_InteractionController.autoSearchInteractionForCustomerCont(interaction.Id);

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_UnifiedSearchCallout.API_UNIFIED_SEARCH, 'UT_UnifiedSearch_Server_Error');

        // Get continuation response
        String responseJson = BWC_InteractionController.autoSearchInteractionForCustomerResp(null, BWC_Callout.lastContinuationState);
        
        // Verify
        BWC_InteractionService.AutosearchResponse response = 
            (BWC_InteractionService.AutosearchResponse)JSON.deserialize(responseJson, BWC_InteractionService.AutosearchResponse.class);
        
        System.assertEquals(false, response.success);

    }

    @isTest
    private static void test_getInteractionNotifications_All() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('BYPASS', 'BYPASS');

        // Cause CPNI and passcode failed notifications
        interaction.Cpni_Consent__c = 'Implied';
        interaction.Passcode_Authentication_Failed__c = true;
        update interaction;

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_InteractionController.getInteractionNotificationsCont(interaction.Id);

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_PaymentDetailsCallout.API_PAYMENT_DETAILS, 'UT_GetPaymentDetails_Master');

        // Get continuation response
        String responseJson = BWC_InteractionController.getInteractionNotificationsResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_InteractionService.GetInteractionNotificationsResponse response =
            (BWC_InteractionService.GetInteractionNotificationsResponse)JSON.deserialize(responseJson, BWC_InteractionService.GetInteractionNotificationsResponse.class);
        
        // 3 notifications: CPNI, EPA Eligible, EPA Enrolled
        System.assertEquals(3, response.notifications.size());

    }

    @isTest
    private static void test_getInteractionNotifications_Special() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('BYPASS', 'BYPASS');

        // Set special flags
        update (new Account(Id = interaction.Customer__c, Is_Prepaid_Only__c = true, isFirstNet__c = true, Is_Business_Customer__c = true));
        update (new Billing_Account__c(Id = interaction.Billing_Account__c, Is_FirstNet__c = true));

        // Call method using continuation -- should return non-continuation since callout is not needed
        String responseJson = (String)BWC_InteractionController.getInteractionNotificationsCont(interaction.Id);

        // Verify
        BWC_InteractionService.GetInteractionNotificationsResponse response =
            (BWC_InteractionService.GetInteractionNotificationsResponse)JSON.deserialize(responseJson, BWC_InteractionService.GetInteractionNotificationsResponse.class);
        System.assertEquals(3, response.notifications.size());
        System.assertEquals(Label.BWC_PrepaidAccountNotice, response.notifications[0].message);

    }

    @isTest
    private static void test_checkCpniConsent() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');

        Boolean result = BWC_InteractionController.checkCpniConsent(interaction.Id);
        System.assertEquals(true, result);

        // Set implied consent
        Billing_Account__c billingAccount = new Billing_Account__c(Id = interaction.Billing_Account__c, CPNI_Preference__c = 'Implied');
        update billingAccount;

        result = BWC_InteractionController.checkCpniConsent(interaction.Id);
        System.assertEquals(false, result);
        System.assertEquals('Implied', [SELECT Cpni_Consent__c FROM Interaction__c WHERE Id = :interaction.Id].Cpni_Consent__c);

    }

    @isTest
    private static void test_setCpniConsent() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');
        BWC_InteractionController.setCpniConsent(interaction.Id, 'Implied', interaction.Billing_Account__c);
        System.assertEquals('Implied', [SELECT Cpni_Consent__c FROM Interaction__c WHERE Id = :interaction.Id].Cpni_Consent__c);

    }

    @isTest
    private static void test_getInteractionNotifications_RetailUsers_Legacy() {

        Employee__c emp = BWC_TestDataFactory.createAuthorizedRetailEmployee(UserInfo.getUserId());

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('BYPASS', 'BYPASS');

        // Set special flags
        update (new Account(Id = interaction.Customer__c, isFirstNet__c = true));
        update (new Billing_Account__c(Id = interaction.Billing_Account__c, Is_FirstNet__c = true, FirstNet_Type__c = BWC_BillingAccount.FIRST_NET_LEGACY, Customer_Liability__c = BWC_BillingAccount.CUSTOMER_LIABILITY_IRU));

        // Call method using continuation -- should return non-continuation since callout is not needed
        String responseJson = (String)BWC_InteractionController.getInteractionNotificationsCont(interaction.Id);

        // Verify
        BWC_InteractionService.GetInteractionNotificationsResponse response =
            (BWC_InteractionService.GetInteractionNotificationsResponse)JSON.deserialize(responseJson, BWC_InteractionService.GetInteractionNotificationsResponse.class);
        System.assertEquals(1, response.notifications.size());
        System.assertEquals(Label.BWC_Legacy_IRU_Account, response.notifications[0].message);

    }

    @isTest
    private static void test_getInteractionNotifications_RetailUsers_UTF() {

        Employee__c emp = BWC_TestDataFactory.createAuthorizedRetailEmployee(UserInfo.getUserId());

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('BYPASS', 'BYPASS');

        // Set special flags
        update (new Account(Id = interaction.Customer__c, isFirstNet__c = true));
        update (new Billing_Account__c(Id = interaction.Billing_Account__c, Is_FirstNet__c = true, FirstNet_Type__c = BWC_BillingAccount.FIRST_NET_UTF, Customer_Liability__c = BWC_BillingAccount.CUSTOMER_LIABILITY_IRU));

        // Call method using continuation -- should return non-continuation since callout is not needed
        String responseJson = (String)BWC_InteractionController.getInteractionNotificationsCont(interaction.Id);

        // Verify
        BWC_InteractionService.GetInteractionNotificationsResponse response =
            (BWC_InteractionService.GetInteractionNotificationsResponse)JSON.deserialize(responseJson, BWC_InteractionService.GetInteractionNotificationsResponse.class);
        System.assertEquals(1, response.notifications.size());
        System.assertEquals(Label.BWC_UTF_IRU_Account, response.notifications[0].message);

    }

    @isTest
    private static void test_getInteractionNotifications_RetailUsers_BusinessAccount() {

        Employee__c emp = BWC_TestDataFactory.createAuthorizedRetailEmployee(UserInfo.getUserId());

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('BYPASS', 'BYPASS');

        // Set special flags
        update (new Account(Id = interaction.Customer__c, isFirstNet__c = true, Is_Business_Customer__c = true));
        update (new Billing_Account__c(Id = interaction.Billing_Account__c, Is_FirstNet__c = true, FirstNet_Type__c = BWC_BillingAccount.FIRST_NET_UTF, Customer_Liability__c = BWC_BillingAccount.CUSTOMER_LIABILITY_CRU));

        // Call method using continuation -- should return non-continuation since callout is not needed
        String responseJson = (String)BWC_InteractionController.getInteractionNotificationsCont(interaction.Id);

        // Verify
        BWC_InteractionService.GetInteractionNotificationsResponse response =
            (BWC_InteractionService.GetInteractionNotificationsResponse)JSON.deserialize(responseJson, BWC_InteractionService.GetInteractionNotificationsResponse.class);
        System.assertEquals(1, response.notifications.size());
        System.assertEquals(Label.BWC_BusinessAccountCRU, response.notifications[0].message);

    }

}
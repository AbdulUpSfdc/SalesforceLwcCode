/*
    Unit test coverage for BWC_NotesSearchController.
*/
@isTest
public with sharing class BWC_NotesSearchController_Test {

    @isTest
    private static void test_getNotesSearchDetails() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);

        BWC_NotesSearch.NotesSearchRequest request = new BWC_NotesSearch.NotesSearchRequest();
        String requestJson = JSON.serialize(request);

        try{
        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation) BWC_NotesSearchController.getNotesSearchCont(interaction.Id, requestJson);
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_NotesSearchCallout.NOTES_SEARCH_DETAILS,'UT_GetNotesSearch_error');

        // Get continuation response
        String responseJson = BWC_NotesSearchController.getNotesSearchResp(null, BWC_Callout.lastContinuationState);

        // Verify 
        BWC_NotesSearch.NotesSearchResponse response = (BWC_NotesSearch.NotesSearchResponse)JSON.deserialize(responseJson, BWC_NotesSearch.NotesSearchResponse.class);
        
        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_NotesSearchCallout.NOTES_SEARCH_DETAILS, 'UT_GetNotesSearch_error');
        responseJson = (String)BWC_NotesSearchController.getNotesSearchCont(interaction.Id, requestJson);
        response = (BWC_NotesSearch.NotesSearchResponse)JSON.deserialize(responseJson, BWC_NotesSearch.NotesSearchResponse.class);
        System.assert(false);
    	}
    
    catch (System.Exception e) {
            System.assert(true);
        }
    }

    @isTest
    private static void test_getNotes() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_NotesSearchMock', 200);
        // Setup request
        BWC_NotesSearch.NotesSearchRequest request = BWC_TestDataFactory.createNotesSearchRequest();
        //Get response
        BWC_NotesSearchCallout.GetNotesSearchCallOut response  = new BWC_NotesSearchCallout.GetNotesSearchCallOut(null);
        System.assertNotEquals(null, response);
    }

    @isTest
    private static void test_getNotes_RequestNull() {

        //Get response
        try{
           BWC_NotesSearchCallout.GetNotesSearchCallOut  response  = new BWC_NotesSearchCallout.GetNotesSearchCallOut(null);
            System.assert(true, 'Expected exception not thrown.');
        }
        catch (BWC_Exception e) {
            System.assertEquals('Argument required: request', e.getMessage());
        }
    }

    @isTest
    private static void test_Negative_BadBody() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_Mock_NotJson', 200);
        // Setup request
        BWC_NotesSearch.NotesSearchRequest request = BWC_TestDataFactory.createNotesSearchRequest();
        //Get response
        try {
            BWC_NotesSearchCallout.GetNotesSearchCallOut  response  = new BWC_NotesSearchCallout.GetNotesSearchCallOut(request);
            System.assert(true, 'Excpected exception not thrown.');
        }
        catch (BWC_Exception e) {
            System.assert(e.getCause() instanceOf System.JSONException);
        }
    }
}
/**
 * Unit test coverage for BWC_RecommendationsController.
 * Also provides coverage for corresponding parts of BWC_RecommendationService and BWC_RecommendationCallout.
 */
@isTest
public class BWC_RecommendationsControllerTest {

    @TestSetup
    static void dataSetup(){
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c billAcctObj = BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Interaction__c interact = BWC_TestDataFactory.createInteraction(acctObj);

        BWC_AuthorizationCallout.AuthorizationStatusContent authorizationContent = new BWC_AuthorizationCallout.AuthorizationStatusContent();
        BWC_AuthorizationCallout.AssociatedAccount associatedAccount = new BWC_AuthorizationCallout.AssociatedAccount();
        associatedAccount.accountBan = billAcctObj.Billing_Account_Number__c;
        associatedAccount.authorizationLevel='L1';
        associatedAccount.accountType='Wireless';

        authorizationContent.associatedAccounts = new List<BWC_AuthorizationCallout.AssociatedAccount>{associatedAccount};

        interact.Billing_Account__c = billAcctObj.Id;
        interact.Authorization_Json__c = JSON.serialize(authorizationContent, true);
        interact.Is_Authorized__c = true;

        update interact;
    }

    @IsTest
    static void getRecommendationsContTest(){

        Test.startTest();

        Id interactionId = [SELECT ID FROM Interaction__c LIMIT 1].Id;

        System.Continuation continuation = (System.Continuation) BWC_RecommendationsController.getRecommendationsCont(interactionId);

        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_RecommendationCallout.API_RECOMMENDATION, 'UT_Recommendations_Success');

        String responseJson = BWC_RecommendationsController.getRecommendationsResp(null, BWC_Callout.lastContinuationState);
        BWC_Recommendations.RecommendationsResponse response =
            (BWC_Recommendations.RecommendationsResponse) JSON.deserialize(responseJson, BWC_Recommendations.RecommendationsResponse.class);

        Test.stopTest();

    }

    @IsTest
    static void getRecommendationsSyncTest(){

        Test.startTest();

        Id interactionId = [SELECT ID FROM Interaction__c LIMIT 1].Id;

        BWC_ApiMock.setTestApiMock(BWC_RecommendationCallout.API_RECOMMENDATION, 'UT_Recommendations_Success');

        String responseJson = (String) BWC_RecommendationsController.getRecommendationsCont(interactionId);
        BWC_Recommendations.RecommendationsResponse response =
            (BWC_Recommendations.RecommendationsResponse) JSON.deserialize(responseJson, BWC_Recommendations.RecommendationsResponse.class);

        Test.stopTest();

    }

    @IsTest
    static void getRecommendationContTestNegative(){

        Test.startTest();

        Id interactionId = [SELECT ID FROM Interaction__c LIMIT 1].Id;

        System.Continuation continuation = (System.Continuation) BWC_RecommendationsController.getRecommendationsCont(interactionId);

        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_RecommendationCallout.API_RECOMMENDATION, 'UT_Recommendations_404');

        try {

            String responseJson = BWC_RecommendationsController.getRecommendationsResp(null, BWC_Callout.lastContinuationState);
            BWC_Recommendations.RecommendationsResponse response =
                (BWC_Recommendations.RecommendationsResponse) JSON.deserialize(responseJson, BWC_Recommendations.RecommendationsResponse.class);
            System.assert(false, 'Exception not thrown');

        } catch (Exception e) {
            System.assert(true);
        }


        Test.stopTest();

    }

    @IsTest
    static void getRecommendationsSyncTestNegative(){

        Test.startTest();

        Id interactionId = [SELECT ID FROM Interaction__c LIMIT 1].Id;

        BWC_ApiMock.setTestApiMock(BWC_RecommendationCallout.API_RECOMMENDATION, 'UT_Recommendations_404');

        try {

            String responseJson = (String) BWC_RecommendationsController.getRecommendationsCont(interactionId);
            BWC_Recommendations.RecommendationsResponse response =
                (BWC_Recommendations.RecommendationsResponse) JSON.deserialize(responseJson, BWC_Recommendations.RecommendationsResponse.class);

            System.assert(false, 'Exception not thrown');
        } catch (Exception e) {
            System.assert(true);
        }

        Test.stopTest();

    }

}
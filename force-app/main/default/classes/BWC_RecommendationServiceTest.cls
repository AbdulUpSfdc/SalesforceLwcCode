@isTest
public class BWC_RecommendationServiceTest {
    @TestSetup
    static void dataSetup(){
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c billAcctObj = BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Interaction__c interact = BWC_TestDataFactory.createInteraction(acctObj);
        interact.Billing_Account__c = billAcctObj.Id;
        interact.Is_Authorized__c = true;
        BWC_AuthorizationCallout.AuthorizationStatusContent authorizationContent = new BWC_AuthorizationCallout.AuthorizationStatusContent();
        BWC_AuthorizationCallout.AssociatedAccount associatedAccount = new BWC_AuthorizationCallout.AssociatedAccount();
        associatedAccount.accountBan = acctObj.Primary_BAN__c;
        associatedAccount.authorizationLevel='L1';
        associatedAccount.accountType='Wireless';

        authorizationContent.associatedAccounts = new List<BWC_AuthorizationCallout.AssociatedAccount>{associatedAccount};

        interact.Authorization_Json__c = JSON.serialize(authorizationContent, true);

        update interact;
    }

    @IsTest
    static void getRecommendationServiceTest(){

        BWC_Utils.setStaticResourceMock('BWC_RecommendationResponse', 200);
        Test.startTest();
        Id interactionId = [SELECT ID FROM Interaction__c LIMIT 1].Id;
        //List<BWC_Recommendations.RecommendationResponse> response = BWC_RecommendationService.getRecommendationsOffers(interactionId);       
		BWC_RecommendationService.GetRecommendations get_Recommendations = new BWC_RecommendationService.GetRecommendations(interactionId);
            
        Test.stopTest();

    }

    @IsTest
    static void getRecommendationServiceTestNegative(){

        BWC_Utils.setStaticResourceMock('BWC_RecommendationResponse', 200);
        Test.startTest();
        Boolean exceptionThrown=false;
        try {
            //List<BWC_Recommendations.RecommendationResponse> response = BWC_RecommendationService.getRecommendationsOffers(null);
            BWC_RecommendationService.GetRecommendations get_Recommendations = new BWC_RecommendationService.GetRecommendations(null);
        } catch (Exception ex) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown);

        Test.stopTest();

    }

}
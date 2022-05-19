@isTest
public class BWC_RecommendationCalloutTest {
    @TestSetup
    static void dataSetup(){
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c billAcctObj = BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Interaction__c interact = BWC_TestDataFactory.createInteraction(acctObj);
        interact.Billing_Account__c = billAcctObj.Id;
        
        update interact;
    }
    
    @IsTest
    static void getRecommendationCalloutTest(){
        
        BWC_Utils.setStaticResourceMock('BWC_RecommendationResponse', 200);
        Test.startTest();
        Id interactionId = [SELECT ID FROM Interaction__c LIMIT 1].Id;
        
        //BWC_Recommendations.RecommendationRequest request = BWC_RecommendationService.getRequest(interactionId);
        //List<BWC_Recommendations.RecommendationResponse> response = BWC_RecommendationCallout.getRecommendationOffers(request);
        
        Test.stopTest();
        
    }
}
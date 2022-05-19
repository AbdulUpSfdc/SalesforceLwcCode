public with sharing class BWC_RecommendationService {

    public class GetRecommendations extends BWC_InteractionServiceBase{

        public BWC_Recommendations.RecommendationsRequest request;
        public BWC_Recommendations.RecommendationsResponse response;

        public GetRecommendations(Id interactionId){

            super(interactionId, null);
            this.buildRequest();

        }

        public void buildRequest(){

            this.request = new BWC_Recommendations.RecommendationsRequest();

            List<BWC_Recommendations.RecommendationAccount> accounts = new List<BWC_Recommendations.RecommendationAccount>();
            List<Billing_Account__c> billingAccounts = this.getL1BillingAccounts();

            for(Billing_Account__c billingAccount : billingAccounts){

                BWC_Recommendations.RecommendationAccount account = new BWC_Recommendations.RecommendationAccount();
                account.accountNumber = billingAccount.Billing_Account_Number__c;
                account.accountType = String.isNotBlank(billingAccount.Account_type__c) ? billingAccount.Account_type__c : '';

                accounts.add(account);
            }

            this.request.ctiCallIdentifier = this.interactionId;
            this.request.accounts = accounts;

            this.callout = new BWC_RecommendationCallout.GetRecommendationsCallout(this.request);

        }

        public override Object buildResponse(){

            this.response = (BWC_Recommendations.RecommendationsResponse) this.callout.getResponse();
            return this.response;
        }

    }


}
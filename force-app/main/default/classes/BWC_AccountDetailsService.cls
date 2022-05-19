public with sharing class BWC_AccountDetailsService {


    public class AccountDetails extends BWC_InteractionServiceBase {

        public BWC_AccountDetails.AccountDetailsResponse response;
        public List<BWC_AccountDetails.AccountDetailsRequest> request;
        public String individualId;

        public AccountDetails(Id interactionId, String billingAccountIdsJson, String individualId){
            super(interactionId, null);

            this.individualId = individualId;
            List<String> billingAccountIds = (List<String>) JSON.deserialize(billingAccountIdsJson, List<String>.class);
            this.buildRequest(billingAccountIds);
        }

        public void buildRequest(List<String> billingAccountIds){

            Set<String> billingAccountIdSet = new Set<String>(billingAccountIds);
            this.request = new List<BWC_AccountDetails.AccountDetailsRequest>();
            for(Billing_Account__c billingAccount : this.billingAccounts){

                if( billingAccountIdSet.contains(billingAccount.Id) ){
                    this.request.add(
                        new BWC_AccountDetails.AccountDetailsRequest(
                            billingAccount.Billing_Account_Number__c,
                            billingAccount.Account_Type__c)
                    );
                }
            }

            System.debug('this.request:'+this.request);

            this.callout = new BWC_AccountDetailsCallout.AccountDetailsCallout(this.request, this.individualId);
        }

        public override Object buildResponse(){
            this.response = (BWC_AccountDetails.AccountDetailsResponse) this.callout.getResponse();
            BWC_AccountDetails.Individual individual = this.response.individuals;

            List<Billing_Account__c> billingAccounts = new List<Billing_Account__c>();
            for(BWC_AccountDetails.Accounts acc : individual.accounts){

                if(this.billingAccountsByBan.containsKey(acc.id)){
                    Billing_Account__c billAcc = this.billingAccountsByBan.get(acc.id);

                    if(acc.details.error!=null){
                        // TODO: throw exception?
                        continue;
                    }

                    billAcc.Product_Name_360__c = acc.details?.productName360;
                    billAcc.POTS_Voice_Phone_Number__c = acc.details?.serviceNumber;

                    billingAccounts.add(billAcc);
                }

            }

            if(!billingAccounts.isEmpty()){
                update billingAccounts;
            }


            return this.response;
        }
    }
}
public with sharing class BWC_AccountDetailsCallout {

    public static final String API_ACCOUNT_DETAILS = 'Account_Details';//TODO: create Custom metadata

    // https://c360-api-qa.att.com/att-qa-accounts-e/api/v2/individuals/1c335e11-ae1a-11c1-1a1b-bcc678d93c9c/accounts/details
    // individualId: dynamic value

    public with sharing class AccountDetailsCallout extends BWC_Callout {

        BWC_AccountDetails.AccountDetailsResponse response;

        public AccountDetailsCallout(List<BWC_AccountDetails.AccountDetailsRequest> request, String individualId){

            // TODO: add path, third param. {individualId}/accounts/details
            this.setCallout(API_ACCOUNT_DETAILS, request, individualId+'/accounts/details', null, null);
        }

        public override Object buildResponse(){
            this.response = (BWC_AccountDetails.AccountDetailsResponse) this.deserialize(BWC_AccountDetails.AccountDetailsResponse.class);
            return this.response;
        }

    }

}
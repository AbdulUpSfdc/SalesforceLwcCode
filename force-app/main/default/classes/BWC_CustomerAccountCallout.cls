public with sharing class BWC_CustomerAccountCallout {
    /*
        Callout to get various billing account details.
    */
    public class GetCustomerAccountCallout extends BWC_Callout {
       
        BWC_CustomerAccount.AccountDetailsResponse response;
        /*
            Construct the callout object from request.
        */
        public GetCustomerAccountCallout(String ban,String accountType) {
            String path = ban + '/details/search';
            String queryString = 'accountType=' + accountType;
            this.setCallout(BWC_Constants.API_CUSTOMER_ACCOUNT, null, path, queryString, 'GET');
        }

        public override Boolean throwOnError() {
            // Don't throw on 404 -- treat as empty
            return (this.httpResponse.getStatusCode() != 404);
        }
        /*
            Returns BWC_CustomerAccount.AccountDetailsResponse.
        */
        public override Object buildResponse() {
            // Response requires extra wrapper because API returns an array but we need root to be an object so it can extend BWC_Callout.Response
            this.response = (BWC_CustomerAccount.AccountDetailsResponse)this.deserialize(BWC_CustomerAccount.AccountDetailsResponse.class);
            return this.response;
        }

    } 
   
    /*
        Callout to get various billing account details.
    */
    public static BWC_CustomerAccount.PutBillingInfoResponse putBillingInfo(String ban, String accountType, BWC_CustomerAccount.PutBillingInfoRequest billingInfo) {

        if (String.isEmpty(ban)) {
            throw new BWC_Exception('Argument required: ban');
        }
        if (String.isEmpty(accountType)) {
            throw new BWC_Exception('Argument required: accountType');
        }
        if (billingInfo == null) {
            throw new BWC_Exception('Argument required: billingInfo');
        }

        // Serialize
        String requestBody = JSON.serialize(billingInfo, true);

        // Make the call
        String path = ban + '/billingInfo';
        String queryString = 'accountType=' + accountType;
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_CUSTOMER_ACCOUNT_P, requestBody, path, queryString, 'PUT');

        // Attempt deserialize
        BWC_CustomerAccount.PutBillingInfoResponse returnValue;
        try {
            returnValue = (BWC_CustomerAccount.PutBillingInfoResponse)JSON.deserialize(response.getBody(), BWC_CustomerAccount.PutBillingInfoResponse.class);
        }
        catch (System.JSONException e) {
            throw new BWC_Exception('Failed to deserialize HTTP response body.', e);
        }

        return returnValue;

    }

    /*
        Callout to get various billing account details.
    */
    public static BWC_CustomerAccount.UpdateAccountPasscodeResponse updateAccountPasscode(String ban, String accountType, BWC_CustomerAccount.UpdateAccountPasscodeRequest passcodeInfo) {

        if (String.isEmpty(ban)) {
            throw new BWC_Exception('Argument required: ban');
        }
        if (String.isEmpty(accountType)) {
            throw new BWC_Exception('Argument required: accountType');
        }
        if (passcodeInfo == null) {
            throw new BWC_Exception('Argument required: passcodeInfo');
        }

        // Serialize
        String requestBody = JSON.serialize(passcodeInfo, true);

        // Make the call
        String path = ban + '/billingaccountinfo';
        String queryString = 'accountType=' + accountType;
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_CUSTOMER_ACCOUNT_S, requestBody, path, queryString, 'PUT');

        // Attempt deserialize
        BWC_CustomerAccount.UpdateAccountPasscodeResponse returnValue;
        try {
            returnValue = (BWC_CustomerAccount.UpdateAccountPasscodeResponse)JSON.deserialize(response.getBody(), BWC_CustomerAccount.UpdateAccountPasscodeResponse.class);
        }
        catch (System.JSONException e) {
            throw new BWC_Exception('Failed to deserialize HTTP response body.', e);
        }

        return returnValue;

    }

}
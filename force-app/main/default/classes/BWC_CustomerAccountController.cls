public with sharing class BWC_CustomerAccountController {

    @AuraEnabled(continuation = true)
    public static Object getCustomerInfoForBillingAccountCont(Id recordId, Id InteractionId) {
        
        try {

            BWC_CustomerAccountService.GetCustomerAccountService service = new BWC_CustomerAccountService.GetCustomerAccountService(recordId,InteractionId);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'getCustomAccountResp';
                return response;
            }

            // No continuation needed, so return it directly
            BWC_CustomerAccount.AccountDetailsResponse accountDetailsResponse = (BWC_CustomerAccount.AccountDetailsResponse)response;
            return accountDetailsResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e, 'Record Id:' + recordId);
        }

    }
    @AuraEnabled
    public static String getCustomAccountResp(List<String> labels, Object state) {

        try {

            BWC_CustomerAccountService.GetCustomerAccountService service = (BWC_CustomerAccountService.GetCustomerAccountService)state;
            BWC_CustomerAccount.AccountDetailsResponse accountDetailsResponse = (BWC_CustomerAccount.AccountDetailsResponse)service.processContinuationResponse();
            return accountDetailsResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }

    @AuraEnabled
    public static String putBillingInfo(String ban, String accountType, String billingInfoJson) {

        PutBillingInfoResponseWrapper responseWrapper = new PutBillingInfoResponseWrapper();

        try {

            BWC_CustomerAccount.PutBillingInfoRequest billingInfo = (BWC_CustomerAccount.PutBillingInfoRequest)JSON.deserialize(billingInfoJson, BWC_CustomerAccount.PutBillingInfoRequest.class);
            BWC_CustomerAccount.PutBillingInfoResponse response = BWC_CustomerAccountService.putBillingInfo(ban, accountType, billingInfo);
            responseWrapper.success = true;
            responseWrapper.response = response;

        }
        catch (System.Exception e) {

            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, 'ban: ' + ban + ' accountType: ' + accountType, null);

        }

        // Return the JSON, LWC will parse it.
        return responseWrapper.serialize();

    }
    
    @AuraEnabled
    public static String updateAccountPasscode(String ban, String accountType, String passcodeInfoJson) {

        UpdateAccountPasscodeResponseWrapper responseWrapper = new UpdateAccountPasscodeResponseWrapper();

        try {

            BWC_CustomerAccount.UpdateAccountPasscodeRequest passcodeInfo = (BWC_CustomerAccount.UpdateAccountPasscodeRequest)JSON.deserialize(passcodeInfoJson, BWC_CustomerAccount.UpdateAccountPasscodeRequest.class);
            BWC_CustomerAccount.UpdateAccountPasscodeResponse response = BWC_CustomerAccountService.updateAccountPasscode(ban, accountType, passcodeInfo);
            responseWrapper.success = true;
            responseWrapper.response = response;

        }
        catch (System.Exception e) {

            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, 'ban: ' + ban + ' accountType: ' + accountType, null);

        }

        // Return the JSON, LWC will parse it.
        return responseWrapper.serialize();

    }

    /*
        Wrapper for returning response along with error information.
    */
    public class AccountDetailsResponseWrapper extends BWC_ResponseWrapper {
        public BWC_CustomerAccount.AccountDetailsResponse response;
    }

    /*
        Wrapper for returning response along with error information.
    */
    public class PutBillingInfoResponseWrapper extends BWC_ResponseWrapper {
        public BWC_CustomerAccount.PutBillingInfoResponse response;
    }

    /*
        Wrapper for returning response along with error information.
    */
    public class UpdateAccountPasscodeResponseWrapper extends BWC_ResponseWrapper {
        public BWC_CustomerAccount.UpdateAccountPasscodeResponse response;
    }

}
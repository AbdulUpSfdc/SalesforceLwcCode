public with sharing class BWC_AuthorizationController {

    /**************************************************************************
      checkAuthorizationStatus
    **************************************************************************/
    
    @AuraEnabled(continuation = true)
    public static Object checkAuthorizationStatusCont(Id interactionId, Id billingAccountId) {
        
        try {

            BWC_AuthorizationService.CheckAuthorizationStatusService service = 
                new BWC_AuthorizationService.CheckAuthorizationStatusService(interactionId, billingAccountId);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'checkAuthorizationStatusResp';
                return response;
            }

            // It's response we can return directly without continuation
            BWC_AuthorizationService.CheckAuthorizationStatusResponse checkAuthorizationStatusResponse = (BWC_AuthorizationService.CheckAuthorizationStatusResponse)response;
            return checkAuthorizationStatusResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }

    @AuraEnabled
    public static String checkAuthorizationStatusResp(List<String> labels, Object state) {

        try {
            BWC_AuthorizationService.CheckAuthorizationStatusService service = (BWC_AuthorizationService.CheckAuthorizationStatusService)state;
            BWC_AuthorizationService.CheckAuthorizationStatusResponse checkAuthorizationStatusResponse =
                (BWC_AuthorizationService.CheckAuthorizationStatusResponse)service.processContinuationResponse();
            return checkAuthorizationStatusResponse.serialize();
        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }

    /**************************************************************************
      isAuthenticatedWithOtp
    **************************************************************************/

    /*
        Tell whether specified billingAccountId is authenticated using OTP on the interaction.
    */
    @AuraEnabled
    public static Boolean isAuthenticatedWithOtp(Id interactionId, Id billingAccountId) {
        try {
            return BWC_AuthorizationService.isAuthenticatedWithOtp(interactionId, billingAccountId);
        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }
    }

    /**************************************************************************
      setNoAuthentication
    **************************************************************************/

    /*
        Set indicator that agent used legacy system and authentication did not complete.
    */
    @AuraEnabled
    public static void setNoAuthentication(Id interactionId) {

        try {
            BWC_AuthorizationService.setNoAuthentication(interactionId);
        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }

}
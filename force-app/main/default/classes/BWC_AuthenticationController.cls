public with sharing class BWC_AuthenticationController {

    /**************************************************************************
      generatePin
    **************************************************************************/
    
    /*
        Call generatePin service using Continuation;
    */
    @AuraEnabled(continuation = true)
    public static Object generatePinCont(Id interactionId, Id billingAccountId, String deliveryMethodsJson) {

        try {

            BWC_AuthenticationCallout.DeliveryMethods deliveryMethods = (BWC_AuthenticationCallout.DeliveryMethods)JSON.deserialize(deliveryMethodsJson, BWC_AuthenticationCallout.DeliveryMethods.class);

            BWC_AuthenticationService.GeneratePinService service = new BWC_AuthenticationService.GeneratePinService(interactionId, billingAccountId, deliveryMethods);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'generatePinResp';
                return response;
            }

            // No continuation needed, so return it directly
            BWC_AuthenticationCallout.GeneratePinResponse generatePinResponse = (BWC_AuthenticationCallout.GeneratePinResponse)response;
            return generatePinResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }

    /*
        Handle the response when generatePin service is called using Continuation;
    */    
    @AuraEnabled
    public static String generatePinResp(List<String> labels, Object state) {

        try {
            BWC_AuthenticationService.GeneratePinService service = (BWC_AuthenticationService.GeneratePinService)state;
            BWC_AuthenticationCallout.GeneratePinResponse generatePinResponse = (BWC_AuthenticationCallout.GeneratePinResponse)service.processContinuationResponse();
            return generatePinResponse.serialize();
        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }

    /**************************************************************************
      validatePin
    **************************************************************************/

    @AuraEnabled(continuation = true)
    public static Object validatePinCont(Id interactionId, Id billingAccountId, String securityCode, String identificationType, String otpContactMethod) {

        try {

            BWC_AuthenticationService.ValidatePinService service = new BWC_AuthenticationService.ValidatePinService(interactionId, billingAccountId, securityCode, identificationType, otpContactMethod);
            Object response =  service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'validatePinResp';
                return response;
            }

            // No continuation needed, so return it directly
            BWC_AuthenticationCallout.ValidatePinResponse validatePinResponse = (BWC_AuthenticationCallout.ValidatePinResponse)response;
            return validatePinResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }

    @AuraEnabled
    public static String validatePinResp(List<String> labels, Object state) {

        try {
            BWC_AuthenticationService.ValidatePinService service = (BWC_AuthenticationService.ValidatePinService)state;
            BWC_AuthenticationCallout.ValidatePinResponse validatePinResponse = (BWC_AuthenticationCallout.ValidatePinResponse)service.processContinuationResponse();
            return validatePinResponse.serialize();
        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }

    /**************************************************************************
      validateCredentials
    **************************************************************************/

    @AuraEnabled(continuation = true)
    public static Object validateCredentialsCont(Id interactionId, Id billingAccountId, String accountCredentialsJson) {

        try {

            BWC_AuthenticationCallout.AccountCredentials accountCredentials = (BWC_AuthenticationCallout.AccountCredentials)JSON.deserialize(accountCredentialsJson, BWC_AuthenticationCallout.AccountCredentials.class);


            BWC_AuthenticationService.ValidateCredentialsService service = new BWC_AuthenticationService.ValidateCredentialsService(interactionId, billingAccountId, accountCredentials);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'validateCredentialsResp';
                return response;
            }

            // No continuation needed, so return it directly
            BWC_AuthenticationCallout.ValidateCredentialsResponse validateCredentialsResponse = (BWC_AuthenticationCallout.ValidateCredentialsResponse)response;
            return validateCredentialsResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }        

    }

    @AuraEnabled
    public static String validateCredentialsResp(List<String> labels, Object state) {

        try {
            BWC_AuthenticationService.ValidateCredentialsService service = (BWC_AuthenticationService.ValidateCredentialsService)state;
            BWC_AuthenticationCallout.ValidateCredentialsResponse validateCredentialsResponse = (BWC_AuthenticationCallout.ValidateCredentialsResponse)service.processContinuationResponse();
            return validateCredentialsResponse.serialize();    
        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }

    /**************************************************************************
      bypassAuthentication
    **************************************************************************/

    @AuraEnabled
    public static void bypassAuthentication(Id interactionId, Id billingAccountId) {

        try {
            BWC_AuthenticationService.bypassAuthentication(interactionId, billingAccountId);
        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }        

    }

}
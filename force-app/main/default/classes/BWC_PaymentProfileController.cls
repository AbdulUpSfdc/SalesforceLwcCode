/*
    Exposes methods to allow LWC to call Payment Profile service.
*/
public with sharing class BWC_PaymentProfileController {

    /*
        Method for calling from LWC. Returns serialized JSON.
    */
    @AuraEnabled
    public static String postPaymentProfile(String paymentProfileJson, String mode) {
        return postPaymentProfileRaisr(paymentProfileJson, mode, null);
    }

    /*
        Method for calling from LWC. Returns serialized JSON.
    */
    @AuraEnabled
    public static String postPaymentProfileRaisr(String paymentProfileJson, String mode, String spiDataJson) {

        // The wrapper class to return to LWC
        PaymentProfileResponseWrapper responseWrapper = new PaymentProfileResponseWrapper();
        responseWrapper.success = false;

        try {

            // Deserialize the request sent by LWC
            BWC_PaymentProfile.PaymentProfile paymentProfile = 
                (BWC_PaymentProfile.PaymentProfile)JSON.deserialize(paymentProfileJson, BWC_PaymentProfile.PaymentProfile.class);
            
            // Remove irrelevant content
            if (paymentProfile.paymentMethod != null) {
                if (paymentProfile.paymentMethod.paymentMethodType == BWC_Constants.PAYMENT_METHOD_TYPE_CARD) {
                    paymentProfile.paymentMethod.bankAccount = null;
                }
                else {
                    paymentProfile.paymentMethod.card = null;
                }
            }

            BWC_PaymentProfile.SpiData spiData = new BWC_PaymentProfile.SpiData();
            if (spiDataJson != null) {
                spiData = (BWC_PaymentProfile.SpiData)JSON.deserialize(spiDataJson, BWC_PaymentProfile.SpiData.class);   
            }

            // Call the Payment Profile service
            responseWrapper.response = BWC_PaymentProfileService.postPaymentProfile(paymentProfile, mode, spiData);
            responseWrapper.success = true;

        }
        catch (System.Exception e) {

            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            responseWrapper.details = e.getTypeName() + ': ' + e.getStackTraceString();
            BWC_ExceptionUtils.handleException(e, null, null);

        }

        return responseWrapper.serialize();

    }

    /*
        Wrapper for returning response along with error information.
    */
    public class PaymentProfileResponseWrapper extends BWC_ResponseWrapper  {

        public BWC_PaymentProfile.PaymentProfileResponse response;

    }

}
/*
    Exposes methods to allow LWC to call Make Payment or Update Payment service.
*/
public with sharing class BWC_MakePaymentController {

    /*
        Method for calling from LWC. Returns serialized JSON.
    */
    @AuraEnabled
    public static String makePayment(String requestJson) {
        return makePaymentRaisr(requestJson, null);
    }

    /*
        Method for calling from LWC with Raisr Smart-fields data. Returns serialized JSON.
    */
    @AuraEnabled
    public static String makePaymentRaisr(String requestJson, String spiDataJson) {

        MakePaymentResponseWrapper responseWrapper = new MakePaymentResponseWrapper();
        responseWrapper.success = false;

        try {

            BWC_MakePayment.MakePaymentRequest request = 
                (BWC_MakePayment.MakePaymentRequest)JSON.deserialize(requestJson, BWC_MakePayment.MakePaymentRequest.class);

            List<BWC_MakePayment.SpiData> spiData = new List<BWC_MakePayment.SpiData>();
            if (spiDataJson != null) {
                spiData = (List<BWC_MakePayment.SpiData>)JSON.deserialize(spiDataJson, List<BWC_MakePayment.SpiData>.class);   
            }
            
            // Call the service
            responseWrapper.response = BWC_MakePaymentService.makePayment(request, spiData);
            responseWrapper.success = true;

        }
        catch (System.Exception e) {

            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, null, null);

        }

        return responseWrapper.serialize();

    }

    /*
        Wrapper for returning response along with error information.
    */
    public class MakePaymentResponseWrapper extends BWC_ResponseWrapper {
        public BWC_MakePayment.MakePaymentResponse response;
    }

   /*
        Method for calling from LWC. Returns serialized JSON.
    */
    @AuraEnabled
    public static String updatePayment(String requestJson) {
        return updatePaymentRaisr(requestJson, null);
    }

    @AuraEnabled
    public static String updatePaymentRaisr(String requestJson, String spiDataJson) {

        UpdatePaymentResponseWrapper responseWrapper = new UpdatePaymentResponseWrapper();
        responseWrapper.success = false;

        try {

            BWC_MakePayment.UpdatePaymentRequest request = 
                (BWC_MakePayment.UpdatePaymentRequest)JSON.deserialize(requestJson, BWC_MakePayment.UpdatePaymentRequest.class);

            List<BWC_MakePayment.SpiData> spiData = new List<BWC_MakePayment.SpiData>();
            if (spiDataJson != null) {
                spiData = (List<BWC_MakePayment.SpiData>)JSON.deserialize(spiDataJson, List<BWC_MakePayment.SpiData>.class);   
            }
            
            // Call the service
            responseWrapper.response = BWC_MakePaymentService.updatePayment(request, spiData);
            responseWrapper.success = true;

        }
        catch (System.Exception e) {

            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, null, null);

        }

        return responseWrapper.serialize();

    }

    /*
        Wrapper for returning response along with error information.
    */
    public class UpdatePaymentResponseWrapper extends BWC_ResponseWrapper {
        public BWC_MakePayment.UpdatePaymentResponse response;
    }

    /*
        Method for calling from LWC. Returns serialized JSON.
    */
    @AuraEnabled
    public static String deletePayment(String requestJson) {

        DeletePaymentResponseWrapper responseWrapper = new DeletePaymentResponseWrapper();
        responseWrapper.success = false;

        try {

            BWC_MakePayment.DeletePaymentRequest request = 
                (BWC_MakePayment.DeletePaymentRequest)JSON.deserialize(requestJson, BWC_MakePayment.DeletePaymentRequest.class);
            
            // Call the service
            responseWrapper.response = BWC_MakePaymentService.deletePayment(request);
            responseWrapper.success = true;

        }
        catch (System.Exception e) {

            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, null, null);

        }

        return responseWrapper.serialize();

    }

    /*
        Wrapper for returning response along with error information.
    */
    public class DeletePaymentResponseWrapper extends BWC_ResponseWrapper {
        public BWC_MakePayment.DeletePaymentResponse response;
    }

    /*
        Method for calling from LWC. Returns serialized JSON.
    */
    @AuraEnabled
    public static String epaEnroll(String requestJson) {
        return epaEnrollRaisr(requestJson, null);
    }

    @AuraEnabled
    public static String epaEnrollRaisr(String requestJson, String spiDataJson) {

        EpaEnrollResponseWrapper responseWrapper = new EpaEnrollResponseWrapper();
        responseWrapper.success = false;

        try {

            BWC_MakePayment.EpaEnrollRequest request = 
                (BWC_MakePayment.EpaEnrollRequest)JSON.deserialize(requestJson, BWC_MakePayment.EpaEnrollRequest.class);
            
            BWC_MakePayment.SpiData spiData = new BWC_MakePayment.SpiData();
            if (spiDataJson != null) {
                spiData = (BWC_MakePayment.SpiData)JSON.deserialize(spiDataJson, BWC_MakePayment.SpiData.class);   
            }

            // Call the service
            responseWrapper.response = BWC_MakePaymentService.epaEnroll(request, spiData);
            responseWrapper.success = true;

        }
        catch (System.Exception e) {

            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, null, null);

        }

        return responseWrapper.serialize();

    }    

    /*
        Wrapper for returning response along with error information.
    */
    public class EpaEnrollResponseWrapper extends BWC_ResponseWrapper {
        public BWC_MakePayment.EpaEnrollResponse response;
    }

}
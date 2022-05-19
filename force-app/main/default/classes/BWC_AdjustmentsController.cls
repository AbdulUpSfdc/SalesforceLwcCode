public with sharing class BWC_AdjustmentsController {

    /*
        Continuation Method for Posted Adjustments
    */
    @AuraEnabled(Continuation=true)
    public static Object getPostedAdjustmentsCont(String recordId, String requestsJson) {
        try {

            BWC_Log.setRelatedRecordId(recordId);
            
            List<BWC_Adjustments.PostedAdjustmentsRequest> requests =
                (List<BWC_Adjustments.PostedAdjustmentsRequest>) JSON.deserialize(requestsJson, List<BWC_Adjustments.PostedAdjustmentsRequest>.class);

            BWC_AdjustmentsService.GetPostedAdjustmentsService service = 
                new BWC_AdjustmentsService.GetPostedAdjustmentsService(recordId, requests);

            Object response = service.callWithContinuation();

            if(response instanceof Continuation) {
                ((Continuation) response).continuationMethod = 'getPostedAdjustmentsResp';
                return response;
            }

            return ((BWC_Adjustments.PostedAdjustmentsResponse) response).serialize();
            
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(
                e,
                'recordId=' + recordId + '|' + 'requestsJson=' + requestsJson,
                recordId
            );
        }
    }

    /*
        Continuation Response Method for Posted Adjustments
    */
    @AuraEnabled
    public static String getPostedAdjustmentsResp(List<String> labels, Object state) {
        
        // rebuild state of request after continuation succeeds
        try {

            BWC_AdjustmentsService.GetPostedAdjustmentsService service = (BWC_AdjustmentsService.GetPostedAdjustmentsService) state;
            BWC_Adjustments.PostedAdjustmentsResponse response = 
                (BWC_Adjustments.PostedAdjustmentsResponse) service.processContinuationResponse();
            return response.serialize();

        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

    /*
        Continuation Method for Pending Adjustments
    */
    @AuraEnabled(Continuation=true)
    public static Object getPendingAdjustmentsCont(String recordId, String requestsJson) {
        try {

            BWC_Log.setRelatedRecordId(recordId);
            
            List<BWC_Adjustments.PendingAdjustmentsRequest> requests =
                (List<BWC_Adjustments.PendingAdjustmentsRequest>) JSON.deserialize(requestsJson, List<BWC_Adjustments.PendingAdjustmentsRequest>.class);

            BWC_AdjustmentsService.GetPendingAdjustmentsService service = 
                new BWC_AdjustmentsService.GetPendingAdjustmentsService(recordId, requests);

            Object response = service.callWithContinuation();

            if(response instanceof Continuation) {
                ((Continuation) response).continuationMethod = 'getPendingAdjustmentsResp';
                return response;
            }

            return ((BWC_Adjustments.PendingAdjustmentsResponse) response).serialize();
            
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(
                e,
                'recordId=' + recordId + '|' + 'requestsJson=' + requestsJson,
                recordId
            );
        }
    }

    /*
        Continuation Response Method for Pending Adjustments
    */
    @AuraEnabled
    public static String getPendingAdjustmentsResp(List<String> labels, Object state) {
        
        // rebuild state of request after continuation succeeds
        try {

            BWC_AdjustmentsService.GetPendingAdjustmentsService service = (BWC_AdjustmentsService.GetPendingAdjustmentsService) state;
            BWC_Adjustments.PendingAdjustmentsResponse response = 
                (BWC_Adjustments.PendingAdjustmentsResponse) service.processContinuationResponse();
            return response.serialize();

        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

    /*
        Continuation Method for CDE Recommendations
    */
    @AuraEnabled(Continuation=true)
    public static Object getCdeRecommendationsCont(String recordId, String requestJson) {
        try {

            BWC_Log.setRelatedRecordId(recordId);
            
            BWC_Adjustments.CdeRecommendationsRequest request =
                (BWC_Adjustments.CdeRecommendationsRequest) JSON.deserialize(requestJson, BWC_Adjustments.CdeRecommendationsRequest.class);

            BWC_AdjustmentsService.GetCdeRecommendationsService service = 
                new BWC_AdjustmentsService.GetCdeRecommendationsService(recordId, request);

            Object response = service.callWithContinuation();

            if(response instanceof Continuation) {
                ((Continuation) response).continuationMethod = 'getCdeRecommendationsResp';
                return response;
            }

            return ((BWC_Adjustments.CdeRecommendationsResponse) response).serialize();
            
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(
                e,
                'recordId=' + recordId + '|' + 'requestJson=' + requestJson,
                recordId
            );
        }
    }

    /*
        Continuation Response Method for CDE Recommendations
    */
    @AuraEnabled
    public static String getCdeRecommendationsResp(List<String> labels, Object state) {
        
        // rebuild state of request after continuation succeeds
        try {

            BWC_AdjustmentsService.GetCdeRecommendationsService service = (BWC_AdjustmentsService.GetCdeRecommendationsService) state;
            BWC_Adjustments.CdeRecommendationsResponse response = 
                (BWC_Adjustments.CdeRecommendationsResponse) service.processContinuationResponse();
            return response.serialize();

        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

    /*
        Synchronous Method for Post Adjustments
    */
    @AuraEnabled
    public static Object postAdjustments(String recordId, String requestJson) {
        try {

            BWC_Log.setRelatedRecordId(recordId);
            
            BWC_Adjustments.PostAdjustmentsRequest request =
                (BWC_Adjustments.PostAdjustmentsRequest) JSON.deserialize(requestJson, BWC_Adjustments.PostAdjustmentsRequest.class);

            return BWC_AdjustmentsService.postAdjustments(recordId, request).serialize();
            
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(
                e,
                'recordId=' + recordId + '|' + 'requestJson=' + requestJson,
                recordId
            );
        }
    }

    /*
        Synchronous Method for Reverse Adjustment
    */
    @AuraEnabled
    public static Object reverseAdjustment(String recordId, String requestJson) {
        try {

            BWC_Log.setRelatedRecordId(recordId);
            
            BWC_Adjustments.ReverseAdjustmentRequest request =
                (BWC_Adjustments.ReverseAdjustmentRequest) JSON.deserialize(requestJson, BWC_Adjustments.ReverseAdjustmentRequest.class);

            return BWC_AdjustmentsService.reverseAdjustment(recordId, request).serialize();
            
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(
                e,
                'recordId=' + recordId + '|' + 'requestJson=' + requestJson,
                recordId
            );
        }
    }
}
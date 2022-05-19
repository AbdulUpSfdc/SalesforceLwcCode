/**
*   Class that exposes Continuation method, used by bwcRecommendationServices LWC
*/
public with sharing class BWC_RecommendationsController {

    @AuraEnabled(continuation = true)
    public static Object getRecommendationsCont(Id interactionId){

        BWC_Log.setRelatedRecordId(interactionId);

        try {

            BWC_RecommendationService.GetRecommendations service =
                new BWC_RecommendationService.GetRecommendations(interactionId);

            Object response = service.callWithContinuation();

            if(response instanceof Continuation){
                ((Continuation)response).continuationMethod = 'getRecommendationsResp';
                return response;
            }

            BWC_Recommendations.RecommendationsResponse recommendationsResponse = (BWC_Recommendations.RecommendationsResponse) response;

            return recommendationsResponse.serialize();

        } catch (Exception e) {

            throw BWC_Controller.handleException(e);

        }

    }

    @AuraEnabled
    public static String getRecommendationsResp(List<String> labels, Object state){
        try {

            BWC_RecommendationService.GetRecommendations service =
                (BWC_RecommendationService.GetRecommendations)state;

            BWC_Recommendations.RecommendationsResponse recommendationsResponse =
            (BWC_Recommendations.RecommendationsResponse)service.processContinuationResponse();

            return recommendationsResponse.serialize();

        } catch (Exception e) {

            throw BWC_Controller.handleException(e);

        }
    }

}
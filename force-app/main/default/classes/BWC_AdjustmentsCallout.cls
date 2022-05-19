/*
    Call Mulesoft to get Adjustments, get CDE Recommendations, & Post Adjustments
*/
public with sharing class BWC_AdjustmentsCallout {
    
    public static final String API_POSTED_ADJUSTMENTS = 'Posted_Adjustments';
    public static final String API_PENDING_ADJUSTMENTS = 'Pending_Adjustments';
    public static final String API_CDE_RECOMMENDATIONS = 'Cde_Recommendations';
    public static final String API_POST_ADJUSTMENTS = 'Post_Adjustments'; // TODO add this 
    public static final String API_REVERSE_ADJUSTMENT = 'Reverse_Adjustment';
    
    public class GetPostedAdjustmentsCallout extends BWC_Callout {
        List<BWC_Adjustments.PostedAdjustmentsRequest> request;
        BWC_Adjustments.PostedAdjustmentsResponse response;

        /*
            Construct the callout object from request
        */
        public GetPostedAdjustmentsCallout(List<BWC_Adjustments.PostedAdjustmentsRequest> requests) {

            this.setCallout(API_POSTED_ADJUSTMENTS, requests, null, null, null);

        }

        /*
            Returns  List<BWC_Adjustments.PostedAdjustmentsResponse>
        */
        public override Object buildResponse() {

            this.response = new BWC_Adjustments.PostedAdjustmentsResponse();
            this.response.response = (List<BWC_Adjustments.PostedAdjustment>) this.deserialize(
                List<BWC_Adjustments.PostedAdjustment>.class
            );
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);
            return this.response;

        }
    }

    public class GetPendingAdjustmentsCallout extends BWC_Callout {
        List<BWC_Adjustments.PendingAdjustmentsRequest> request;
        BWC_Adjustments.PendingAdjustmentsResponse response;

        /*
            Construct the callout object from request
        */
        public GetPendingAdjustmentsCallout(List<BWC_Adjustments.PendingAdjustmentsRequest> requests) {

            this.setCallout(API_PENDING_ADJUSTMENTS, requests, null, null, null);

        }

        /*
            Returns  BWC_Adjustments.PendingAdjustmentsResponse
        */
        public override Object buildResponse() {

            this.response = new BWC_Adjustments.PendingAdjustmentsResponse();
            this.response.response = (List<BWC_Adjustments.PendingAdjustmentsResponseNode>) this.deserialize(
                List<BWC_Adjustments.PendingAdjustmentsResponseNode>.class
            );
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);
            return this.response;

        }
    }

    public class GetCdeRecommendationsCallout extends BWC_Callout {
        BWC_Adjustments.CdeRecommendationsRequest request;
        BWC_Adjustments.CdeRecommendationsResponse response;

        /*
            Construct the callout object from request
        */
        public GetCdeRecommendationsCallout(BWC_Adjustments.CdeRecommendationsRequest request) {

            this.setCallout(
                API_CDE_RECOMMENDATIONS, 
                request, 
                request.accountNumber + '/adjustments/recommendations', 
                'accountType=' + request.accountType,
                null
            );

        }

        /*
            Returns BWC_Adjustments.CdeRecommendationsResponse
        */
        public override Object buildResponse() {
           
            this.response = (BWC_Adjustments.CdeRecommendationsResponse) this.deserialize(
                BWC_Adjustments.CdeRecommendationsResponse.class
            );

            return this.response;

        }
    }

    public class GetPostAdjustmentsCallout extends BWC_Callout {
        BWC_Adjustments.PostAdjustmentsRequest request;
        BWC_Adjustments.PostAdjustmentsResponse response;

        /*
            Construct the callout object from request
        */
        public GetPostAdjustmentsCallout(BWC_Adjustments.PostAdjustmentsRequest request) {

            this.setCallout(
                API_POST_ADJUSTMENTS, 
                request, 
                request.accountNumber + '/adjustments', 
                'accountType=' + request.accountType, 
                null
            );

        }

        /*
            Returns BWC_Adjustments.PostAdjustmentsResponse 
        */
        public override Object buildResponse() {
            
            this.response = (BWC_Adjustments.PostAdjustmentsResponse) this.deserialize(
                BWC_Adjustments.PostAdjustmentsResponse.class
            );

            return this.response;

        }
    }

    public class GetReverseAdjustmentCallout extends BWC_Callout {
        BWC_Adjustments.ReverseAdjustmentRequest request;
        BWC_Adjustments.ReverseAdjustmentResponse response;

        /*
            Construct the callout object from request
        */
        public GetReverseAdjustmentCallout(BWC_Adjustments.ReverseAdjustmentRequest request) {

            this.setCallout(
                API_REVERSE_ADJUSTMENT, 
                request, 
                request.accountNumber + '/adjustments',
                null, 
                null
            );

        }

        public override Object buildResponse() {

            this.response = (BWC_Adjustments.ReverseAdjustmentResponse) this.deserialize(
                BWC_Adjustments.ReverseAdjustmentResponse.class
            );

            return this.response;
            
        }
    }
}
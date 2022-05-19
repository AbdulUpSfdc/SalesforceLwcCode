public class BWC_RecommendationCallout {

    public static final String API_RECOMMENDATION = 'BANRecommendations';

    public class GetRecommendationsCallout extends BWC_Callout {

        BWC_Recommendations.RecommendationsRequest request;
        BWC_Recommendations.RecommendationsResponse response;

        public GetRecommendationsCallout(BWC_Recommendations.RecommendationsRequest request){

            this.setCallout(API_RECOMMENDATION, request, null, null, null);

        }

        public override Object buildResponse(){

            this.response = new BWC_Recommendations.RecommendationsResponse();
            this.response.recommendations = (List<BWC_Recommendations.Recommendation>) this.deserialize(List<BWC_Recommendations.Recommendation>.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);

            return this.response;
        }

    }

}
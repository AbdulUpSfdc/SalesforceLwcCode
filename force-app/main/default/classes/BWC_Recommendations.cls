public with sharing class BWC_Recommendations {

    public class RecommendationsRequest {
        public List<RecommendationAccount> accounts;
        public string ctiCallIdentifier;
    }

    public class RecommendationAccount {
        public string accountNumber;
        public string accountType;
    }

    public class RecommendationsResponse extends BWC_Callout.CalloutResponse {
        public List<Recommendation> recommendations;
    }

    public class Recommendation{
        public String accountNumber;
        public String accountType;
        public String transactionId;
        public List<Offers> offers;
    }

    public class Offers{
        public String displayDescription;
        public String SFDCIconType;
        public String url;
        public String intentType;
        public String contentId;
        public String inventorySpaceId;
        public String statusCode;
    }
}
public with sharing class BWC_IMEISearch {

    public class IMEISearchRequest {
        public String attuid;
        public String imei;
    }
    
    public class IMEISearchResponse{
        public String makeId;
        public String dataOnlyIndicatorId;
        public String modelId;
        public String frequencyId;
        public String deviceCategoryId;
        public String lteTypeId;
        public String blackListedIndicatorId;
        public String nfcCapabilityId;
        public String blackListStatusDateTime;
        public String umtsTypeId;
        public String certificationId;
        public String voLTEId;
        public String itemId; 
        public String networkCompatibilityIndicator; 
        public String Message;
        
    }
}
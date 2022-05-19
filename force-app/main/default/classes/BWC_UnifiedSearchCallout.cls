public with sharing class BWC_UnifiedSearchCallout {

    public static final String API_UNIFIED_SEARCH = 'Unified_Search';

    public with sharing class CustomerSearchCallout extends BWC_Callout {

        BWC_UnifiedSearch.UnifiedSearchResponse response;

        public CustomerSearchCallout(BWC_UnifiedSearch.UnifiedSearchRequest request){

            this.setCallout(API_UNIFIED_SEARCH, request, null, null, null);
        }

        public override Object buildResponse(){

            this.response = (BWC_UnifiedSearch.UnifiedSearchResponse)this.deserialize(BWC_UnifiedSearch.UnifiedSearchResponse.class);
            return this.response;
        }

    }

}
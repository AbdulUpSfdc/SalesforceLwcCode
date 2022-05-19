public with sharing class BWC_CustomerSearchCallout {

    public static final String API_CUSTOMER_SEARCH = 'Customer_Search';
    public static final String API_CBR_SEARCH = 'CBR_Search';

    public with sharing class CustomerSearchCallout extends BWC_Callout {

        // Request and Response state
        BWC_CustomerSearch.CustomerSearchRequest request;
        BWC_CustomerSearch.CustomerSearchResponse response;

        /*
            Construct the callout object from request.
        */
        public CustomerSearchCallout(BWC_CustomerSearch.CustomerSearchRequest request) {

            this.setCallout(API_CUSTOMER_SEARCH, request, null, null, null);

        }

        public override Boolean throwOnError() {
            // Don't throw on 404 -- treat as empty
            return (this.httpResponse.getStatusCode() != 404);
        }

        /*
            Returns BWC_PaymentDetails.PaymentDetailsResponses.
        */
        public override Object buildResponse() {

            this.response = new BWC_CustomerSearch.CustomerSearchResponse();

            // Response structure depends upon http status
            if (this.httpResponse.getStatusCode() == 404) {

                // 404 means empty (API should no longer respond with 404 for empty result but leaving this code)
                this.response.accountResponses = new List<BWC_CustomerSearch.AccountResponse>();
    
            }
            else {
    
                if (this.httpResponse.getStatusCode() == 200 || this.httpResponse.getStatusCode() == 206) {
    
                    // Should be list of customer accounts
                    this.response.accountResponses = (List<BWC_CustomerSearch.AccountResponse>)this.deserialize(List<BWC_CustomerSearch.AccountResponse>.class);

                    if (response.accountResponses.size() == 1 && response.accountResponses[0].accountHeader == null) {
                        // It's an empty response -- remove the erroneous array entry
                        this.response.accountResponses = new List<BWC_CustomerSearch.AccountResponse>();
                    }
    
                }
                else if (this.httpResponse.getStatusCode() == 300) {
                    // Should be list of addressses
                    response.addressesResponse = (BWC_CustomerSearch.AddressesResponse)this.deserialize(BWC_CustomerSearch.AddressesResponse.class);
                }
    
            }

            this.response.setHttpInfo(this.httpRequest, this.httpResponse);
            return this.response;

        }

    }

    public with sharing class CBRSearchCallout extends BWC_Callout {

        BWC_CustomerSearch.CBRResponse response;

        public CBRSearchCallout(String phoneNumber){
            String queryString = 'phoneNumber='+phoneNumber;
            this.setCallout(API_CBR_SEARCH, null, null, queryString, null);
        }

        public override Boolean throwOnError() {
            // Don't throw on 404 -- treat as empty
            return (this.httpResponse.getStatusCode() != 404);
        }

        public override Object buildResponse(){
            this.response = (BWC_CustomerSearch.CBRResponse) this.deserialize(BWC_CustomerSearch.CBRResponse.class);
            return this.response;
        }
    }

}
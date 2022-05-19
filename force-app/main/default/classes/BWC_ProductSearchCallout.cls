public with sharing class BWC_ProductSearchCallout {

    public static final String API_PRODUCT_SEARCH = 'Product_Search';

    public inherited sharing class ProductSearchCallout extends BWC_Callout {

        // Request and Response state
        List<BWC_ProductSearch.ProductSearchRequest> request;
        BWC_ProductSearch.ProductSearchResponse response;

        /*
            Construct the callout object from request.
        */
        public ProductSearchCallout(List<BWC_ProductSearch.ProductSearchRequest> request) {

            this.request = request;
            this.setCallout(API_PRODUCT_SEARCH, request, null, null, null);

        }

        /*
            Returns BWC_PaymentDetails.PaymentDetailsResponses.
        */
        public override Object buildResponse() {

            this.response = (BWC_ProductSearch.ProductSearchResponse)this.deserialize(BWC_ProductSearch.ProductSearchResponse.class);
            return this.response;

        }

    }

}
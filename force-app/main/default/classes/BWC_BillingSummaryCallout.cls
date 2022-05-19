/* ================================================
* @author : Shoukat Khan
* @date :   09/30/2020   
* @group : Billing Summary 
* @description : This class has method getBillingData that makes a call to mulesoft to get billing summary.
*       It uses the class BWC_IntegrationUtility to make the http call.
================================================*/
public with sharing class BWC_BillingSummaryCallout {
    public BWC_BillingSummaryCallout() {

    }

    /*
    THis method calls the Mulesoft Billing Summary API to retrieve the products.
    */
    public static HttpResponse getBillingData(List<BillingSummaryRequest> billingSummaryRequests) {

        String body = JSON.serialize(billingSummaryRequests);

        System.debug('Billing Summary Request body:' + body);
        //Pass the named credential name (Billing_Summary) to use and the body to send
        // TBD: Future retry logic to be added in this method BWC_IntegrationUtility.makeHTTPCallout
        HttpResponse response;
        
        try {
            // Use BWC_IntegrationUtility to make mulesoft call.
            // Pass the Named Credential to use. 
            response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_BILLING_SUMMARY, body);
        }
        catch (BWC_HttpException e) {
 
            if (e.statusCode == 404) {
                // In this case 404 is interpreted as no data, not error
                response = e.response;
            }
            else {
                throw e;
            }
 
        }
 
        System.debug('Billing Summary Response body:' + response.getBody());
        return response;  
    }
    
    public class BillingSummaryRequest{
        public String product;
        public String ban;

        public BillingSummaryRequest() {
        }
        
        public BillingSummaryRequest(String product, String ban) {
            this.product = (product == 'Wireless')?'Wireless':'Wireline';
            this.ban = ban;
        }
    }

}
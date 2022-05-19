/* ================================================
* @author : Shoukat Khan
* @date :   09/29/2020   
* @group : Billing Summary
* @description : This class has method getBillingData 
================================================*/
public with sharing class BWC_BillingSummaryService {

    public static BWC_BillingSummaryResultWrapper getBillingData(String recordId) {

        // Get all authorized billing accounts that are not unified accounts
        List<Billing_Account__c> billingAccounts = BWC_AccountService.getBillingAccounts(recordId, BWC_Constants.VALID_BILLING_ACCOUNT_TYPES, null,  true, true);

        if (billingAccounts.isEmpty()) {

            // No valid billing accounts, just return empty response without calling api
            BWC_BillingSummaryResultWrapper response = new BWC_BillingSummaryResultWrapper();
            response.success = true;
            response.result = new BWC_BillingSummaryRespWrapper();
            return response;

        }

        // Create the payload to get Billing Summary from Mulesoft.
        List<BWC_BillingSummaryCallout.BillingSummaryRequest> billingSummaryRequests = new List<BWC_BillingSummaryCallout.BillingSummaryRequest>();
        for(Billing_Account__c billingAccount : billingAccounts) {
            BWC_BillingSummaryCallout.BillingSummaryRequest bsr = 
                new BWC_BillingSummaryCallout.BillingSummaryRequest(
                    billingAccount.Account_Type__c,
                    billingAccount.Billing_Account_Number__c);
                    
            billingSummaryRequests.add(bsr);
        }

        BWC_BillingSummaryResultWrapper resultWrapper = new BWC_BillingSummaryResultWrapper();
        resultWrapper.success = false;

        try {
            // Make a mulesoft call to Billing Summary API
            HttpResponse response = BWC_BillingSummaryCallout.getBillingData(billingSummaryRequests);
            if (response.getStatusCode() == BWC_Constants.HTTP_STATUS_CODE_200) {

                resultWrapper.result = (BWC_BillingSummaryRespWrapper)JSON.deserialize(response.getBody(), BWC_BillingSummaryRespWrapper.class);
                resultWrapper.success = true;

                // Add bans to result to allow cross-reference of failures
                Integer wirelessIndex = 0;
                Integer wirelineIndex = 0;
                for (Integer i = 0; i < billingSummaryRequests.size(); i++) {

                    if (billingSummaryRequests[i].product == 'Wireless') {
                        resultWrapper.result.Wireless[wirelessIndex].ban = billingSummaryRequests[i].ban;
                        wirelessIndex++;
                    }
                    else {
                        resultWrapper.result.Wireline[wirelineIndex].ban = billingSummaryRequests[i].ban;
                        wirelineIndex++;
                    }

                }

            }
            else {
                // invalid status code, so send error message
                resultWrapper.message = 'Status Code: ' + response.getStatusCode() + '; Body: ' + response.getBody();
            }
        }
        catch (Exception ex) {
            resultWrapper.message = ex.getMessage();
        }

        return resultWrapper;
    }
}
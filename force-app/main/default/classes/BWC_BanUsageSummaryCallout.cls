public class BWC_BanUsageSummaryCallout {

    public static BWC_BanUsageSummary.UsageSummaryResponse getCustomerUsageSummary(BWC_BanUsageSummary.UsageSummaryRequest request) {

        if (request == null) {
            throw new BWC_Exception('Argument required: request');
        }

        // Serialize
        String requestBody = JSON.serialize(request, true);

        System.debug('Request Body: ' + requestBody);
        
        // Make the call
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_CUSTOMER_USAGE, requestBody);

        // Attempt deserialize
        BWC_BanUsageSummary.UsageSummaryResponse returnValue = new BWC_BanUsageSummary.UsageSummaryResponse();

        // Deserialize response
        try {
            List<BWC_BanUsageSummary.UsageResponse> dataUsage = (List<BWC_BanUsageSummary.UsageResponse>)JSON.deserialize(response.getBody(), List<BWC_BanUsageSummary.UsageResponse>.class);
            System.debug('returnValue: ' + dataUsage);
            returnValue.response = dataUsage;
        } catch(Exception e) {
            System.debug('Error deserializing response: ' + e.getMessage());
            throw new BWC_Exception('Failed to deserialze HTTP response body.', e.getMessage());
        }

        return returnValue;
    }
}
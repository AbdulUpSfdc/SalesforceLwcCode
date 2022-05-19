public with sharing class BWC_IMEISearchCallout {

    public static BWC_IMEISearch.IMEISearchResponse IMEISearch(String queryString){
        if(queryString==null) throw new BWC_Exception('queryString is null');
        
        //String requestBody = JSON.serialize(request, true);
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_IMEI_SEARCH, null,null,queryString);
        BWC_IMEISearch.IMEISearchResponse returnValue=new BWC_IMEISearch.IMEISearchResponse();
        try {
            returnValue = (BWC_IMEISearch.IMEISearchResponse) JSON.deserialize(response.getBody(), BWC_IMEISearch.IMEISearchResponse.class);
        } catch(JSONException e) {
            throw new BWC_Exception('Failed to deserialze HTTP response body.', e);
        }
        
        return returnValue;
    }
}
public with sharing class BWC_RSATokenCallout {

     public static BWC_RSAToken.RSATokenResponse getRSAToken(String params){
        if(params==null) throw new BWC_Exception('query String is null');
         HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_RSATOKEN, null, null, params, 'GET');
        BWC_RSAToken.RSATokenResponse returnValue=new BWC_RSAToken.RSATokenResponse();
        try {
            returnValue = (BWC_RSAToken.RSATokenResponse) JSON.deserialize(response.getBody(), BWC_RSAToken.RSATokenResponse.class);
        } catch(JSONException e) {
            throw new BWC_Exception('Failed to deserialze HTTP response body.', e);
        }
        
        return returnValue;
    }
}
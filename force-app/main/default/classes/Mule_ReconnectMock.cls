/**
 * Name - Mule_ReconnectMock
 * Description - Mock response for Mule_Reconnect Test
 * Date - 10/26/2021
 * Author - Akinsola Jegede @Salesforce
 */
@isTest
global class Mule_ReconnectMock implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
        Boolean isReqBodyOK = isRequestBodyOk(req.getBody());
        Integer statusCode =  isReqBodyOK ? 200:400;
        String messageBody =  isReqBodyOK ? 'Successful':'Failed';

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"message":"'+messageBody+'","description":"'+messageBody+'"}');
        res.setStatusCode(statusCode);
        return res;
    }

    private Boolean isRequestBodyOk(String reqBody){
       	Mule_Reconnect.WrapCallOutData body = (Mule_Reconnect.WrapCallOutData)JSON.deserializeStrict(reqBody,Mule_Reconnect.WrapCallOutData.class);
        if(String.isEmpty(body.dataFeedName)) return false;
        return true;
    }
}
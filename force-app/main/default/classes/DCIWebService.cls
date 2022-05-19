/*
* This class is the webservice to create a DCI checkin in Salesforce
* @Author: Reshma Jewrani, Alisha Mundaden
*/
@RestResource(urlMapping='/DCIlead/*')
global without sharing class DCIWebService {
    /* 
    *This method is to handle get request on the DCI web service.
    */
    @HttpGet
    global static String doGet(){

        return 'Service is up and Running';
    }
    /* 
    *This method is to handle post request on the DCI web service.
    */
    @HttpPost
    global static void doPost(){
        String jsonResponse;
        try{
            RestRequest request = RestContext.request;  
            String jSONRequestBody=request.requestBody.toString().trim();  
            Map<String, Object> requestMap = DCIService.validateDCILeadRequest(jSONRequestBody,'DCILead');
            RetailDTO.DCIResponseDTO responseDTO = DCIService.processRequest(requestMap);
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseDTO));
        }catch(RetailError.ClientSideException e){
            RestContext.response.statusCode = 400;
            RetailError.ErrorJsonResponse errs = new RetailError.ErrorJsonResponse('BAD_REQUEST', e.getMessage());
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(errs));
        }catch(Exception e){ //something else happened ServerSide
            RestContext.response.statusCode = 500;
            RetailError.ErrorJsonResponse errs = new RetailError.ErrorJsonResponse('SERVER_ERROR', e.getMessage());
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(errs));
        }
    } 
}
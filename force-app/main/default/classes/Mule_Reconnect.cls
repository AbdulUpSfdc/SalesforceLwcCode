/**
 * Name - Mule_Reconnect
 * Description - Callout class to resubmitted datafeed failure to mulesoft for reprocess
 * muleReconnect method is consumed imparatively by LWC
 * WrapCallOutData - wrapper class that defines data structure expected by client
 * Date - 10/26/2021
 * Author - Akinsola Jegede @Salesforce
 */
public with sharing class Mule_Reconnect {
    // Aura enabled method for component callout
    @AuraEnabled
    public static String muleReconnect(String jobType,String startDateTime,String endDateTime,String transactionNumbers){
        WrapCallOutData callOut = new WrapCallOutData(jobType,startDateTime,endDateTime,transactionNumbers);
        HttpResponse h = callOut.makeCallout();
        ResponseBody rb = new ResponseBody();
        
        //handle response. If response is not properly formed, display the status as message
        try{
            rb= (ResponseBody)JSON.deserialize(h.getBody(),ResponseBody.class);  
            rb.displayMessage = nullCheck(rb.message)+ '  '+ nullCheck(rb.description);
            if(rb.message== null && rb.description==null) rb.displayMessage = h.getStatus();
        }catch(Exception e){
            rb.displayMessage = h.getStatus();
        }
        
       	if(h.getStatusCode()==200) return 'Success';
        throw new AuraHandledException(rb.displayMessage);
    }
    private static String nullCheck(String value){
        if(value == null) return '';
        return value;
    }
   
    private class ResponseBody{
        private String description {get; set;}
        private String message {get; set;}
        private String displayMessage {get; set;}
    }
    
    @TestVisible
    private class WrapCallOutData{
        @TestVisible
        private String datafeedName {get; set;}
        @TestVisible
        private String startDateTime {get; set;}
        @TestVisible
        private String endDateTime {get; set;}
        @TestVisible
        private String transactionNumbers {get; set;}
 		
        private WrapCallOutData(String datafeedName,String startDateTime,String endDateTime,String transactionNumbers ){
            this.datafeedName = datafeedName;
            this.startDateTime = startDateTime;
            this.endDateTime = endDateTime;
            this.transactionNumbers = transactionNumbers;
        }

        private HttpResponse makeCallout() {
            
            Http h = new Http();
            HttpRequest req = new HttpRequest();

            //Form URL and Parameters
            String endpoint = 'callout:Mulesoft_Datafeed_Resubmission';
            
            //Set body of request
            String body = JSON.serialize(this);
			
            //Set client certificate
            req.setClientCertificateName('sf_named_credential_mulesoft_cacert');
            
            //Define Request Header
            req.setHeader('client_id', '{!$Credential.UserName}'); 
            req.setHeader('client_secret', '{!$Credential.Password}');
            req.setHeader('Content-Type', 'application/json');
            req.setEndpoint(endpoint);
            req.setMethod('POST');  
            req.setBody(body);
            req.setTimeout(120000);
           
            // Send the request, and return a response
            HttpResponse res = h.send(req);
           
            
            return res;
        }
    }
    
}
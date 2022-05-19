public without sharing class MessagingRequestHandler {
    
    
    public static List<MessagingRequest> processOutboundMessaging(string autoResponse, Id leadId, String phone, List<MessagingRequest> lstMessagingInputs, Boolean isStore, Boolean isAttCtn ){
        MessagingRequest  objOutboundSMS = getSMSFlowRequest(leadId, phone, autoResponse, isStore, isAttCtn);
        lstMessagingInputs.add(objOutboundSMS);

        return lstMessagingInputs;

    }

    /*
	* This method returns MessagingRequest object to send Welcome SMS Flow.
	*/
    public static MessagingRequest getSMSFlowRequest(Id targetRecordId, String phone, String content, Boolean isStore, Boolean isAttCtn){
        MessagingRequest messagingReq = new MessagingRequest();        
                 
         messagingReq.targetRecordId = targetRecordId;
         messagingReq.numberToSendTo = phone;
         messagingReq.isWelcomeSMSForStore = isStore;
         messagingReq.messagingContent = content;
         messagingReq.IsAttCTN = isAttCtn;
         return messagingReq;
    }


    public static void sendOutboundSMS(List<MessagingRequest> smsList, String flowInputName, String flowName) {
       
        Map<String, Object> flowInputs = new Map<String, Object>();       
        flowInputs.put(flowInputName, (Object)smsList);
        system.debug('NotificatonRequest to Flow----->' + flowInputs);
        if(!Test.isRunningTest())
        NotificationsHandler.callFlow(flowName, flowInputs);   
    
    }

    
    public static String getMessagingContentFormat(String shortCode, String contentToFormat, List<String> dynamicFiller){

        String formattedString = contentToFormat;
        if(dynamicFiller!=null)
        formattedString = String.format(formattedString, dynamicFiller);   
        List<String> responseFiller = new List<String>{formattedString};
        String autoMessage = '';
        List<RetailDCIAutoResponseSMS__mdt> listRetailAutoResponse = [SELECT id, AutoResponse__c 
                                                                     FROM  RetailDCIAutoResponseSMS__mdt 
                                                                     WHERE ShortCode__c = :shortCode];
        if(listRetailAutoResponse.size() > 0){                                                               
            autoMessage = String.format(listRetailAutoResponse[0].AutoResponse__c, responseFiller);
        }
        return autoMessage;
    }

}
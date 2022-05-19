public without sharing class SendSMSEWTChangesQueable implements Queueable, Database.AllowsCallouts {
    public Set<Id> increasedEWT;
    public Set<Id> decreasedEWT;
    //Constructor to get Messaging Session Ids to be processed 
    public SendSMSEWTChangesQueable(Set<Id> increasedEWT,Set<Id> decreasedEWT) {
        this.increasedEWT = increasedEWT;
        this.decreasedEWT = decreasedEWT;
    }
    
    /*
* This method will call the business logic in the ProcessMessagingSessionHelper Class 
*/
    public void execute(QueueableContext context) {
        List<RetailCheckinQueue__c> retailCheckInQueueList = [select EstimatedWaitTime__c,DCIEstimatedStartTime__c,DCICommunicatedStartTime__c,Lead__r.PreferedLanguage__c,Lead__c,Id,Lead__r.mobilePhone, Lead__r.IsAttCtn__c from  RetailCheckinQueue__c
                                                              where Id in: increasedEWT or Id in: decreasedEWT];
        
        for(RetailCheckinQueue__c rec : retailCheckInQueueList){
            if(increasedEWT.contains(rec.Id)){
                SendSms(rec,true);
            }else{
                SendSms(rec,false);
            }
        }
        //MessagingRequestHandler.sendOutboundSMS(lstMessagingInputs, 'MessageInput', DCIConstants.DCI_OUTBOUNDTEXT_FLOW);
    }
    
    public static void SendSms(RetailCheckInQueue__c retailRecord, Boolean isIncreased){
        string ss;
        List<MessagingRequest> lstMessagingInputs = new List<MessagingRequest>();
        Map<String, Object> MessagingRequest = new Map<String, Object>();
        
        MessagingRequest.put('RecordIdToAssociateTo',retailRecord.Lead__c);
        MessagingRequest.put('PhoneNumberToMessage',retailRecord.Lead__r.mobilePhone);
          string response = null;
       //string waitTime = String.valueof(RetailCheckinQueueTriggerHelper.getMinutesBetweenTwoDates(retailRecord.DCICommunicatedStartTime__c, retailRecord.DCIEstimatedStartTime__c));
       String waitTime = string.valueOf(retailRecord.EstimatedWaitTime__c);
       if(isIncreased){
            if(retailRecord.Lead__r.PreferedLanguage__c == 'English'){
              response =  MessagingRequestHandler.getMessagingContentFormat(RetailConstants.EWTCheckinIncreaseE,waitTime,null);
              lstMessagingInputs =  MessagingRequestHandler.processOutboundMessaging(response, retailRecord.Lead__c, retailRecord.Lead__r.MobilePhone, lstMessagingInputs, false, retailRecord.Lead__r.IsAttCtn__c);  
            }             
              else{
                response =  MessagingRequestHandler.getMessagingContentFormat(RetailConstants.EWTCheckinIncreaseS,waitTime,null);
           // MessagingRequest.put('MessageToSend',response);
            lstMessagingInputs =  MessagingRequestHandler.processOutboundMessaging(response, retailRecord.Lead__c, retailRecord.Lead__r.MobilePhone, lstMessagingInputs, false, retailRecord.Lead__r.IsAttCtn__c);
              }
          }
        else {
             if(retailRecord.Lead__r.PreferedLanguage__c == 'English'){
              response =  MessagingRequestHandler.getMessagingContentFormat(RetailConstants.EWTCheckinDecreaseE,waitTime,null);
              lstMessagingInputs =  MessagingRequestHandler.processOutboundMessaging(response, retailRecord.Lead__c, retailRecord.Lead__r.MobilePhone, lstMessagingInputs, false, retailRecord.Lead__r.IsAttCtn__c);  
            } 
              else {
                response =  MessagingRequestHandler.getMessagingContentFormat(RetailConstants.EWTCheckinDecreaseS,waitTime,null);
          //  MessagingRequest.put('MessageToSend',response);
            lstMessagingInputs =  MessagingRequestHandler.processOutboundMessaging(response, retailRecord.Lead__c, retailRecord.Lead__r.MobilePhone, lstMessagingInputs, false, retailRecord.Lead__r.IsAttCtn__c);
              }
          }
       // MessagingRequest.put('MessagingChannelDeveloperName',RetailConstants.TFN_DCI);
       // MessagingRequest.put('MessageId','');
       // NotificationsHandler.callFlow('RetailLeadSendSMS', MessagingRequest);   
       MessagingRequestHandler.sendOutboundSMS(lstMessagingInputs, 'MessageInput', DCIConstants.DCI_OUTBOUNDTEXT_FLOW); 
    }
}
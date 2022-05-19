/*
* This class is used to build the Messaging Request to call Outbound Message Flow from Apex.
* Author: Mohit Pandey
*/
public class MessagingRequest {
    @AuraEnabled
    public Id targetRecordId;
    @AuraEnabled
    public String numberToSendTo;
    @AuraEnabled
    public String messagingContent;    
    @AuraEnabled
    public Boolean isWelcomeSMSForStore;  
    @AuraEnabled
    public Boolean IsAttCTN;
    
   
}
/*
* This class is used to build the Messaging Request to call Outbound Message Flow from Apex.
* Author: Ravindra
*/
public class MessageCollection {
    
    @AuraEnabled
    public String IsWelcome;
    @AuraEnabled
    public String MessageId;
    @AuraEnabled
    public String MessageToSend;
    @AuraEnabled
    public String MessagingChannelDeveloperName;
    @AuraEnabled
    public String MessagingMessageId;
    @AuraEnabled
    public String PhoneNumberToMessage;
    @AuraEnabled
    public String RecordIdToAssociateTo;
    @AuraEnabled
    public String SentSMSMessage;    
    
    public MessageCollection(){
      
    }
    
}
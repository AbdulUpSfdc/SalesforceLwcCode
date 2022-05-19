public with sharing class BWC_CommunicationTemplateService {

    public static void updateCommRecord(String templateId, string templateName, string communicationRecordId){
        String uniqueTemplateName;
        String objName = Id.valueOf(templateId).getSObjectType().getDescribe().getName();
        Communication_Template_Mapping__c commTemplate =[select Id,Email_Template_Id__c,EmailTemplate__c,SMS_Template_Id__c,SMS_Template__c,SMS_Template_Unique_Name__c from Communication_Template_Mapping__c where Id=:communicationRecordId  WITH SECURITY_ENFORCED LIMIT 1];
        switch on objName {
            when 'EmailTemplate' {
                commTemplate.Email_Template_Id__c=templateId;
                commTemplate.EmailTemplate__c=templateName;
            }
            when 'MessagingTemplate' {
                uniqueTemplateName = [Select Id, DeveloperName from MessagingTemplate where Id =:templateId ].DeveloperName;
                commTemplate.SMS_Template_Id__c=templateId;
                commTemplate.SMS_Template__c=templateName;
                commTemplate.SMS_Template_Unique_Name__c = uniqueTemplateName;
            }
            when else { // default block, optional
            }
        }
        update commTemplate;

    }
 
    //This Method Deletes the Communication Template Record with the Selected Email Template
    public static void deleteCommRecord(String templateId, string templateName, string communicationRecordId){
     String objName = Id.valueOf(templateId).getSObjectType().getDescribe().getName();     
     Communication_Template_Mapping__c commTemplate =[select Id,Email_Template_Id__c,EmailTemplate__c,SMS_Template_Id__c,SMS_Template__c,SMS_Template_Unique_Name__c from Communication_Template_Mapping__c where Id=:communicationRecordId WITH SECURITY_ENFORCED LIMIT 1 ];
     switch on objName {
         when 'EmailTemplate' {
            commTemplate.Email_Template_Id__c='';
            commTemplate.EmailTemplate__c='';
         }
         when 'MessagingTemplate' {
            commTemplate.SMS_Template_Id__c='';
            commTemplate.SMS_Template__c='';
            commTemplate.SMS_Template_Unique_Name__c = '';
         }
         when else { // default block, optional 
         }
     }
     update commTemplate;

    }

    //This Method Retrives the Communication Template Record on load of the page
    public static List<Communication_Template_Mapping__c> getCommunicationRecord(string communicationRecordId){
        List<Communication_Template_Mapping__c> commTemplate =[select Id,Email_Template_Id__c,EmailTemplate__c,SMS_Template_Id__c,SMS_Template__c,SMS_Template_Unique_Name__c from Communication_Template_Mapping__c where Id=:communicationRecordId WITH SECURITY_ENFORCED LIMIT 1 ];
        return commTemplate;
    }
    
}
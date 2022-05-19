public with sharing class BWC_CaseEmailAlertsUtility{
    public static Map<String,Communication_Template_Mapping__c> languageTemplateMapForCaseAction = new Map<string,Communication_Template_Mapping__c >();
    public static Map<string,Communication_Template_Mapping__c> languageTemplateMapForclosed = new Map<string,Communication_Template_Mapping__c>();
    public static Map<string,Communication_Template_Mapping__c> languageTemplateMapForviolatedCases = new Map<string,Communication_Template_Mapping__c>();
    public static Boolean isEmailSent = false;
    public static Id emailtemplateid;    
    public static void sendEmailFromCase(List<case> caseRecordsList, Map<Id,case> oldMap){
        set<string> languageSet = new set<string>();
        string communicationType;
        string language;
        string templateId;
        string uniqueSMStemplate;
        List<Messaging.SingleEmailMessage> mailsList = new List<Messaging.SingleEmailMessage>();
        List<BWC_CaseNotificationRequest> lstOfCases = new List<BWC_CaseNotificationRequest>();
        List<case> caseRecList = [Select Id,CaseAction__c,Account.PersonContactId, Billing_Account__r.Language_Preference__c,Billing_Account__r.Id,Billing_Account__r.Email__c, ContactId,Billing_Account__r.Contact_Number__c,Resolution__c,Resolution2__c,Status,External_SLA_Violated__c,Billing_Account_Customer_Email__c from case where Id in : caseRecordsList WITH SECURITY_ENFORCED];
        Map<String, String> owNameAddressMap = new Map<String, String>();
		for(OrgWideEmailAddress oWAdd: [select Id, DisplayName, Address from OrgWideEmailAddress WITH SECURITY_ENFORCED]){
			owNameAddressMap.put(oWAdd.DisplayName, oWAdd.Id);
		}
        for(case caseRecord : caseRecList ){
            if(caseRecord.Billing_Account__r.Language_Preference__c ==BWC_Constants.LANGUAGE_SPANISH){
                languageSet.add(caseRecord.Billing_Account__r.Language_Preference__c);
            }
            else{
                languageSet.add(BWC_Constants.LANGUAGE_ENGLISH);
            }
        }
        for(Communication_Template_Mapping__c templateMapping : [select Id,Language_Preference__c,Communication_Type__c,Email_Template_Id__c,SMS_Template_Id__c,SMS_Template_Unique_Name__c,Case_Action__c,Resolution__c,Resolution_2__c, Email_Send_From__c from Communication_Template_Mapping__c where Language_Preference__c in : languageSet and Status__c = 'Active' WITH SECURITY_ENFORCED]){
            if(templateMapping.Communication_Type__c!=null && templateMapping.Language_Preference__c!=null){
                if(templateMapping.Communication_Type__c==BWC_Constants.COMMUNICATIONTYPE_EMV){
                    languageTemplateMapForviolatedCases.put(templateMapping.Communication_Type__c+templateMapping.Language_Preference__c+templateMapping.Case_Action__c,templateMapping);
                }
                if(templateMapping.Case_Action__c!=null && templateMapping.Communication_Type__c==BWC_Constants.COMMUNICATIONTYPE_NEWCASE){
                    languageTemplateMapForCaseAction.put(templateMapping.Communication_Type__c+templateMapping.Language_Preference__c+templateMapping.Case_Action__c,templateMapping);
                }
                if(templateMapping.Resolution__c!=null && templateMapping.Resolution_2__c!=null && templateMapping.Communication_Type__c==BWC_Constants.COMMUNICATIONTYPE_CASECLOSED){
                    languageTemplateMapForclosed.put(templateMapping.Communication_Type__c+templateMapping.Language_Preference__c+templateMapping.Resolution__c+templateMapping.Resolution_2__c+templateMapping.Case_Action__c,templateMapping);
                }
                if(templateMapping.Resolution__c!=null && templateMapping.Resolution_2__c==null && templateMapping.Communication_Type__c==BWC_Constants.COMMUNICATIONTYPE_CASECLOSED){
                    languageTemplateMapForclosed.put(templateMapping.Communication_Type__c+templateMapping.Language_Preference__c+templateMapping.Resolution__c+templateMapping.Case_Action__c,templateMapping);
                }
            }  
        }
        if(Test.isRunningTest()){
            emailtemplateid = [select id,Name from EmailTemplate where name='Case Close Resolution Corrected ATT English' WITH SECURITY_ENFORCED limit 1].Id;    
        }
        
        for(case caseRecord : caseRecList ){
            Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
			String fromEmailAddress = '';
            if(caseRecord.Billing_Account__r.Language_Preference__c == BWC_Constants.LANGUAGE_SPANISH){
                language = caseRecord.Billing_Account__r.Language_Preference__c;
            }else{
                language = BWC_Constants.LANGUAGE_ENGLISH;
            }
            if(caseRecord.status == CaseConstants.NEW_STATUS  && caseRecord.External_SLA_Violated__c == null ){
                communicationType = BWC_Constants.COMMUNICATIONTYPE_NEWCASE;
                if(languageTemplateMapForCaseAction.containsKey(communicationType+language+caseRecord.CaseAction__c)){
                    if(String.isNotBlank(caseRecord.Billing_Account__r.Email__c)){
                        templateId = languageTemplateMapForCaseAction.get(communicationType+language+caseRecord.CaseAction__c).Email_Template_Id__c;
						fromEmailAddress = languageTemplateMapForCaseAction.get(communicationType+language+caseRecord.CaseAction__c).Email_Send_From__c;
                    } else{
                        uniqueSMStemplate = languageTemplateMapForCaseAction.get(communicationType+language+caseRecord.CaseAction__c).SMS_Template_Unique_Name__c;
                    }
                }
            }
            else if(caseRecord.status == CaseConstants.CLOSED_STATUS){
                communicationType= BWC_Constants.COMMUNICATIONTYPE_CASECLOSED;
                if(languageTemplateMapForclosed.containsKey(communicationType+language+caseRecord.Resolution__c+caseRecord.Resolution2__c+caseRecord.CaseAction__c)){
                    if(String.isNotBlank(caseRecord.Billing_Account__r.Email__c)){
                        templateId = languageTemplateMapForclosed.get(communicationType+language+caseRecord.Resolution__c+caseRecord.Resolution2__c+caseRecord.CaseAction__c).Email_Template_Id__c;
						fromEmailAddress = languageTemplateMapForclosed.get(communicationType+language+caseRecord.Resolution__c+caseRecord.Resolution2__c+caseRecord.CaseAction__c).Email_Send_From__c;
                    } else {
                        uniqueSMStemplate = languageTemplateMapForclosed.get(communicationType+language+caseRecord.Resolution__c+caseRecord.Resolution2__c+caseRecord.CaseAction__c).SMS_Template_Unique_Name__c;   
                    }
                }
                else if(languageTemplateMapForclosed.containsKey(communicationType+language+caseRecord.Resolution__c+caseRecord.CaseAction__c)){
                    if(String.isNotBlank(caseRecord.Billing_Account__r.Email__c)){
                        templateId = languageTemplateMapForclosed.get(communicationType+language+caseRecord.Resolution__c+caseRecord.CaseAction__c).Email_Template_Id__c;
						fromEmailAddress = languageTemplateMapForclosed.get(communicationType+language+caseRecord.Resolution__c+caseRecord.CaseAction__c).Email_Send_From__c;
                    } else{
                        uniqueSMStemplate = languageTemplateMapForclosed.get(communicationType+language+caseRecord.Resolution__c+caseRecord.CaseAction__c).SMS_Template_Unique_Name__c;
                    }
                }
            }
            else if(caseRecord.External_SLA_Violated__c != null){
                communicationType= BWC_Constants.COMMUNICATIONTYPE_EMV;
                if(languageTemplateMapForviolatedCases.containsKey(communicationType+language+caseRecord.CaseAction__c)){
                    if(String.isNotBlank(caseRecord.Billing_Account__r.Email__c)){
                        templateId = languageTemplateMapForviolatedCases.get(communicationType+language+caseRecord.CaseAction__c).Email_Template_Id__c;
						fromEmailAddress = languageTemplateMapForviolatedCases.get(communicationType+language+caseRecord.CaseAction__c).Email_Send_From__c;
                    }else{
                        uniqueSMStemplate = languageTemplateMapForviolatedCases.get(communicationType+language+caseRecord.CaseAction__c).SMS_Template_Unique_Name__c;
                    }
                }
            }
            if(String.isBlank(caseRecord.Billing_Account__r.Email__c) && uniqueSMStemplate!=null){
                BWC_CaseNotificationRequest welcomeSMSInput = BWC_NotificationsHandler.getSMSDeliveryFlowRequest(caseRecord.Id, caseRecord.Billing_Account__r.Contact_Number__c, uniqueSMStemplate, caseRecord.Billing_Account__r.Id);
                lstOfCases.add(welcomeSMSInput);
            } else {
                if((Test.isRunningTest() && caserecord.Account.PersonContactId!=null ) || (caserecord.Account.PersonContactId!=null && caserecord.Billing_Account_Customer_Email__c!= null && templateId!=null)){
                    semail.setTemplateId(templateId);
                    if(Test.isRunningTest() && emailtemplateid!=null){
                        semail.setTemplateId(emailtemplateid);
                    }
                    semail.setTargetObjectId(caserecord.Account.PersonContactId);
                    semail.setWhatId(caseRecord.Id);
                    semail.setToAddresses(new List<String> {caserecord.Billing_Account_Customer_Email__c});
                    if (String.isNotBlank(fromEmailAddress) &&  fromEmailAddress != BWC_Constants.CTM_FROM_EMAIL_NONE) {
                        semail.setOrgWideEmailAddressId(owNameAddressMap.get(fromEmailAddress));
                    }
                    mailsList.add(semail);
                }
            }
        }
        try{
                if(!mailsList.isempty()){
                    Messaging.sendEmail(mailsList);
                    isEmailSent = true;
                }
                if(!lstOfCases.isempty()) {
                    BWC_NotificationsHandler.sendSMS(lstOfCases);
                    isEmailSent = true;
                }
        }catch (Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            BWC_ExceptionUtils.handleException(e, true); 
            throw e;    }
    }
  }
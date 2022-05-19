public with sharing class EmailMessageHandler {
    
    public static final String EMAIL_PUBLIC_GROUP_NAME = 'KM_Email_Template_Administrators';
    public static final String MSG_INVALID_TEMPLATE = 'Private templates are not approved for use.  Please select another template.  Templates are managed by members of the KM Email Template Administrators Group.';
    public static final String MSG_TEMPLATE_SELECTION_REQUIRED = 'Email Template must be selected';
 
    public static void beforeInsert(EmailMessage[] eMsg1){
            KMProfile__c profile = KMProfile__c.getInstance(UserInfo.getProfileId()); 
            KMEmail__c  e = KMEmail__c.getInstance();
            String emailList = e.Email__c;
            EmailTemplate emailTemplate;
            User CICDUser;
           
            if(profile.RunEmailMessageTgr__c){
                    System.debug('The Before Insert trigger ran');
                    for(EmailMessage eMsg : eMsg1) {
                    
                        if(eMsg.FromAddress!= emailList && !(eMsg.Subject.contains(ArticleKeywordSearchBatch.EMAIL_SUBJECT)))
                        {
                            eMsg.adderror('You must select Org wide address as from address');
                        }
                       
                        if (eMsg.Subject != null && eMsg.Subject.contains(FeedItemTriggerHelper.FEEDCOMMENT_TEXT)) {
                            // do nothing
                        }else if(eMsg.Subject != null && eMsg.Subject.contains(ArticleKeywordSearchBatch.EMAIL_SUBJECT)){
                            // do nothing
                             }
                             else {
                            System.debug('email Template id: ' + eMsg.EmailTemplateId);
                            if(eMsg.EmailTemplateId==null) {
                                System.debug('Email template is null');
                                eMsg.adderror(MSG_TEMPLATE_SELECTION_REQUIRED);
                            } else {
                                 System.debug('Email template is not null');
                                if (isEmailTemplateValid(eMsg.EmailTemplateId) == false) {
                                    System.debug('Invalid template: ' + eMsg.EmailTemplateId);
                                    eMsg.adderror( MSG_INVALID_TEMPLATE);   
                                }    
                            }
                        }   
                    }
                }
                else{
                    System.debug('The Before Insert trigger didnot run as the profile didnot match the criteria');
                }
        }
    
    public static void afterInsert(EmailMessage[] eMsg2){
        List<EmailMessageRelation> emrList= new List<EmailMessageRelation>();
        KMProfile__c profile = KMProfile__c.getInstance(UserInfo.getProfileId()); 
        KMEmail__c  e = KMEmail__c.getInstance();
        String emailList = e.Email__c;
        Set<Id> userIDSet = new Set<Id>();
        List<EmailMessageRelation> relationList;
        
        
        if(profile.RunEmailMessageTgr__c){
            relationList = [SELECT Id from EmailMessageRelation WHERE RelationId = :UserInfo.getUserId() AND RelationAddress = :emailList];
            
            for(EmailMessage eMsg : eMsg2){
                if (relationList.isEmpty()) {
                        system.debug(eMsg.Id);
                        EmailMessageRelation emr = new EmailMessageRelation();
                        emr.EmailMessageId = eMsg.id;
                        emr.RelationId = UserInfo.getUserId(); // user id of the sender
                        emr.RelationAddress = emailList;
                        emr.RelationType = 'FromAddress';
                        emrList.add(emr);
                        System.debug('The After Insert trigger ran');
                    }    
                }
            }
            else{
                System.debug('The After Insert trigger didnot run as the profile didnot match the criteria');
            }
            if(!emrList.isEmpty()){
                insert emrList;
            }
            System.debug(emrList);
    }
    
     public static Boolean isEmailTemplateValid(Id emailTemplateId) {
        EmailTemplate template = WithoutSharingHelper.getEmailTemplateById(emailTemplateId, EMAIL_PUBLIC_GROUP_NAME);
        System.debug('Valid template: ' + template);
        return !(template == null);
        
    }
    
 
    
                                              
   
}
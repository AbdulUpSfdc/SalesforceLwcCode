public inherited sharing class BWC_EmailMessageTriggerHandler extends SFS_TriggerHandler {

    private static final String HEADER_LINE_DELIM = '\n';
    private static final String HEADER_KVP_DELIM = ':';
    private static final String HEADER_SES = 'X-SES-Outgoing';
    private static final String HEADER_REPLY_TO = 'Reply-To';
    private static final String EMAIL_START = '<';
    private static final String EMAIL_END = '>';

    private static final String MSG_INVALID_TEMPLATE = 'Private templates are not approved for use.  Please select another template.  Templates are managed by members of the KM Email Template Administrators Group.';
    private static final String MSG_TEMPLATE_SELECTION_REQUIRED = 'Email Template must be selected';
    @TestVisible private static final String EMAIL_PUBLIC_GROUP_NAME = 'KM_Email_Template_Administrators';

    private static final List<String> AUTO_REOPEN_CASE_RECORD_TYPE_LIST = new List<String>{'Wireline Escalation','Escalation'};
    private static final String RESOLUTION_CODE_PREFIX_MATCH = 'Additional';  

    //Runs before insert and update
    protected override void preValidate(List<SObject> records) {
        //Retrieving custom settings related to KM Profile & Email
        KMProfile__c profile = KMProfile__c.getInstance(UserInfo.getProfileId()); 
        KMEmail__c  e = KMEmail__c.getInstance();
        String emailList = e.Email__c;

        if(profile.RunEmailMessageTgr__c) {
            checkKMEmailAddressAndTemplate(records, emailList);
        } else {
            System.debug('The Before Insert trigger didnot run as the profile didnot match the criteria');
        }
        //Check every oubound email send from Case Record page
        restrictEmailSenderOnCase(records);

        //Check every inbound email for AWS SES headers
        for (EmailMessage emailMsg : (List<EmailMessage>) records) {
            if(emailMsg.Incoming) {
                updateFromAddressForSES(emailMsg);
            }  
        }  
    }
    //Runs after Insert or Undelete by the framework
    protected override void postInsert(List<SObject> records) {
        
        relateAndInsertEmailMsgRelationRec(records);
        emailToCaseReopen(records);
    }
    
    // 15329 - Allow closed Wireline & Wireless cases to be auto reopened after email reply
    public static void emailToCaseReopen(List<SObject> records) {
        Set<Id> caseIds = new Set<Id>();
        List<Case> casesToReopen = new List<Case>();
         
    	//ParentId = related CaseId
        for (EmailMessage emailMsg : (List<EmailMessage>) records) {
            if(emailMsg.ParentId != null){
                caseIds.add(emailMsg.ParentId);
            }
        }
        
        if(!caseIds.isEmpty()) {
            casesToReopen.addAll(filterCasesToReopen(caseIds));
        }
        
        if(!casesToReopen.isEmpty()) {
            reopenCase(casesToReopen);
        }
    }

    // 13811 - Preventing users w/o edit access to Case from sending emails
    public void restrictEmailSenderOnCase(List<SObject> records) {
        // Creating list of case IDs
        Set<Id> caseList = new Set<Id>();
        for (EmailMessage email : (List<EmailMessage>) records) {
            if(String.isNotBlank(email.ParentId)) {
                caseList.add(email.ParentId);
            }
        }

        // Querying UserRecordAccess based on list of case IDs and creating map
        List<UserRecordAccess> userRecordAccessList = [
            SELECT RecordId, HasEditAccess
            FROM UserRecordAccess
            WHERE UserId = :UserInfo.getUserId() AND RecordId IN :caseList
        ];

        if(!userRecordAccessList.isEmpty() && userRecordAccessList != null) {
            Map<Id, UserRecordAccess> recordAccessMap = new Map<Id, UserRecordAccess>();
            for (UserRecordAccess record : userRecordAccessList) {
                recordAccessMap.put(record.RecordId, record);
            }
            //Checking if user has edit access and handling error
            for (EmailMessage email : (List<EmailMessage>) records) {
                if (recordAccessMap.containsKey(email.ParentId) &&
                    recordAccessMap.get(email.ParentId).HasEditAccess == false) {
                    addError(email, System.Label.BWC_EmailMessage_Invalid_Permissions);
                }
            }
        }
    }
    
    //14823 - Consolidating emailmessage trigger handlers. Moved KM business logic to a method
    @TestVisible
    private static void checkKMEmailAddressAndTemplate(List<SObject> records, String emailList) {
        
        for(EmailMessage emailMsg : (List<EmailMessage>) records) {
            if(emailMsg.FromAddress!= emailList && !(emailMsg.Subject.contains(ArticleKeywordSearchBatch.EMAIL_SUBJECT)))
            {
                emailMsg.adderror('You must select Org wide address as from address');
            }
            if (emailMsg.Subject != null && emailMsg.Subject.contains(FeedItemTriggerHelper.FEEDCOMMENT_TEXT)) {
                // do nothing
            } else if(emailMsg.Subject != null && emailMsg.Subject.contains(ArticleKeywordSearchBatch.EMAIL_SUBJECT)){
                // do nothing
            } else {
                System.debug('email Template id: ' + emailMsg.EmailTemplateId);
                if(emailMsg.EmailTemplateId==null) {
                    System.debug('Email template is null');
                    emailMsg.adderror(MSG_TEMPLATE_SELECTION_REQUIRED);
                } else {
                    System.debug('Email template is not null');
                    if (isEmailTemplateValid(emailMsg.EmailTemplateId) == false) {
                        System.debug('Invalid template: ' + emailMsg.EmailTemplateId);
                        emailMsg.adderror( MSG_INVALID_TEMPLATE);   
                    }    
                }
            }   
        }
    }

    public static Boolean isEmailTemplateValid(Id emailTemplateId) {
        EmailTemplate template = WithoutSharingHelper.getEmailTemplateById(emailTemplateId, EMAIL_PUBLIC_GROUP_NAME);
        System.debug('Valid template: ' + template);
        return !(template == null);
    }

    //14823 - Consolidating emailmessage trigger handlers. Moved KM business logic to a method
    private static void relateAndInsertEmailMsgRelationRec(List<SObject> records) {
        List<EmailMessageRelation> emrList= new List<EmailMessageRelation>();
        KMProfile__c profile = KMProfile__c.getInstance(UserInfo.getProfileId()); 
        KMEmail__c  e = KMEmail__c.getInstance();
        String emailList = e.Email__c;
        Set<Id> userIDSet = new Set<Id>();
        List<EmailMessageRelation> relationList;
        
        if(profile.RunEmailMessageTgr__c){
            relationList = [SELECT Id from EmailMessageRelation WHERE RelationId = :UserInfo.getUserId() AND RelationAddress = :emailList];
            
            for(EmailMessage eMsg : (List<EmailMessage>) records){
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
        else {
            System.debug('The After Insert trigger didnot run as the profile didnot match the criteria');
        }
        if(!emrList.isEmpty()) {
            insert emrList;
        }
        System.debug(emrList);
    }

    /** 
     * Added as a part of 14823 story
     * This method is used to update the 'FromAddress' of the email message for
     * email messages that were forwarded through AWS
     */
    @TestVisible
    private static void updateFromAddressForSES(EmailMessage message)
    {
            // update the FromAddress if it was forwarded via Amazon SES
            Map<String, String> headers = getEmailHeaderMap(message);
            // check if this message was forwarded by Amazon SES
            // AND contains the 'Reply-To' header
            if (headers.containsKey(HEADER_SES) &&
                headers.containsKey(HEADER_REPLY_TO))
            {
                // parse the email address out of the Reply-To header
                String replyTo = headers.get(HEADER_REPLY_TO);
                // check if the reply-to contains a formatted email: "First Last <email@company.com>"
                if (replyTo.contains(EMAIL_START))
                {
                    replyTo = replyTo.substringBetween(EMAIL_START, EMAIL_END);
                }
                // update the FromAddress to the Reply-To for forwarded messages
                message.FromAddress = replyTo;
            }
    }

    /**
     * Added as a part of 14823 story
     * This method is used to convert the email headers of an EmailMessage into
     * a Map that can be used to process header fields.
     */
    @TestVisible
    private static Map<String, String> getEmailHeaderMap(EmailMessage message)
    {
        // define the return map
        Map<String, String> headerMap = new Map<String, String>();
        // split the headers into their separate lines
        List<String> headerLines = message.Headers.split(HEADER_LINE_DELIM);
        // loop through the header lines, split into KVP, and add to map
        for (String header : headerLines)
        {
            // split the header by the first colon to create the KVP
            List<String> kvp = header.split(HEADER_KVP_DELIM, 2);

            // check if we split the KVP correctly...
            if (!kvp.isEmpty() && kvp.size() > 1)
            {
                // add header to the map
                headerMap.put(kvp[0], kvp[1]);
            }
        }

        return headerMap;
    }

    /**
     * Method to retrieve record type id by name
     * @param recordTypeName Name of the record type from the config
     * @return Id Returns the Id for the record type 
     */
    @TestVisible
    private static String getRecordTypeIdByName(String recordTypeName) {
        return Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
    }

    /**
     * Method to filter closed cases by Resolution
     * @param caseIds Set of case Ids (originally as parent id on an inbound email message)
     * @return casesToReopen Filtered list of cases to reopen 
     */
    @TestVisible
    private static List<Case> filterCasesToReopen(Set<Id> caseIds) {
        List<String> validRecordTypeIds = new List<String>();
        List<Case> casesToReopen = new List<Case>();

        //Get record type ids for which Auto Case Reopen functionality should trigger
        for (String recordTypeName : AUTO_REOPEN_CASE_RECORD_TYPE_LIST) {
            validRecordTypeIds.add(getRecordTypeIdByName(recordTypeName));
        }
         
        // Get closed case records by Ids and valid Record Type Ids
        List<Case> filteredClosedCases = [
            SELECT Id, RoutingAction__c, Days_since_Close__c, Resolution__c, Case_Type__c, RecordTypeId, Status
            FROM Case
            WHERE Id IN :caseIds AND RecordTypeId IN :validRecordTypeIds  AND Status = 'Closed' AND Days_since_Close__c <= 60 AND Case_Type__c != 'Billing | Adjustment WLN'   
        ];

        //Filter closed cases by Resolution LIKE 'No Additional%'. Can't be added to WHERE clause as its a picklist field
        for (Case closedCase : filteredClosedCases) {
            String resolution = closedCase.Resolution__c;
            if(String.isNotBlank(resolution) && resolution.startsWith(RESOLUTION_CODE_PREFIX_MATCH)) {
                casesToReopen.add(closedCase);
            }
        }

        return casesToReopen;
    }

    /**
     * Method to Reopen cases by setting the Status to New and Routing Action to Tier 1
     * @param casesToReopen Filtered closed cases by resolution that should be reopened
     */
    @TestVisible
    private static void reopenCase(List<Case> casesToReopen) {
        List<Case> casesToUpdate = new List<Case>();
        for (Case emailCase : casesToReopen) {
            emailCase.Status = CaseConstants.CASE_STATUS_NEW;
            emailCase.RoutingAction__c = CaseConstants.ROUTE_ACTION_TIER_1;
            casesToUpdate.add(emailCase);
        }
        // Update Cases
        try {
        	update casesToUpdate; 
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }

    }
}
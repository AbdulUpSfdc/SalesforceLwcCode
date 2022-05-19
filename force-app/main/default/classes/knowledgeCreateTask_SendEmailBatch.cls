global with sharing class knowledgeCreateTask_SendEmailBatch implements Database.Batchable<sObject>,Database.Stateful{
    
    public static final String DEFAULT_DATE_PARAMETER = 'DAY_ONLY(FutureReviewDate__c)=TODAY OR FutureReviewDate__c = null';
    public static final String SETTING_MASTER_LABEL = 'KM FRD Batch Base Setting';
    public static final String BATCH_LOGGING_ERROR_LABEL = 'KMFRDError';
    public static final String BATCH_LOGGING_INFO_LABEL = 'KMFRDBatch';
    public static final String BASE_QUERY = 'SELECT Id,PublishStatus,Title,FutureReviewDate__c,ContentSponsor__c,BWSecContentSponsor__c,LastModifiedById,LastModifiedBy.Email '
        										+'FROM Knowledge__kav WHERE  publishstatus = \'Online\' AND (';	

    string sponsorPostFix = '@att.com';
    string htmlBody = '';
    string htmlBodySecCS = '';
    global Map<Id,String> contentSponsorEmail = new Map<Id,String>();
    global Map<Id,String> ownerEmail = new Map<Id,String>();
    Id orgwideIdAddressId;
    String displayName = 'Message From AT&T';
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
       String dateParameter = DEFAULT_DATE_PARAMETER;
       dateParameter = getQueryParameters();
       String query = BASE_QUERY +  dateParameter + ')'; 
       system.debug('query'+query); 
       Logger.info('Initiating Logging for new batch job', BC.getJobId());
       Logger.info('FRD Query to validate: ' + query, BC.getJobId()).setTopics(new List<String>{BATCH_LOGGING_INFO_LABEL});
        if ( dateParameter != DEFAULT_DATE_PARAMETER) {
        	 Logger.info('Using override date parameters: ' + dateParameter, BC.getJobId()); 
             Logger.saveLog();
        } else {
             Logger.info('Using preset date parameters: ' + dateParameter, BC.getJobId());
             Logger.saveLog();
        }
       
        if (validateQuery(query) == false) {
        	makeLog(BC.getJobId(), 'UNABLE TO RUN FRD BATCH; INVALID QUERY: ' + query);
            System.debug('UNABLE TO RUN FRD BATCH; INVALID QUERY: ' + query);
            return null;
        }
      
        
       
        return Database.getQueryLocator(query);
        
    }
    global void execute(Database.BatchableContext BC, List<Knowledge__kav> scope)
    {
        system.debug('Scope'+scope);
        List<Task> lstTasktoInsert = new List<Task>();
        Set<Task> lstTasktoInsertSet = new Set<Task>();
        Set<Id> taskIdSet = new Set<Id>();
        Set<Id> knowledgeIdSet = new Set<Id>();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<String> lstSponsorUID=new List<String>();
        List<String> lstSecSponsorUID=new List<String>();
        Map<String,Knowledge__kav> knowledgeMap = new Map<String,Knowledge__kav>();
        Map<String, String> emailToUserMap = new Map<String, String>();
        Map<String, User> nameToUserMap = new Map<String, User>();
        Map<Id, String> failedArticles = new  Map<Id, String>();
        Set<Id> knowledgeNeedsTask = new Set<Id>();
        Set<Id> knowledgeNoTask = new Set<Id>();
        Map<Id, Knowledge__kav> knowledgeIdMap = new  Map<Id, Knowledge__kav>(scope);
        Map<String,Task> knowledgeTaskMap = new Map<String,Task>();
      //  List<Task> taskCount = new List<Task>();
        
        
         Logger.info('Processing these articles: ' + JSON.serialize(knowledgeIdMap.keySet()), BC.getJobId()).setTopics(new List<String>{BATCH_LOGGING_INFO_LABEL});
         Logger.saveLog();
            
        try {
        for(Knowledge__kav knowledge : scope)
        {
            knowledgeIdSet.add(knowledge.Id);
            if(knowledge.ContentSponsor__c!=''){
                contentSponsorEmail.put(knowledge.Id,knowledge.ContentSponsor__c + sponsorPostFix);
                lstSponsorUID.add(knowledge.ContentSponsor__c);
                
                knowledgeMap.put(knowledge.Id,knowledge);
                
            }
            if(null != knowledge.BWSecContentSponsor__c && knowledge.BWSecContentSponsor__c != ''){
                lstSecSponsorUID.add(knowledge.BWSecContentSponsor__c);
            }
            ownerEmail.put(knowledge.Id,knowledge.LastModifiedBy.Email);
        }
        
        List<User> lstSponsors =[SELECT Email,ATTUID__c,ManagerId,Manager.Email,FirstName,LastName,FederationIdentifier FROM User where FederationIdentifier=:lstSponsorUID 
                                    OR FederationIdentifier=:lstSecSponsorUID];
        for(User u : lstSponsors){
            System.debug('u.Federationidentifier=' + u.FederationIdentifier );
            emailToUserMap.put(u.FederationIdentifier.toLowerCase(),u.Email);  
            nameToUserMap.put(u.FederationIdentifier.toLowerCase(),u);
            system.debug('nameToUserMap'+nameToUserMap);
        }
      
        System.debug('Email to user Map ' + emailToUserMap);
        System.debug('Name to user Map ' + nameToUserMap);
        Logger.info('Email to user Map ' + emailToUserMap, BC.getJobId()).setTopics(new List<String>{BATCH_LOGGING_INFO_LABEL});
        Logger.info('Name to user Map ' + nameToUserMap, BC.getJobId()).setTopics(new List<String>{BATCH_LOGGING_INFO_LABEL});
       	Logger.saveLog();    
    
            
        for(Task taskRec : [SELECT Id,whatid,Subject,Status,knowledge__c FROM task WHERE knowledge__c in:knowledgeIdSet]){
              system.debug('taskRec'+ taskRec);
            knowledgeTaskMap.put(taskRec.knowledge__c,taskRec);          
        }            

        //if(taskIdSet.size() == 0){
            Task taskObj = new Task();
            String managerEmail;
            String currSponsorEmail;
            string firstName;
            String LastName;
            String contentSponsorName;
            String contentSponsorOwnerId;
            String secfirstName;
            String secLastName;
            String secContentSponsorName;
            Boolean isConSponsorExists;            
           
            for(Knowledge__kav knowledge : scope)
            { 
                system.debug('knowledgeNeedsTask' +knowledgeNeedsTask);
                if(knowledgeTaskMap.containsKey(knowledge.Id)){
                    if(knowledgeTaskMap.get(knowledge.Id).Status != 'Completed' && knowledgeTaskMap.get(knowledge.Id).Subject.contains('Content Review')){
                        system.debug('Open task do not create');
                        knowledgeNoTask.add(knowledge.Id);
                        continue;
                    }
                }                
                system.debug('Outside IF continue');
                
               /* if (!knowledgeNeedsTask.contains(knowledge.Id) || knowledgeIdSet.contains(knowledge.Id)) {
                    continue;
                }*/
                isConSponsorExists = false;
                firstName = '';
                LastName = '';
                contentSponsorName='';
                contentSponsorOwnerId = '';
                secfirstName = '';
                secLastName = '';
                secContentSponsorName = '';
                managerEmail = '';
                currSponsorEmail='';
                if(knowledge.ContentSponsor__c != null){
                    system.debug('Inside Content  SPonsor if block');
                String currSponsorUID=knowledge.ContentSponsor__c;
                
                if(emailToUserMap.containsKey(currSponsorUID.toLowerCase())){
                	 currSponsorEmail=emailToUserMap.get(currSponsorUID.toLowerCase());
                }
                if(nameToUserMap.containsKey(currSponsorUID.toLowerCase())){
                    System.debug('Sponsor id in name to user map: '+ currSponsorUID); 
 
                    firstName = nameToUserMap.get(currSponsorUID.toLowerCase()).FirstName;
                     LastName = nameToUserMap.get(currSponsorUID.toLowerCase()).LastName;
                     contentSponsorName = firstName +' '+ LastName;
                     contentSponsorOwnerId = nameToUserMap.get(currSponsorUID.toLowerCase()).ID;
                    isConSponsorExists = true;
                } else {
                		System.debug('Sponsor id NOT in name to user map: '+ currSponsorUID); 
   
                }
                String currSecSponsorUID=knowledge.BWSecContentSponsor__c;
                if(null != currSecSponsorUID && nameToUserMap.containsKey(currSecSponsorUID.toLowerCase())){
                    secfirstName = nameToUserMap.get(currSecSponsorUID.toLowerCase()).FirstName;
                     secLastName = nameToUserMap.get(currSecSponsorUID.toLowerCase()).LastName;
                     secContentSponsorName = secfirstName +' '+ secLastName;
                
                    system.debug('contentSponsorOwnerId'+contentSponsorOwnerId);
                    if(nameToUserMap.containsKey(currSponsorUID)){
                        if(nameToUserMap.get(currSponsorUID).ManagerId != null){
                           managerEmail = nameToUserMap.get(currSponsorUID).Manager.Email;
                             isConSponsorExists = true;
                        }
                 }
                }    
                system.debug('Manager Email'+ managerEmail);
                if(isConSponsorExists){
                    if(knowledge.FutureReviewDate__c != null){
                     taskObj = CreateTask('Content Review'+''+knowledge.FutureReviewDate__c, knowledge.Id, contentSponsorOwnerId,currSponsorEmail,contentSponsorName
                                          ,managerEmail,secContentSponsorName);
                    }else{
                     taskObj = CreateTask('Content Review', knowledge.Id,contentSponsorOwnerId,currSponsorEmail,contentSponsorName,managerEmail,secContentSponsorName);
                    }
                    knowledgeNeedsTask.add(knowledge.Id);
                    lstTasktoInsert.add(taskObj);
                
                } else {
                    System.debug('Adding knowledge id ' + knowledge.Id + ' in failedArticles');
                	failedArticles.put(knowledge.Id, knowledge.ContentSponsor__c + '|' + knowledge.BWSecContentSponsor__c);    
                }
                System.debug('Adding task in the lstTaskToInsert list with AssignedTo ' + taskObj.OwnerId);
                
            } 
        }
        //} 
            //Dedup
            lstTasktoInsertSet.addAll(lstTasktoInsert);
            lstTasktoInsert = new List<Task>();
            lstTasktoInsert.addAll(lstTasktoInsertSet);
            Logger.info('Creating tasks for these articles: ' + knowledgeNeedsTask.toString(), BC.getJobId()).setTopics(new List<String>{BATCH_LOGGING_INFO_LABEL});
         	Logger.info('Number of tasks to insert ' + lstTasktoInsert.size() , BC.getJobId()).setTopics(new List<String>{BATCH_LOGGING_INFO_LABEL});
       	    Logger.saveLog();
            Logger.info('Open tasks already exist for these articles: ' + knowledgeNoTask.toString(), BC.getJobId()).setTopics(new List<String>{BATCH_LOGGING_INFO_LABEL});
       		Logger.saveLog();
                if(lstTasktoInsert.size() > 0 )
                {
                    //Database.SaveResult[] srList = Database.insert(lstTasktoInsert, true);
                    insert lstTasktoInsert;
                    system.debug('lstTasktoInsert'+lstTasktoInsert);
                    Logger.info('Number of tasks inserted ' + lstTasktoInsert.size() , BC.getJobId()).setTopics(new List<String>{BATCH_LOGGING_INFO_LABEL});
       				Logger.saveLog();
                } else {
                	Logger.info('No tasks inserted. ', BC.getJobId()).setTopics(new List<String>{BATCH_LOGGING_INFO_LABEL});
       				Logger.saveLog();
                }
            
            if (!failedArticles.isEmpty()) {
                makeLog(BC.getJobId(), failedArticles);
            } else {
                System.debug('No batch failures');
                 Logger.info('Batch completed - no failures', BC.getJobId()).setTopics(new List<String>{BATCH_LOGGING_INFO_LABEL});
         		 Logger.saveLog();
            }
        } catch(Exception e) {
            Map<Id, Knowledge__kav> batchKnowledgeMap = new  Map<Id, Knowledge__kav>(scope);
            String serializedException = getExceptionString(e) + '; failed articles: ' + JSON.serialize(batchKnowledgeMap.keySet());
            System.debug('Exception caught in batch: ' + serializedException);
            makeLog(BC.getJobId(), serializedException);
        }   
            
    
        Map<Id, Task> taskMap = new Map<Id, Task>(lstTasktoInsert);      
        set<Id> taskId = taskMap.keySet();
      

        
        // Query from Organization-Wide Email Address 
        try{
            List<OrgWideEmailAddress> lstEmailAddress=[select Id, Displayname from OrgWideEmailAddress WHERE Displayname= :displayName];
            if (!lstEmailAddress.isEmpty()) {
                orgwideIdAddressId = lstEmailAddress[0].Id;
            }
            Set<String> emailAddressesSentTo = new Set<String>();
            for(Task taskEmail :[SELECT Id, Subject,Content_Sponsor_Name__c,Secondary_Content_Sponsor_Name__c,createdDate,knowledge__r.ArticleNumber
                                 ,knowledge__c,knowledge__r.Id,knowledge__r.Title,Owner.Name
                                 , knowledge__r.ContentSponsor__c 
                                 FROM Task where id IN:taskId]){
                System.debug('knowledgeMap.get(taskEmail.Knowledge__c)=' + knowledgeMap.get(taskEmail.Knowledge__c));
                if(knowledgeMap.get(taskEmail.Knowledge__c)!=null){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
                    List<String> sendTo = new List<String>();
                    String contentSponsorId = knowledgeMap.get(taskEmail.Knowledge__c).ContentSponsor__c;
                    String contentSponsorEmailId = emailToUserMap.get(contentSponsorId.toLowerCase());
                    emailAddressesSentTo.add(contentSponsorEmailId);
                    sendTo.add(contentSponsorEmailId);
                    mail.setToAddresses(sendTo);
                    if (orgwideIdAddressId != null && !Test.isRunningTest()) {
                        mail.setOrgWideEmailAddressId(orgwideIdAddressId);
                    } else {
                        mail.setSenderDisplayName(displayName);  
                    }  
                    
                    mail.setSubject('New task created for content sponsor.');
                    htmlBody = 'Hello '+taskEmail.Content_Sponsor_Name__c+ ',<br><br>';
                    htmlBody += 'The FRD task for the below knowledge article has been assigned to you.<br>';
                    htmlBody += '<table border="1" style="border-collapse: collapse" cellspacing="5" cellpadding="5" align="left"><tr><th>Knowledge Article</th><th>Task Subject</th><th>Task Created Date</th></tr>';
                    String Subject = taskEmail.subject;
                    datetime dt = taskEmail.createddate;
                    string createddate = dt.format('MM/dd/yyyy');
                    string title = taskEmail.knowledge__r.Title;
                    htmlBody += '<tr><td>' + title + '</td><td>' + Subject + '</td><td>' + createddate + '</td></tr>'; // + duedate + '</td></tr>';
                    htmlBody += '</table><br>';
                    htmlBody += '<br><br><br>For more details, please review the task here: '+'<br>';
                    htmlBody += URL.getSalesforceBaseUrl().toExternalForm()+'/'+taskEmail.id+'<br></br>';
                   // htmlBody += URL.getSalesforceBaseUrl().toExternalForm()+'/'+'lightning/r/Knowledge__kav/'+taskEmail.knowledge__r.id+'/view'+'<br></br>';
                    htmlBody += '<br>Thanks!';
                    string plainTextBody = htmlBody;
                    mail.setHtmlBody(plainTextBody);
                    mails.add(mail);
                    system.debug('mails'+mails);
                    
                    // Mail to secondary content sponsor
                    if(taskEmail.Secondary_Content_Sponsor_Name__c!=null){
                    Messaging.SingleEmailMessage mailSecondaryCS = new Messaging.SingleEmailMessage(); 
                    List<String> sendToSecCS = new List<String>();
                    String contentSecSponsorId = knowledgeMap.get(taskEmail.Knowledge__c).BWSecContentSponsor__c;
                    String contentSecSponsorEmailId = emailToUserMap.get(contentSecSponsorId.toLowerCase());
                    sendToSecCS.add(contentSecSponsorEmailId);
                    emailAddressesSentTo.add(contentSponsorEmailId);    
                    mailSecondaryCS.setToAddresses(sendToSecCS);
                    if (orgwideIdAddressId != null && !Test.isRunningTest()) {
                        mailSecondaryCS.setOrgWideEmailAddressId(orgwideIdAddressId);
                    } else {
                        mailSecondaryCS.setSenderDisplayName(displayName);  
                    }  
                   
                    String titleLength = taskEmail.knowledge__r.Title; //SObjectType.Knowledge__kav.Fields.Title.Length;
                        system.debug('Length'+titleLength);
                    if(titleLength.Length() > 11){
                        system.debug('Inside if');
                    String articleName = taskEmail.knowledge__r.Title.substring(0,10);
                         system.debug('articleName'+articleName);
                        mailSecondaryCS.setSubject(articleName+'....'+taskEmail.knowledge__r.ArticleNumber+ '- Secondary Content Sponsor Notification');
                    }else{
                        mailSecondaryCS.setSubject(title+'....'+taskEmail.knowledge__r.ArticleNumber+ '- Secondary Content Sponsor Notification');
                    }
                   // mailSecondaryCS.setSubject('New task created for primary content sponsor.');
                    htmlBodySecCS = 'Hello '+taskEmail.Secondary_Content_Sponsor_Name__c+ ',<br><br>';
                    htmlBodySecCS += 'The FRD task for the below knowledge article has been assigned to primary content sponsor.You will not have visibility to the task until it is assigned to you.<br>';
                    htmlBodySecCS += 'This is a notification email. No action needed.<br>';
                    htmlBodySecCS += '<table border="1" style="border-collapse: collapse" cellspacing="5" cellpadding="5" align="left"><tr><th>Knowledge Article</th><th>Task Subject</th><th>Task Created Date</th></tr>';
                    String SubjectSecCS = taskEmail.subject;
                    datetime dtSecCS = taskEmail.createddate;
                    string createddatesecCS = dtSecCS.format('MM/dd/yyyy');
                    string titleSecCS = taskEmail.knowledge__r.Title;
                    htmlBodySecCS += '<tr><td>' + titleSecCS + '</td><td>' + SubjectSecCS + '</td><td>' + createddatesecCS + '</td></tr>'; // + duedate + '</td></tr>';
                    htmlBodySecCS += '</table><br>';
                    htmlBodySecCS += '<br><br><br>Please find the link to knowledge article for which the task has been created as below: '+'<br>';
                   // htmlBodySecCS += URL.getSalesforceBaseUrl().toExternalForm()+'/'+taskEmail.id+'<br></br>';
                    htmlBodySecCS += URL.getSalesforceBaseUrl().toExternalForm()+'/'+'lightning/r/Knowledge__kav/'+taskEmail.knowledge__r.id+'/view'+'<br></br>';
                    htmlBodySecCS += '<br>Thanks!';
                    string plainTextBodySecCS = htmlBodySecCS;
                    mailSecondaryCS.setHtmlBody(plainTextBodySecCS);
                    mails.add(mailSecondaryCS);
                    }
                    
                }
         
            }
            if(mails.size()>0){
                Messaging.sendEmail(mails); 
                 System.debug('Mail sent');
                     Logger.info(Mails.size() + ' emails sent: ' +  emailAddressesSentTo.toString(), BC.getJobId()).setTopics(new List<String>{BATCH_LOGGING_INFO_LABEL});
                     Logger.saveLog();
            } else {
               Logger.info('No email sent', BC.getJobId()).setTopics(new List<String>{BATCH_LOGGING_INFO_LABEL});
               Logger.saveLog(); 
            }
        } catch (Exception e) {
          	   Logger.error('Error sending emails: ' + getExceptionString(e), BC.getJobId()).setTopics(new List<String>{BATCH_LOGGING_INFO_LABEL});
               Logger.saveLog(); 
            }   
    }
    
    global Task CreateTask(String Subject,String Id, String OwnerId , String sponsorEmail,String contentSponsorName, String managerEmail,String secContentSponsorName){
        Task t = new Task();
        t.Subject = Subject;
        t.Type = 'Outbound Call';
        t.Status = 'Open';
        t.Priority = 'Normal';
        t.ActivityDate= date.today();
        //t.WhatId =Id;
        //t.WhoId = 'Content Review';
        t.Knowledge__c = Id;
        t.OwnerId = OwnerId;
        t.Content_Sponsor_Email__c = sponsorEmail;
        t.Content_Sponsor_Name__c = contentSponsorName;
        if(managerEmail != null){
        t.Content_Sponsor_Manager__c = managerEmail;
        }
        t.Secondary_Content_Sponsor_Name__c = secContentSponsorName;
        t.Description= 'Please review the article, update author notes and re-publish the article. Then change the task status to complete.';
        return t;     
    } 
    
    global void finish(Database.BatchableContext BC){
         Logger.info('Processing Completed', BC.getJobId()).setTopics(new List<String>{BATCH_LOGGING_INFO_LABEL});
         Logger.saveLog();
    }
    
    public static void makeLog(String jobId, Map<Id, String> failedArticles) {
        //JSON.serialize(e)
        
        String failedArticlesString = '';
        if (failedArticles != null && !failedArticles.isEmpty()) {
            failedArticlesString = failedArticles.toString(); 
        }
        List<Object> params = new List<Object>{BATCH_LOGGING_ERROR_LABEL,  null, 'Job Id: ' + jobId + '; Failed articles due to unmatched sponsor: ' +failedArticlesString};
        
       
            System.debug('The KM_Logging_Setting__mdt logging setting is turned on.');
            LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
            Logger.error(logMessage).setTopics(new List<String>{BATCH_LOGGING_ERROR_LABEL});
            Logger.saveLog();
           
        
   }  
    
    public static void makeLog(String jobId, String exceptionJson) {
 
        List<Object> params = new List<Object>{BATCH_LOGGING_ERROR_LABEL,  null, 'Job Id: ' + jobId + '; Exception: ' + exceptionJSON};
        LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
        Logger.error(logMessage).setTopics(new List<String>{BATCH_LOGGING_ERROR_LABEL});
        Logger.saveLog();
        
   }  
    
    @testVisible
	private static String getExceptionString(Exception exceptionCaught) {
        String errorMsg = '';
        errorMsg += 'Cause=' + String.valueOf(exceptionCaught.getCause()) + ' ';
        errorMsg += 'Line Number=' + exceptionCaught.getLineNumber() + ' ';
        errorMsg += 'Message=' + exceptionCaught.getMessage() + ' ';
        errorMsg += 'Stack Trace=' + exceptionCaught.getStackTraceString() + ' ';
        errorMsg += 'Type Name=' + exceptionCaught.getTypeName() + ' ';
        return errorMsg;
  	}
    
    public static String getQueryParameters() {
        List<KM_FRD_Batch_Setting__mdt> batchSettingList = getBatchSettings();
         if (batchSettingList.isEmpty()) {
             return DEFAULT_DATE_PARAMETER;
         } else {
             if (batchSettingList [0].Use_Custom_Date_Parameter__c == true) {
                System.debug('Using Customer Date Paramater: ' + batchSettingList[0].Date_Parameters__c);
                return batchSettingList[0].Date_Parameters__c;
             }
         }

       return DEFAULT_DATE_PARAMETER;
    }
    
    @testVisible
    private static List<KM_FRD_Batch_Setting__mdt> getBatchSettings() {
        
        List<KM_FRD_Batch_Setting__mdt> batchSettingList = [SELECT  Id,
                                	Date_Parameters__c, Use_Custom_Date_Parameter__c
                        FROM KM_FRD_Batch_Setting__mdt
                        WHERE MasterLabel = :SETTING_MASTER_LABEL];
        System.debug(batchSettingList.size() + ' rows found for ' + SETTING_MASTER_LABEL + '; ' + batchSettingList);
        if (batchSettingList.IsEmpty()) {
        	makeLog(null, 'NO BATCH SETTINGS FOUND');
        }
        return batchSettingList;
                
    }

	public static Boolean validateOverRideSetting() {
       String query = BASE_QUERY + getQueryParameters() + ')'; 
       return validateQuery(query);
    }
    
    public static Boolean validateQuery(String query) {
        Boolean queryIsValid = true;
        query += ' LIMIT 1';
        System.debug('Query to validate: ' + query);
        List<SObject> sobjectlist; 
        try {
        	sobjectlist = Database.query(query);
    	} catch (Exception e) {
        	queryIsValid = false;
    	}
        return queryIsValid;
    }
    
    
}
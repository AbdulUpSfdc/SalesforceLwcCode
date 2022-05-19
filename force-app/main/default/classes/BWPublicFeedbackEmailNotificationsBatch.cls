/*****
 Name             : BWPublicFeedbackEmailNotificationsBatch
 Description      : Batch class to send hourly email notifications to CS, SME and SCS about newly added public feedback/comments
 ****/

public without sharing class BWPublicFeedbackEmailNotificationsBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful{
    public Map<Id, List<Id>> expertArticleMap = new Map<Id, List<Id>>();
    public Map<Id, String> articleFeedbackMap = new Map<Id, String>();
    public Map<Id, String> feedbackCommentsMap = new Map<Id, String>();
    public KM_Public_Feedback_Email_Setting__mdt emailSettings = new KM_Public_Feedback_Email_Setting__mdt();
    public Datetime DATETIME_VALUE;

    public BWPublicFeedbackEmailNotificationsBatch(){
        //get Email settings from Custom Metadata Type
        emailSettings =[SELECT Email_Subject__c, Reply_To_Display_Name__c, Sender_s_Display_Name__c, Email_Frequency__c, Email_Batch_Size__c
                        FROM KM_Public_Feedback_Email_Setting__mdt
                        WHERE DeveloperName = 'BWPublicFeedbackEmailNotificationsBatch'];
    }
    public void execute(SchedulableContext SC) {
        Id batchJobId = Database.executeBatch(new BWPublicFeedbackEmailNotificationsBatch(), Integer.valueOf(emailSettings.Email_Batch_Size__c));
    }

	public Database.QueryLocator start(Database.BatchableContext BC){
		Integer emailFrequency = Integer.valueOf(emailSettings.Email_Frequency__c);
        DATETIME_VALUE = System.now().addMinutes((-1)* emailFrequency);

		String query = 'SELECT Id, Feedback__c, Knowledge__c, Knowledge__r.Title, Knowledge__r.UrlName, CreatedBy.Name, CreatedDate';
		query += ' FROM BWPublicFeedbackThread__c';
		query += ' WHERE Is_Deleted__c = false';
		query += ' AND (CreatedDate >= :DATETIME_VALUE OR Last_Comment_Creation_Date__c >= :DATETIME_VALUE)';
        query += ' ORDER BY Knowledge__c, CreatedDate DESC';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<BWPublicFeedbackThread__c> articleFeedbackThreads){
		System.debug('PUBLIC FEEDBACK EMAIL NOTIFICATIONS BATCH - INITIALIZED');

        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        Map<Id, BWPublicFeedbackThread__c> feedbackThreadMap = new Map<Id, BWPublicFeedbackThread__c>();
        List<Id> articleIDs = new List<Id>();

        try{
            /*  Build feedback thread map and add the feedback HTML body in feedback comment map in order to make sure that 
                feedback with no comments get added to the feedback comments map*/
            for (BWPublicFeedbackThread__c feedback : articleFeedbackThreads){
                String feedbackURL = baseURL + +'/' + feedback.Id;
                String feedbackHTMLBody = '<div style = "margin-left: 60px;"><b>' + feedback.CreatedBy.Name + '</b> &nbsp;<small style="color:gray;">' + feedback.CreatedDate.format('MM/dd/yyyy HH:mm') + '</small><br><a href="' + feedbackURL + '">' + feedback.Feedback__c + '</a></div><br>';

                feedbackThreadMap.put(feedback.Id, feedback);
                feedbackCommentsMap.put(feedback.Id, feedbackHTMLBody);
                if(feedback.Knowledge__c != NULL){
                    articleIDs.add(feedback.Knowledge__c);
                }
            }

            /*  Build a map of feedback Id and an HTML string of the feedback  and its associated comments  */
            for(BWFeedbackThreadComment__c comment:[SELECT Id, FeedbackComment__c, CreatedBy.Name, CreatedDate, KMPublicFeedbackThread__c
                                                    FROM BWFeedbackThreadComment__c
                                                    WHERE KMPublicFeedbackThread__c IN :feedbackThreadMap.keySet() AND Is_Deleted__c = false AND CreatedDate >= :DATETIME_VALUE
                                                    ORDER BY KMPublicFeedbackThread__c, CreatedDate DESC]){
                String commentHTMLBody = '<div style = "margin-left: 100px;"><b>' + comment.CreatedBy.Name + '</b> &nbsp;<small style="color:gray;">' + comment.CreatedDate.format('MM/dd/yyyy HH:mm') + '</small><br>' + comment.FeedbackComment__c + '</div><br>';
                String existingHTMLBody = feedbackCommentsMap.get(comment.KMPublicFeedbackThread__c);

                feedbackCommentsMap.put(comment.KMPublicFeedbackThread__c, existingHTMLBody + commentHTMLBody);               
            }

            /*  Build a map of knowledge article Id and a list of associated feedback Record Ids    */
            for(Id feedbackId : feedbackCommentsMap.keySet()){
                BWPublicFeedbackThread__c feedback = feedbackThreadMap.get(feedbackId);
                String persistentURL = baseURL + '/lightning/articles/Knowledge/' + feedback.Knowledge__r.UrlName;
                String feedbackHTMLBody = feedbackCommentsMap.get(feedbackId);
                String articleHTMLBody = '<div style = "margin-left: 30px;"><h3><a href="'+ persistentURL + '"><b>' + feedback.Knowledge__r.Title + '</b></a></h3></div>';

                if(articleFeedbackMap.containsKey(feedback.Knowledge__c)){
                    String existingHTMLBody = articleFeedbackMap.get(feedback.Knowledge__c);
                    articleFeedbackMap.put(feedback.Knowledge__c, existingHTMLBody + feedbackHTMLBody);
                }
                else{
                    articleFeedbackMap.put(feedback.Knowledge__c, articleHTMLBody + feedbackHTMLBody);
                }
            }
            /*  Build a map of article SMEs (user Id) and a list of associated article IDs  */
            for(BWKMArticleSME__c expert : [SELECT Id, Knowledge_Article__c, User__c
                                            FROM BWKMArticleSME__c
                                            WHERE Knowledge_Article__c IN :articleIDs]){        
                if(expertArticleMap.containsKey(expert.User__c)){
                    expertArticleMap.get(expert.User__c).add(expert.Knowledge_Article__c);
                }
                else{
                    expertArticleMap.put(expert.User__c, new List<Id>{expert.Knowledge_Article__c});
                }
            } 
        }
        catch (Exception e) {
            BWC_ExceptionUtils.handleException(e, true);
        } 
	}

	public void finish(Database.BatchableContext BC){
		System.debug('PUBLIC FEEDBACK EMAIL NOTIFICATIONS BATCH - FINISHED');
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        try{
            emailList = configureEmails();
            if(!emailList.isEmpty()){
                System.debug('Sending Email Notifications');
                Messaging.sendEmail(emailList);
            }
            /*  Schedule the next batch */
            //scheduleNextBatch();
        }
        catch (Exception e) {
            system.debug('ERROR ::: ' + e);
            BWC_ExceptionUtils.handleException(e, true);
        } 
	}

    private List<Messaging.SingleEmailMessage> configureEmails(){
        Id senderAddressId;
        String replyToAddress = '';
        List<String> orgWideEmailDisplayNames = new List<String>{emailSettings.Reply_To_Display_Name__c, emailSettings.Sender_s_Display_Name__c};
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

        for(OrgWideEmailAddress emailAddress : [SELECT Id, Address, DisplayName 
                                                FROM OrgWideEmailAddress 
                                                WHERE DisplayName IN :orgWideEmailDisplayNames]){
            if(emailAddress.DisplayName == emailSettings.Sender_s_Display_Name__c){
                senderAddressId = emailAddress.Id;
            }
            else if(emailAddress.DisplayName == emailSettings.Reply_To_Display_Name__c){
                replyToAddress = emailAddress.Address;
            }
        }
        for(Id expertId : expertArticleMap.keySet()){
            String htmlBody = '';

            for(Id articleId : expertArticleMap.get(expertId)){
                htmlBody += articleFeedbackMap.get(articleId);
            }
            /*  compose email message   */
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            email.setOrgWideEmailAddressId(senderAddressId);
            if(String.isNotBlank(replyToAddress)){
                email.setReplyTo(replyToAddress);
            }
            email.setToAddresses(new List<String>{expertId});             
            email.setSubject(emailSettings.Email_Subject__c);  
            email.setHtmlBody(htmlBody);
            emailList.add(email);
        }
        return emailList;
    }

    /*private void scheduleNextBatch(){
		if (!test.isRunningTest()){
            BWPublicFeedbackEmailNotificationsBatch batch = new BWPublicFeedbackEmailNotificationsBatch();
			System.scheduleBatch(batch, 'BWPublicFeedbackEmailNotificationsBatch', Integer.valueOf(emailSettings.Email_Frequency__c), Integer.valueOf(emailSettings.Email_Batch_Size__c));
		}
	}*/
}
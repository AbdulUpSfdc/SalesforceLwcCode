public with sharing class BWArticleFeedbackHelper {
    public static final String NOTIFICATION_FEATURE_NAME = 'Private_Feedback_Bell_Notifications';
    public static final String NOTIFICATION_TYPE = 'Bell_Notification';
    public static final String NOTIFICATION_TITLE = 'You have received private feedback response for the article - ';

    public static void updateSponsorEmail(Map<Id, KM_Article_Feedback__c> newFeedbackMap)
    {
       // String firstName = '';
        try{
        List<KM_Article_Feedback__c> lstKAF = [select id, Article_Sponser_Email__c,ArticleSponsorATTUID__c,Content_Sponsor_Name__c, Article_Secondary_Sponsor_ATT_UID__c,Article_Secondary_Sponser_Email__c,Secondary_Content_Sponsor_Name__c 
                                              from KM_Article_Feedback__c where Id IN :newFeedbackMap.keySet()];
        List<String> lstSponsorUID=new List<String>();
        List<String> lstSecondarySponsorUID=new List<String>();
        for (KM_Article_Feedback__c KAF:lstKAF)
        {
            if(KAF.ArticleSponsorATTUID__c!='' || kAF.ArticleSponsorATTUID__c != NULL )
            {
            lstSponsorUID.add(KAF.ArticleSponsorATTUID__c);
            }
            if(KAF.Article_Secondary_Sponsor_ATT_UID__c!='' || kAF.Article_Secondary_Sponsor_ATT_UID__c != NULL ){
                lstSecondarySponsorUID.add(KAF.Article_Secondary_Sponsor_ATT_UID__c);
            }
        }
       
        List<User> lstSponsors =[SELECT Email,ATTUID__c ,FirstName,LastName,FederationIdentifier FROM User where FederationIdentifier=:lstSponsorUID OR FederationIdentifier=:lstSecondarySponsorUID];
        
        Map<String, String> emailToUserMap = new Map<String, String>();
        Map<String, User> nameToUserMap = new Map<String, User>();
        for (User u : lstSponsors) {
       	   emailToUserMap.put(u.FederationIdentifier,u.Email);  
           nameToUserMap.put(u.FederationIdentifier,u);
           
       }
       for (KM_Article_Feedback__c kAF2:lstKAF)
       {
           if(kAF2.ArticleSponsorATTUID__c != NULL || kAF2.ArticleSponsorATTUID__c != '' ){
           String currSponsorUID=kAF2.ArticleSponsorATTUID__c;
           String currSponsorEmail=emailToUserMap.get(currSponsorUID);
           KAF2.Article_Sponser_Email__c=currSponsorEmail;
           string firstName = nameToUserMap.get(currSponsorUID).FirstName;
           String LastName = nameToUserMap.get(currSponsorUID).LastName;
           KAF2.Content_Sponsor_Name__c = firstName +' '+LastName;
           }
           if(kAF2.Article_Secondary_Sponsor_ATT_UID__c != NULL || kAF2.Article_Secondary_Sponsor_ATT_UID__c != '' ){
           String currSecSponsorUID=kAF2.Article_Secondary_Sponsor_ATT_UID__c;
           String currSecSponsorEmail=emailToUserMap.get(currSecSponsorUID);
           KAF2.Article_Secondary_Sponser_Email__c =currSecSponsorEmail;
           string secfirstName = nameToUserMap.get(currSecSponsorUID).FirstName;
           String secLastName = nameToUserMap.get(currSecSponsorUID).LastName;
           KAF2.Secondary_Content_Sponsor_Name__c  = secfirstName +' '+secLastName;
           }
           
          
       }
        database.update(lstKAF);
    }
    catch(Exception e){
                      System.debug(LoggingLevel.ERROR, e.getMessage());
                  //  System.debug('Content Sponsor field is blank/incorrect on Knowledge Article');
        }
    }
    
///working on Agent primary channel logic 
    //
    /*public static void addPrimaryChnnl(List<KM_Article_Feedback__c> newFeedbckRecords){
       string PermissionSetId,prmaryChnnlName,BWDefaultkmChannel=null;
        try{ 
     BWDefaultkmChannel = [ Select BWDefaultKMChannel__c from Employee__c where User__r.id =:userinfo.getuserid()].BWDefaultKMChannel__c;
     if(BWDefaultkmChannel!=null || string.isnotempty(BWDefaultkmChannel))
     PermissionSetId  =  [Select Permission_Set_Id__c from BW_Channel_Mapping__c where KM_Channel_ID__c =:BWDefaultkmChannel].Permission_Set_Id__c; 
      if(PermissionSetId!=null || string.isnotempty(PermissionSetId))
      prmaryChnnlName = [select label from PermissionSet where Id =:PermissionSetId   ].label;  
            if(prmaryChnnlName!=null || string.isnotempty(prmaryChnnlName)){  
               for(KM_Article_Feedback__c kmArtFdbk :newFeedbckRecords ) {
          kmArtFdbk.Agent_Feedback_Primary_Channel__c = prmaryChnnlName.split('KM')[1];
            }}
        } catch(exception e ) { system.debug('Error has occured ');}
        
    }

    public static void sendFeedbackNotifications(Map<Id, KM_Article_Feedback__c> oldFeedbackMap, Map<Id, KM_Article_Feedback__c> newFeedbackMap) {
        try { 
            KM_Settings__mdt featureSettings = KM_Utility.getFeatureSettings(NOTIFICATION_FEATURE_NAME);
            Boolean featureEnabled = featureSettings.Feature_Switch__c;

            if(featureEnabled) {
                // Get Id for the custom notification type
                CustomNotificationType notificationType = [ SELECT Id
                                                            FROM CustomNotificationType
                                                            WHERE DeveloperName =: NOTIFICATION_TYPE];
                for(Id feedbackId : newFeedbackMap.keySet()) {
                    String feedbackResponse = newFeedbackMap.get(feedbackId).Feedback_Response__c;
                    String feedbackStatus = newFeedbackMap.get(feedbackId).Feedback_Status__c;
                    String articleTitle = newFeedbackMap.get(feedbackId).Parent_Article_Title__c;

                    if( String.isNotBlank(feedbackResponse)
                        && oldFeedbackMap.get(feedbackId).Feedback_Response__c <> feedbackResponse
                        && (feedbackStatus == 'Replied' || feedbackStatus == 'Waiting for Agent' || feedbackStatus == 'Resolved')) {
                        
                            // Create a new custom notification
                        Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        Set<String> recipientId = new Set<String>{newFeedbackMap.get(feedbackId).CreatedById};

                        // Set notification parameters
                        notification.setTitle(NOTIFICATION_TITLE);
                        notification.setBody(articleTitle);
                        notification.setNotificationTypeId(notificationType.Id);
                        notification.setTargetId(feedbackId);

                        // send the notification
                        notification.send(recipientId);
                    }
                }
            }
        }
        catch(Exception e) {
            String errorMessage = 'Private feedback bell notification process has failed. Error message - ' + e;
            makeLog(NOTIFICATION_FEATURE_NAME, '', JSON.serialize(errorMessage));
        }
    }*/
    
    public static void makeLog(String topicName, String recordId, String exceptionJson) {
        List<Object> params = new List<Object>{topicName,  null, 'Message: ' + exceptionJson};  
        LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
        Logger.error(logMessage).setTopics(new List<String>{topicName});
        Logger.saveLog();
    }
    
    
    public static void handleBeforeInsert(List<KM_Article_Feedback__c> newFeedbackResponseList){
       setAutoResponseAndupdateStatus(newFeedbackResponseList);
    }
    public static void setAutoResponseAndupdateStatus(List<KM_Article_Feedback__c> newFeedbackResponseList){
        for(KM_Article_Feedback__c feedbackResponse : newFeedbackResponseList){
		    system.debug('Feedback Response' + feedbackResponse);
			if(feedbackResponse.Reason__c != null && feedbackResponse.Reason__c == KM_Constants.REASON_ARTICLE_LIKE){
                feedbackResponse.Feedback_Response__c = 'Thank you for the feedback. Next time, click the Like button (thumbs up). This is the best way to indicate you have read and “like” the information presented in this article.';
                feedbackResponse.Feedback_Status__c = KM_Constants.RESOLVED;
            }	    
        }
    }
}
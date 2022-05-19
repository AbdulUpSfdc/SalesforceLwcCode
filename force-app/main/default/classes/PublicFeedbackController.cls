public without sharing class PublicFeedbackController {
    public PublicFeedbackController() {}



    @AuraEnabled(cacheable=true)
    public static Boolean ChkIfIModerator(string userid)
    {
        Boolean hasModeratorPermissionSet = false;
        //string userid = '0050n000003lWDEAA2'; 
        integer hasPermissionset = [SELECT count() FROM PermissionSetAssignment WHERE AssigneeId = :userid AND PermissionSet.Name = 'KM_Public_Feedback_Moderator'];
        
        if(hasPermissionset > 0 )
        {   
            hasModeratorPermissionSet = true;
        //	system.debug('found it'); 
        }
        else
        {
            hasModeratorPermissionSet = false;
        //	system.debug('did not find it '); 
        }
        return hasModeratorPermissionSet;
    }
    
    @AuraEnabled(cacheable=true)
    public static boolean isFeedbackVisible(){
        String userPrimaryChannel = KMUserUtility.getUserPrimaryChannel();
        Profile userProfile = getProfileById(Userinfo.getProfileId());
        if (userProfile == null) {
        	throw new KnowledgeException('No profile found for id:' + Userinfo.getProfileId());                                      
        }                                     
                                                     
        Boolean  isVisible;
        isVisible =  KMFeatureAccessibilityHelper.featureIsAccessible('Public Feedback', 'Profile', userProfile.Name ) ||
        KMFeatureAccessibilityHelper.featureIsAccessible('Public Feedback', 'Primary Channel', userPrimaryChannel );
        return isVisible;
    }
    
    public static Profile getProfileById(Id profileId){
        List <Profile> profilelist = [select Id, Name from Profile where Id = :profileId];
        if (!profileList.isEmpty()) {
        	return profileList[0];
        } else {
            return null;
        }    
    }

   /* @AuraEnabled(cacheable=true)
    public static Boolean checkIfAgent(String userId){
        Boolean hasAgentPermission = false;
       // private static string KM_CA_CUSTOM = 'KM_CA_Custom';
        private static string KM_CALL_CENTER_AGENT = 'KM_Call_Center_Agent';
        Set<String> permissionSetNames = new Set<String>();

        for (PermissionSetAssignment gm : [ SELECT Id, PermissionSetId, PermissionSet.Name, PermissionSet.ProfileId, PermissionSet.Profile.Name, AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE AssigneeId =:userId ]){
                    permissionSetNames.add(gm.PermissionSet.Name);
         }

         hasAgentPermission = false;
         if(permissionSetNames.contains(KM_CALL_CENTER_AGENT)){
			hasAgentPermission = true;
          }

        return hasAgentPermission;
       
    }*/

    @AuraEnabled
    public static List<FeedbackThreadWrapper> getFeedbackThread(String searchKey,String articleID) {
        try{
           
            if(String.isNotBlank(searchKey)){
                return new List<FeedbackThreadWrapper>(findThreadAndComments(searchKey,articleID));
            }else{
                return new List<FeedbackThreadWrapper>(getPublicFeedbackThreads(articleID));
            }
        }catch(Exception e){
           // system.debug('Inside Catch' + e.getMessage());
           // return new List<FeedbackThreadWrapper>();
           throw new AuraHandledException(e.getMessage());
        }
    }

  
   
    public static List<FeedbackThreadWrapper> getPublicFeedbackThreads(string articleID){
    try{
     List<FeedbackThreadWrapper> respWrapperList = new List<FeedbackThreadWrapper>();
     Map<Id,Knowledge__kav> archivedKA = new Map<Id,Knowledge__kav>();
     Map<Id,Knowledge__kav> publishedKA = new Map<Id,Knowledge__kav>();
     set<Id> articleIds = new Set<Id>();

     Knowledge__kav articleKA= [SELECT Id,KnowledgeArticleId FROM Knowledge__kav WHERE Id=:articleID];
     
        archivedKA = new Map<Id,Knowledge__kav>([SELECT Id,PublishStatus,KnowledgeArticleId FROM Knowledge__kav WHERE 
                                PublishStatus='Archived'AND IsLatestVersion=false and KnowledgeArticleId=:articleKA.KnowledgeArticleId]);
        
        publishedKA = new Map<Id,Knowledge__kav>([SELECT Id,PublishStatus,KnowledgeArticleId FROM Knowledge__kav WHERE 
                                PublishStatus ='Online' and  IsLatestVersion=true and KnowledgeArticleId=:articleKA.KnowledgeArticleId]);
        
        articleIds.addAll(archivedKA.keySet());
        articleIds.addAll(publishedKA.keySet());
      
       
       List<BWPublicFeedbackThread__c> feedbackThreadList = [SELECT Id,Name, Knowledge__c,Article_Version_Number__c,Is_Deleted__c,Deleted_Date__c,Unmasked_Display_Name__c,
       Owner.Name, FORMAT(CreatedDate) FormatedCreatedDate,CreatedDate, CreatedById,CreatedBy.Name,DisplayName__c,Feedback__c,Knowledge_Parent_Id__c,(Select Id,Name,DisplayName__c,Is_Deleted__c,Unmasked_Display_Name__c,Deleted_Date__c,FeedbackComment__c,FORMAT(CreatedDate) FormatedCreatedDate,CreatedDate,CreatedById,CreatedBy.Name FROM Feedback_Thread_Comments__r ORDER BY CreatedDate DESC)
                                                            FROM BWPublicFeedbackThread__c WHERE Knowledge__c IN :articleIds ORDER BY CreatedDate DESC];

            if(!feedbackThreadList.isEmpty()){
                for(BWPublicFeedbackThread__c feedbackThread : feedbackThreadList){
                    FeedbackThreadWrapper respWrapper = new FeedbackThreadWrapper();
                    List<FeedbackCommentWrapper> cmtWrapperList = new List<FeedbackCommentWrapper>();
                   // String formatThreadDeletedDate = feedbackThread.Deleted_Date__c.FORMAT();
                   if(feedbackThread.Is_Deleted__c == true){
                        feedbackThread.Feedback__c = 'This thread was deleted on' + ' '+ feedbackThread.Deleted_Date__c;
                        respWrapper.feedbackComments = NULL; //new List<FeedbackCommentWrapper>();
                        respWrapper.feedbackThreads =  feedbackThread;
                        respWrapper.commentCount = 0;
                        respWrapperList.add(respWrapper); 
                    }
                    else{
                    for(BWFeedbackThreadComment__c comment : feedbackThread.Feedback_Thread_Comments__r){
                        FeedbackCommentWrapper cmtWrapper = new FeedbackCommentWrapper();
                        //String formatCommentDeletedDate = comment.Deleted_Date__c.FORMAT();
                        if(comment.Is_Deleted__c == true){
                            comment.FeedbackComment__c = 'This comment was deleted on' + ' ' +comment.Deleted_Date__c;
                            cmtWrapper.feedbackComment = comment;
                            cmtWrapper.containsSearchTerm = true;
                            cmtWrapperList.add(cmtWrapper);
                        }else{
                        cmtWrapper.feedbackComment = comment;
                        cmtWrapper.containsSearchTerm = true;
                        cmtWrapperList.add(cmtWrapper);
                        }
                    }
                    respWrapper.feedbackThreads = feedbackThread;
                    respWrapper.feedbackComments = cmtWrapperList;
                    Integer commentCount = cmtWrapperList.size();
                    respWrapper.commentCount = commentCount;
                    respWrapperList.add(respWrapper);
                    }
                }
            }
       
            return respWrapperList;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }                                                          
      
    }

    @AuraEnabled(cacheable=true)
    public static List<FeedbackThreadWrapper> findThreadAndComments(String searchKey, String articleID) {
      try{
        List<FeedbackThreadWrapper> threadWrapperList = new List<FeedbackThreadWrapper>();
        String searchTerm = searchKey.trim();
        String upperSearchTerm = searchTerm.toUpperCase();
        
        Knowledge__kav articleKA= [SELECT Id,KnowledgeArticleId FROM Knowledge__kav WHERE Id=:articleID];
       
        Boolean containsSearchTerm = false;
      
        for(BWPublicFeedbackThread__c feedbackthread: [SELECT Id,Name, Knowledge__c,Is_Deleted__c,Deleted_Date__c,Article_Version_Number__c,CreatedBy.Name,Unmasked_Display_Name__c,
                                            Owner.Name, FORMAT(CreatedDate) FormatedCreatedDate, CreatedDate,CreatedById,DisplayName__c,Feedback__c,Knowledge_Parent_Id__c,(Select Id,Name,DisplayName__c,Unmasked_Display_Name__c,Is_Deleted__c,Deleted_Date__c,FeedbackComment__c,FORMAT(CreatedDate) FormatedCreatedDate,CreatedDate,CreatedById,CreatedBy.Name FROM Feedback_Thread_Comments__r ORDER By CreatedDate DESC)
                                            FROM BWPublicFeedbackThread__c WHERE Knowledge_Parent_Id__c =: articleKA.KnowledgeArticleId ORDER BY CreatedDate DESC]){
            
            containsSearchTerm = false;
            FeedbackThreadWrapper trdWrapper = new FeedbackThreadWrapper();
            List<FeedbackCommentWrapper> cmtWrapperList = new List<FeedbackCommentWrapper>();
           // String formatThreadDeletedDate = feedbackthread.Deleted_Date__c.FORMAT();
            if(feedbackthread.Is_Deleted__c == true){
                feedbackthread.Feedback__c = 'This thread was deleted on' + ' '+ feedbackthread.Deleted_Date__c;
                trdWrapper.feedbackComments = NULL; //new List<FeedbackCommentWrapper>();
                trdWrapper.feedbackThreads =  feedbackthread;
                trdWrapper.commentCount = 0;
                threadWrapperList.add(trdWrapper); 
            }
            else{
            for(BWFeedbackThreadComment__c threadComment : feedbackthread.Feedback_Thread_Comments__r){
                //containsSearchTerm = false;
                FeedbackCommentWrapper cmtWrapper = new FeedbackCommentWrapper();
               // String formatCommentDeletedDate = threadComment.Deleted_Date__c.FORMAT();
                if(threadComment.Is_Deleted__c == true){
                    threadComment.FeedbackComment__c = 'This comment was deleted on' + ' ' +threadComment.Deleted_Date__c;
                    cmtWrapper.feedbackComment = threadComment;
                    cmtWrapper.containsSearchTerm = true;
                }else{
                    cmtWrapper.feedbackComment = threadComment;
                    if(String.isNotBlank(threadComment.FeedbackComment__c) && threadComment.FeedbackComment__c.toUpperCase().contains(upperSearchTerm)){
                        cmtWrapper.containsSearchTerm = true;
                        containsSearchTerm = true;
                    }
                    else{
                        cmtWrapper.containsSearchTerm = false;
                    }
                }
                cmtWrapperList.add(cmtWrapper);
            }
            if((String.isNotBlank(feedbackThread.Feedback__c) && feedbackThread.Feedback__c.toUpperCase().contains(upperSearchTerm)) || containsSearchTerm == true) {
                    trdWrapper.feedbackThreads =  feedbackthread;
                    trdWrapper.feedbackComments = cmtWrapperList;
                    Integer commentCount = cmtWrapperList.size();
                    trdWrapper.commentCount = commentCount;
                    threadWrapperList.add(trdWrapper); 
                }  
            }
           // threadWrapperList.add(trdWrapper); 
          
        }
            return threadWrapperList;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }      
    }
  
    public class FeedbackThreadWrapper{
        @AuraEnabled
        public BWPublicFeedbackThread__c feedbackThreads {get;set;}
        @AuraEnabled
        public List<FeedbackCommentWrapper> feedbackComments {get;set;}
        @AuraEnabled
        public Integer commentCount {get;set;}
    }
    public class FeedbackCommentWrapper{
        @AuraEnabled
        public BWFeedbackThreadComment__c feedbackComment {get;set;}
        @AuraEnabled
        public Boolean containsSearchTerm {get;set;}
    }
}
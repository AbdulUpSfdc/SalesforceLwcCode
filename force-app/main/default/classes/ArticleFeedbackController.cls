/******
    Name        : ArticleFeedbackController
    Description : This is the controller class for the consolidatedRelatedFeedback Component
*/

public with sharing class ArticleFeedbackController{
    
    @AuraEnabled(cacheable=true)
    public static ResponseHandler getArticleFeedbacks(string articleId) {
        system.debug('KnowledgeArticle Id ' + articleId);
        try{
            return new ResponseHandler(processResponseHandler(articleFeedbacks(articleId)));
        }catch(Exception e){
            return new ResponseHandler(e.getMessage());
        }
    }

    private static List<KM_Article_Feedback__c> processResponseHandler(List<KM_Article_Feedback__c> articleFeedbacks){
        system.debug('KnowledgeArticle Id Feedback collect ' + articleFeedbacks);
        List<KM_Article_Feedback__c> tempArticleFeedback = new List<KM_Article_Feedback__c>();
        for(KM_Article_Feedback__c articleFeedBack: articleFeedbacks){
            if(articleFeedBack.Knowledge__r.VersionNumber!= null){
                tempArticleFeedback.add(articleFeedBack);
            }
            
        }
        return tempArticleFeedback;
    }

    private static List<KM_Article_Feedback__c> articleFeedbacks(string articleId){
        system.debug('KnowledgeArticle Id Feedback collect ' + articleId);
    set<Id> articleIds = new Set<Id>();

    Knowledge__kav articleKA= [SELECT Id,KnowledgeArticleId FROM Knowledge__kav WHERE Id=:articleId];

    List<Knowledge__kav> archivedKA=   [SELECT Id,PublishStatus,UrlName,VersionNumber,KnowledgeArticleId FROM Knowledge__kav WHERE 
                            PublishStatus='Archived' AND IsLatestVersion=false and KnowledgeArticleId=:articleKA.knowledgeArticleId];
                            system.debug('archivedKA ' + archivedKA);
    
    List<Knowledge__kav> publishedKA=   [SELECT Id,PublishStatus,UrlName,VersionNumber,KnowledgeArticleId FROM Knowledge__kav WHERE 
                            PublishStatus ='Online' AND  IsLatestVersion=true and KnowledgeArticleId=:articleKA.knowledgeArticleId];
                            system.debug('publishedKA ' + publishedKA);
       
       for(Knowledge__kav arka :archivedKA) {
           articleIds.add(arka.Id);
           system.debug('articleIds ' + articleIds);
       }                    
    
                          
       for(Knowledge__kav pbka :publishedKA) {
           articleIds.add(pbka.Id);
           system.debug('articleIds ' + articleIds);
       }                    
    
        return [
            SELECT Id, Name, Description__c, Knowledge__c,Knowledge__r.VersionNumber,
            Owner.Name, Feedback_Response__c, Feedback_Status__c,Reason__c,CreatedDate
            FROM KM_Article_Feedback__c
            WHERE Knowledge__c IN:articleIds
            ORDER BY LastmodifiedDate DESC
        ];
    }
    
    @AuraEnabled(cacheable = true)
    public static string getProfile(){
        Id profileId = UserInfo.getProfileId();
    String profileName =[Select Id, Name from Profile where Id=:profileId].Name;
     return profileName;
    }
    public class ResponseHandler{
        @AuraEnabled
        public Boolean isSuccess {get;set;}
        @AuraEnabled
        public String errorMessage {get;set;}
        @AuraEnabled
        public List<KM_Article_Feedback__c> articleFeedbacks {get;set;}
        
        public ResponseHandler(List<KM_Article_Feedback__c> articleFeedbacks){
            this.isSuccess = true;
            this.errorMessage = '';
            this.articleFeedbacks = articleFeedbacks;
        }
        
        public ResponseHandler(String errorMessage){
            this.isSuccess = false;
            this.errorMessage = errorMessage;
            this.articleFeedbacks = new List<KM_Article_Feedback__c>();
        }
    }
}
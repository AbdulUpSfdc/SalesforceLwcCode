/******
    Name        : RelatedFeedbackController
    Description : This is the controller class for the RelatedFeedbackController
*/

public without sharing class RelatedFeedbackController {
    
    @AuraEnabled(cacheable=true)
    public static ResponseHandler getArtcileFeedbacks(string knowledgeArticleId) {
        try{
            return new ResponseHandler(processResponseHandler(artcileFeedbacks(knowledgeArticleId)));
        }catch(Exception e){
            return new ResponseHandler(e.getMessage());
        }
    }

    private static List<KM_Article_Feedback__c> processResponseHandler(List<KM_Article_Feedback__c> articleFeedbacks){
        List<KM_Article_Feedback__c> tempArticleFeedback = new List<KM_Article_Feedback__c>();
        for(KM_Article_Feedback__c artcileFeedBack: articleFeedbacks){
            if(artcileFeedBack.Feedback_Response__c != NULL){
                tempArticleFeedback.add(artcileFeedBack);
            }
        }
        return tempArticleFeedback;
    }

    private static List<KM_Article_Feedback__c> artcileFeedbacks(string knowledgeArticleId){
    
    set<Id> articleIds = new Set<Id>();

    List<Knowledge__kav> archivedKA=   [SELECT Id,PublishStatus,KnowledgeArticleId FROM Knowledge__kav WHERE 
                            PublishStatus='Archived'AND IsLatestVersion=false and KnowledgeArticleId=:knowledgeArticleId];
    
    List<Knowledge__kav> publishedKA=   [SELECT Id,PublishStatus,KnowledgeArticleId FROM Knowledge__kav WHERE 
                            PublishStatus ='Online'and  IsLatestVersion=true and KnowledgeArticleId=:knowledgeArticleId];
       
       for(Knowledge__kav arka :archivedKA) {
           articleIds.add(arka.Id);
       }                    
    
                          
       for(Knowledge__kav pbka :publishedKA) {
           articleIds.add(pbka.Id);
       }                    
    
        return [
            SELECT Id, Name, Description__c, Knowledge__c,
            Owner.Name, Feedback_Response__c, Feedback_Status__c
            FROM KM_Article_Feedback__c
            WHERE Knowledge__c IN :articleIds
            AND Feedback_Status__c != 'New'
            AND CreatedById =:UserInfo.getUserId()
            ORDER BY LastmodifiedDate DESC
        ];
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
public with sharing class RecommandedRelatedArticleController {
    
    @AuraEnabled(cacheable=true)
    public static ResponseHandler getknowledgeList(string knowledgeRecordId) {

        Set<Id> knowledgeSearchIds = new Set<Id>();
        Set<String> promotionterms = new Set<String>();
        try{   
            // get all Promoted Search Terms.
            for(SearchPromotionRule spr : getSearchPromotionRule(knowledgeRecordId)){
                promotionterms.add(spr.Query);
            }

            //Get all knowledge articles Ids.
            for(SearchPromotionRule spr : getSearchPromotionRule(knowledgeRecordId, promotionterms)){
                knowledgeSearchIds.add(spr.PromotedEntityId);
            }
            return new ResponseHandler(getOtherArticles(knowledgeSearchIds));

        }catch(System.Exception e){
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
            return new ResponseHandler(e.getMessage());
        }
        
    }

    //Get All the SearchPrmotionRule related to the selected Knowledge Article.
    private static List<SearchPromotionRule> getSearchPromotionRule(string knowledgeRecordId){
        try{
            return [
                SELECT Id, Query, PromotedEntityId 
                FROM SearchPromotionRule
                WHERE PromotedEntityId =: knowledgeRecordId
            ];
        }catch(System.Exception e){
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
        }
        return new List<SearchPromotionRule>();
    }

    //Get All the other SearchPrmotionRule related to the selected Knowledge Article's Search Terms.
    private static List<SearchPromotionRule> getSearchPromotionRule(string knowledgeRecordId, Set<String> promotionterms){
        try{
            return [
                SELECT Query, PromotedEntityId, Id 
                FROM SearchPromotionRule 
                WHERE Query IN :promotionterms
                AND PromotedEntityId != :knowledgeRecordId
            ];
        }catch(System.Exception e){
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
        }
        return new List<SearchPromotionRule>();
    }

    //Get all other knowledge article that are somehow related to the current knowledge Article's Search Term.
    private static List<Knowledge__kav> getOtherArticles(Set<id> knowledgeSearchIds){
        try{
            return [
                SELECT Id, Title, KnowledgeArticleId,
                ValidationStatus, LastPublishedDate, ArticleNumber
                FROM Knowledge__kav 
                WHERE Id IN :knowledgeSearchIds
                ORDER BY LastPublishedDate DESC
                LIMIT 15
            ];
        }catch(System.Exception e){
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
        }
        return new List<Knowledge__kav>();
    }

    public class ResponseHandler{
        @auraenabled public Boolean isSuccess;
        @auraenabled public String errorMessage;
        @auraenabled public List<KnowledgeArticleHandler> knowledegArtileList;

        public ResponseHandler(List<Knowledge__kav> knowledegArtileList){
            this.isSuccess = true;
            this.errorMessage = '';
            List<KnowledgeArticleHandler> tempKnowledegArtileList = new List<KnowledgeArticleHandler>();
            for(Knowledge__kav knowledge: knowledegArtileList){
                tempKnowledegArtileList.add(new KnowledgeArticleHandler(knowledge));
            }
            this.knowledegArtileList = tempKnowledegArtileList;
        }

        public ResponseHandler(String errorMessage){
            this.isSuccess = false;
            this.errorMessage = errorMessage;
            this.knowledegArtileList = new List<KnowledgeArticleHandler>();
        }
    }

    public class KnowledgeArticleHandler{
        @auraenabled public Knowledge__kav knowledge;
        @auraenabled public String recordURL;
        @auraenabled public String timeFormat;

        public KnowledgeArticleHandler(Knowledge__kav knowledge){
            this.knowledge = knowledge;
            this.recordURL = '/lightning/r/Knowledge__kav/' + knowledge.id + '/view';
            this.timeFormat = knowledge.LastPublishedDate != NULL ? knowledge.LastPublishedDate.format('h:mm a') : '';
        }
    }
}
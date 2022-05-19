public without sharing class VotingComponentController {
   
    private static final string TOPIC_NAME = 'VotingComponentController';
   
    @AuraEnabled(cacheable=true)
    public static ResponseHandler getLikeDislikeCount(String knowledgeArticleId){
        try{
            Map<String, Integer> voteByCount = getVoteByCount(knowledgeArticleId, new Set<String>{'1','5'});
            return new ResponseHandler(voteByCount.get('1'), voteByCount.get('5'), getVoteByUser(knowledgeArticleId));
        } catch(Exception exceptionObject){
            String errMsg = 'Error while retrieving like and dislike count for articleId:'+ knowledgeArticleId + '. '+ exceptionObject.getMessage() ;
            KM_Utility.makeLog(TOPIC_NAME, errMsg);
            AuraHandledException ex = new AuraHandledException(errMsg);
            ex.setMessage(errMsg);
            throw ex; 
        }
    }

    @AuraEnabled
    public static ResponseHandler doVoting(String existingVoteId, String knowledgeArticleId, boolean isLike){ 
        try{
            Knowledge__kav knowledgeArticle = [SELECT Id, ArticleNumber FROM Knowledge__kav WHERE Id = :knowledgeArticleId LIMIT 1];
            Knowledge__ka articleInstance = [SELECT Id FROM Knowledge__ka WHERE ArticleNumber = :knowledgeArticle.ArticleNumber LIMIT 1];
            Vote vt = new Vote(
                ParentId = articleInstance.Id,
                Type = isLike ? '5' : '1'
            );
            if(String.isNotBlank(existingVoteId)){
                vt.Id=existingVoteId;
            }
            UPSERT vt;
            
            return getLikeDislikeCount(knowledgeArticleId);
        } catch(Exception exceptionObject){
            String errMsg = 'Error while upserting vote for articleId: '+ knowledgeArticleId + '. '+ exceptionObject.getMessage();
            KM_Utility.makeLog(TOPIC_NAME, errMsg);
            AuraHandledException ex = new AuraHandledException(errMsg);
            ex.setMessage(errMsg);
            throw ex; 
        }
    }

    private static Vote getVoteByUser(String knowledgeArticleId){
        try{
            Knowledge__kav knowledgeArticle = [SELECT Id, ArticleNumber FROM Knowledge__kav WHERE Id = :knowledgeArticleId LIMIT 1];
            Knowledge__ka articleInstance = [SELECT Id FROM Knowledge__ka WHERE ArticleNumber = :knowledgeArticle.ArticleNumber LIMIT 1];
            return [
                SELECT Id, ParentId, Type, CreatedById
                FROM Vote 
                WHERE ParentId = :articleInstance.Id
                 AND CreatedById = :Userinfo.getuserid()
                LIMIT 1
            ];
        } catch(Exception exceptionObject){
            String errMsg = 'Error while retrieving votes for user for articleId:'+ knowledgeArticleId + '. '+ exceptionObject.getMessage();
            KM_Utility.makeLog(TOPIC_NAME, errMsg);
            AuraHandledException ex = new AuraHandledException(errMsg);
            ex.setMessage(errMsg);
            throw ex;   
        }
    }

    public static Map<String, Integer> getVoteByCount(Id KnowledgeArticleId, Set<String> typdeIds){
        Map<String, Integer> voteByCount = new Map<String, Integer>();
        
            
            voteByCount.put('1', 0);
            voteByCount.put('5', 0);
            
        try{
            Knowledge__kav knowledgeArticle = [SELECT Id, ArticleNumber FROM Knowledge__kav WHERE Id = :knowledgeArticleId LIMIT 1];
            Knowledge__ka articleInstance = [SELECT Id FROM Knowledge__ka WHERE ArticleNumber = :knowledgeArticle.ArticleNumber LIMIT 1];
            for(AggregateResult ar :[
                SELECT Count(id) totalcount, Type 
                FROM Vote 
                WHERE ParentId = :articleInstance.Id 
                AND TYPE IN :typdeIds 
                GROUP BY TYPE]){
                voteByCount.put(
                    ''+ar.get('Type'),
                    Integer.valueOf(''+ar.get('totalcount'))
                );
            }    
        } catch(Exception exceptionObject){
          String errMsg = 'Error while retrieving vote count for articleId:'+ knowledgeArticleId;
          KM_Utility.makeLog(TOPIC_NAME, errMsg);
          //throw new AuraHandledException(errMsg + exceptionObject.getMessage());
        }
        return voteByCount;
    }

 
    public class ResponseHandler{
        @AuraEnabled
        public Boolean isSuccess {get;set;}
        @AuraEnabled
        public String errMessage {get;set;}
        @AuraEnabled
        public Integer likeCount {get;set;}
        @AuraEnabled
        public Integer dislikeCount {get;set;}
        @AuraEnabled
        public Vote voteObj {get;set;}

        public ResponseHandler(Integer dislikeCount, Integer likeCount, Vote voteObj){
            this.isSuccess = true;
            this.errMessage = '';
            this.likeCount = likeCount != NULL ? likeCount : 0;
            this.dislikeCount = dislikeCount != NULL ? dislikeCount : 0;
            this.voteObj = voteObj;
        }
        
        public ResponseHandler(String errorMessage){
            this.isSuccess = false;
            this.errMessage = errorMessage;
            this.likeCount = 0;
            this.dislikeCount = 0;
        }

        public ResponseHandler(){
            this.isSuccess = true;
            this.errMessage = '';
        }
    }
}
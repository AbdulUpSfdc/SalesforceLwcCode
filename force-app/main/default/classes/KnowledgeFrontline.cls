public with sharing class KnowledgeFrontline {
    @AuraEnabled(cacheable=true)
    public static List<Knowledge__kav> getKnowledgeList() {
        return [
                SELECT Id, Title, BW_Article_Summary__c, BW_Preview_Image__c 
                FROM Knowledge__kav 
               // WITH SECURITY_ENFORCED 
                LIMIT 10
            ];
    }

    @AuraEnabled(cacheable=true)
    public static ResponseHandler getSingleKnowledge() {
        ResponseHandler responseObj = new ResponseHandler();
        getKnowledgeViewResponse(responseObj, [
            SELECT Id, Title, BW_Article_Summary__c, BW_Preview_Image__c, BW_FrontLine_Focus__c, ArticleTotalViewCount
            FROM Knowledge__kav
            WHERE BW_FrontLine_Focus__c=True
            AND PublishStatus ='Online'
           // WITH SECURITY_ENFORCED
            
            LIMIT 5
        ]);
        return responseObj;
    }
    
    private static void getKnowledgeViewResponse(ResponseHandler responseObj, List<Knowledge__kav> lstKnw){
        List<CompWrapper> fronLinelstCompWrapper = new List<CompWrapper>();
        for(Knowledge__kav obj: lstKnw){
            CompWrapper cmp = new CompWrapper();
            cmp.compId = obj.Id;
            cmp.title = obj.Title;
            cmp.summary = (obj.BW_Article_Summary__c!=null)?(obj.BW_Article_Summary__c).substringAfter('>').replace('&amp;','&').substringBefore('<'):'';
            cmp.previewImage = (obj.BW_Preview_Image__c!=null)? (obj.BW_Preview_Image__c).substringAfter('src="').replace('&amp;','&').substringBefore('"'):'';
            cmp.ArticleTotalViewCount = obj.ArticleTotalViewCount;
            
            if(obj.BW_FrontLine_Focus__c){
                fronLinelstCompWrapper.add(cmp);
            }
            
        }  
        responseObj.isSuccess = true;
        responseObj.errorMessage = '';
        responseObj.frontLineKnwList = fronLinelstCompWrapper;
    }


    public class ResponseHandler{
        @AuraEnabled
        public Boolean isSuccess {get;set;}
        @AuraEnabled
        public String errorMessage {get;set;}
        
        @AuraEnabled
        public List<KnowledgeFrontline.CompWrapper> frontLineKnwList {get;set;}
    }
    public class CompWrapper {
        @AuraEnabled
        public Id compId {get;set;}
        @AuraEnabled
        public String title {get;set;}

        @AuraEnabled
        public String summary {get;set;}
        @AuraEnabled
        public String previewImage {get;set;}

        @AuraEnabled
        public Integer ArticleTotalViewCount {get;set;}

        @AuraEnabled
        public Integer previewCount {get;set;}
        @AuraEnabled
        public Integer likeCount {get;set;}
        @AuraEnabled
        public Integer messageCount {get;set;}


        //Todo actual caculation
        public CompWrapper(){
            this.previewCount = Integer.valueof((Math.random() * 1000));
            this.likeCount = Integer.valueof((Math.random() * 1000));
            this.messageCount = Integer.valueof((Math.random() * 1000));
        }
    }
 
}
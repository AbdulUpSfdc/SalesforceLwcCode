public with sharing class ArticleDataWrapper {
    
    public static final Map<Id,Schema.RecordTypeInfo> knowledgeRecordTypeMapById;
    public static final Map<String, Id> knowledgeRecordTypeMapByName = new  Map<String, Id>();
    
    static {
        Schema.DescribeSObjectResult d = Schema.SObjectType.Knowledge__kav; 
        knowledgeRecordTypeMapById = d.getRecordTypeInfosById();
        for (Id rtId : knowledgeRecordTypeMapById.keySet()) {
         	 knowledgeRecordTypeMapByName.put(getRecordTypeName(rtId), rtId);   
        }
    }
    
    public String recordTypeName {get; set;}
    public Id sourceArticleRecordId {get; set;}
    public Map<String, List<String>> dateCategoryMap {get; set;}
    public List<String> marketNameList {get; set;}
    public List<Id> fileIdList {get; set;} {fileIdList = new List<Id>();}
    public Knowledge__kav knowledgeArticle {get; set;}
    
    public ArticleDataWrapper(Knowledge__kav knowledgeArticle, Map<String, List<String>> dateCategoryMap, List<String> marketNameList) {
        this.knowledgeArticle = knowledgeArticle;
        this.dateCategoryMap = dateCategoryMap;
        this.marketNameList = marketNameList;
        if (knowledgeArticle != null && knowledgeArticle.RecordTypeId != null) {
            this.recordTypeName = getRecordTypeName(knowledgeArticle.RecordTypeId);
        }   
    }
    
    public static Map<Id,Schema.RecordTypeInfo> getUserKnowledgeRecTypes() {
        Schema.DescribeSObjectResult d = Schema.SObjectType.Knowledge__kav; 
        Map<Id,Schema.RecordTypeInfo> rtMapById = new Map<Id,Schema.RecordTypeInfo>();
        rtMapById = d.getRecordTypeInfosById();
        return rtMapById;
    }
    
    public static String getRecordTypeName(Id recordTypeId) {
        return knowledgeRecordTypeMapById.get(recordTypeId).getName();  
    }	
    
    public static Id getRecordTypeId(String recordTypeName) {
        return knowledgeRecordTypeMapByName.get(recordTypeName); 
    }
    
}
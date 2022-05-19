public without sharing class BWLinkValidationHelper {
    
    public static final String DATA_CATEGORIES_MATCH = 'Data Categories Match with Parent Article';
    public static final String DATA_CATEGORIES_PARENT_ALL = 'Parent Article has all data categories';
    public static final String DATA_CATEGORIES_CHILD_ALL = 'Child Article has all data categories';
    public static final String DATA_CATEGORIES_CHILD_NONE = 'Child Article has no assigned data categories';
    
    public static final String DATA_CATEGORIES_BOTH_ALL = 'Parent Article and Child Article have all data categories';
    public static final String ERROR_INVALID_ID = 'Invalid article URL or ID: ';
    public static final String MSG_LINK_ONLY = 'Link Only Available for: ';
    public static final String MSG_INVALID_LINK_URL = 'Invalid Link URL; Link cannot be validated.';
    public static final String MSG_LINK_NOT_AVAILABLE ='Link Not Available for: ';
    public static final String ARTICLE_URL_PATH = '/articles/Knowledge/';
    //public static final String ARTICLE_TYPE = 'External Link';
    public static final String ARTICLE_TYPE = 'Knowledge Article';
    
    @AuraEnabled
    public static void validateLinks(Id ArticleId){
        System.debug('Article id: ' + articleId);
        Set<Id> articleIdSet = new Set<Id>();
        Set<String> setParentCategories = new Set<String>();
        Set<String> setChildCategories= new Set<String>();
        Set<String> setChildParentCategories = new Set<String>();
        Set<String> linkedArticleURLNames = new Set<String>();
        String linkedkmArticleId;
        Boolean parentHasAllDataCategories = false;
        String strValidationMessage='';
        String articleURL;
        Map<String, Id> mapRelatedArticleURL = new Map<String, Id>(); 
        List< Knowledge__kav> externalLinkArticles;
        List<BWKnowledgeArticleLink__c> badLinkList = new List<BWKnowledgeArticleLink__c>();
        Map<Id, BWKnowledgeArticleLink__c> mapRelatedLinkIdRelatedAricle = new Map<Id, BWKnowledgeArticleLink__c>();
        Map<String, BWKnowledgeArticleLink__c> mapRelatedLinkArticleURL = new Map<String, BWKnowledgeArticleLink__c>();
        
        Map<Id, List<Knowledge__DataCategorySelection>> dataCategoryMap = new Map<Id, List<Knowledge__DataCategorySelection>>();
        Map<Id, BWKnowledgeArticleLink__c> articleLinksMap;
        Map<Id, BWKnowledgeArticleLink__c> validArticleLinksMap = new Map<Id, BWKnowledgeArticleLink__c>();
        articleLinksMap = new Map<Id, BWKnowledgeArticleLink__c>([SELECT Id,Knowledge_Article__c,Type__c,Link_URL__c,ValidationMessage__c 
                                                                  FROM BWKnowledgeArticleLink__c
                                                                  WHERE Knowledge_Article__c=:ArticleId 
                                                                  AND Type__c= :ARTICLE_TYPE]);
        
        System.debug('*** Linked articles found: ' + articleLinksMap.size());
        
        if (articleLinksMap.isEmpty()) {
            //nothing to compare to; avoid further action;
            return;
        } 
        
        articleIdSet.add(ArticleId); 
        
        for (BWKnowledgeArticleLink__c kal:articleLinksMap.values()) {
            //get the underlying article link id and related that to this record
            
            system.debug(kal.Link_URL__c);
            if (isValidArticleURL(kal.Link_URL__c)) {
                articleURL = getArticleURL(kal.Link_URL__c);
                linkedArticleURLNames.add(articleURL);
                system.debug('Link URL ' + kal.Link_URL__c + '; article URL: ' + articleURL);
                mapRelatedLinkArticleURL.put(articleURL, kal);
                validArticleLinksMap.put(kal.Id, kal);
            } else {
                kal.ValidationMessage__c= MSG_INVALID_LINK_URL ;
                badLinkList.add(kal);
            }
        }   
        
        if (!badLinkList.isEmpty()) {
        	updateArticleLinkValidationMessage(badLinkList);	
        }    
        
        if (validArticleLinksMap.isEmpty()) {
            //no valid liks to look; just update the messages;
            System.debug('No valid article links found');
            return;
        } 
        
        
        externalLinkArticles = [SELECT Id, UrlName FROM Knowledge__kav WHERE UrlName IN :linkedArticleURLNames];
        if (externalLinkArticles.isEmpty()) {
            //no valid articles to look at; exit
            System.debug('No related valid article links found');
            return;
        } 
        
        System.assert(!externalLinkArticles.isEmpty());
        for (Knowledge__kav ka : externalLinkArticles) {
            mapRelatedArticleURL.put(ka.URLName, ka.Id);
            articleIdSet.add(ka.Id);
            mapRelatedLinkIdRelatedAricle.put(ka.id, mapRelatedLinkArticleURL.get(ka.URLName));
        }
        /*
for (BWKnowledgeArticleLink__c kal:validArticleLinksMap.values()) {
//get the underlying article link id and related that to this record

system.debug(kal.Link_URL__c);
if (isValidArticleURL(kal.Link_URL__c)) {
linkedArticleURLNames.add(getArticleURL(kal.Link_URL__c));
articleIdSet.add(linkedkmArticleId);
mapRelatedLinkIdRelatedAricle.put(linkedkmArticleId, kal);
} else {
kal.ValidationMessage__c=kal.Link_URL__c;
}
} */
        
        List<Knowledge__DataCategorySelection> lstCategorySelection= getDataCategories(articleIdSet);
        System.debug('Category selections: ' + lstCategorySelection);
        articleIdSet.remove(ArticleId); // only needed to query all data categories at once
        
        strValidationMessage = getDataCategoryValidationMessage(lstCategorySelection);
        if (strValidationMessage.equals(DATA_CATEGORIES_MATCH)) {
            for (BWKnowledgeArticleLink__c kal:validArticleLinksMap.values()) {
                kal.ValidationMessage__c=strValidationMessage; 
            }
            updateArticleLinkValidationMessage(validArticleLinksMap.values());
            return;
        }
        
        dataCategoryMap = buildDataCategoryMap(lstCategorySelection);
        
        setParentCategories = getDataCategoryNameSet(dataCategoryMap.get(articleId));
        
        System.debug('Complete list of parent categories: ' + json.serialize(setParentCategories));
        
        parentHasAllDataCategories = hasAllDataCategories(setParentCategories);
        
        for (Id childArticleId :  articleIdSet) {
            BWKnowledgeArticleLink__c articleLink = mapRelatedLinkIdRelatedAricle.get(childArticleId);
            setChildCategories = getDataCategoryNameSet(dataCategoryMap.get(childArticleId));
            System.debug('All Child categories: ' + json.serialize(setChildCategories));
            
            strValidationMessage= getDataCategoryValidationMessage(setParentCategories, setChildCategories);
            
            articleLink.ValidationMessage__c=strValidationMessage;
            articleLinksMap.put(articleLink.Id,  articleLink);
            
        }
        
        updateArticleLinkValidationMessage(validArticleLinksMap.values());
    }
    
    
    public static void addToMapOfLists(Map<Id, List<SObject>> theMap, Id key, SObject sobj){
        List<SObject> sobjList = theMap.get(key);
        if(sobjList == null){
            sobjList = new List<SObject>();
        }
        sobjList.add(sobj);
        theMap.put(key, sobjList);
    }
    
    @TestVisible
    private static Boolean hasAllDataCategories(Set<String> categorySet) {
        return  categorySet != null && categorySet.size() == 1 && categorySet.contains('All');
    }
    
    @TestVisible
    private static void updateArticleLinkValidationMessage(List<BWKnowledgeArticleLink__c> lstArticleLinks) {
        try {
            update lstArticleLinks;    
        }
        catch(System.Exception e){
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
            return;
        } 
    }
    
    @AuraEnabled
    public static String compareDataCategories(String parentArticleId, String linkedArticleId){
        System.debug('Parent article Id: ' + parentArticleId+'; Linked article Id: '+linkedArticleId);
        Set<Id> articleIdSet = new Set<Id>();
        Set<String> setChildCategories= new Set<String>();
        Set<String> setParentCategories = new Set<String>();
        Map<Id, List<Knowledge__DataCategorySelection>> dataCategoryMap = new Map<Id, List<Knowledge__DataCategorySelection>>();
        String linkedArticleIdValidation;
        
        Boolean parentHasAllDataCategories = false;
        String strValidationMessage='';
        articleIdSet.add(parentArticleId);
        linkedArticleIdValidation = getArticleID(linkedArticleId);
        if (linkedArticleIdValidation.contains(ERROR_INVALID_ID)) {
            return linkedArticleIdValidation;
        }   
        articleIdSet.add(linkedArticleIdValidation);
        
        List<Knowledge__DataCategorySelection> lstCategorySelection= getDataCategories(articleIdSet);
        articleIdSet.remove( parentArticleId); // only needed to query all data categories at once
        
        strValidationMessage = getDataCategoryValidationMessage(lstCategorySelection);
        if (strValidationMessage.equals(DATA_CATEGORIES_MATCH)) {
            return strValidationMessage;
        }   
        dataCategoryMap = buildDataCategoryMap(lstCategorySelection);
        
        setParentCategories = getDataCategoryNameSet(dataCategoryMap.get(parentArticleId));
        
        System.debug('Complete list of parent categories: ' + json.serialize(setParentCategories));
        
        
        for (Id childArticleId :  articleIdSet) {
            
            setChildCategories = getDataCategoryNameSet(dataCategoryMap.get(childArticleId));
            System.debug('All Child categories: ' + json.serialize(setChildCategories));
            strValidationMessage= getDataCategoryValidationMessage(setParentCategories, setChildCategories);
            
        }
        return strValidationMessage;
    }
    
    public static String getDataCategoryValidationMessage(Set<String> setParentCategories, Set<String> setChildCategories) {
        String strValidationMessage = '';
        Set<String> setChildParentCategories = new Set<String>();
        
        if (hasAllDataCategories(setParentCategories)) {
            if (setChildCategories.isEmpty()) {
                strValidationMessage = DATA_CATEGORIES_CHILD_NONE;
                System.debug('Validation Message ' + strValidationMessage); 
            } else if (!hasAllDataCategories(setChildCategories)) {
                for (String strcategory: setChildCategories){
                    strValidationMessage=strValidationMessage+'\n' + MSG_LINK_ONLY + strcategory;
                    System.debug('Validation Message ' + strValidationMessage);
                }
            } else {
                strValidationMessage = DATA_CATEGORIES_BOTH_ALL;    
            }    
            System.debug(strValidationMessage);
            return strValidationMessage;
        }
        if (setChildCategories.containsAll(setParentCategories)) {
            strValidationMessage=DATA_CATEGORIES_MATCH;
            System.debug('All parent categories are in the child.');
        } else if (hasAllDataCategories(setChildCategories)) {
            strValidationMessage = DATA_CATEGORIES_CHILD_ALL;
        }  else {
            setChildParentCategories = new Set<String>(setParentCategories);
            
            setChildParentCategories.removeAll(setChildCategories); // only deal with ones that aren't there
            System.debug('Parent categories without categories in child: ' + json.serialize( setChildParentCategories));
            
            for (String strcategory: setChildParentCategories){
                strValidationMessage=strValidationMessage+'\n'+ MSG_LINK_NOT_AVAILABLE +  strcategory;
                System.debug('Validation Message ' + strValidationMessage);
            }
        }    
        if(strValidationMessage==''){
            strValidationMessage=DATA_CATEGORIES_MATCH;
        }
        
        return strValidationMessage;
    }
    
    public static String getDataCategoryValidationMessage(List<Knowledge__DataCategorySelection> dataCategories) {
        String strValidationMessage = '';
        if (dataCategories.isEmpty()) { //there are no data categories on parent or child(ren)
            strValidationMessage=DATA_CATEGORIES_MATCH;
        } else {
            System.debug('All data categories: ' + dataCategories);
        }
        return strValidationMessage;
    }
    
    public static Map<Id, List<Knowledge__DataCategorySelection>> buildDataCategoryMap(List<Knowledge__DataCategorySelection> dataCategories) {
        Map<Id, List<Knowledge__DataCategorySelection>> dataCategoryMap = new Map<Id, List<Knowledge__DataCategorySelection>>();
        for (Knowledge__DataCategorySelection kdc: dataCategories) {
            addToMapOfLists(dataCategoryMap, kdc.ParentId, kdc);       
        }
        return dataCategoryMap;
    }
    
    public static List <Knowledge__DataCategorySelection> getDataCategories(Set<Id> articleIdSet) {
        /*list<Knowledge__DataCategorySelection> datacategoryassign =new list<Knowledge__DataCategorySelection>();
        map<id,string>Articleid =new map<id,string>();
        list<Knowledge__kav> alldatacategory =new list<Knowledge__kav>();
        datacategoryassign=[SELECT toLabel(DataCategoryName),Id,ParentId,DataCategoryGroupName 
                FROM Knowledge__DataCategorySelection 
                WHERE ParentId in :articleIdSet];
         For(Knowledge__DataCategorySelection da :datacategoryassign)
         {
             if(da.DataCategoryName =='All')
             {
                 system.debug('All data category'+da.DataCategoryGroupName);
                 Articleid.put(da.ParentId,da.DataCategoryGroupName);
             }
             
             
         }
        //string roleresource=Articleid[0].values();
        alldatacategory=[SELECT ID FROM Knowledge__kav WHERE ID in :Articleid.keyset()  WITH  DATA CATEGORY Resource_Type__c Below All__c
                                  ORDER BY Title ASC];
        
        if(Articleid.size() !=null){
            //return alldatacategory;
        }
        else{
            return datacategoryassign;
        }
        
       */ 
        return [SELECT toLabel(DataCategoryName),Id,ParentId,DataCategoryGroupName 
                FROM Knowledge__DataCategorySelection 
                WHERE ParentId in :articleIdSet]; 
        
    }    
    
    public static String getArticleId(String kmArticleURL) {
        if (kmArticleURL == null || kmArticleURL.length()<18) {
            return ERROR_INVALID_ID +  kmArticleURL;
        }
        Id linkedkmArticleId;
        String kmArticleIdstrip=kmArticleURL.substringBeforeLast('/view');
        linkedkmArticleId=kmArticleIdstrip.right(18);
        return linkedkmArticleId;
    }
    
    
    public static Boolean isValidArticleURL(String kmArticleURL) {
        if (kmArticleURL == null || !kmArticleURL.contains(ARTICLE_URL_PATH)) {
            return false;
        }
        return true;
    }
    
    
    public static String getArticleURL(String kmArticleURL) {
        
        String articleURL;
        if (!isValidArticleURL(kmArticleURL)) {
            return null;
            
        } else {
            articleURL = kmArticleURL.substringAfterLast(ARTICLE_URL_PATH);
        }
        return articleURL;
    }
    
    public static Set<String> getDataCategoryNameSet(List<Knowledge__DataCategorySelection> dataCategories) {
        Set<String> dataCategoryNameSet = new Set<String>(); 
        if (dataCategories == null) {
            return dataCategoryNameSet;
        }
        for (Knowledge__DataCategorySelection kdc: dataCategories) {
            String categoryName=kdc.DataCategoryName;
            System.debug('DataCategoryName: ' + categoryName);
            dataCategoryNameSet.add(categoryName);
            
        }
        return dataCategoryNameSet;
    }

    @AuraEnabled(cacheable = true)
	public static List<BWKnowledgeArticleLink__c> getKnowledgeArticleLinks(Id articleId){
		List<BWKnowledgeArticleLink__c> articleLinks = new List<BWKnowledgeArticleLink__c>();
		try{
			articleLinks = [SELECT Id, Name, Status__c, ContentSponsor__c, Type__c
			                FROM BWKnowledgeArticleLink__c
			                WHERE EmailEnabled__c = true AND Knowledge_Article__c = :articleId];
		} catch (Exception e){
			// Log the exception
			BWC_ExceptionUtils.handleException(e, true);
		}
		return articleLinks;
	}
}
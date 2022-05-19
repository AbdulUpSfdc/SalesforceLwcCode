public without sharing class MarketHelper {
    
    public static final String MSG_DRAFT_STATUS = 'The article must be in draft status.';
    
    /*
Description: Class to handle mass market updates to article

*/
    public class MarketHelperException extends Exception {}
    
    public static Integer disassociateAllMarkets(Id ArticleId) {
        Knowledge__kav article = getArticle(ArticleId);
        if (article == null || !isArticleDraft(article)) {
            throw new MarketHelperException(MSG_DRAFT_STATUS);
        }
        List<BWMarketAssociation__c> marketAssociationList = getMarketAssociationList(articleId);
        if (!marketAssociationList.isEmpty()) {
            try {
                delete marketAssociationList;
            } catch(System.Exception e){
                System.debug('disassociateAllMarkets:'+e);
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            } 
        } else {
            System.debug('No markets to disassociate.');
        } 
        return marketAssociationList.size(); 
    } 
    
    public static Integer associateAllMarkets(Id ArticleId) {
        Knowledge__kav article = getArticle(ArticleId);
        if (article == null || !isArticleDraft(article)) {
            throw new MarketHelperException(MSG_DRAFT_STATUS);
        }
        List<BWMarketAssociation__c> newMarketAssociationList = new List<BWMarketAssociation__c>();
        List<BWMarketMaster__c> marketList;
        Map<Id, BWMarketMaster__c> marketMap;
        BWMarketAssociation__c newAssociation;   
        
        List<BWMarketAssociation__c> existingMarketAssociationList = getMarketAssociationList(articleId);
        Set<Id> existingMarketIdSet = new Set<Id>();
        
        for (BWMarketAssociation__c association : existingMarketAssociationList) {
            existingMarketIdSet.add(association.BWMarketMaster__c);    
        }
        
        if (!existingMarketIdSet.isEmpty()) {
            marketList = [SELECT Id, Name from BWMarketMaster__c WHERE ID NOT IN :existingMarketIdSet];
        } else {
            marketList = [SELECT Id, Name from BWMarketMaster__c ];
        }
        
        marketMap = new Map<Id, BWMarketMaster__c>(marketList);
        
        for (Id marketId : marketMap.keySet()) {
            newAssociation = new BWMarketAssociation__c();
            newAssociation.BWMarketMaster__c = marketId;
            newAssociation.Knowledge__c=ArticleId;
            newMarketAssociationList.add(newAssociation);
        }
        
        System.debug(existingMarketIdSet.size() + ' markets were already associated. ' + newMarketAssociationList.size() + ' new markets to be associated.');
        
        if (!newMarketAssociationList.isEmpty()) {
            try{
                database.insert(newMarketAssociationList);
            } catch(System.Exception e){
                System.debug('associateAllMarkets:'+e);
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            } 
        } else {
            System.debug('No new markets to create.');
        }   
        return newMarketAssociationList.size(); 
    }
    
    public static List<BWMarketAssociation__c> getMarketAssociationList(Id articleId) {
        return [SELECT BWMarketMaster__c,Id,Knowledge__c 
                FROM BWMarketAssociation__c WHERE Knowledge__c = :ArticleId];
    }    
    
    public static Knowledge__kav getArticle(Id ArticleId) {
        Map<Id, Knowledge__kav> knowledgeMap = new Map<Id, Knowledge__kav>([SELECT Id, PublishStatus FROM Knowledge__kav
                                                                          WHERE Id = :ArticleId]);
        return knowledgeMap.get(ArticleId);                                                                
    }
    
    public static Boolean isArticleDraft(Knowledge__kav article) {
        return article.PublishStatus != null && article.PublishStatus.equalsIgnoreCase('Draft');
    }
}
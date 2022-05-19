@isTest	
public with sharing class KnowledgeEmailControllerTest {

    public static testmethod void testgetEmailFormLinks() {
    	Id knowledgeRecordId = null;
        List<BWKnowledgeArticleLink__c> links = KnowledgeEmailController.getEmailFormLinks(knowledgeRecordId);
        System.assert(links.isEmpty());        
    }
    
}
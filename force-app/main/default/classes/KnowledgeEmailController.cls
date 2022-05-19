public without sharing class KnowledgeEmailController {
    @AuraEnabled
    public static List<BWKnowledgeArticleLink__c> getEmailFormLinks(Id knowledgeRecordId){
           List<BWKnowledgeArticleLink__c> lstKnowledgeLinks= [SELECT Knowledge_Article__c,Link_Title__c,
                                                                Link_URL__c,ShareLinkURL__c 
                                                                FROM BWKnowledgeArticleLink__c
                                                                where Knowledge_Article__c=:knowledgeRecordId 
                                                                and ShareLinkURL__c!='' ];
         
        system.debug(lstKnowledgeLinks);
        return lstKnowledgeLinks;
    }
     
}
/*****
 Name             : BWArchiveKnowledgeArticleLinks
 Description      : Helper class to archive knowledge article links
 ****/

public with sharing class BWArchiveKnowledgeArticleLinks{
	public static void archiveArticleLinks(Set<Id> articleIds){
		List<BWKnowledgeArticleLink__c> linksToBeArchived = new List<BWKnowledgeArticleLink__c>();

		for (BWKnowledgeArticleLink__c link : [SELECT Id, Status__c
		                                       FROM BWKnowledgeArticleLink__c
		                                       WHERE Knowledge_Article__c = :articleIds AND Status__c <> 'Archived']){
			
            link.Status__c = 'Archived';
			linksToBeArchived.add(link);
		}

        //Archive Knowledge Article Links
		if (!linksToBeArchived.isEmpty()){
			try{
                update linksToBeArchived;
            } catch (System.Exception e){
				System.debug('EXCEPTION - Failed to update article links status');
				BWC_ExceptionUtils.handleException(e, true);
			}
		}
	}
}
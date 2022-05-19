trigger checkShareLinkBeforeDeletion on BWKnowledgeArticleLink__c (before delete) {
    if(Trigger.isBefore){
        if(Trigger.isDelete)
        {
          knowledgeArticleLinkHelper.beforeDelete(trigger.oldMap);
        }
    }

}
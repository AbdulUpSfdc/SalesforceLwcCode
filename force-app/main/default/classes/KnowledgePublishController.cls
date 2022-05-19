/*********
Name            : KnowledgePublishController
Description     : This is Controller class for the Lightning component knowledgePublishAuraComponent.cmp
*********/

public with sharing class KnowledgePublishController {
    private static string AUTO_PUBLISH_PERM_AUTHOR_GROUP = 'Auto Publish Permission Authors';
    
    @AuraEnabled
    public static String updateKnowledgeRecord(String recordId){
        string returnString;
        Boolean isPublish = TRUE;
        List<Knowledge__kav> knowledgeListUpdate = new List<Knowledge__kav>();
        Set<String> groupNames = new Set<String>();
        for (GroupMember gm : [select group.name,group.DeveloperName from GroupMember where UserOrGroupId = :UserInfo.getUserId()]){
            groupNames.add(gm.group.name);
        }  
        try{
            List<Knowledge__kav> knowledgeListRecord = [SELECT Id, PublishStatus, CustomValidationStatus__c, NumberOfArchivedArticles__c, KnowledgeArticleId, CustomPublicationStatus__c, BWScheduledArticlePublicationDate__c 
                                                        FROM Knowledge__kav where Id =: recordId];
            
            List<BWKnowledgeArticleLink__c> knowledgeArticleLink = [Select Id, Status__c,Knowledge_Article__c 
                                                                    FROM BWKnowledgeArticleLink__c Where Knowledge_Article__c IN: knowledgeListRecord and Status__c ='Archived'];  
            Integer noOfArchivedArticleRec = knowledgeArticleLink.size();
            for(Knowledge__kav knowledgeList :knowledgeListRecord){
                if(noOfArchivedArticleRec == 0 && knowledgeList.CustomValidationStatus__c == TRUE
                   && (knowledgeList.CustomPublicationStatus__c != 'Ready for Publication' 
                       ||knowledgeList.CustomPublicationStatus__c == NULL)
                   && groupNames.contains(AUTO_PUBLISH_PERM_AUTHOR_GROUP)
                   && knowledgeList.BWScheduledArticlePublicationDate__c == null
                   && knowledgeList.PublishStatus == 'Draft'
                  ){
                      knowledgeList.CustomPublicationStatus__c = 'Ready for Publication'; 
                      knowledgeListUpdate.add(knowledgeList);
                      isPublish = TRUE;
                  }else if(noOfArchivedArticleRec > 0){
                      string errAccId = 'Validation failed due to references to expired and/or archived articles within the article body. Please review the Status in the Knowledge Article Links list for errors and re-publish.';
                      AuraHandledException ex = new AuraHandledException(errAccId);
                      ex.setMessage(errAccId);
                      throw ex;
                  }
                else if(noOfArchivedArticleRec ==0 && knowledgeList.CustomValidationStatus__c != TRUE
                        && knowledgeList.CustomPublicationStatus__c != 'Ready for Publication'
                       ){
                           if(groupNames.contains(AUTO_PUBLISH_PERM_AUTHOR_GROUP)){
                               knowledgeList.CustomPublicationStatus__c = 'Ready for Publication'; 
                               knowledgeList.CustomValidationStatus__c = TRUE;
                               knowledgeListUpdate.add(knowledgeList);
                               isPublish = FALSE;
                           }else{
                               string errAccId = 'You are not authorized to auto publish. Please assign to the Content Strategy Team';
                               AuraHandledException ex = new AuraHandledException(errAccId);
                               ex.setMessage(errAccId);
                               throw ex;
                           }
                       }else if(knowledgeList.BWScheduledArticlePublicationDate__c != null 
                                && noOfArchivedArticleRec ==0
                                && knowledgeList.CustomPublicationStatus__c == 'Ready for Publication'
                                && knowledgeList.CustomValidationStatus__c == TRUE
                               ){
                                   /*string errAccId = 'Article Scheduled for Publishing.';
                                   AuraHandledException ex = new AuraHandledException(errAccId);
                                   ex.setMessage(errAccId);
                                   throw ex;*/
                                   returnString = 'Article scheduled for publishing';
                                   
                               }else{
                                   returnString = 'Knowledge article published successfully.';
                                   KbManagement.PublishingService.publishArticle(knowledgeList.KnowledgeArticleId, true);
                               }   
            }
            
            if(knowledgeListUpdate.size() > 0){
                if(!isPublish)
                { 
                    returnString = 'Verification for Archived Links succeeded. Please click publish button to publish the article.';
                    update knowledgeListUpdate;
                }
                else{
                    returnString = 'Knowledge article published successfully.';
                    update knowledgeListUpdate;
                    for(Knowledge__kav ka : knowledgeListUpdate){
                        String articleVersionId = ka.knowledgeArticleId;
                        KbManagement.PublishingService.publishArticle(articleVersionId, true);
                    }
                    
                }
            }
            return returnString;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());             
        }
        
    }
}
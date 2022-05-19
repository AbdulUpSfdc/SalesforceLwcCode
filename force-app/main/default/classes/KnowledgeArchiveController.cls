/*********
    Name            : KnowledgeArchiveController
    Description     : This is Controller class for the Lightning component knowledgeArchiveAuraComponent.cmp
*********/

public with sharing class KnowledgeArchiveController {
    @AuraEnabled
    public static String updateKnowledgeRecordArchive(String recordId){
        List<Knowledge__kav> draftVersions = new List<Knowledge__kav>();
        List<Knowledge__kav> knowledgeListRecord = new List<Knowledge__kav>();
        String returnString = NULL;
        String htmlBody = '';

        System.debug('Record Id on button click'+recordId);
        try{
            knowledgeListRecord = [ SELECT Id, UrlName, ContentSponsor__c, ArticleNumber, PublishStatus, KnowledgeArticleId 
                                    FROM Knowledge__kav 
                                    WHERE publishstatus = 'Online' and Id =: recordId];
            if(knowledgeListRecord.isEmpty()){
                return 'archivedArticle';
            }
            else{
                //declare a string
                String strCompare = '%/' + knowledgeListRecord[0].UrlName;
                    
                System.debug('strCompare: '+strCompare);
                
                //Check if there are Knwoeldge articlelinks object on tht record, Parent Article Id and urlname where URlanme = current article urlname
            
                List<BWKnowledgeArticleLink__c> knowledgeArticleLink = [Select 
                                                                        Knowledge_Article__r.KnowledgeArticleId,
                                                                        Knowledge_Article__r.Title,
                                                                        ParentArticleNumber__c
                                                                        FROM BWKnowledgeArticleLink__c 
                                                                        Where Knowledge_Article__r.publishstatus='Online' and
                                                                        Link_URL__c LIKE :strCompare];  
                
                

                System.debug('Values in the knowledgeArticleLink list: '+json.serialize(knowledgeArticleLink));
                System.debug('Values in the KnowledgeList'+knowledgeListRecord);
                
                System.debug('knowledgeArticleLink size'+knowledgeArticleLink.size());
                if(knowledgeArticleLink.size() > 0){
                    returnString = '';
                    for(BWKnowledgeArticleLink__c kal: knowledgeArticleLink){
                        system.debug('Error Exception'+kal);
                        //construct the string and return
                        if(kal.ParentArticleNumber__c != Null || kal.Knowledge_Article__r.KnowledgeArticleId != Null){
                            
                            //returnString +='\n MyCSP Article Name-'+(kal.ParentArticleNumber__c+': Knowledge Article Id:'+kal.Knowledge_Article__r.KnowledgeArticleId).split('\r\n\t\r\n')+'\r\n';
                            //returnString += '\n\nKnowledge Article Id- '+kal.Knowledge_Article__r.KnowledgeArticleId+': MyCSP Article Name- '+kal.ParentArticleNumber__c;
                            //htmlBody += '\n\n MyCSP Article Name- '+kal.ParentArticleNumber__c+':  Knowledge Article Id- '+URL.getSalesforceBaseUrl().toExternalForm()+ '/lightning/r/Knowledge__kav/' + kal.Knowledge_Article__r.KnowledgeArticleId +'/view';
                            htmlBody += '\n\n'+kal.Knowledge_Article__r.Title+': '+URL.getSalesforceBaseUrl().toExternalForm()+ '/lightning/r/Knowledge__kav/' + kal.Knowledge_Article__r.KnowledgeArticleId +'/view';
                                
                            returnString = htmlBody;
                            system.debug('RETURN'+returnString);
                        }
                    }               
                }
                
                else{
                    draftVersions = [SELECT Id 
                                    FROM Knowledge__kav 
                                    WHERE KnowledgeArticleId = :knowledgeListRecord[0].KnowledgeArticleId AND PublishStatus = 'Draft'];
                    if(!draftVersions.isEmpty()){
                        returnString = 'draftVersionExists';
                    }
                    else{
                        for (Knowledge__kav kav: knowledgeListRecord){
                            String articleVersionId = kav.knowledgeArticleId;
                            System.debug('articleVersionId'+articleVersionId);
                            KbManagement.PublishingService.archiveOnlineArticle(articleVersionId, null);
                        }
                    }
                }
                System.debug('ReturnString return value:'+returnString);
                return returnString;
            }
            
        }
        catch (Exception ex) {
            throw new AurahandledException('Error Details: ' + ex.getMessage());
        } 
    }
}
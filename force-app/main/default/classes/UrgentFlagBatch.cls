/*******
Name            : UrgentFlagBatch
Description     : This is the UrgentFlagBatch class to capture all the knowledge article which are 30 days old 
and having BW_Is_Urgent__c is true.and if any article found, then make it false.
*******/
public with sharing class UrgentFlagBatch implements Database.Batchable<sobject>{
    
    //interface method to collect the batches of records or objects to be passed to execute method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Query the metadata record to get the urgent flag days 
        Knowledge_Landing_Setting__mdt knwMetadata = [SELECT Id, DeveloperName, Label, Days_to_News_Article__c,
                                                      Days_to_Urgent_Flag__c FROM Knowledge_Landing_Setting__mdt
                                                      WHERE DeveloperName = 'default'];
        
        //Generate the date which is Urgent Flag days from Today.
        Integer tempNumber = (Integer)knwMetadata.Days_to_Urgent_Flag__c - 1;
        Date old30Days = System.today().addDays(-Integer.valueOf(knwMetadata.Days_to_Urgent_Flag__c));
        Date old29Days = System.today().addDays(-tempNumber);
        Date todayDate = System.today();
        
        return Database.getQueryLocator([
            SELECT Id, BW_Is_Urgent__c, LastPublishedDate, BW_News_End_Date__c,
            KnowledgeArticleId, RecordType.Name FROM Knowledge__kav 
            WHERE ((BW_Is_Urgent__c = true
          	AND LastPublishedDate >=: old30Days
          	AND LastPublishedDate <: old29Days)
          	OR (RecordType.Name = 'News Article'
               AND DAY_ONLY(BW_News_End_Date__c) =: todayDate))
          	AND Language = 'en_US'
          	AND publishStatus = 'Online'
        ]);
        
    }
    
    //interface method to process each batch of records
    public void execute(Database.BatchableContext bc, List<Knowledge__kav> knowledgeList){
        system.debug('list '+knowledgeList);
        List<String> kwList = new List<String>();
        List<Knowledge__kav> knowledgeToUpdate = new List<Knowledge__kav>();
        if(knowledgeList.size() > 0){
            for(Knowledge__kav kavObj : knowledgeList){
                if(kavObj.RecordType.Name == 'News Article'){
                    system.debug('i am in if end date today');
                      system.debug('id '+kavObj.id);
                    //Making new Article Archieved if End date is Today
                	KbManagement.PublishingService.archiveOnlineArticle(kavObj.KnowledgeArticleId, Null);  
                }else{
                      system.debug('i am in if end date not today');
                      system.debug('id '+kavObj.id);
                    String knowledgeId = KbManagement.PublishingService.editOnlineArticle(kavObj.KnowledgeArticleId, true);
                	//Make the Urdent false, so that it will not visible on the landing page.
                	kwList.add(knowledgeId);  
                  }
                
            }
        }
        //Update the Article with the new value.
        for(Knowledge__kav kavObj : [SELECT Id, BW_Is_Urgent__c, LastPublishedDate,BW_News_Start_Date__c ,RecordType.Name, 
                                     KnowledgeArticleId, PublishStatus  FROM Knowledge__kav 
                                     WHERE Id IN : kwList]){
            kavObj.BW_Is_Urgent__c = false;
            if(kavObj.BW_News_Start_Date__c != NULL 
            && kavObj.RecordType.Name == 'News Article' 
            && kavObj.BW_News_Start_Date__c < System.Now()){
                kavObj.BW_News_Start_Date__c = System.Now().AddSeconds(1);
            }
            knowledgeToUpdate.add(kavObj);        
        }
        
        if(knowledgeToUpdate.size() > 0){
            UPDATE knowledgeToUpdate;
        }
        
        for(Knowledge__kav kavObj : knowledgeToUpdate){
            KbManagement.PublishingService.publishArticle(kavObj.KnowledgeArticleId, true);
        }
    }
    
    //interface method to execute any post-processing operations
    public void finish(Database.BatchableContext bc){
        
    }
}
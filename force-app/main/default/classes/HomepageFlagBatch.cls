/*******
Name            : HomepageFlagBatch
Description     : This is the HomepageFlagBatch class to capture all the knowledge article which are 13 days old 
and having BW_Home_Page_Display__c is true.and if any article found, then make it false.
*******/
public without sharing class HomepageFlagBatch implements Database.Batchable<sobject>{
    
    //interface method to collect the batches of records or objects to be passed to execute method
    public Database.QueryLocator start(Database.BatchableContext bc){ 
        //Query the metadata record to get the Home Page flag days 
        Knowledge_Landing_Setting__mdt knwMetadata = [
            SELECT Id, DeveloperName, Label, 
            Days_to_Home_Page_Flag__c FROM Knowledge_Landing_Setting__mdt
            WHERE DeveloperName = 'default'
        ];
        
        //Generate the date which is Home Page Flag days from Today.
        Integer tempNumber = (Integer)knwMetadata.Days_to_Home_Page_Flag__c -1;
        Date old13Days = System.today().addDays(-Integer.valueOf(knwMetadata.Days_to_Home_Page_Flag__c));
        Date old12Days = System.today().addDays(-tempNumber);
        
        //Get the Knowledge Article which are 13 days from now and showing on the lading page.
        return Database.getQueryLocator([
            SELECT Id, BW_Home_Page_Display__c , LastPublishedDate,
            KnowledgeArticleId FROM Knowledge__kav 
            WHERE (BW_Home_Page_Display__c = true
            AND LastPublishedDate >=: old13Days 
            AND LastPublishedDate <: old12Days
            AND Language = 'en_US'
            AND publishStatus = 'Online')
        ]);
    }
    
    //interface method to process each batch of records
    public void execute(Database.BatchableContext bc, List<Knowledge__kav> knowledgeList){
        Set<Id> kwIds = new Set<Id>();
        List<Knowledge__kav> knowledgeToUpdate = new List<Knowledge__kav>();
        try{
            if(knowledgeList.size() > 0){
                for(Knowledge__kav kavObj : knowledgeList){
                    String knowledgeId = KbManagement.PublishingService.editOnlineArticle(kavObj.KnowledgeArticleId, true);
                    kwIds.add(knowledgeId);
                }
            }
            
            //Update the Article with the new value.
            for(Knowledge__kav kavObj : [SELECT Id, BW_Home_Page_Display__c, LastPublishedDate, RecordType.Name,
                                        BW_News_Start_Date__c,BW_News_End_Date__c, KnowledgeArticleId, PublishStatus  
                                        FROM Knowledge__kav 
                                        WHERE Id IN : kwIds]){
                
                kavObj.BW_Home_Page_Display__c = false;
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
        }catch(System.Exception e) {
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
        }
    }
    
    //interface method to execute any post-processing operations
    public void finish(Database.BatchableContext bc){
        
    }
}
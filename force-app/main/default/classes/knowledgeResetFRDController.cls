/*********
Name            : knowledgeResetFRDController
Description     : This is Controller class for the Lightning component knowledgeResetFRD.cmp
*********/

public with sharing class knowledgeResetFRDController {
    
    @AuraEnabled
    public static List<Knowledge__kav> getKnowledge(String recordId){
        List<Knowledge__kav> knowledgeListUpdate = new List<Knowledge__kav>();
        try{
            List<Knowledge__kav> knowledgeListRecord = [SELECT Id,FutureReviewDate__c FROM Knowledge__kav where Id =: recordId];
            
            for(Knowledge__kav knowledgeList :knowledgeListRecord){
                if(knowledgeList.FutureReviewDate__c != null){
                    knowledgeList.FutureReviewDate__c = system.now().addMonths(6);
                    knowledgeListUpdate.add(knowledgeList);
                }
            }
            update knowledgeListUpdate;
            return knowledgeListUpdate;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());             
        }
        
    }
}
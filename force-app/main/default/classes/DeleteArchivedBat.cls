/*******
Name            : DeleteArchivedBat
Description     : This is the DeleteArchivedBat class which will get all the archived articles whose
                  retention date is lesser than today and deletes them from the system on a button click "Batch Delete Archived"
Profiles        : Knowledge Admin can execute this class.
Status          : Completed
*******/
public with sharing class DeleteArchivedBat {
    
    @AuraEnabled(cacheable=true)
    public static Integer DeleteArchivedArticles(){
        Date Today = System.today();
        List<Knowledge__kav> knowledgeList;
        try{
           knowledgeList = [ Select knowledgeArticleId, Title From Knowledge__kav where publishstatus='Archived' AND RetentionDate__c < Today];
            if( knowledgeList.size() >0){
            for(Knowledge__kav kw : knowledgeList){
                        KbManagement.PublishingService.deleteArchivedArticle(kw.knowledgeArticleId);
                    }
            } 
        }catch(DMLException e){
            System.debug('Archived Article not Deleted based on Retention Date'+ e.getMessage());
        } 
        return knowledgeList.size();
        
        
     }

}
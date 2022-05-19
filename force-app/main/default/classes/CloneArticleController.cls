public with sharing class CloneArticleController {
    
    @AuraEnabled
    public static String getPublishStatus(String recordId){
        return [SELECT Id, PublishStatus FROM Knowledge__kav WHERE Id =: recordId].PublishStatus;
    }
    @AuraEnabled
    public static String cloneArticle(String recordId)
    {
        try{
            String objectAPIName = 'Knowledge__kav';
            Set <String> fieldMap = schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap().keySet();
            String soqlQuery = 'SELECT ' ; 
            for (String s :fieldMap ){
                if(schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap().get(s).getDescribe().isAccessible()){
                    soqlQuery +=  + s+',';
                }
            }
            soqlQuery =  soqlQuery.removeEnd(',');
            soqlQuery += ' FROM ' +objectAPIName +' WHERE ID = \'' + recordId +'\'' ;
            System.debug('soqlQuery'+soqlQuery);
            SObject record = Database.query(soqlQuery);
            String ArticleNo=String.valueOf(record.get('ArticleNumber'));
            system.debug('@@@@ArticleNo'+ArticleNo);
            if(record.get('PublishStatus') != null && String.valueOf(record.get('PublishStatus')) == 'Archived') {
                throw new AuraHandledException('error: Archived Articles cannot be cloned.');
            }
            SObject clonedRecord= record.clone(false, false, false, false);
            String oldUrlName=String.valueOf(clonedRecord.get('urlName'));  
            
            DateTime objDate = System.now();
            String tempDate = String.valueOf(objDate).replaceAll(':','-').replaceAll(' ','-');
            if(oldUrlName.contains('--')){
                String newURLName = oldUrlName.substring(0, oldUrlName.indexOf('--'));
                clonedRecord.put('urlName',newURLName+'--'+tempDate) ;
            }
            else{
                clonedRecord.put('urlName',oldUrlName+'--'+tempDate) ;
            }  
            Id KnowledgeNewsArticalRecTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId();
            if(KnowledgeNewsArticalRecTypeId == record.get('RecordTypeId')) {
                clonedRecord.put('BW_News_Start_Date__c', Date.today().addDays(1));
                clonedRecord.put('BW_News_End_Date__c', Date.today().addDays(1));
            }
            if(clonedRecord.get('FutureReviewDate__c') != null 
               && DateTime.valueOf(clonedRecord.get('FutureReviewDate__c')) < DateTime.now()) {
                clonedRecord.put('FutureReviewDate__c', system.now().addMonths(6));
                System.debug('AFTER value log for FRD test =>' + clonedRecord.get('FutureReviewDate__c') );
            }
            clonedRecord.put('CustomValidationStatus__c',False);
            if(clonedRecord.get('CustomPublicationStatus__c')=='Ready for Publication')
            {
                clonedRecord.put('CustomPublicationStatus__c',null);
                //clonedRecord.put('CustomValidationStatus__c',False);
                system.debug('CustomPublicationStatus__c'+clonedRecord.get('CustomPublicationStatus__c'));
            }
            insert clonedRecord;
            Knowledge__kav obj = [Select id,ArticleNumber FROM Knowledge__kav WHERE Id=:clonedRecord.id Limit 1];
            return obj.ArticleNumber+'-*-'+obj.Id;
        }catch(System.Exception e){
            // String exceptionString = 'Error cloning article';
            // String topicName = 'KMCloneException';
            System.debug('Log for ex: '+e.getLineNumber() + '  '+ e.getStackTraceString());
            KMErrorHandlingUtility.logError('Error cloning article', 'KMCloneException');
            system.debug('@@@e.getMessage()'+e.getMessage());
            throw new AuraHandledException('error: '+e.getMessage());
        } 
        
    } 
}
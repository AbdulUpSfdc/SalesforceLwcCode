@isTest
public without sharing class RetryBatchApexTest {
    
    @isTest
    static void testRetry() {
        
        List<LeadRedistribution__c> lrds = New List<LeadRedistribution__c>();
        List<sObject> failedDMLsObjects = new List<sObject>();
        
        for (Integer i=0; i < 10; i++) {
            LeadRedistribution__c lrd = New LeadRedistribution__c();
            lrd.Reason__c = 'Invalid Reason';
            lrds.add(lrd);
        }
        
        Database.SaveResult[] srList = DataBase.insert(lrds, false);
        
        Integer i = 0;
        for (Database.SaveResult insertResult : srList) {
            if (!insertResult.isSuccess()) {
                failedDMLsObjects.add(lrds.get(i));
                for(Database.Error err : insertResult.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                }
            }
            i++;
        }
        
        Test.startTest();
        ID batchprocessid = Database.executeBatch(New RetryBatchApex(failedDMLsObjects));
        Test.stopTest();
        
        ApexClass retryClass = [SELECT Id, Name FROM ApexClass WHERE Name Like 'RetryBatchApex'];
        List<AsyncApexJob> jobsList = [SELECT Id, Status, ApexClass.Name, MethodName, ExtendedStatus, ParentJobId, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE ApexClassId =: retryClass.Id];
        System.assert(jobsList.size() > 3);
        
        
    }
}
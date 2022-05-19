public without sharing class OverdueChildCasesBatch implements Database.Batchable<sObject> {
    public Iterable<sObject> start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        String childRecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOPField').ID;
        String responseRecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOPResponse').ID;
        
        return Database.getQueryLocator(
            'SELECT Id,ParentId FROM Case WHERE Status <> \'Closed\' AND Status <> \'Cancelled \' AND ' +
            '(RecordTypeId = :childRecordTypeId OR RecordTypeId = :responseRecordTypeId) AND ' + 
            'DaysToClose__c < 0 ' + 
            'ORDER BY ParentId ASC NULLS FIRST'
        );
        
    }
    
    public void execute(Database.BatchableContext bc, List<Case> overdueChildCases) {
        // process each batch of records
        Set<String> parentsWithOverdueChildrenIds = new Set<String>();
        for(Case c : overdueChildCases) {
            parentsWithOverdueChildrenIds.add(c.ParentId);
        }
        
        List<Case> casesToUpdate = new List<Case>();
        for(Case c : [SELECT Id,OverdueChildCases__c FROM Case WHERE Id IN :parentsWithOverdueChildrenIds]) {
            c.OverdueChildCases__c = TRUE;
            casesToUpdate.add(c);
        }
        
        Boolean allOrNothing = false;
        List<Database.SaveResult> saveResult = Database.update(casesToUpdate, allOrNothing);
    } 
    
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }    

}
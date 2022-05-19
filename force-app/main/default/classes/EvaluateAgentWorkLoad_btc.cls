/*
*PBCNTRSENT-1475
Updated as part of -SPTSFDCSPT-9319
*/
public without sharing class EvaluateAgentWorkLoad_btc implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext bc){
        String RECORD_TYPE= 'OOP';
        String query = 'Select Status, Id,Ownerid From Case Where ownerId !=Null and recordTypeId!=Null and recordType.name=:RECORD_TYPE';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC,List<Case> scope){
        Set<ID> caseId_Set = new Set<ID>();
        String userOwner = Schema.SObjectType.User.getKeyPrefix();
        for(Case c : scope){
            if(string.ValueOf(c.ownerId).startsWith(userOwner))    {
              caseId_Set.add(c.Id);
            }
            
        }//for ends..    
        if(caseId_Set.size()>0){
       
            processCases(caseId_Set);
        } 
    }
    public void finish(Database.BatchableContext BC){}
    
    private void processCases(Set<ID> caseIds){
        List<Case> caseList = new List<Case>();
        for(Case currentCase : [Select Status, RecordType.DeveloperName From Case Where ID IN :caseIds]){
        if(currentCase.RecordType.DeveloperName.equalsIgnoreCase('OOP') && (currentCase.Status.equalsIgnoreCase(CaseConstants.CASE_STATUS_NEW) || currentCase.Status.equalsIgnoreCase(CaseConstants.CASE_STATUS_IN_PROGRESS))){
            currentCase.status = CaseConstants.CASE_STATUS_WORKING;
            caseList.add(currentCase);  
           
        }
        }//for ends..
        if(caseList.size()>0){
            Database.SaveResult[] srList = Database.update(caseList,false);
			for (Database.SaveResult sr : srList) {
			if (sr.isSuccess()) {
				// Operation was successful, so get the ID of the record that was processed
				System.debug('Successfully updated Case record having SF id: ' + sr.getId());
			}
			else{
				// Operation failed, so get all errors                
				for(Database.Error err : sr.getErrors()) {
					System.debug('The following error has occurred.');                    
					System.debug(err.getStatusCode() + ': ' + err.getMessage());
					System.debug('Case fields that affected this error: ' + err.getFields());
				}
			}
			}
        }
    } 
}
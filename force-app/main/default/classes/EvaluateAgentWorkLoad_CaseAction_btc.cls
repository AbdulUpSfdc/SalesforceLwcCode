/*
*SPTSFDCSPT-9320
*/
public without sharing class EvaluateAgentWorkLoad_CaseAction_btc implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'Select Status__c,Ownerid,Id From Case_Action__c Where ownerId !=Null';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC,List<Case_Action__c> scope){
        Set<ID> caseActionId_Set = new Set<ID>();
        String userOwner = Schema.SObjectType.User.getKeyPrefix();
        for(Case_Action__c c : scope){
            if(
            string.ValueOf(c.ownerId).startsWith(userOwner))    {
              caseActionId_Set.add(c.Id);
            }
            
        }//for ends.. 
      
        if(caseActionId_Set.size()>0){
        
            processCases(caseActionId_Set);
        } 
    }
    public void finish(Database.BatchableContext BC){}
    
    private void processCases(Set<ID> Case_Action_Ids){
        List<Case_Action__c> caseActionList = new List<Case_Action__c>();
      
        for(Case_Action__c currentCase : [Select Status__c,RecordType.DeveloperName From Case_Action__c Where ID IN :Case_Action_Ids]){
       
        if((currentCase.RecordType.DeveloperName.equalsIgnoreCase('Field')|| currentCase.RecordType.DeveloperName.equalsIgnoreCase('Response')) && (currentCase.Status__c.equalsIgnoreCase(CaseConstants.CASE_STATUS_NEW) || currentCase.Status__c.equalsIgnoreCase(CaseConstants.CASE_STATUS_IN_PROGRESS))){
            
            currentCase.Status__c = CaseConstants.CASE_STATUS_WORKING;
            caseActionList.add(currentCase);     
        }
        
        }//for ends..
        
        if(caseActionList.size()>0){
            Database.update(caseActionList,false);
        }
    } 
}
/* ================================================* 
* @date :   4/20/2021   
* @group : Case 
* @description : class OOP Service for only OOP
================================================*/


public without Sharing class CaseOOP_Service{

    //Not to execute syncCasesAccount and Products logic
    //public static Boolean isExecuteSyncAccountProducts = true;
  
    //Method to update last activity date on case  
    public static void updateLastActivityonCase(Set<Id> caseIds){
    
        if(caseIds.size()>0){
            String oopRtId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RECORD_TYPE).ID;
            //retrieve cases related to caseIds
            Map<Id,Case> caseMap = new Map<Id,Case>([SELECT Id, RecordTypeId, Last_Activity_Date__c from Case where Id IN :caseIds AND RecordTypeId = :oopRtId]);
            
            if(caseMap.size()>0){
                for(Case c : caseMap.values()){
                    //Assign current date and time to last activity date field on case
                    c.Last_Activity_Date__c = dateTime.now();
                }
                
                update caseMap.values();
            }
            
        }
    }    
    
}
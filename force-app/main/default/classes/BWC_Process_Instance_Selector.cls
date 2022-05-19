public with sharing class BWC_Process_Instance_Selector {
    public static List<ProcessInstanceWorkitem> getProcessInstances(set<Id> TargetObjectIdList){       
        List<ProcessInstanceWorkitem> ProcessInstanceWorkitemLst = New List<ProcessInstanceWorkitem>();
        ProcessInstanceWorkitemLst=[SELECT ActorId
       FROM ProcessInstanceWorkitem
        WHERE ProcessInstanceId IN (
            SELECT Id
            FROM ProcessInstance
            WHERE TargetObjectId in :TargetObjectIdList
            AND Status = 'Pending')];      
        if(ProcessInstanceWorkitemLst.size()>0){
            return ProcessInstanceWorkitemLst;
        } 
        return null;
    }
}
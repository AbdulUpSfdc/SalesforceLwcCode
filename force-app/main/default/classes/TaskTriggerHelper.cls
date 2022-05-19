/* ================================================* 
* @date :   4/20/2021   
* @group : Task
* @description : Helper class to drive the logic related to Tasks
================================================*/

public without sharing class TaskTriggerHelper {

    public static void maskTask() {
        List<Task> listOfTasks = (List<Task>) Trigger.new;
        Map<Id, Task> mapOfOldTasks = (Map<Id, Task>) Trigger.oldMap;

         // Mask Body of the post
         for(Task task : listofTasks) {
            // If insert or Body is changing on Update, mask the content
            if (task.Description != null && (mapOfOldTasks == null || task.Description != mapOfOldTasks.get(task.Id).Description)) {
                task.Description = BWC_Utils.maskSentence(task.Description);
            }   
        }        
    }

    //After Insert + After Update
    public static void filterTaskAfterInsertUpdate(){
        String case_prefix = Schema.SObjectType.Case.getKeyPrefix(); 
        String tskWhatId; 
        Set<ID> caseIds = new Set<ID>();

        for(Task t: (List<Task>)trigger.new){
            tskWhatId = t.WhatId;
            if(String.isNotBlank(t.WhatId) && tskWhatId.startsWith(case_prefix)){
                caseIds.add(t.WhatId);
            }
        }
        
        //update last activity date on OOP Case records 
        if(caseIds.size()>0){
            CaseOOP_Service.updateLastActivityonCase(caseIds);
        }
    }    

    public static void ProcessTaskBeforeInsert(){
        checkPermissions(trigger.new);
    }
    
    public static void ProcessTaskAfterInsert(){
        changeCaseStatus(trigger.new);
    }
    @TestVisible
    private static void checkPermissions(List<Task> newTasks){
        try{
            Set<Id> CaseIds = new Set<Id>();
            Set<Id> caseIdsWithoutAccess = new Set<Id>();
            Map<Id,List<Task>> caseToTaskMap = new Map<Id,List<Task>>();
            List<Task> tasksToProcess = new List<Task>();
            List<Task> tasksToNotProcess = new List<Task>();
            for(task tk : newTasks){
                if(tk.WhatId?.getsObjectType() == Case.sObjectType && tk.Type == CaseConstants.CASE_TYPE_HOLD_CASE_REMINDER){
                    CaseIds.add(tk.WhatId);
                    if(caseToTaskMap.containsKey(tk.WhatId)){
                        caseToTaskMap.get(tk.WhatId).add(tk);
                    }else{
                        caseToTaskMap.put(tk.WhatId, new List<Task>{tk}); 
                    }
                }
            }
            List<userRecordAccess> caseAccessList = [SELECT HasReadAccess,HasEditAccess,RecordId 
                                                     FROM UserRecordAccess 
                                                     WHERE UserId = :UserInfo.getUserId() 
                                                     AND RecordId IN :CaseIds];
            for(userRecordAccess access : caseAccessList){
                if(CaseIds.contains(access.RecordId) && access.HasEditAccess){
                    tasksToProcess.addAll(caseToTaskMap.get(access.RecordId));
                }else{
                    tasksToNotProcess.addAll(caseToTaskMap.get(access.RecordId));
                }
            }
            
            changeReminderDatetime(tasksToProcess);
            
            for(Task tk : tasksToNotProcess){
                tk.WhatId.addError(Label.Case_Hold_Escalation_Edit_Access_Check);
            }
        }catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    @TestVisible
    private static void changeCaseStatus(List<Task> taskList) {
        try{
            Set<Id> caseIdSet = new Set<Id>();
            for(Task tsk : taskList)
            {
                if(tsk.whatId != null && tsk.Type != null && tsk.whatId.getsObjectType() == Case.sObjectType && tsk.Type == CaseConstants.CASE_TYPE_HOLD_CASE_REMINDER){
                    caseIdSet.add(tsk.whatId);
                }
            }
            List<Case> caseList = [Select Id, Type,Status from Case where Id IN :caseIdSet];
            List<Case> caseUpdated = new List<Case>();
            for(Case record:caseList){
                record.Status = CaseConstants.ON_HOLD_STATUS;
                caseUpdated.add(record);
            }
            if(caseUpdated.size()>0){
                update caseUpdated;
            }
        }
        catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
    @TestVisible
    private static void changeReminderDatetime(List<Task> taskId) {
        try{
            for(Task tk : taskId)
            {
                if(tk.whatId != null && tk.Type != null && tk.whatId.getsObjectType() == Case.sObjectType && tk.Type == CaseConstants.CASE_TYPE_HOLD_CASE_REMINDER){
                    tk.IsReminderSet = true;
                    DateTime objDT = DateTime.now().addHours(4);
                    tk.ReminderDateTime = objDT;
                }
            }
        }
        catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
}
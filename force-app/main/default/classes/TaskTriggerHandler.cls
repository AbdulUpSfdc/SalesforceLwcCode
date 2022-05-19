/* ================================================* 
* @date :   4/20/2021   
* @group : Task
* @description : Handler class to drive the Task trigger scenarios
================================================*/

public without sharing class TaskTriggerHandler {

    public static void delegateProcessing() {
        System.Debug('Task Trigger Activated.');
        System.Debug(JSON.serializePretty(Trigger.isBefore));
        if (Trigger.isBefore) {
            try {
                TaskTriggerHelper.maskTask();
                if(Trigger.isInsert){
                    TaskTriggerHelper.ProcessTaskBeforeInsert();
                }
            }
            catch(Exception e) {
                BWC_ExceptionUtils.handleException(e, true); 
            }
        }
        if (Trigger.isAfter) {            
            if(trigger.isInsert || trigger.isUpdate){
                TaskTriggerHelper.filterTaskAfterInsertUpdate();    
                if(Trigger.isInsert){
                    TaskTriggerHelper.ProcessTaskAfterInsert();
                }
            }
        }
    }
}
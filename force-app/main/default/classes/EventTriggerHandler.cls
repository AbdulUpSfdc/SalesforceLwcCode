/* ================================================* 
* @date :   4/20/2021   
* @group : Event
* @description : Handler class to drive the Event trigger scenarios
================================================*/

public without sharing class EventTriggerHandler {

    public static void delegateProcessing() {
        
        if (Trigger.isAfter) {            
            if(trigger.isInsert || trigger.isUpdate){
                EventTriggerHelper.filterEventAfterInsertUpdate();    
            }
        }
    }
}
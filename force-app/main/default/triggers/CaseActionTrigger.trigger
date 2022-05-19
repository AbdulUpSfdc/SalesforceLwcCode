trigger CaseActionTrigger on Case_Action__c (before insert, before update, after insert, after update) {

    if(boolean.Valueof(System.Label.caseActionTriggerBypass)){ return;}
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            Case_Action_Trigger_Helper.handleBeforeInsert();
        }

        if(Trigger.isUpdate){
            Case_Action_Trigger_Helper.handleBeforeUpdate();
        }
    }

    if(Trigger.isAfter){

        if(Trigger.isInsert){
            Case_Action_Trigger_Helper.handleAfterInsert();
        }

        if(Trigger.isUpdate){
            Case_Action_Trigger_Helper.handleAfterUpdate();
        }
    }
}
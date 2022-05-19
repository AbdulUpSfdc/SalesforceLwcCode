//PBCNTRSENT-520
public class ChildCaseAssignmentConfigTriggerHandler {
     public static void handler(){
        if(trigger.isBefore){
            if(trigger.isInsert){
                ChildCaseAssignmentConfigTriggerHelper.filterOnBeforeInsert();
            }
            if(trigger.isUpdate){
                ChildCaseAssignmentConfigTriggerHelper.filterOnUpdate();
            }
        }
    }
}
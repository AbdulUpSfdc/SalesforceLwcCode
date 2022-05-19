public without sharing class EmployeeGroupAssignmentTriggerHandler {
    public static void updateGroupIdHandler(){
        if(User_Onboarding_Config__c.getInstance().Employee_Group_Assignment_Trigger__c){
            if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
                if(Trigger.new <> null){
                    EmployeeGroupAssignmentTriggerHelper.updateGroupIdHelper(Trigger.New);                                                             
                }
            }
        }
    }
}
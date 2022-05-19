public without sharing class BWC_TaskCaseHandler {
    /*
* Call this method from an after insert Task.
* It updates the status of case to 'OnHold' when task type is 'Hold case reminder'.
*/
    public static void changeCaseStatus(List<Task> taskList) {
        try{
            Set<Id> caseIdSet = new Set<Id>();
            for(Task tsk : taskList)
            {
                if(tsk.whatId != null && tsk.Type != null && tsk.whatId.getsObjectType() == Case.sObjectType && tsk.Type == 'Hold case reminder'){
                	caseIdSet.add(tsk.whatId);
                }
            }
            List<Case> caseList = [Select Id, Type from Case where Id IN :caseIdSet];
            List<Case> caseUpdated = new List<Case>();
            for(Case record:caseList){
                record.Status = 'On Hold';
                caseUpdated.add(record);
            }
            if(caseUpdated.size()>0){
                update caseUpdated;
            }
        }
        catch (Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }
    }
    //To set the Reminder time for the task created from Hold Case button form escalation case.
    public static void changeReminderDatetime(List<Task> taskId) {
        try{
            for(Task tk : taskId)
            {
                if(tk.whatId != null && tk.Type != null && tk.whatId.getsObjectType() == Case.sObjectType && tk.Type == 'Hold case reminder'){
                	tk.IsReminderSet = true;
                	DateTime objDT = DateTime.now().addHours(4);
               	 	tk.ReminderDateTime = objDT;
                }
            }
        }
        catch (Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }
    }
    
}
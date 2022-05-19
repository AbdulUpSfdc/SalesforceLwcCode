@isTest
public class BWC_TaskCaseHandlerTest {
    @isTest
    public static void changeCaseStatusTask(){
        Case caseWithState = new Case();
        caseWithState.ExpectedCloseDate__c = Date.parse('08/28/21');
        caseWithState.Type='OOP';
        caseWithState.Origin='Phone';
        caseWithState.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
        caseWithState.Description = 'Test scenario one';
        caseWithState.Status = 'New';
        caseWithState.Priority='Medium';
        caseWithState.CustomerType__c='Consumer';
        caseWithState.ownerid=UserInfo.getUserId();
        insert caseWithState;
        
        List<Task> task = new List<Task>();
        Task tk = new Task();
        tk.Type = 'Hold Case Reminder';
        tk.Subject = '	Hold case reminder';
        tk.Status = 'Open';
        tk.Priority = 'Normal'; 
        tk.whatId = caseWithState.Id;
        task.add(tk);
        BWC_TaskCaseHandler.changeCaseStatus(task);
        
    }
    
    @isTest
    public static void changeReminderDatetime(){
        Case caseWithState = new Case();
        caseWithState.ExpectedCloseDate__c = Date.parse('08/28/21');
        caseWithState.Type='OOP';
        caseWithState.Origin='Phone';
        caseWithState.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
        caseWithState.Description = 'Test scenario one';
        caseWithState.Status = 'New';
        caseWithState.Priority='Medium';
        caseWithState.CustomerType__c='Consumer';
        caseWithState.ownerid=UserInfo.getUserId();
        insert caseWithState;
        
        
        List<Task> task = new List<Task>();
        Task tk = new Task();
        tk.Type = 'Hold Case Reminder';
        tk.Subject = '	Hold case reminder';
        tk.Status = 'Open';
        tk.Priority = 'Normal'; 
        tk.whatId = caseWithState.Id;
        task.add(tk);
        BWC_TaskCaseHandler.changeReminderDatetime(task);
        
    }
}
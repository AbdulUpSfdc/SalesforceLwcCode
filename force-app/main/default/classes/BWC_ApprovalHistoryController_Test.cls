@isTest
public class BWC_ApprovalHistoryController_Test {

    @testSetup
    static void setup(){
        BWC_TestDataFactory.createAdjustment();
    }
    
    @isTest
    static void testGetHistory() {
        test.startTest();
        List<Adjustment__c> myAdj = [SELECT Id
                                     FROM Adjustment__c
                                     WHERE Channel__c = 'Collections'
                                     ORDER BY CreatedDate Desc
                                     LIMIT 1];
        
        System.debug('myAdj: ' + myAdj);
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(myAdj[0].Id);
        app.setProcessDefinitionNameOrId('Collections_Approval_Process');
        Approval.ProcessResult result = Approval.process(app);
        
        List<Approval.ProcessWorkitemRequest> reqs = new list<Approval.ProcessWorkitemRequest>();
        ProcessInstanceWorkitem workItem = [Select Id from ProcessInstanceWorkitem where ProcessInstance.TargetObjectId =: myAdj[0].Id ORDER BY CreatedDate Desc, Id Desc LIMIT 1];
        
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments('test comment');
        req.setAction('Approve');           
        req.setWorkitemId(workItem.Id);
        req.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        reqs.add(req);                                          
        Approval.ProcessResult[] results = Approval.process(reqs);
        
        reqs = new list<Approval.ProcessWorkitemRequest>();
        workItem = [Select Id from ProcessInstanceWorkitem where ProcessInstance.TargetObjectId =: myAdj[0].Id ORDER BY CreatedDate Desc, Id Desc LIMIT 1];
        Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        req2.setComments('Full Rejection');
        req2.setAction('Reject');           
        req2.setWorkitemId(workItem.Id);
        reqs.add(req2);                                 
        Approval.ProcessResult[] results2 = Approval.process(reqs);             
        BWC_ApprovalHistoryController.getHistory(myAdj[0].Id);
        test.stopTest();
    }
}
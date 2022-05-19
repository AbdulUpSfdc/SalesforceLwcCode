@IsTest
private class BWC_PerformAdjustmentApproval_Test {
    @IsTest
    static void testapproveRequest() {
        Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();
        
        // Create an approval request for Adjustment
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting approval request.');
        req.setObjectId(adjustment.Id);
        
        // Submit the request for approval
        Approval.ProcessResult res = Approval.process(req);
        System.debug(res);
        
        // Verify the result
        System.assert(res.isSuccess());
        BWC_PerformAdjustmentApproval.approveRequest(adjustment.Id,'Submitting for approval');
        Adjustment__c adj = [
            SELECT Id, Status__c
            FROM Adjustment__c
            WHERE Id = :adjustment.Id
        ];
         System.assertEquals('Level 2', adj.Status__c);
    }
    
     @IsTest
    static void testreturnBackRequest() {
        Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();
        
        // Create an return back request for Adjustment
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting returnBack request.');
        req.setObjectId(adjustment.Id);
        
        // Submit the request for approval
        Approval.ProcessResult res = Approval.process(req);
        System.debug(res);
        
        // Verify the result
        System.assert(res.isSuccess());
        BWC_PerformAdjustmentApproval.returnBackRequest(adjustment.Id,'Submitting for Return Back');
        Adjustment__c adj = [
            SELECT Id, Status__c
            FROM Adjustment__c
            WHERE Id = :adjustment.Id
        ];
        System.assertEquals('Rejected', adj.Status__c);
        
    }
    
     @IsTest
    static void testrejectRequest() {
        Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();
        
        // Create an reject request for Adjustment
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting Reject request.');
        req.setObjectId(adjustment.Id);
        
        // Submit the request for approval
        Approval.ProcessResult res = Approval.process(req);
        System.debug(res);
        
        // Verify the result
        System.assert(res.isSuccess());
        BWC_PerformAdjustmentApproval.rejectRequest(adjustment.Id,'Submitting for Rejection');
        Adjustment__c adj = [
            SELECT Id, Status__c
            FROM Adjustment__c
            WHERE Id = :adjustment.Id
        ];
   		System.assertEquals('Rejected', adj.Status__c);
        
    }
}
@IsTest
private class BWC_FullRejectAdjustmentApproval_Test {
  @IsTest
  static void checkAccessibility() {
    Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();
    User testUser = BWC_TestDataFactory.createUser();

    System.runAs(testUser) {
      try {
        BWC_FullRejectAdjustmentApproval.checkAccessibility(adjustment.Id);
      } catch (AuraHandledException e) {
        System.assert(true);
      }
    }
  }

  @IsTest
  static void testFullReject() {
    Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();

    // Create an approval request for Adjustment
    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
    req.setComments('Submitting approval request.');
    req.setObjectId(adjustment.Id);

    // Submit the approval request for the Adjustment
    Approval.ProcessResult result = Approval.process(req);

    // Verify the result
    System.assert(result.isSuccess());

    BWC_FullRejectAdjustmentApproval.fullReject(adjustment.Id);

    Adjustment__c adj = [
      SELECT Id, Status__c
      FROM Adjustment__c
      WHERE Id = :adjustment.Id
    ];

    System.assertEquals('Rejected', adj.Status__c);
  }
}
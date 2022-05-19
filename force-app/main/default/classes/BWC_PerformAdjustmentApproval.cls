public without sharing class BWC_PerformAdjustmentApproval {
  private static Boolean isFullreject = false;
    
  public static Boolean IsRunningFullRejection { 
      get {return isFullreject;}
      private set { isFullreject = value;} 
  }

	@AuraEnabled(cacheable=false)
  public static string approveRequest(Id workItemId, String comments) {
    Boolean bContinue = true;
    String message = '';

      List<ProcessInstanceWorkitem> pInstanceWorkitems = [
        SELECT Id, ProcessInstanceId, ActorId
        FROM ProcessInstanceWorkitem
        WHERE
          ProcessInstanceId IN (
            SELECT Id
            FROM ProcessInstance
            WHERE Status = 'Pending' AND TargetObjectId = :workItemId
          )
      ];

      if (pInstanceWorkItems.isEmpty()) {
        bContinue = false;
        //message = System.Label.FullRejectSuccessMessage;
      } else {
        ProcessInstanceWorkitem currentUserWorkItem = findCurrentUserWorkItem(pInstanceWorkitems);

        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments(comments);
        req.setAction('Approve');
        req.setNextApproverIds(new List<Id>{ currentUserWorkItem.ActorId });

        // Use the ID from the newly created item to specify
        // the item to be worked
        req.setWorkitemId(currentUserWorkItem.Id);

        // Submit the request for approval
        Approval.ProcessResult res = Approval.process(req);
      }
    message = System.Label.ApproveAdjustmentSuccessMsg;
    return message;
  }

  private static ProcessInstanceWorkitem findCurrentUserWorkItem(List<ProcessInstanceWorkitem> pInstanceWorkitems) {
    ProcessInstanceWorkitem returnVal = pInstanceWorkitems[0];
    for (ProcessInstanceWorkitem pwt : pInstanceWorkitems) {
        if (pwt.ActorId == UserInfo.getUserId()) {
            returnVal = pwt;
        }
    }    
    return returnVal;
  }
    
    @AuraEnabled(cacheable=false)
    public static string returnBackRequest(Id workItemId, String comments) {
    Boolean bContinue = true;
    String message = '';

      List<ProcessInstanceWorkitem> pInstanceWorkitems = [
        SELECT Id, ProcessInstanceId, ActorId
        FROM ProcessInstanceWorkitem
        WHERE
          ProcessInstanceId IN (
            SELECT Id
            FROM ProcessInstance
            WHERE Status = 'Pending' AND TargetObjectId = :workItemId
          )
      ];

      if (pInstanceWorkItems.isEmpty()) {
        bContinue = false;
        //message = System.Label.FullRejectSuccessMessage;
      } else {
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments(comments);
        req.setAction('Reject');
        req.setNextApproverIds(new List<Id>{ pInstanceWorkitems[0].ActorId });

        // Use the ID from the newly created item to specify
        // the item to be worked
        req.setWorkitemId(pInstanceWorkitems[0].Id);

        // Submit the request for approval
        Approval.ProcessResult res = Approval.process(req);
      }
    message = System.Label.ReturnBackAdjustmentSuccessMsg;
    return message;
  }

  @AuraEnabled(cacheable=false)
  public static string rejectRequest(Id workItemId, String comments) {
    IsRunningFullRejection = true;
    Boolean bContinue = true;
    String message = '';
    comments = 'Full Rejection : ' + comments;
    do {
      List<ProcessInstanceWorkitem> pInstanceWorkitems = [
        SELECT Id, ProcessInstanceId, ActorId
        FROM ProcessInstanceWorkitem
        WHERE
          ProcessInstanceId IN (
            SELECT Id
            FROM ProcessInstance
            WHERE Status = 'Pending' AND TargetObjectId = :workItemId
          )
      ];

      if (pInstanceWorkItems.isEmpty()) {
        bContinue = false;
        message = System.Label.FullRejectSuccessMessage;
      } else {
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments(comments);
        req.setAction('Reject');
        req.setNextApproverIds(new List<Id>{ pInstanceWorkitems[0].ActorId });

        // Use the ID from the newly created item to specify
        // the item to be worked
        req.setWorkitemId(pInstanceWorkitems[0].Id);

        // Submit the request for approval
        Approval.ProcessResult res = Approval.process(req);
      }
    } while (bContinue);
    return message;
  }
}
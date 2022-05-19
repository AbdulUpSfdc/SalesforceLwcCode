public without sharing class BWC_FullRejectAdjustmentApproval {

    private static Boolean isFullreject = false;
    
    public static Boolean IsRunningFullRejection { 
        get {return isFullreject;}
        private set { isFullreject = value;} 
    }

    @AuraEnabled(cacheable=false)
    public static string checkAccessibility(Id workItemId) {
        String message;
        try {
          UserRecordAccess UserRecordAccessoBJ = [Select RecordId,HasEditAccess FROM UserRecordAccess WHERE UserId=:UserInfo.getUserId() AND RecordId =:workItemId ];
          message = UserRecordAccessoBJ.HasEditAccess ? fullReject(workItemId) : System.Label.FullRejectUnauthorizedMessage;
        } catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
        }
        return message;
    }

    @AuraEnabled(cacheable=false)
    public static string fullReject(Id workItemId)
    {
        IsRunningFullRejection = true;
        Boolean bContinue = true;
        String message='';
        do
        {
            List<ProcessInstanceWorkitem> pInstanceWorkitems = [
                SELECT Id, ProcessInstanceId, ActorId
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstanceId IN (
                    SELECT Id
                    FROM ProcessInstance
                    WHERE Status = 'Pending'
                    AND TargetObjectId =: workItemId)];

            if (pInstanceWorkItems.isEmpty()) {
                System.debug('No more pending process steps.');
                bContinue = false;
                 message = System.Label.FullRejectSuccessMessage;
                
            } else {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setComments('Full Rejection.');
                req.setAction('Reject');
                req.setNextApproverIds(new Id[] {pInstanceWorkitems[0].ActorId});

                // Use the ID from the newly created item to specify
                // the item to be worked
                req.setWorkitemId(pInstanceWorkitems[0].Id);

                // Submit the request for approval
                Approval.ProcessResult res =  Approval.process(req);
            }
        } while (bContinue);
        return message;
    }
}
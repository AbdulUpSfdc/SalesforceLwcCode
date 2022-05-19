public with sharing class BWC_AdjustmentCasesService {
    // For full reject adjustment
    private static Boolean isFullReject = false;
    public static Boolean isRunningFullRejection {
        get {
            return isFullReject;
        }
        set {
            isFullReject = value;
        }
    }

    // Approve adjustment request
    public static String approveAdjustmentRequest(Id workItemId, String comments) {
        Boolean bContinue = true;
        String message = '';

        // FLS Not needed, results not returned to user
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
        } else {
            // CDEX 94231 fix
            ProcessInstanceWorkitem currentUserWorkItem = new ProcessInstanceWorkItem();
            ProcessInstanceWorkitem returnVal = pInstanceWorkitems[0];
            for (ProcessInstanceWorkitem pwt : pInstanceWorkitems) {
                if (pwt.ActorId == UserInfo.getUserId()) {
                    returnVal = pwt;
                }
            }
            currentUserWorkItem = returnVal;

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

    // Verify if user is able to approve adjustment
    public static String checkAdjustmentApprovalPerm(Id workItemId) {
        String msg = '';

        // Check if user can edit record
        Boolean recordEditability = BWC_Utils.checkRecordEditability(workItemId);

        if (recordEditability) {
            msg = 'insufficientSOA';

            // FLS Not needed, results not returned to user
            Adjustment__c adj = [
                SELECT Status__c, Total_Agent_Adjusted_Amount__c
                FROM Adjustment__c
                WHERE Id = :workItemId
            ];
            // FLS Not needed, results not returned to user
            List<Employee__c> approvedEmployee = [
                SELECT Id, SOA_Level__r.Authorization_Amount__c
                FROM Employee__c
                WHERE User__c = :UserInfo.getUserId()
                LIMIT 1
            ];

            // Per business, manager should not be able to approve adjustment if SOA is not atleast $400 for compliance reasons
            if (adj.Status__c == 'Level 1 (Manager)') {
                if (
                    approvedEmployee.size() > 0 &&
                    approvedEmployee[0].SOA_Level__r.Authorization_Amount__c >=
                    CaseConstants.WIRELESS_LEVEL_ONE_MANAGER_SOA
                ) {
                    msg = 'authorized';
                } else {
                    // Execute Chatter post logic for Manager
                    BWC_Adjustment_ChatterPost.postSOAFailMessageForManager(workItemId);
                }
            } else {
                // FLS Not needed, results not returned to user
                List<ProcessInstanceWorkitem> pInstanceWorkitem = [
                    SELECT Id, Actor.Name
                    FROM ProcessInstanceWorkitem
                    WHERE
                        ProcessInstanceId IN (
                            SELECT Id
                            FROM ProcessInstance
                            WHERE Status = 'Pending' AND TargetObjectId = :workItemId
                        )
                ];
                if (pInstanceWorkitem.size() > 0) {
                    // FLS Not needed, results not returned to user
                    SOA_Approved_Amount__mdt SOAApprovedAmount = [
                        SELECT Min_Amount__c
                        FROM SOA_Approved_Amount__mdt
                        WHERE MasterLabel = :pInstanceWorkitem[0].Actor.Name
                    ];
                    if (
                        approvedEmployee.size() > 0 &&
                        approvedEmployee[0].SOA_Level__r.Authorization_Amount__c > SOAApprovedAmount.Min_Amount__c
                    ) {
                        msg = 'authorized';
                    } else {
                        // Execute Chatter post logic for Queue
                        BWC_Adjustment_ChatterPost.postSOAFailMessageForQueue(workItemId);
                    }
                }
            }
        } else {
            msg = 'unauthorized';
        }
        return msg;
    }

    // Check if user can edit record
    public static Boolean checkRecordEditability(Id recordId) {
        // FLS Not needed, results not returned to user
        UserRecordAccess userRecordAccess = [
            SELECT RecordId, HasEditAccess
            FROM UserRecordAccess
            WHERE UserId = :UserInfo.getUserId() AND RecordId = :recordId
        ];

        return userRecordAccess.HasEditAccess ? true : false;
    }

    // Fully reject adjustment
    public static String fullRejectAdjustment(Id workItemId, String comments) {
        return (new WithoutSharingACS()).fullRejectAdjustment(workItemId, comments);
    }

    private without sharing class WithoutSharingACS {
        // Need without sharing so full reject can execute
        public String fullRejectAdjustment(Id workItemId, String comments) {
            isRunningFullRejection = true;
            Boolean bContinue = true;
            String message = '';
            comments = 'Full Rejection: ' + comments;

            do {
                // FLS Not needed, results not returned to user
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

    // Get adjustment line item
    public static Adjustment_Line_Item__c getAdjustmentLineItem(String recordId) {
        return [
            SELECT Id, Charge_Code__c, Charge_Type__c, Adj_Reason_Description__c, Adjustment_Type__c
            FROM Adjustment_Line_Item__c
            WHERE Id = :recordId
            WITH SECURITY_ENFORCED
        ];
    }

    // Get record where user has edit access
    public static List<Adjustment__c> getEditableAdjustment(String recordId) {
        List<Adjustment__c> adjustmentsList = new List<Adjustment__c>();
        Boolean userCanEdit = BWC_Utils.checkRecordEditability(recordId);

        // Checking permissions
        if (!userCanEdit) {
            throw new BWC_Exception('User does not have permission to edit this record.');
        }

        // Getting adjustments
        adjustmentsList = [
            SELECT
                Id,
                Case__r.Id,
                Case__r.Last_Interaction__c,
                Case__r.Last_Interaction__r.Billing_Account_Type__c,
                Case__r.Last_Interaction__r.Billing_Account_Number__c,
                Statement_ID__c,
                Status__c
            FROM Adjustment__c
            WHERE Id = :recordId
            WITH SECURITY_ENFORCED
        ];

        // If adjustment isn't rejected, throw an error
        if (adjustmentsList[0].Status__c != 'Rejected') {
            throw new BWC_Exception('Adjustment is still open. Please reject the Adjustment first.');
        }

        // Returning results
        return adjustmentsList;
    }

    // Get approval history for Adjustments
    public static List<AdjustmentApprovalWrapper> getHistory(String recordId) {
        List<AdjustmentApprovalWrapper> appWrapList = new List<AdjustmentApprovalWrapper>();
        Map<Id, List<ProcessInstanceNode>> ProcessNodeToInstanceMap = new Map<Id, List<ProcessInstanceNode>>();
        Id prevProcessNode;
        List<ProcessInstanceNode> newInstanceList = new List<ProcessInstanceNode>();
        String approvalProcess;

        // FLS Not needed, results not returned to user
        for (ProcessInstanceNode pInstanceNode : [
            SELECT
                Id,
                CreatedDate,
                ProcessNodeId,
                ProcessNodeName,
                LastActorId,
                LastActor.Name,
                NodeStatus,
                CompletedDate,
                ProcessInstance.ProcessDefinition.DeveloperName
            FROM ProcessInstanceNode
            WHERE ProcessInstance.TargetObjectId = :recordId
            ORDER BY ProcessNodeId, CompletedDate DESC
        ]) {
            approvalProcess = pInstanceNode.ProcessInstance.ProcessDefinition.DeveloperName;

            if (prevProcessNode == null) {
                prevProcessNode = pInstanceNode.ProcessNodeId;
            }

            if (prevProcessNode != pInstanceNode.ProcessNodeId) {
                newInstanceList = new List<ProcessInstanceNode>();
            }

            newInstanceList.add(pInstanceNode);
            ProcessNodeToInstanceMap.put(pInstanceNode.ProcessNodeId, newInstanceList);

            prevProcessNode = pInstanceNode.ProcessNodeId;
        }

        String quePrefix;
        if (approvalProcess.contains(CaseConstants.HLA_APPROVAL)) {
            quePrefix = 'HLA';
        } else if (approvalProcess.contains(CaseConstants.COLLECTIONS)) {
            quePrefix = 'RM';
        }

        // FLS Not needed, results not returned to user
        List<SOA_Approved_Amount__mdt> approvalLevels = [
            SELECT Queue_Name__c, Level__c
            FROM SOA_Approved_Amount__mdt
            WHERE Queue_Prefix__c = :quePrefix
        ];

        Map<String, Decimal> queNameToLevelMap = new Map<String, Decimal>();
        Map<Decimal, String> levelToQueNameMap = new Map<Decimal, String>();
        queNameToLevelMap.put(CaseConstants.MANAGERS_APPROVAL, 1);
        levelToQueNameMap.put(1, CaseConstants.MANAGERS_APPROVAL);

        for (SOA_Approved_Amount__mdt appLevel : approvalLevels) {
            Decimal level = appLevel.Level__c;
            queNameToLevelMap.put(appLevel.Queue_Name__c, level.stripTrailingZeros());
            levelToQueNameMap.put(level.stripTrailingZeros(), appLevel.Queue_Name__c);
        }

        // Traversing a polymorphic field’s relationship is not supported in queries using WITH SECURITY_ENFORCED
        List<ProcessInstance> approvalsCompleteList = [
            SELECT
                Id,
                (
                    SELECT
                        Id,
                        ProcessNodeId,
                        ProcessNode.Name,
                        StepStatus,
                        Actor.Name,
                        OriginalActorId,
                        OriginalActor.Name,
                        CreatedDate,
                        Comments
                    FROM StepsAndWorkitems
                    WHERE StepStatus != :CaseConstants.NO_RESPONSE
                    ORDER BY CreatedDate ASC, Id ASC
                )
            FROM ProcessInstance
            WHERE TargetObjectId = :recordId
        ];

        Integer listSize = approvalsCompleteList[0].StepsAndWorkitems.size();
        Map<String, ProcessInstanceHistory> highestQueMap = new Map<String, ProcessInstanceHistory>();
        Map<String, Id> fullRejectsMap = new Map<String, Id>();
        String highestQue;
        Id highestFullReject;
        Integer count = 0;

        for (ProcessInstanceHistory iH : approvalsCompleteList[0].StepsAndWorkitems) {
            count++;
            if (iH.Comments != null && iH.Comments.contains(CaseConstants.FULL_REJECTION)) {
                fullRejectsMap.put(iH.ProcessNode.Name, iH.Id);
            } else {
                highestQue = iH.ProcessNode.Name;
                highestQueMap = new Map<String, ProcessInstanceHistory>();
                highestQueMap.put(iH.ProcessNode.Name, iH);
            }

            if (count == listSize) {
                // Determine if you need to go down a que based on if the highest que was rejected
                // If previous que was approved go up one based on meta data
                if (
                    highestQueMap.get(highestQue) != null &&
                    highestQueMap.get(highestQue).StepStatus == CaseConstants.REJECTED
                ) {
                    Decimal previousLevel = queNameToLevelMap.get(highestQue) - 1;
                    highestFullReject = fullRejectsMap.get(levelToQueNameMap.get(previousLevel));
                } else {
                    Decimal level;
                    if (highestQue == null) {
                        highestQue = iH.ProcessNode.Name;
                        level = queNameToLevelMap.get(highestQue);
                        highestFullReject = fullRejectsMap.get(levelToQueNameMap.get(level));
                    } else {
                        level = queNameToLevelMap.get(highestQue) + 1;
                        highestFullReject = fullRejectsMap.get(levelToQueNameMap.get(level));
                    }
                }
            }
        }

        Map<Id, Integer> lastUsedIndexMap = new Map<Id, Integer>();
        ProcessInstanceHistory prevProcessHistory;
        ProcessInstanceNode instNode;

        // Traversing a polymorphic field’s relationship is not supported in queries using WITH SECURITY_ENFORCED
        for (
            ProcessInstanceHistory pIH : [
                SELECT
                    Id,
                    (
                        SELECT
                            Id,
                            ProcessNodeId,
                            ProcessNode.Name,
                            StepStatus,
                            Actor.Name,
                            OriginalActorId,
                            OriginalActor.Name,
                            CreatedDate,
                            Comments
                        FROM StepsAndWorkitems
                        WHERE StepStatus != :CaseConstants.NO_RESPONSE
                        ORDER BY CreatedDate DESC, Id DESC
                    )
                FROM ProcessInstance
                WHERE TargetObjectId = :recordId
            ]
            .StepsAndWorkitems
        ) {
            AdjustmentApprovalWrapper newAppWrap;

            if (pIH.StepStatus == CaseConstants.STARTED && pIH.ProcessNodeId == null) {
                newAppWrap = new AdjustmentApprovalWrapper();
                newAppWrap.stepName = CaseConstants.APPROVAL_SUBMITTED;
                newAppWrap.appDate = pIH.CreatedDate.format('MM/dd/YYYY, hh:mm a');
                newAppWrap.status = CaseConstants.SUBMITTED;
                newAppWrap.assignedTo = pIH.OriginalActor.Name;
                newAppWrap.actualApprover = pIH.OriginalActor.Name;
                newAppWrap.actualApproverId = URL.getSalesforceBaseUrl().toExternalForm() + '/' + pIH.OriginalActorId;
                newAppWrap.comments = pIH.Comments;
            } else {
                // Get new index from the map when the processNodeId changes
                if (pIH.ProcessNodeId != null && pIH.ProcessNodeId != prevProcessHistory?.ProcessNodeId) {
                    if (!lastUsedIndexMap.containsKey(pIH.ProcessNodeId)) {
                        lastUsedIndexMap.put(pIH.ProcessNodeId, 0);
                    } else {
                        Integer lastUsedIndex = lastUsedIndexMap.get(pIH.ProcessNodeId);
                        lastUsedIndexMap.put(pIH.ProcessNodeId, lastUsedIndex + 1);
                    }
                    instNode = ProcessNodeToInstanceMap.get(pIH.ProcessNodeId)[lastUsedIndexMap.get(pIH.ProcessNodeId)];
                }

                if (
                    pIH.Comments == null ||
                    pIH.Comments == '' ||
                    pIH.Id == highestFullReject && (pIH.Comments != null && pIH.Comments != '') &&
                    pIH.Comments.contains(CaseConstants.FULL_REJECTION) ||
                    (pIH.Comments != null && pIH.Comments != '') && !pIH.Comments.contains(CaseConstants.FULL_REJECTION)
                ) {
                    newAppWrap = new AdjustmentApprovalWrapper();
                    newAppWrap.stepName = pIH.ProcessNode.Name;
                    if (instNode?.CompletedDate != null) {
                        newAppWrap.appDate = instNode.CompletedDate.format('MM/dd/YYYY, hh:mm a');
                    } else {
                        newAppWrap.appDate = pIH.CreatedDate.format('MM/dd/YYYY, hh:mm a');
                    }
                    newAppWrap.status = pIH.StepStatus;
                    if (instNode?.LastActor.Name != null) {
                        newAppWrap.actualApprover = instNode.LastActor.Name;
                        newAppWrap.actualApproverId =
                            URL.getSalesforceBaseUrl().toExternalForm() +
                            '/' +
                            instNode.LastActorId;
                    } else {
                        newAppWrap.actualApprover = pIH.OriginalActor.Name;
                        newAppWrap.actualApproverId =
                            URL.getSalesforceBaseUrl().toExternalForm() +
                            '/' +
                            pIH.OriginalActorId;
                    }
                    newAppWrap.assignedTo = pIH.OriginalActor.Name;
                    newAppWrap.comments = pIH.Comments;
                }
            }
            prevProcessHistory = pIH;
            if (newAppWrap != null) {
                appWrapList.add(newAppWrap);
            }
        }
        return appWrapList;
    }

    // Get adjustment reason descriptions and and return to LWC
    public static List<ReasonCode> getReasonDescriptions(String adjType, String chargeCode, String chargeType) {
        List<ReasonCode> reasonCodes = new List<ReasonCode>();

        String query = 'SELECT Id, Charge_Code__c, Charge_Type__c, Adj_Reason_Description__c, Adj_Reason_Explanation_Code__c, Adj_Reason_System_Code__c FROM Reason_Code_for_Charge_Code__c WHERE Charge_Type__c = :chargeType';
        if (adjType == 'Line Item') {
            query = query + ' AND Charge_Code__c =: chargeCode';
        }
        query = query + ' WITH SECURITY_ENFORCED';
        List<Reason_Code_for_Charge_Code__c> codes = Database.query(query);

        for (Reason_Code_for_Charge_Code__c rc : codes) {
            reasonCodes.add(
                new ReasonCode(
                    rc.Charge_Code__c,
                    rc.Charge_Type__c,
                    rc.Adj_Reason_Description__c,
                    rc.Adj_Reason_Explanation_Code__c,
                    rc.Adj_Reason_System_Code__c
                )
            );
        }

        return reasonCodes;
    }

    public static String returnBackAdjustment(Id workItemId, String comments) {
        Boolean bContinue = true;
        String message = '';

        // FLS Not needed, results not returned to user
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

    // Checks if user has the ability to take ownership of an adjustment case and if so, updates case owner
    public static Boolean takeOwnershipAdjustmentCase(String caseId) {
        String message;
        Id userId = UserInfo.getUserId();

        // Getting adjustments based on criteria
        // FLS Not needed, results not returned to user
        List<Adjustment__c> adjustmentsList = [
            SELECT Id, Case__r.OwnerId, Case__c, Delegate_1__c, Delegate_2__c, Status__c
            FROM Adjustment__c
            WHERE
                Case__c = :caseId
                AND (Delegate_1__c = :userId
                OR Delegate_2__c = :userId
                OR Manager__c = :userId)
                AND Status__c = 'Level 1 (Manager)'
        ];

        // If query returns results, execute ownership update and return Boolean
        if (adjustmentsList.size() > 0) {
            Case obj = [SELECT id, OwnerId FROM Case WHERE Id = :caseId LIMIT 1];
            obj.OwnerId = userId;
            update obj;
            return true;
        } else {
            return false;
        }
    }

    // Update adjustment line item
    public static void updateAdjustmentLineItem(Adjustment_Line_Item__c adjLineItem) {
        update adjLineItem;
    }

    // Wrapper for adjustment approval history
    public class AdjustmentApprovalWrapper {
        public String stepName;
        public String appDate;
        public String status;
        public String assignedTo;
        public String actualApprover;
        public String actualApproverId;
        public String comments;
    }

    // Wrapper for adjustment reason codes
    public class ReasonCode {
        public String chargeCode;
        public String chargeType;
        public String reasonDescription;
        public String reasonExplanationCode;
        public String reasonSystemCode;

        public ReasonCode(
            String chargeCode,
            String chargeType,
            String reasonDescription,
            String reasonExplanationCode,
            String reasonSystemCode
        ) {
            this.chargeCode = chargeCode;
            this.chargeType = chargeType;
            this.reasonDescription = reasonDescription;
            this.reasonExplanationCode = reasonExplanationCode;
            this.reasonSystemCode = reasonSystemCode;
        }
    }
}
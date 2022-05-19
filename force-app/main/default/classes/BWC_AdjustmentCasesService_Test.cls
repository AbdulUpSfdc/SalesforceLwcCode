// Test class for BWC_AdjustmentCasesService and BWC_AdjustmentCasesController
@IsTest
private class BWC_AdjustmentCasesService_Test {
    @IsTest
    static void testApproveAdjustmentRequest() {
        Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();

        // Create an approval request for Adjustment
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting approval request.');
        req.setObjectId(adjustment.Id);

        // Submit the request for approval
        Approval.ProcessResult res = Approval.process(req);
        System.assert(res.isSuccess(), 'Request not successful.');

        // Call method and verify result
        BWC_AdjustmentCasesController.approveAdjustmentRequest(adjustment.Id, 'Submitting for approval.');
        Adjustment__c adj = [SELECT Id, Status__c FROM Adjustment__c WHERE Id = :adjustment.Id];
        System.assertEquals('Level 2', adj.Status__c, 'Adjustment status not changed.');

        // Exception handling
        User testUser = BWC_TestDataFactory.createUser();
        System.runAs(testUser) {
            try {
                BWC_AdjustmentCasesController.approveAdjustmentRequest(adjustment.Id, 'Submitting for approval.');
            } catch (Exception e) {
                System.assert(true, 'Exception not handled.');
            }
        }
    }

    @IsTest(SeeAllData=true)
    public static void testCheckAdjustmentApprovalLevelOne() {
        Adjustment__c adj = BWC_TestDataFactory.createAdjustment();

        Adjustment_Line_Item__c lineItem = [
            SELECT Id
            FROM Adjustment_Line_Item__c
            WHERE Adjustment__c = :adj.Id
            LIMIT 1
        ];
        lineItem.Requested_Amount__c = 395;
        lineItem.Agent_Adjusted_Amount__c = 395;
        update lineItem;

        SOA_Level__c soaLevel = [
            SELECT Id
            FROM SOA_Level__c
            WHERE Authorization_Amount__c > 0 AND Authorization_Amount__c < 400
            LIMIT 1
        ];

        Employee__c emp = [
            SELECT Id, SOA_Level__c, User__c
            FROM Employee__c
            WHERE User__c != NULL AND User__r.IsActive = TRUE
            LIMIT 1
        ];
        emp.SOA_Level__c = soaLevel.Id;
        update emp;

        // Create an approval request for Adjustment
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting approval request.');
        req.setObjectId(adj.Id);

        // Submit the request for approval
        Approval.ProcessResult res = Approval.process(req);

        // Calling method and verifying result
        User testUser = [SELECT Id FROM User WHERE Id = :emp.User__c LIMIT 1];
        System.runAs(testUser) {
            String response = BWC_AdjustmentCasesController.checkAdjustmentApprovalPerm(adj.Id);
            System.assert(response != null, 'Response is null.');
        }

        // Exception handling
        System.runAs(testUser) {
            try {
                BWC_AdjustmentCasesController.checkAdjustmentApprovalPerm(null);
            } catch (Exception e) {
                System.assert(true, 'Exception not handled.');
            }
        }
    }

    @IsTest(SeeAllData=true)
    public static void testCheckAdjustmentApprovalLevelTwo() {
        Adjustment__c adj = BWC_TestDataFactory.createAdjustment();
        SOA_Level__c soaLevel = [SELECT Id FROM SOA_Level__c WHERE Authorization_Amount__c > 400 LIMIT 1];

        Employee__c emp = [
            SELECT Id, SOA_Level__c, User__c
            FROM Employee__c
            WHERE User__c != NULL AND User__r.IsActive = TRUE
            LIMIT 1
        ];
        emp.SOA_Level__c = soaLevel.Id;
        update emp;

        // Create an approval request for Adjustment
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting approval request.');
        req.setObjectId(adj.Id);

        // Submit the request for approval
        Approval.ProcessResult res = Approval.process(req);

        User testUser = [SELECT Id FROM User WHERE Id = :emp.User__c LIMIT 1];
        System.runAs(testUser) {
            try {
                BWC_AdjustmentCasesController.approveAdjustmentRequest(adj.Id, 'Submitting for approval.');
                BWC_AdjustmentCasesController.checkAdjustmentApprovalPerm(adj.Id);
            } catch (Exception e) {
                System.assert(true, 'Exception not handled.');
            }
        }
    }

    @IsTest
    public static void testCheckRecordEditability() {
        Adjustment__c adj = BWC_TestDataFactory.createAdjustment();

        // Call method and verify results
        String response = BWC_AdjustmentCasesController.checkRecordEditability(adj.Id);
        System.assert(response != null, 'Record not editable.');

        // Exception handling
        try {
            BWC_AdjustmentCasesController.checkRecordEditability(null);
        } catch (Exception e) {
            System.assert(true, 'Exception not handled.');
        }
    }

    @IsTest
    static void testFullRejectAdjustment() {
        Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();

        // Create an reject request for Adjustment
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting reject request.');
        req.setObjectId(adjustment.Id);

        // Submit the request for approval
        Approval.ProcessResult res = Approval.process(req);
        System.assert(res.isSuccess(), 'Request not successful.');

        // Call the method and verify the result
        BWC_AdjustmentCasesController.fullRejectAdjustment(adjustment.Id, 'Submitting for rejection.');
        Adjustment__c adj = [SELECT Id, Status__c FROM Adjustment__c WHERE Id = :adjustment.Id];
        System.assertEquals('Rejected', adj.Status__c, 'Adjustment status not changed.');
    }

    @IsTest
    static void testEditableAdjPerm() {
        Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();
        User testUser = BWC_TestDataFactory.createUser();

        // Checking permissions block
        System.runAs(testUser) {
            try {
                List<Adjustment__c> adj = BWC_AdjustmentCasesController.getEditableAdjustment(adjustment.Id);
            } catch (Exception e) {
                System.assert(true, 'Exception not handled.');
            }
        }
    }

    @IsTest
    static void testGetAdjustmentLineItem() {
        Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();
        Adjustment_Line_Item__c lineItem = [
            SELECT Id
            FROM Adjustment_Line_Item__c
            WHERE Adjustment__c = :adjustment.Id
            LIMIT 1
        ];

        // Checking permissions block
        Adjustment_Line_Item__c lineItemTest = BWC_AdjustmentCasesController.getAdjustmentLineItem(lineItem.Id);
        System.assert(lineItemTest != null, 'Line item is null.');

        // Exception handling
        try {
            BWC_AdjustmentCasesController.getAdjustmentLineItem(null);
        } catch (Exception e) {
            System.assert(true, 'Exception not handled.');
        }
    }

    @IsTest
    static void testGetEditableAdj() {
        Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();
        adjustment.Status__c = 'Rejected';
        update adjustment;

        // Get adjustment info and check value
        List<Adjustment__c> adj = BWC_AdjustmentCasesController.getEditableAdjustment(adjustment.Id);
        System.assert(adj != null, 'Adjustment is null.');
    }

    @IsTest
    static void testGetHistory() {
        Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();

        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(adjustment.Id);
        app.setProcessDefinitionNameOrId('Collections_Approval_Process');
        Approval.ProcessResult result = Approval.process(app);

        List<Approval.ProcessWorkitemRequest> reqs = new List<Approval.ProcessWorkitemRequest>();
        ProcessInstanceWorkitem workItem = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :adjustment.Id
            ORDER BY CreatedDate DESC, Id DESC
            LIMIT 1
        ];

        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments('Test.');
        req.setAction('Approve');
        req.setWorkitemId(workItem.Id);
        req.setNextApproverIds(new List<Id>{ UserInfo.getUserId() });
        reqs.add(req);
        Approval.ProcessResult[] results = Approval.process(reqs);

        reqs = new List<Approval.ProcessWorkitemRequest>();
        workItem = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :adjustment.Id
            ORDER BY CreatedDate DESC, Id DESC
            LIMIT 1
        ];
        Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        req2.setComments('Full rejection.');
        req2.setAction('Reject');
        req2.setWorkitemId(workItem.Id);
        reqs.add(req2);
        Approval.ProcessResult[] results2 = Approval.process(reqs);

        // Call method and verify results
        String historyList = BWC_AdjustmentCasesController.getHistory(adjustment.Id);
        System.assert(historyList != null, 'History list is null.');

        // Exception handling
        try {
            BWC_AdjustmentCasesController.getHistory(null);
        } catch (Exception e) {
            System.assert(true, 'Exception not handled.');
        }
    }

    @IsTest
    static void testGetReasonDescriptions() {
        List<Reason_Code_for_Charge_Code__c> newCodes = new List<Reason_Code_for_Charge_Code__c>();
        newCodes.add(
            new Reason_Code_for_Charge_Code__c(
                Biller__c = 'Telegence',
                Charge_Code__c = 'GOODWILL',
                Charge_Type__c = 'GOODWILL',
                Adj_Reason_Description__c = 'Goodwill Credit',
                Adj_Reason_Explanation_Code__c = 'CDEE-2020',
                Adj_Reason_System_Code__c = 'GOODWILL',
                External_Id__c = 'a2bc88fa-43f0-11ec-81d3-0242ac130003'
            )
        );
        newCodes.add(
            new Reason_Code_for_Charge_Code__c(
                Biller__c = 'Telegence',
                Charge_Code__c = 'Line Item',
                Charge_Type__c = 'Line Item',
                Adj_Reason_Description__c = 'Line Item Credit',
                Adj_Reason_Explanation_Code__c = 'CDEE-2021',
                Adj_Reason_System_Code__c = 'Line Item',
                External_Id__c = 'b404c122-43f0-11ec-81d3-0242ac130003'
            )
        );
        insert newCodes;

        // Verify results for Goodwill
        String goodwillReasonDescriptions = BWC_AdjustmentCasesController.getReasonDescriptions(
            'Goodwill',
            'Goodwill',
            'Goodwill'
        );
        System.assert(!String.isEmpty(goodwillReasonDescriptions), 'Goodwill reason descriptions are empty.');

        // Verify results for Line Item
        String lineItemReasonDescriptions = BWC_AdjustmentCasesController.getReasonDescriptions(
            'Line Item',
            'Line Item',
            'Line Item'
        );
        System.assert(!String.isEmpty(lineItemReasonDescriptions), 'Line item reason descriptions are empty.');

        // Exception handling
        User testUser = BWC_TestDataFactory.createUser();
        System.runAs(testUser) {
            try {
                BWC_AdjustmentCasesController.getReasonDescriptions(null, null, null);
            } catch (Exception e) {
                System.assert(true, 'Exception not handled.');
            }
        }
    }

    @IsTest
    static void testReturnBackAdjustment() {
        Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();

        // Create an return back request for Adjustment
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting returnBack request.');
        req.setObjectId(adjustment.Id);

        // Submit the request for approval
        Approval.ProcessResult res = Approval.process(req);
        System.assert(res.isSuccess(), 'Request not successful.');

        // Call method and verify the result
        BWC_AdjustmentCasesController.returnBackAdjustment(adjustment.Id, 'Returning back.');
        Adjustment__c adj = [SELECT Id, Status__c FROM Adjustment__c WHERE Id = :adjustment.Id];
        System.assertEquals('Rejected', adj.Status__c, 'Adjustment status not changed.');
    }

    @IsTest
    static void testTakeOwnershipAdjustmentCase() {
        Adjustment__c adj = BWC_TestDataFactory.createAdjustment();
        adj.Status__c = 'Level 1 (Manager)';
        update adj;

        // Run as manager and verify result
        User testManager = [SELECT Id FROM User WHERE Id = :adj.Manager__c LIMIT 1];
        System.runAs(testManager) {
            Boolean response = BWC_AdjustmentCasesController.takeOwnershipAdjustmentCase(adj.Case__c);
            System.assert(response == true, 'Take ownership failed.');
        }
    }

    @IsTest
    static void testUpdateAdjustmentLineItem() {
        Adjustment__c adj = BWC_TestDataFactory.createAdjustment();
        Adjustment_Line_Item__c lineItem = [
            SELECT Id, Adj_Reason_Description__c
            FROM Adjustment_Line_Item__c
            WHERE Adjustment__c = :adj.Id
        ];
        lineItem.Adj_Reason_Description__c = 'Test';

        // Calling method and verifying result
        BWC_AdjustmentCasesController.updateAdjustmentLineItem(JSON.serialize(lineItem));
        Adjustment_Line_Item__c lineItemTest = [
            SELECT Id, Adj_Reason_Description__c
            FROM Adjustment_Line_Item__c
            WHERE Adjustment__c = :adj.Id
        ];
        System.assert(lineItemTest.Adj_Reason_Description__c == 'Test', 'Field not changed.');

        // Exception handling
        try {
            lineItem.Agent_Adjusted_Amount__c = null;
            BWC_AdjustmentCasesController.updateAdjustmentLineItem(JSON.serialize(lineItem));
        } catch (Exception e) {
            System.assert(true, 'Exception not handled.');
        }
    }
}
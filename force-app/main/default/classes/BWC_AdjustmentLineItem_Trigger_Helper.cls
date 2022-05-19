public with sharing class BWC_AdjustmentLineItem_Trigger_Helper {

    private static List<Adjustment_Line_Item__c> adjustmentLineItemList;
    private static Map<Id,Sobject> updateMap;
    
    public static void handleBeforeInsert() {
        initializeData();
        handleLineItemFieldsBeforeInsert();
    }
    public static void handleBeforeUpdate() {

        initializeData();
    }
    public static void handleAfterInsert() {
        initializeData();
        handleAdjustmentStatusUpdate();
    }
    public static void handleAfterUpdate() {

        initializeData();
    }
    public static void initializeData() {
        updateMap = new Map<Id,Sobject>();
        if(Trigger.isBefore){
            if(Trigger.isInsert) {
                adjustmentLineItemList = new List<Adjustment_Line_Item__c>();
                adjustmentLineItemList = Trigger.new;
            }

            if(Trigger.isUpdate) {

            }
        }
        if(Trigger.isAfter) {
            if(Trigger.isInsert) {
                adjustmentLineItemList = new List<Adjustment_Line_Item__c>();
                adjustmentLineItemList = (list<Adjustment_Line_Item__c>)Trigger.newMap.values();
            }
            if(Trigger.isUpdate) {

            }
        }
    }
    public static void handleAdjustmentStatusUpdate() {
        set<Id> adjIdlist = new set<Id>();
        Boolean hasManagerCustomPerm = False;
        for(Adjustment_Line_Item__c adjLineItem: adjustmentLineItemList){
            adjIdlist.add(adjLineItem.Adjustment__c);
        }
        list<Adjustment__c> adjList = BWC_Adjustment_Selector.getAdjustments(adjIdlist);
        for(Adjustment__c adj:adjList){
            adj.Status__c = CaseConstants.ADJUSTMENT_SUBMIT_FOR_APPROVAL;
            
            hasManagerCustomPerm = FeatureManagement.checkPermission(CaseConstants.BACKOFFICE_MANAGER_CUSTOM_PERM);
            if (hasManagerCustomPerm){
                adj.Override_By_Manager__c = True;
            }
            updateMap.put(adj.id, adj);
        }
        
        upsert updateMap.values();
        handleAdjustmentApproval(updateMap.keySet());
        updateMap.clear();
    }
    public static void handleAdjustmentApproval(set<id> adjIdlist) {
        handleApprovalRequests(adjIdlist);
    }
    @future
    public static void handleApprovalRequests(set<id> adjIdList) {
         List<Approval.ProcessSubmitRequest> approvalProcessSubmitRequestsList = new List<Approval.ProcessSubmitRequest>();

        for(Id adjId : adjIdList) {
            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setComments('Approval started');
            approvalRequest.setObjectId(adjId);
            approvalProcessSubmitRequestsList.add(approvalRequest);
        }
         List<Approval.ProcessResult> approvalResultsList = Approval.process(approvalProcessSubmitRequestsList);
    }
    public static void handleLineItemFieldsBeforeInsert() {
        for (Adjustment_Line_Item__c adjLine : adjustmentLineItemList) {
            adjLine.Agent_Adjusted_Amount__c = adjLine.Requested_Amount__c;            
        }
    }
}
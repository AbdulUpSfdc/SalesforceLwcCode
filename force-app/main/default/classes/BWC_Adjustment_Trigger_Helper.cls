public with sharing class BWC_Adjustment_Trigger_Helper {
    
    private static Map<Id,Employee__c> employeeMap;
    private static Map<Id,Employee__c> managerMap;
    private static Map<Id,Adjustment__c> adjustmentMap;
    private static List<Adjustment__c> adjustmentList;
    private static Map<Id,Sobject> updateMap;
    private static Map<Id,Case> parentCaseMap;
    
    public static void handleBeforeInsert() {
        initializeData();
        handleEmployeeRecordFieldsOnAdjustment();
    }
    public static void handleBeforeUpdate() {
        initializeData();
    }
    public static void handleAfterInsert() {

    }
    public static void handleAfterUpdate() {
        initializeData();
        handleParentCaseUpdate();
        handleCaseOwnerUpdate();
        handleApprovedOrRejectedAdjustment();
        upsert updateMap.values();
        updateMap.clear();
    }
    public static void initializeData() {
        updateMap = new Map<Id,SObject>();
        
        if(Trigger.isBefore){
            if(Trigger.isInsert) {
                adjustmentMap = new Map<id,Adjustment__c>();
                employeeMap = new Map<id,Employee__c>();
                managerMap = new Map<id,Employee__c>();
                adjustmentList = Trigger.new;
                setEmployeeMap();
            }
            
            if(Trigger.isUpdate) {
                adjustmentMap = new Map<id,Adjustment__c>();
                adjustmentMap = (Map<id,Adjustment__c>)Trigger.newMap;
                adjustmentList = adjustmentMap.values();
            }
        }
        if(Trigger.isAfter) {
            if(Trigger.isInsert) {

            }
            if(Trigger.isUpdate) {
                adjustmentMap = new Map<id,Adjustment__c>();
                adjustmentMap = (Map<id,Adjustment__c>)Trigger.newMap;
                parentCaseMap = new Map<Id,Case>();
                adjustmentList = adjustmentMap.values();
                setParentCaseMap();
            }
        }
    }
    public static void handleParentCaseUpdate(){
        // Parent Case updates - after update
        if(Trigger.isAfter && Trigger.isUpdate) {
            list<Adjustment__c> postedAdjustmentList = new list<Adjustment__c>();
            list<Adjustment__c> rollUpUpdatedAdjustmentList = new list<Adjustment__c>();
            for(Adjustment__c adj :adjustmentList){
                if(hasValueChanged('Status__c',adj.Id) && adj.Status__c == 'Posted'){
                    postedAdjustmentList.add(adj);
                }
                if(hasValueChanged('Total_Requested_Amount__c', adj.Id) || hasValueChanged('Total_Charge_Amount__c', adj.Id)){
                    rollUpUpdatedAdjustmentList.add(adj);
                }
            }
            handlePostedAdjustment(postedAdjustmentList);
            handleRollupFieldUpdates(rollUpUpdatedAdjustmentList);
        }
    }

    public static void handleEmployeeRecordFieldsOnAdjustment() {
        Id runningUser = UserInfo.getUserId();
        for(Adjustment__c adj:adjustmentList){
            if(managerMap.get(runningUser)!=null && employeeMap.get(runningUser)!=null) {
                adj.Delegate_1__c = (String.isNotBlank(managerMap.get(runningUser)?.Delegate_1__c))?managerMap.get(runningUser)?.Delegate_1__c:(String.isNotBlank(managerMap.get(runningUser)?.Delegate_2__c))?managerMap.get(runningUser)?.Delegate_2__c:managerMap.get(runningUser)?.User__c;
                adj.Delegate_2__c = (String.isNotBlank(managerMap.get(runningUser)?.Delegate_2__c))?managerMap.get(runningUser)?.Delegate_2__c:(String.isNotBlank(managerMap.get(runningUser)?.Delegate_1__c))?managerMap.get(runningUser)?.Delegate_1__c:managerMap.get(runningUser)?.User__c;
                adj.Manager__c = managerMap.get(runningUser)?.User__c;
                adj.Channel__c = employeeMap.get(runningUser)?.Channel1__c;
                adj.Sub_Channel__c = employeeMap.get(runningUser)?.Sub_Channel__c;
            } else {
                throw new BWC_Exception('Missing Employee record');
            }
        }
    }
    public static void setEmployeeMap() {
        Employee__c employee = BWC_Employee_Selector.getEmployee(UserInfo.getUserId());
        employeeMap.put(UserInfo.getUserId(),employee);
        Employee__c manager = BWC_Employee_Selector.getUsersManagerEmployeeRec(UserInfo.getUserId());
        managerMap.put(UserInfo.getUserId(), manager);
    }

    public static void setParentCaseMap(){
        list<id> parentCaseIdList =new list<Id>();
        for(Adjustment__c adj:adjustmentList){
            parentCaseIdList.add(adj.Case__c);
        }
        list<Case> caseList = BWC_Case_Selector.getCasesById(parentCaseIdList);
        for(Case c: caseList){
            parentCaseMap.put(c.id,c);
        }
    }
    public static void handlePostedAdjustment(list<Adjustment__c> postedAdjustmentList){
        String closeNotes;
        for(Adjustment__c adj : postedAdjustmentList){
            closeNotes = 'Adjustment Successfully Submitted \n '+ 'Total Requested Amount = '+ adj?.Total_Requested_Amount__c+' \n'+
                'Total Agent Adjusted Amount = ' + adj?.Total_Agent_Adjusted_Amount__c;
            parentCaseMap.get(adj.Case__c).CloseNotes__c = closeNotes;
            parentCaseMap.get(adj.Case__c).Status = Case_Action_Constants.CLOSED;
            parentCaseMap.get(adj.Case__c).Resolution__c = 'No Action';
            // Handle Case.Resolution2__c SPTSFDCSPT-4552 AC1
             if (adj.Total_Requested_Amount__c == adj.Total_Agent_Adjusted_Amount__c) {
                parentCaseMap.get(adj.Case__c).Resolution__c = 'Corrected';
                parentCaseMap.get(adj.Case__c).Resolution2__c = 'Adjustment full amount';
            } else if (adj.Total_Requested_Amount__c > adj.Total_Agent_Adjusted_Amount__c) {
                parentCaseMap.get(adj.Case__c).Resolution__c = 'Corrected';
                parentCaseMap.get(adj.Case__c).Resolution2__c = 'Adjustment partial amount';     
            } 
            
            updateMap.put(parentCaseMap.get(adj.Case__c).Id, parentCaseMap.get(adj.Case__c));
            system.debug('parent case update');
            
        }
    }
    public static void handleCaseOwnerUpdate(){
        // when status contains level and is not manager level
        // need to check process instance  pull actorId and set as case owner
        //for level 1 / manager set case owner to manager user id
        set<id> adjIdList = adjustmentMap.keySet();
        for(Adjustment__c adj :adjustmentList){
            if( hasValueChanged('Status__c',adj.Id) && adj.Status__c.contains('Level') && !BWC_AdjustmentCasesService.isRunningFullRejection){
                if(adj.Status__c.contains(CaseConstants.ADJUSTMENT_STATUS_LEVEL_1)){
                    parentCaseMap.get(adj.Case__c).OwnerId = adj.Manager__c;
                    parentCaseMap.get(adj.Case__c).WorkGroup__c = 'Manager';
                    updateMap.put(parentCaseMap.get(adj?.Case__c).Id, parentCaseMap.get(adj?.Case__c));
                }else{
                    if (adj.Override_By_Manager__c && adj.Status__c.contains(CaseConstants.ADJUSTMENT_STATUS_LEVEL_2)){
                        if (adj.Channel__c == CaseConstants.COLLECTIONS){
                            Group RMq = [SELECT Id FROM Group WHERE Name = :CaseConstants.RM_HLA_AUTDIT_Q AND Type = 'Queue'];
                            parentCaseMap.get(adj.Case__c).OwnerId = RMq.Id;
                		}else{
                            Group HLAq = [SELECT Id FROM Group WHERE Name = :CaseConstants.HLA_BOFC_Q AND Type = 'Queue'];
                            parentCaseMap.get(adj.Case__c).OwnerId = HLAq.Id;
                		}
                        updateMap.put(parentCaseMap.get(adj?.Case__c).Id, parentCaseMap.get(adj?.Case__c));   
                    }else{
                        handleFutureUpdate(adj?.Case__c,adj.Id);
                    }
                }
            } else if (BWC_AdjustmentCasesService.isRunningFullRejection) {
                System.debug('Setting the case owner to current user : Full Reject');
                if (parentCaseMap.get(adj.Case__c).OwnerId != UserInfo.getUserId()) {
                    parentCaseMap.get(adj.Case__c).OwnerId = UserInfo.getUserId();
                }
            }
        }
    }
    @future
    public static void handleFutureUpdate( Id caseId, Id adjId){
        set<id> adjIdlst = new set<Id>();
        list<id> caseIds = new list<Id>();
        adjIdlst.add(adjId);
        caseIds.add(caseId);

        if(BWC_Process_Instance_Selector.getProcessInstances(adjIdlst)!=NULL) {
            id newCaseOwner = BWC_Process_Instance_Selector.getProcessInstances(adjIdlst)[0]?.ActorId;
            Case c = BWC_Case_Selector.getCasesById(caseIds)[0];
            c.OwnerId = newCaseOwner;
            BWC_AdjDelegateCaseOwnerUpdate.updateCaseOwner(c);
        } else {            
            Case c = BWC_Case_Selector.getCasesById(caseIds)[0];
            c.OwnerId = UserInfo.getuserId();
            BWC_AdjDelegateCaseOwnerUpdate.updateCaseOwner(c);
        }
    }
    public static boolean hasValueChanged(string param,Id adjId){
        Boolean returnvalue = false;
        Adjustment__c newAdj = (Adjustment__c)Trigger.newMap.get( adjId );
        Adjustment__c oldAdj = (Adjustment__c)Trigger.oldMap.get( adjId );
        switch on param {
            when 'Status__c' {		// when block 1
                if(oldAdj.Status__c != newAdj.Status__c){returnvalue=true;}
            }
            when 'Total_Charge_Amount__c' {
                if(oldAdj.Total_Charge_Amount__c != newAdj.Total_Charge_Amount__c){returnvalue=true;}
            }
            when 'Total_Requested_Amount__c' {
                if(oldAdj.Total_Requested_Amount__c != newAdj.Total_Requested_Amount__c){returnvalue=true;}                
            }
            when else {		  // default block, optional
                
            }
        }
        return returnvalue;
    }
    public static void handleApprovedOrRejectedAdjustment() {
        Set<Id> adjustmentsSet = new Set<Id>();
        
        // Adding adjustment id to set if status is approved or rejected
        for (Adjustment__c adj : adjustmentList) {
            if(hasValueChanged('Status__c', adj.Id) && (adj.Status__c == CaseConstants.ADJUSTMENT_STATUS_APPROVED || adj.Status__c == CaseConstants.REJECTED)) {
                adjustmentsSet.add(adj.Id);
            }
        }
        
        // Posting adjustment
        if (adjustmentsSet.size() > 0) {
            String postAdjustmentPayload = BWC_PostPendingAdjustmentSelector.createAdjustmentObject(adjustmentsSet);
            System.enqueueJob(new BWC_PostAdjustment(postAdjustmentPayload, adjustmentsSet));
        }                
    }

    public static void handleRollupFieldUpdates(List<Adjustment__c> updatedList) {
        for (Adjustment__c adj : updatedList) {
            parentCaseMap.get(adj.Case__c).Amount_Charged__c = adj.Total_Charge_Amount__c;
			parentCaseMap.get(adj.Case__c).Amount_in_Dispute__c  = adj.Total_Requested_Amount__c;
            
			updateMap.put(parentCaseMap.get(adj.Case__c).Id, parentCaseMap.get(adj.Case__c));
        }
    }
}
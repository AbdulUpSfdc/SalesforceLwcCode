public with sharing class BWC_ApprovalHistoryController {
    @AuraEnabled(cacheable=true)
    public static List<approvalWrapper> getHistory(Id record_Id) {
        System.debug('getHistory called');
        List<approvalWrapper> appWrapList = new List<approvalWrapper>();
        Map<Id, List<ProcessInstanceNode>> ProcessNodeToInstanceMap = new Map<Id, List<ProcessInstanceNode>>();
        Id prevProcessNode;
        List<ProcessInstanceNode> newInstanceList = new List<ProcessInstanceNode>();
        String approvalProcess;

        for(ProcessInstanceNode pInstanceNode : [SELECT Id, CreatedDate, ProcessNodeId, ProcessNodeName, LastActorId, LastActor.Name, NodeStatus, CompletedDate, ProcessInstance.ProcessDefinition.DeveloperName
                                                 FROM ProcessInstanceNode
                                                 WHERE ProcessInstance.TargetObjectId =: record_Id
                                                 ORDER BY ProcessNodeId, CompletedDate Desc]){
            
            approvalProcess = pInstanceNode.ProcessInstance.ProcessDefinition.DeveloperName;                                      
                                                    
            if(prevProcessNode == null){
                prevProcessNode = pInstanceNode.ProcessNodeId; 
            }

            if(prevProcessNode != pInstanceNode.ProcessNodeId){
                newInstanceList = new List<ProcessInstanceNode>();
            }

            newInstanceList.add(pInstanceNode);
            ProcessNodeToInstanceMap.put(pInstanceNode.ProcessNodeId, newInstanceList); 
            System.debug('pInstance: ' + pInstanceNode.ProcessNodeName + ', ' + pInstanceNode.ProcessNodeId + ', ' + pInstanceNode.ProcessNodeName);

            prevProcessNode = pInstanceNode.ProcessNodeId; 
        }        

        String quePrefix;
        if(approvalProcess.contains(CaseConstants.HLA_APPROVAL)  ){
            quePrefix = 'HLA';
        }
        else if(approvalProcess.contains(CaseConstants.COLLECTIONS)){
            quePrefix = 'RM';
        }
        List<SOA_Approved_Amount__mdt> approvalLevels = [SELECT Queue_Name__c, Level__c
                                                         FROM SOA_Approved_Amount__mdt
                                                         WHERE Queue_Prefix__c =: quePrefix];
        
        Map<String, Decimal> queNameToLevelMap = new Map<String, Decimal>();
        Map<Decimal, String> levelToQueNameMap = new Map<Decimal, String>();                                                 
        queNameToLevelMap.put(CaseConstants.MANAGERS_APPROVAL, 1);
        levelToQueNameMap.put(1, CaseConstants.MANAGERS_APPROVAL);

        for(SOA_Approved_Amount__mdt appLevel : approvalLevels){
            System.debug('que added: ' + appLevel.Queue_Name__c);
            Decimal level = appLevel.Level__c;
            queNameToLevelMap.put(appLevel.Queue_Name__c, level.stripTrailingZeros());
            levelToQueNameMap.put(level.stripTrailingZeros(), appLevel.Queue_Name__c);
        }

        List<ProcessInstance> approvalsCompleteList =  [SELECT Id, (SELECT Id, ProcessNodeId, ProcessNode.Name, StepStatus, Actor.Name, OriginalActorId, OriginalActor.Name, CreatedDate, Comments 
                                                                    FROM StepsAndWorkitems 
                                                                    WHERE StepStatus !=: CaseConstants.NO_RESPONSE
                                                        ORDER BY CreatedDate Asc, Id Asc)
                                                        FROM ProcessInstance
                                                        WHERE TargetObjectId =: record_Id];

        Integer listSize = approvalsCompleteList[0].StepsAndWorkitems.size();
        Map<String, ProcessInstanceHistory> highestQueMap = new Map<String, ProcessInstanceHistory>();
        Map<String, Id> fullRejectsMap = new Map<String, Id>();
        String highestQue; 
        Id highestFullReject;
        Integer count = 0;

        for(ProcessInstanceHistory iH : approvalsCompleteList[0].StepsAndWorkitems){
            count++;      
            if(iH.Comments != null && iH.Comments.contains(CaseConstants.FULL_REJECTION)){
                fullRejectsMap.put(iH.ProcessNode.Name, iH.Id);
            }
            else{
                highestQue = iH.ProcessNode.Name;                
                highestQueMap = new Map<String, ProcessInstanceHistory>();
                highestQueMap.put(iH.ProcessNode.Name, iH);
            }

            if(count == listSize){
                //Determine if you need to go down a que based on if the highest que was rejected
                //if previous que was approved go up one based on meta data
                System.debug('highestQue: ' + highestQue);
                if(highestQueMap.get(highestQue) != null && highestQueMap.get(highestQue).StepStatus == CaseConstants.REJECTED){
                    Decimal previousLevel = queNameToLevelMap.get(highestQue) - 1;
                    highestFullReject = fullRejectsMap.get(levelToQueNameMap.get(previousLevel));
                }
                else{
                    Decimal level;
                    if(highestQue == null){
                        highestQue = iH.ProcessNode.Name;
                        level = queNameToLevelMap.get(highestQue);
                        highestFullReject = fullRejectsMap.get(levelToQueNameMap.get(level));
                    }
                    else{
                        level = queNameToLevelMap.get(highestQue) + 1;
                        highestFullReject = fullRejectsMap.get(levelToQueNameMap.get(level));
                    }
                } 
            }        
        }  
        
        Map<Id, Integer> lastUsedIndexMap = new Map<Id, Integer>();
        ProcessInstanceHistory prevProcessHistory;
        ProcessInstanceNode instNode;

        for(ProcessInstanceHistory pIH : [SELECT Id, (SELECT Id, ProcessNodeId, ProcessNode.Name, StepStatus, Actor.Name, OriginalActorId, OriginalActor.Name, CreatedDate, Comments 
                                                      FROM StepsAndWorkitems 
                                                      WHERE StepStatus !=: CaseConstants.NO_RESPONSE
                                                      ORDER BY CreatedDate Desc, Id Desc)
                                          FROM ProcessInstance
                                          WHERE TargetObjectId =: record_Id].StepsAndWorkitems){
          
            approvalWrapper newAppWrap;

            if(pIH.StepStatus == CaseConstants.STARTED && pIH.ProcessNodeId == null){
                newAppWrap = new approvalWrapper();
                newAppWrap.stepName = CaseConstants.APPROVAL_SUBMITTED;
                newAppWrap.appDate = pIH.CreatedDate.format('MM/dd/YYYY, hh:mm a');
                newAppWrap.status = CaseConstants.SUBMITTED;
                newAppWrap.assignedTo = pIH.OriginalActor.Name;                               
                newAppWrap.actualApprover = pIH.OriginalActor.Name;
                newAppWrap.actualApproverId = URL.getSalesforceBaseUrl().toExternalForm()+ '/' + pIH.OriginalActorId;                    
                newAppWrap.comments = pIH.Comments;              
            }
            else{
                System.debug('pIH.ProcessNodeId : ' + pIH);
                //Get new index from the map when the processNodeId changes
                if(pIH.ProcessNodeId != null && pIH.ProcessNodeId != prevProcessHistory?.ProcessNodeId){
                    if(!lastUsedIndexMap.containsKey(pIH.ProcessNodeId)){
                        lastUsedIndexMap.put(pIH.ProcessNodeId, 0);
                    }
                    else{
                        Integer lastUsedIndex = lastUsedIndexMap.get(pIH.ProcessNodeId);
                        lastUsedIndexMap.put(pIH.ProcessNodeId, lastUsedIndex + 1);
                    }
                    instNode = ProcessNodeToInstanceMap.get(pIH.ProcessNodeId)[lastUsedIndexMap.get(pIH.ProcessNodeId)];
                }  
                
                if(pIH.Comments == null || pIH.Comments == '' || pIH.Id == highestFullReject && (pIH.Comments != null && pIH.Comments != '') && pIH.Comments.contains(CaseConstants.FULL_REJECTION) || (pIH.Comments != null && pIH.Comments != '') && !pIH.Comments.contains(CaseConstants.FULL_REJECTION) ){
                    newAppWrap = new approvalWrapper();                                                                        
                    newAppWrap.stepName = pIH.ProcessNode.Name;
                    if(instNode?.CompletedDate != null){
                    newAppWrap.appDate = instNode.CompletedDate.format('MM/dd/YYYY, hh:mm a');
                    }
                    else{
                    newAppWrap.appDate = pIH.CreatedDate.format('MM/dd/YYYY, hh:mm a');    
                    }
                    newAppWrap.status = pIH.StepStatus;
                    if(instNode?.LastActor.Name != null){
                    newAppWrap.actualApprover = instNode.LastActor.Name;
                    newAppWrap.actualApproverId = URL.getSalesforceBaseUrl().toExternalForm()+ '/' + instNode.LastActorId;
                    }                    
                    else {
                    newAppWrap.actualApprover = pIH.OriginalActor.Name;
                    newAppWrap.actualApproverId = URL.getSalesforceBaseUrl().toExternalForm()+ '/' + pIH.OriginalActorId;                    
                    }     
                    newAppWrap.assignedTo = pIH.OriginalActor.Name;                                
                    newAppWrap.comments = pIH.Comments;
                } 
            }
            prevProcessHistory = pIH;
            if(newAppWrap != null){                                    
                appWrapList.add(newAppWrap); 
                System.debug('appWrap: ' + newAppWrap);
            }
        }       
        return appWrapList;
    }

    public class approvalWrapper{

        @auraEnabled
        public string stepName;
        @auraEnabled
        public string appDate;
        @auraEnabled
        public string status;
        @auraEnabled
        public string assignedTo;
        @auraEnabled
        public string actualApprover;
        @auraEnabled
        public string actualApproverId;
        @auraEnabled
        public string comments;
    }

}
public inherited sharing class BWC_CaseMilestoneEventTriggerHandler extends SFS_TriggerHandler {
    // Runs after insert
    protected override void postInsert(List<SObject> records) {
        updateTargetDate(records);
    }

    // SPTSFDCSPT-10529: Copying Target Close Date from Case Milestones to Cases
    // Fire SMS and email functionality upon population of Target Close Date
    private void updateTargetDate(List<SObject> records) {
        // Getting Case IDs from event messages
        List<Id> caseIdList = new List<Id>();

        // For SMS
        Map<Id, Boolean> sendCommunicationCheckMap = new Map<Id, Boolean>();
        List<Case> caseListComm = new List<Case>();

        // Iterating through event messages
        for (Case_Milestone_Event__e event : (List<Case_Milestone_Event__e>) records) {
            caseIdList.add(event.Case_ID__c);
            sendCommunicationCheckMap.put(event.Case_ID__c, event.Send_Communication__c);
        }

        // Getting Cases based on Case ID field in event message
        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, Target_Close_Date__c FROM CASE WHERE Id IN :caseIdList]);

        // Getting associated Case Milestones
        List<CaseMilestone> caseMilestoneList = [
            SELECT Id, CaseId, MilestoneTypeId, TargetDate
            FROM CaseMilestone
            WHERE CaseId IN :caseIdList
        ];

        // Getting Milestones
        Map<Id, MilestoneType> milestoneList = new Map<Id, MilestoneType>(
            [
                SELECT Id, Name
                FROM MilestoneType
                WHERE Id IN (SELECT MilestoneTypeId FROM CaseMilestone WHERE CaseId IN :caseIdList)
            ]
        );

        // Updating Target Close Date on Cases that meet the criteria
        List<Case> updatedCaseList = new List<Case>();
        for (CaseMilestone caseMilestone : caseMilestoneList) {
            // Checking Milestone Name field
            if (milestoneList.get(caseMilestone.MilestoneTypeId)?.Name.contains('External')) {
                // Updating Target Close Date and adding to update list
                caseMap.get(caseMilestone.CaseId).Target_Close_Date__c = CaseMilestone.TargetDate;
                updatedCaseList.add(caseMap.get(caseMilestone.CaseId));
            }
        }

        update updatedCaseList;

        // If Send Communication field is checked, add case to list
        for (Case caseObj : updatedCaseList) {
            if (sendCommunicationCheckMap.get(caseObj.Id)) {
                caseListComm.add(caseObj);
            }
        }

        // Fire SMS and email functionality
        if (caseListComm.size() > 0) {
            BWC_CaseEmailAlertsUtility.sendEmailFromCase(caseListComm, null);
        }
    }
}
/*

Details of the response being sent back in case if the Approve button has been pressed.
    msg = 1 :: User does not have Edit permission
    msg = 2 :: User does not have enough SOA amount
    msg = 3 :: All good and move forward with Approve request

*/
public without sharing class BWC_VerifyAdjustmentApproval {
    @AuraEnabled(cacheable=false)
    public static string checkAccessibilityApprove(Id workItemId) {
        boolean response;
        string msg = '';

        try {
            UserRecordAccess UserRecordAccessoBJ = [
                SELECT RecordId, HasEditAccess
                FROM UserRecordAccess
                WHERE UserId = :UserInfo.getUserId() AND RecordId = :workItemId
            ];

            response = UserRecordAccessoBJ.HasEditAccess ? true : false;

            if (response) {
                msg = '2';

                Adjustment__c adj = [SELECT Status__c, Total_Agent_Adjusted_Amount__c FROM Adjustment__c WHERE Id = :workItemId];

                List<Employee__c> approvedEmployee = [
                    SELECT Id, SOA_Level__r.Authorization_Amount__c
                    FROM Employee__c
                    WHERE User__c = :UserInfo.getUserId()
                    LIMIT 1
                ];

                if (adj.Status__c == 'Level 1 (Manager)') {
                    if (approvedEmployee.size() > 0 && approvedEmployee[0].SOA_Level__r.Authorization_Amount__c >= CaseConstants.WIRELESS_LEVEL_ONE_MANAGER_SOA) {
                        msg = '3';
                    } else {
                        // Execute Chatter post logic for Manager
                        BWC_Adjustment_ChatterPost.postSOAFailMessageForManager(workItemId);
                    }
                } else {
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
                        SOA_Approved_Amount__mdt SOAApprovedAmount = [
                            SELECT Min_Amount__c
                            FROM SOA_Approved_Amount__mdt
                            WHERE MasterLabel = :pInstanceWorkitem[0].Actor.Name
                        ];
                        if (
                            approvedEmployee.size() > 0 &&
                            approvedEmployee[0].SOA_Level__r.Authorization_Amount__c > SOAApprovedAmount.Min_Amount__c
                        ) {
                            msg = '3';
                        } else {
                            // Execute Chatter post logic for Queue
                            BWC_Adjustment_ChatterPost.postSOAFailMessageForQueue(workItemId);
                        }
                    }
                }
            } else {
                msg = '1';
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        //return response;
        return msg;
    }

    @AuraEnabled(cacheable=false)
    public static boolean checkAccessibility(Id workItemId) {
        boolean response;
        try {
            UserRecordAccess UserRecordAccessoBJ = [
                SELECT RecordId, HasEditAccess
                FROM UserRecordAccess
                WHERE UserId = :UserInfo.getUserId() AND RecordId = :workItemId
            ];

            response = UserRecordAccessoBJ.HasEditAccess ? true : false;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return response;
    }
}
/* ================================================
* @author : Mike McKinley
* @date :   08/24/2020   
* @group : Case 
* @description : Methods related to merging cases

* @updated by Brandon Bridges to allow intake 
* agents to merge cases in addition to intake
* admins
================================================*/

public with sharing class CaseMergeHelper {
    
    public static Id sMasterRecordId; 
        
    // prevent Case merge if user is not an Intake Agent or the AccountIdentifiers don't match
    public static 
    void validateMerge(List<Case> mergingCases) {
        // This is not correct but not changing now. Query should return user and then we evaluate.
        Boolean isIntakeAdmin = userIsIntakeAdmin();
        Id oopRecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RECORD_TYPE).Id;
        
        Set<Id> masterCaseIdSet = new Set<Id>();
        Map<Id,Case> masterCaseMap = new Map<Id,Case>();
        for(Case currentCase: mergingCases){
            if(String.isNotBlanK(currentCase.MasterRecordId)){
                masterCaseIdSet.add(currentCase.MasterRecordId);
            }
        }
        
        if(masterCaseIdSet!=Null){
            //retrieve master cases 
            masterCaseMap = new Map<Id,Case>([SELECT Id,Billing_Account__c,AccountIdentifier__c,ExpectedCloseDate__c,ExpectedResponseDate__c,Status,RecordTypeId 
                               FROM Case WHERE Id IN :masterCaseIdSet]);
        }
        
        for(Case currentCase: mergingCases) {
            sMasterRecordId = currentCase.MasterRecordId;  
            
            if(String.isNotBlank(sMasterRecordId)){
                currentCase.Master_Case__c = sMasterRecordId;
                currentCase.Merged_Date__c = datetime.now();
            }
            
            case masterCase = masterCaseMap.get(currentCase.MasterRecordId);
            
            System.debug('*** Validating merge for case id: ' + currentCase.Id + ' (' + currentCase.CaseNumber + '), parent: ' + currentCase.MasterRecordId);
            
            // get the pre-merge values
            Case oldCase = (Case)Trigger.oldMap.get(currentCase.Id);
            
            // only Intake Agents or Intake Admin can merge
            if(isIntakeAdmin == false) {
                // 'Your role cannot merge Cases: only Intake Agents or Intake Admin can merge.'
                currentCase.addError(Label.CaseMerge_OnlyIntakeAdmins);
            }
            
            // prevent merge if Account Identifier doesn't match            
            //else if(String.isNotBlank(oldCase.AccountIdentifier__c) && oldCase.AccountIdentifier__c != masterCase.AccountIdentifier__c) {
            //As per story 3407 replacing account identifier with billing account check 
            else if(String.isNotBlank(oldCase.Billing_Account__c) && oldCase.Billing_Account__c!= masterCase.Billing_Account__c) {
                // 'Account Identifier must match to merge Cases'
                System.debug(Label.CaseMerge_AccountIdentifierMatch);
                currentCase.addError(Label.CaseMerge_AccountIdentifierMatch);
            } 
            
            // prevent merge for Closed or Pending Closed or Cancelled Cases
            else if(oldCase.Status == CaseConstants.PENDING_CLOSED_STATUS ||
                    oldCase.Status == CaseConstants.CLOSED_STATUS ||
                    oldCase.Status == CaseConstants.CANCELLED_STATUS ||
                    masterCase.Status == CaseConstants.PENDING_CLOSED_STATUS ||
                    masterCase.Status == CaseConstants.CLOSED_STATUS ||  
                    masterCase.Status == CaseConstants.CANCELLED_STATUS) {
                // 'Cases which are Closed or Pending Closed cannot be merged.'
                System.debug(Label.CaseMerge_NotClosedOrClosing);
                currentCase.addError(Label.CaseMerge_NotClosedOrClosing);
            }
            
            // only OOP Cases can merge
            else if(oldCase.RecordTypeId != oopRecordTypeId) {
                // 'Only OOP Cases can be merged; Child and Response Cases cannot.'
                System.debug(Label.CaseMerge_OnlyOOPCanMerge);
                currentCase.addError(Label.CaseMerge_OnlyOOPCanMerge);
            }
            
            //When OOP Case is Merged then its record type is changed to OOPClosedReadOnly - 3105 user story
            if(currentCase.RecordTypeId == MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RECORD_TYPE).ID){
                currentCase.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_CLOSED_READ_ONLY_RECORD_TYPE).ID; 
            }
            
            
        }
    }

    // set the expected dates to the earliest dates among the merged Cases
    public static
    void updateMergedDates(Case masterCase) {
        List<Case> mergedCases = [SELECT Id,ExpectedCloseDate__c,ExpectedResponseDate__c FROM Case WHERE Master_Case__c = :masterCase.Id];
        for(Case mergedCase: mergedCases) {
            if(mergedCase.ExpectedCloseDate__c != NULL && mergedCase.ExpectedCloseDate__c < masterCase.ExpectedCloseDate__c) {
                masterCase.ExpectedCloseDate__c = mergedCase.ExpectedCloseDate__c;
            }
            if(mergedCase.ExpectedResponseDate__c != NULL && mergedCase.ExpectedResponseDate__c < masterCase.ExpectedResponseDate__c) {
                masterCase.ExpectedResponseDate__c = mergedCase.ExpectedResponseDate__c;
            }
        }
    }

    // check if the current User is an Intake Agent or Intake admin
    private static
    Boolean userIsIntakeAdmin() {
        Boolean isIntakeAdmin = false;
        String userId = UserInfo.getUserId();
        List<User> users = [SELECT UserRoleId,UserRole.Name,UserRole.DeveloperName FROM User WHERE Id =:userId LIMIT 1];
        if(!users.isEmpty()) {
            User roleUser = users[0];
            // Check is User Role is Intake Admin or Intake Agent, if yes return true
            if((roleUser.UserRole.Name == CaseConstants.ROLE_INTAKE_ADMIN)||(roleUser.UserRole.Name == CaseConstants.ROLE_INTAKE_AGENT)) {
                isIntakeAdmin = true;
            }
        }
        return isIntakeAdmin;
    }

}
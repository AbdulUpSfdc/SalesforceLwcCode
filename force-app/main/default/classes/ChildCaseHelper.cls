/* ================================================
* @author : Mike McKinley
* @date :   08/24/2020
* @group : Case
* @description : Helper class for child Cases
================================================*/

public with sharing class ChildCaseHelper {


    public static void preventClosureWithOpenChildCases(Case currentCase) {
        if(currentCase.Status.equalsIgnoreCase(CaseConstants.CASE_STATUS_CLOSED) || currentCase.Status.equalsIgnoreCase(CaseConstants.CASE_STATUS_CANCELLED) ) {
            Integer openChildren = [SELECT count() FROM Case_Action__c WHERE Case__c =: currentCase.Id AND Status__c NOT IN (:Case_Action_Constants.CLOSED, :Case_Action_Constants.CANCELLED)];
            if(openChildren>0) {
                // 'Parent Case cannot be closed until all child Cases are closed.'
                currentCase.addError(System.Label.ChildrenMustBeClosed);
            }
        }
    }
    public static void preventClosureWithOpenChildCaseActions(Case currentCase) {
        if(currentCase.Status.equalsIgnoreCase(CaseConstants.CASE_STATUS_CLOSED) || currentCase.Status.equalsIgnoreCase(CaseConstants.CASE_STATUS_CANCELLED) ) {
            Integer openChildren = [SELECT count() FROM Case_Action__c WHERE Case__c =: currentCase.Id AND Status__c NOT IN (:Case_Action_Constants.CLOSED, :Case_Action_Constants.CANCELLED)];
            if(openChildren>0) {
                // 'Parent Case cannot be closed until all child Cases are closed.'
                currentCase.addError(System.Label.ChildrenMustBeClosed);
            }
        }
    }


    public static List<Case_Action__c> handlePendingClosureVersion2(Case parentCase){
        List<Case_Action__c> responseCaseActionList = new List<Case_Action__c>();

        Id oopRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OOP').getRecordTypeId();

        if (parentCase.RecordTypeId == oopRecordTypeId && parentCase.Status.equalsIgnoreCase(Case_Action_Constants.PENDING_CLOSED))
        {
            // prevent Pending Closed with open child cases
            Integer openChildren = [SELECT count() FROM Case_Action__c WHERE Case__c = :parentCase.Id
                                    AND Status__c NOT IN (:Case_Action_Constants.CLOSED, :Case_Action_Constants.CANCELLED)];// Added Cancelled Status - km272e
            if (openChildren > 0)
            {
                // 'Parent Case cannot be set to Pending Closed until all child Cases are closed.'
                parentCase.addError(System.Label.ChildrenMustBeClosed_Pending);
            }
            else
            {
                if (parentCase.Is_Response_Required__c)
                {

                    Id responseRtId = Case_Action_Constants.RESPONSE_RECORDTYPE_ID;
                    Integer openResponseCases = [SELECT count() FROM Case_Action__c WHERE Case__c = :parentCase.Id
                                                 AND (
                                                     (RecordTypeId = :responseRtId AND Status__c
                                                     NOT IN (:Case_Action_Constants.CLOSED, :Case_Action_Constants.CANCELLED)
                                                     ))];
                    if (openResponseCases == 0)
                    {
                        // there are no child response cases that are open or have been closed without 'Response Returned', so create another child response
                        Case_Action__c responseCaseAction = createResponseCaseAction(parentCase);
                        Case_Action_Trigger_Helper.hasFired = true;
                        responseCaseActionList.add(responseCaseAction);
                    }
                }
            }
        }
        return responseCaseActionList;
    }

    private static Case_Action__c createResponseCaseAction(Case parentCase){

        Case_Action__c caseAction = Case_Action_Selector.createResponseCaseAction(parentCase);
        return caseAction;

    }

    public static void insertResponseCases(List<SObject> responseCases) {
        system.debug('insert response case Actions'+ responseCases.size());
        if(responseCases.size() > 0) {
            try {
                system.debug('I inserted Response: ');

                insert responseCases;
            }
            catch(Exception e) {
                system.debug('I broke: '+ e.getMessage());

                BWC_ExceptionUtils.handleException(e, true);
                throw e;
            }
        }
    }

    public static Boolean hasMobilityProduct(String productString) {
        Boolean isMobility = false;
        if(String.isNotBlank(productString)) {
            String[] productList = productString.split(',');
            Set<String> productSet = new Set<String>();
            productSet.addAll(productList);

            Set<String> mobilityProducts = new Set<String>{'Digital Life', 'FirstNet','Wireless Prepaid','Wireless'};
            Set<String> intersectionSet = new Set<String>();
            system.debug('productSet'+productSet);
            for(String product : mobilityProducts) {
                if(productSet.contains(product)) {
                    intersectionSet.add(product);
                }
            }
            isMobility = !intersectionSet.isEmpty();
            system.debug('intersectionSet'+intersectionSet);
        }

        return isMobility;
    }

    public static Boolean shouldRejectParent(Case currentCase) {
        Boolean shouldReject = false;
        if(currentCase.Resolution__c == 'Response Returned') {
            shouldReject = true;
        }

        return shouldReject;
    }

    public static void updateRejectedParents(List<Id> rejectedParentIds) {
        if(rejectedParentIds.size() > 0) {
            List<Case> parentCases = [SELECT Id, Status FROM Case WHERE Id IN :rejectedParentIds];
            for(Case parentCase : parentCases) {
                parentCase.Status = 'Response Returned';
            }
            try {
                update parentCases;
            }
            catch(Exception e) {
                BWC_ExceptionUtils.handleException(e, true);
            }
        }
    }
}
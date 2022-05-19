public with sharing class Case_Action_Selector {


    //setter for data structure with accounts
    public static Map<id,Account> getParentCaseAccountMap(set<id> targetList){

        return new  Map<id,Account>([
            SELECT ID, BillingState
            FROM Account
            WHERE id in : targetList ]);
    }
    public static Map<id,Case> getParentCaseMap(set<id> targetList){
        system.debug('Target List'+targetList);
        return new  Map<id,Case>([
            SELECT id , AccountId, BusinessHoursId, State__c, Status, BillingState__c, Product_Type_OOP__c, OwnerId, Cust_Type__c, Product__c,FAN__c, AllChildCasesClosed__c,
                (SELECT id , name, Submission_Source__c, Case__c, Is_Closed__c, Status__c FROM Child_Actions__r)
            FROM Case
            WHERE id in :targetList]);
            
    }
    public static Id getAssignmentQueueId(string targetName, string region){
        string returnValue;
        set<string> queueNames = new set<string>();
        Map<string,string> regionMap = getRegionMap();

        if(regionMap.containsKey(region)){
            queueNames.add(targetName + '_' + regionMap.get(region));
            returnValue = ([
            SELECT Id
            FROM Group
            WHERE  Type = 'Queue'
            AND developerName in :queueNames])?.Id;
        }
        if(returnValue == null){
            queueNames.add(targetName);
            returnValue = ([
            SELECT Id
            FROM Group
            WHERE  Type = 'Queue'
            AND developerName in :queueNames])?.Id;
        }
        return  returnValue;
    }
    //RecordTypeId =: Case_Action_Constants.RESPONSE_RECORDTYPE_ID AND
    public static Map<id,Case> getParentCaseWithOpenChildrenMap( set<Id> ParentCases){
        return new Map<id,Case>( [SELECT Id, Status,
        (SELECT Id , Resolution__c FROM Child_Actions__r WHERE Is_Closed__c = TRUE AND  Resolution__c =: Case_Action_Constants.RESPONSE_SENT)
        FROM Case WHERE Status =: Case_Action_Constants.PENDING_CLOSED AND Id IN :ParentCases]);
    }
    public static Case_Action__c createResponseCaseAction(Case parentCase){


        Case_Action__c responseCaseAction = new Case_Action__c();
        responseCaseAction.RecordTypeId = Case_Action_Constants.RESPONSE_RECORDTYPE_ID;
        responseCaseAction.Status__c = CaseConstants.NEW_STATUS;
        responseCaseAction.Case__c = parentCase.Id;
        String referredBy, referenceData ;
        String Subject = 'Response: ';

        if ((parentCase?.ReferredByFirstName__c) == null){referredBy = ' ';}
        else {referredBy = parentCase?.ReferredByFirstName__c + ' ' + parentCase?.ReferredByLastName__c;}
        if ((parentCase.ReferenceData__c) == null){referenceData = ' ';}
        else {referenceData = parentCase?.ReferenceData__c ;}
        Subject =  Subject + referenceData + ' - ' + referredBy;
        responseCaseAction.Subject__c =    Subject;
        responseCaseAction.Description__c = parentCase.Description;
        responseCaseAction.Name = parentCase.CaseNumber;
        responseCaseAction.Customer__c = parentCase.AccountId;
        responseCaseAction.Region__c = parentCase.Action3__c;
        //we only want to grab the first product in the case product field if applicable

        String state = String.isNotBlank(parentCase?.State__c) ? parentCase?.State__c : parentCase?.BillingState__c;
        responseCaseAction.Expected_Close_Date__c = Case_Action_Trigger_Helper.setExpectedCloseDate(parentCase.SubmissionSourceCode__c, state, parentCase.BusinessHoursId);

        // translate the "Effective Customer Type" to match what is in the quick-action
        // if "Effective Customer Type" is "Consumer" or "Non AT&T Customer", then use it as-is, otherwise use "Business"
        String custType = (parentCase?.Cust_Type__c.equalsIgnoreCase('Consumer') || parentCase?.Cust_Type__c.equalsIgnoreCase('Non AT&T Customer') ? parentCase?.Cust_Type__c : 'Business');
        //set cust type and product
        responseCaseAction.Customer_Type_n_Product__c = custType + ' | ' + (String.isEmpty(parentCase?.Product__c) ? '' : parentCase?.Product__c.split(';')[0]);
        responseCaseAction = assignResponseCase(responseCaseAction,parentCase);
        system.debug('response Case Action logic: ' + responseCaseAction);
        return responseCaseAction;
    }
    /**
     * This method is used to set the owner of the 'Response' Case Action.
     * See SPTSFDCSPT-5841 for details.
     */
    public static Case_Action__c assignResponseCase(Case_Action__c response , case parent) {
        // NOTE: mapping is based solely on the product in the child case (example parent has Wireless and DIRECTV,
        // if child product is wireless then Mobility, if child has DIRECTV then assign to parent case owner)

        // if has mobility product and FAN is populated, assign to Regulatory Response Mobility queue
        String queueName; //= 'OOPRegRespOther'
        //system.debug(response.Customer_Type_n_Product__c.substringAfterLast ('|').trim());
        //system.debug(response.Customer_Type_n_Product__c.substringAfterLast ('|'));
        // NOTE: Video product is defined as DIRECTV, DIRECTV Legacy, AT&T TV
        if(response.Customer_Type_n_Product__c != null && Case_Action_Constants.VIDEO_PRODUCT_LIST.contains(response.Customer_Type_n_Product__c.substringAfterLast ('|').trim()))
        {
            response.OwnerId = parent.OwnerId;
            response.OwnerId = parent?.OwnerId;
        }
        else
        {
            // Included and Modified Action1__c checks as per SPTSFDCSPT-2170 - SALESFORCE
            //check Product , Customer type and FAN with Action1 = Interim or Just Respinse

            if(ChildCaseHelper.hasMobilityProduct(parent.Product__c) && parent.Cust_Type__c == Case_Action_Constants.Consumer
           && String.isBlank(parent.FAN__c)) {
                queueName = (parent.Status.equalsIgnoreCase(Case_Action_Constants.PENDING_CLOSED)? Case_Action_Constants.OOPRegResMobility : Case_Action_Constants.OOPInterimRegResMobility);
            }
            //if its not a mobility product then based on action1 = interim response assigns to Interim Reg Response other queue
            else{
                queueName = (parent.Status.equalsIgnoreCase(Case_Action_Constants.PENDING_CLOSED) ? Case_Action_Constants.OOPRegRespOther : Case_Action_Constants.OOPInterimRegResOther );
            }

            Id queueId = MetadataSelector.queueToDeveloperName_Map.get(queueName)?.Id;
            if(String.isNotBlank(queueId)) {
                response.OwnerId = queueId;
                response.Work_Group__c = queueName;
            }
        }

        return response;
    }
    private static Map<string,string> getRegionMap(){

        Map<string,string> returnMap = new Map<string,string>{
            //'All' => '',
            'Midwest' => 'MW',
            'Out of Region' => 'OOR',
            'Southeast' => 'SE',
            'Southwest' => 'SW',
            'West' => 'W'
        };
        return returnMap;
    }

}
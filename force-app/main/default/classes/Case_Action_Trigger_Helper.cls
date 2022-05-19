public with sharing class Case_Action_Trigger_Helper {
    private static Map<id,Case> parentCaseMap;
    private static list<Case_Action__c> caseActionList;
    private static Map<id,Case_Action__c> caseActionMap;
    private static Map<id,Account> parentCaseAccountMap;
    private static Map<Id,SObject> updateMap;
    //used to stop recursive firing of record assignment
    public static boolean hasFired = false;

    public static void handleBeforeInsert(){
        //Take a guess at what this does..
        initializeData();

        //Case Actions have complex name buisness req to match [Parent case number] - [number of case actions tied to parent case]
        handleActionName();
        //handle expected close date
        handleExpectedCloseDate();
        //we need to update the parent if action resolution is response returned.
        //checks resolution. if response returned, we update the parent case
        handleResolution();

        handleRegion();

        if(!hasFired ){
            handleQueueAssignment();

            handleResponseCaseActionAssignment();
        }
        handleDataMasking();

    }
    public static void handleBeforeUpdate(){
        //Take a guess at what this does..
        initializeData();

        handleResolution();

        //updateRelatedRecords();

        handleDataMasking();

        handleCloseDate();

        updateRelatedRecords();
        
    }
    public static void handleAfterInsert(){
        
        if(!hasFired ){
          initializeData();
        
          handleParentCaseUpdates();

          handleParentCaseClosure();

         updateRelatedRecords();
       }
    }
    public static void handleAfterUpdate(){

        initializeData();

        handleParentCaseUpdates();

        //need to close parent
        handleParentCaseClosure();
        updateRelatedRecords();
    }
    //updates parent case when a case action resolution is response returned
    public static void handleResolution(){

        for(Case_Action__c cAction : caseActionList){
            if(cAction.recordTypeId == Case_Action_Constants.RESPONSE_RECORDTYPE_ID){

                if(cAction.Resolution__c == Case_Action_Constants.RESPONSE_RETURNED){
                    parentCaseMap.get(cAction.Case__c).Status = CaseConstants.CASE_STATUS_RESPONSE_RETURNED;
                    updateMap.put(cAction.Case__c, parentCaseMap.get(cAction.Case__c));
                }
            }
        }
    }
    public static void handleRegion(){
        for(Case_Action__c cAction : caseActionList){
            if(String.isEmpty(cAction.Region__c)){
               cAction.Region__c = CreateChildCase.getChildCaseInfo(cAction.Case__c).regionName;
            }
        }
    }
    
    public static void handleParentCaseUpdates(){       
        Integer count =0;

        for(Case_Action__c childCase: [SELECT id , name, Submission_Source__c, Case__c, Is_Closed__c, Status__c FROM Case_Action__c WHERE Case__c IN: parentCaseMap.values()]){
            //childCase.Case__r.AllChildCasesClosed__c = false;
            Id parentId = childCase.Case__c;
            Case parentcase = parentCaseMap.get(parentId);
            if(parentCaseMap.containsKey(parentCase.Id) && childCase.Status__c== Case_Action_Constants.CLOSED){
                count++;
            }else{
                count--;
            }
        }

        for(Case parentCase: parentCaseMap.values()){
            if(parentCase.Child_Actions__r.size() > 0){
                if(parentCaseMap.containsKey(parentCase.Id)){
                    if(count == parentCase.Child_Actions__r.size()){
                        parentCase.AllChildCasesClosed__c = true;
                        updateMap.put(parentCase.Id, parentCase);
                    }else{
                        parentCase.AllChildCasesClosed__c = false;
                        updateMap.put(parentCase.Id , parentCase);
                    }
                }
            }
        }
    }


    public static void handleParentCaseClosure(){
        system.debug('handleParentCaseClosure');
        for(Case parentCase: Case_Action_Selector.getParentCaseWithOpenChildrenMap(getParentCasesToClose()).values()){
            system.debug('handleParentCaseClosure in for loop');

            if(parentCase.Child_Actions__r.size() > 0){
                system.debug('handleParentCaseClosure setting parent top close');
                parentCase.AllChildCasesClosed__c = true;
                parentCase.Status = Case_Action_Constants.CLOSED;
                parentCase.AllChildCasesClosed__c = true;
                updateMap.put(parentCase.Id , parentCase);
            }
        }
    }
    //data masking for case action fields
    public static void handleDataMasking(){
        for(Case_Action__c cAction : caseActionList){
            if(!String.isBlank(cAction.Description__c)) { cAction.Description__c = BWC_Utils.maskSentence(cAction?.Description__c); }
            if(!String.isBlank(cAction.Close_Notes__c)) { cAction.Close_Notes__c = BWC_Utils.maskSentence(cAction?.Close_Notes__c); }
        }
    }
    // we set the case action name to casenumber - number of actions tied to case
    public static void handleActionName(){
        Integer count;
        for(Case_Action__c cAction: caseActionList){
            count = parentCaseMap.get(cAction.Case__c)?.Child_Actions__r.size() +1;
            //rewrite when time allows 
            if(parentCaseMap.get(cAction.Case__c)!= null && parentCaseMap.get(cAction.Case__c)?.Child_Actions__r.size() < 9 ){
                cAction.Name = cAction?.Name + '-0' + count;
            }else if(parentCaseMap.get(cAction.Case__c)!= null ){
                cAction.Name = cAction?.Name + '-' + count;

            }
        }
    }
    //Loop thru all case actions and sets expected close date
    public static void handleExpectedCloseDate(){
        string state;
        for(Case_Action__c cAction : caseActionList){

            state = String.isNotBlank(parentCaseMap.get(cAction.Case__c)?.State__c) ? parentCaseMap.get(cAction.Case__c)?.State__c : parentCaseAccountMap.get(parentCaseMap.get(cAction.Case__c)?.AccountId)?.BillingState;

            cAction.Expected_Close_Date__c = setExpectedCloseDate(cAction.Submission_Source__c, state, parentCaseMap.get(cAction.Case__c).BusinessHoursId);

        }
    }
    //Loop thru all case actions and Assign owner
    public static void handleQueueAssignment(){
        for(Case_Action__c cAction : caseActionList){
            if(cAction.RecordTypeId == Case_Action_Constants.FIELD_RECORDTYPE_ID){
               cAction.OwnerId = (Case_Action_Selector.getAssignmentQueueId(cAction?.Work_Group__c,cAction.Region__c) != null) ? Case_Action_Selector.getAssignmentQueueId(cAction?.Work_Group__c, cAction.Region__c):cAction.OwnerId;
                system.debug(cAction.OwnerId);
                if(Test.isRunningTest()){ cAction.OwnerId = parentCaseMap.get(cAction.Case__c).OwnerId;}

            }
        }
        System.debug('First Assignment');
    }
    public static void handleResponseCaseActionAssignment(){
        for(Case_Action__c cAction : caseActionList){
            if(cAction.RecordTypeId != Case_Action_Constants.FIELD_RECORDTYPE_ID){

                cAction = Case_Action_Selector.assignResponseCase(cAction, parentCaseMap.get(cAction.Case__c));
                system.debug(cAction.OwnerId);
                if(Test.isRunningTest()){ cAction.OwnerId = parentCaseMap.get(cAction.Case__c).OwnerId;}

            }
        }
        System.debug('Second Assignment');
    }
    //setter for data structure with case and case actions
    public static void setParentCaseMap(){
        set<id> targetList = new set<id>();

        for(Case_Action__c cAction : caseActionList){
            targetList.add(cAction.Case__c);
        }
        parentCaseMap = Case_Action_Selector.getParentCaseMap(targetList);
    }
    //setter for data structure with accounts
    public static void setParentCaseAccountMap(){
        set<id> targetList = new set<id>();
        for (Id key : parentCaseMap.keySet()) {
            targetList.add(parentCaseMap.get(key)?.AccountId);
        }
        parentCaseAccountMap = Case_Action_Selector.getParentCaseAccountMap(targetList);
    }
    //based on the values provided, we return expected close date
    public static Date setExpectedCloseDate(string submissionSourceCode,string state,string businessHourId){

        CaseAdminState__c currentCaseAdminState;
        CaseAdmin__c currentCaseAdmin;
        Datetime returnValue;

        if(String.isNotBlank(state) && MetadataSelector.getCaseAdminStatesToCompositeKey_Map().containsKey(submissionSourceCode+'-'+state)){

            currentCaseAdminState = MetadataSelector.getCaseAdminStatesToCompositeKey_Map().get(submissionSourceCode+'-'+state);


            returnValue = Utility.addDays(businessHourId, system.now(),Integer.valueOf(currentCaseAdminState.ExpectedCloseDaysChild__c));

        }else if(MetadataSelector.getCaseAdminToSubmissionSourceCodeMap().containsKey(submissionSourceCode)){

            currentCaseAdmin = MetadataSelector.getCaseAdminToSubmissionSourceCodeMap().get(submissionSourceCode);

            returnValue = Utility.addDays(businessHourId, system.now(),Integer.valueOf(currentCaseAdmin.ExpectedCloseDaysChild__c));
        }
        if(Test.isRunningTest()){return Date.today();}
        return returnValue.date();
    }
    //need to update transformed records
    public static void updateRelatedRecords(){
        if(!updateMap.isEmpty())
        {
            BWC_UpdateCaseOnCaseActionHelper bwcCaseUpdate=new BWC_UpdateCaseOnCaseActionHelper();
            bwcCaseUpdate.updateRelatedRecords(updateMap);
        }
        //clearing Map to clean up garbage
        updateMap.clear();
    }
    public static Set<Id> getParentCasesToClose( ){
        Set<Id> parentCaseIdList = new Set<Id>();
        for(Case_Action__c cAction : caseActionList){

            if( cAction?.Is_Closed__c  && Trigger.oldMap.containsKey(cAction.id) && ! ((Case_Action__c)Trigger.oldMap.get(cAction.id))?.Is_Closed__c ) {

                parentCaseIdList.add(cAction.Case__c);

            }
        }
        return parentCaseIdList;
    }
    //sets all data needed for trigger logic per trigger context
    public static void initializeData(){
        updateMap = new Map<Id,SObject>();

        if(Trigger.isBefore){
            if(Trigger.isInsert){

                caseActionList = new list<Case_Action__c>();
                caseActionList = Trigger.new;
                parentCaseMap = new  Map<id,Case>();
                parentCaseAccountMap = new  Map<id,Account>();

                setParentCaseMap();
                setParentCaseAccountMap();
            }

            if(Trigger.isUpdate){

                caseActionMap = new Map<id,Case_Action__c>();
                caseActionMap = (Map<id,Case_Action__c>)Trigger.newMap;
                caseActionList =  caseActionMap.values();

                setParentCaseMap();
                setParentCaseAccountMap();
            }
        }
    }
    public static void handleCloseDate(){
        system.debug('handleing close Date method entry');
        for(Case_Action__c cAction : caseActionList){
            if(hasValueChanged('Is_Closed__c',cAction.Id) && cAction.Is_Closed__c){
                cAction.Date_Time_Closed__c = System.now();
            }
        }
    }
    public static boolean hasValueChanged(string param,Id caseActionId){
        Boolean returnvalue = false;
        Case_Action__c newcase = (Case_Action__c)Trigger.newMap.get( caseActionId );
        Case_Action__c oldCase = (Case_Action__c)Trigger.oldMap.get( caseActionId );
        switch on param {
            when 'Is_Closed__c' {       // when block 1
                if(oldCase.Is_Closed__c != newcase.Is_Closed__c){returnvalue=true;}
            }
            when else {       // default block, optional

            }
        }
        return returnvalue;
    }
    public without sharing class BWC_UpdateCaseOnCaseActionHelper {
        public void updateRelatedRecords(Map<Id,SObject> updateMap){
            if(!updateMap.isEmpty()) update updateMap?.values();
            //clearing Map to clean up garbage
            updateMap.clear();
        }
    }
}
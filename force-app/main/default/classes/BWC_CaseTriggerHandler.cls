public inherited sharing class BWC_CaseTriggerHandler extends SFS_TriggerHandler {
        
        private static List<Case> OOPCase_List;
        private static Map<ID, Account> accountToAccountId_Map;
        private static List<Case> caseToShare_List;
        /**
         * This will run before insert or before update, before all other methods.
         * Use this only when you need to validate some critical values before any calculation is done.
         * Otherwise, let normal field validation flag problems with values.
         * @param records The list of trigger records. Use this instead of Trigger.new.
         */
        protected override void calculate(List<SObject> records) {
            List<Case> listCases = (List<Case>)records;
            Map<Id, Case> mapOldCase = (Map<Id, Case>)oldMap;
            List<Case> caseList = (List<Case>)records;
            // Mask Description and Case close notes
            for(Case currCase : listCases) {
                    // If insert or Description is changing on Update, mask the content
                    if (currCase.Description != null && (mapOldCase == null || isChangedField(currCase, Case.Description))) {
                        currCase.Description = BWC_Utils.maskSentence(currCase.Description);
                    }
                    // If insert or CloseNotes__c is changing on Update, mask the content
                    if ( currCase.recordTypeId != MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.ESCALATION_RECORD_TYPE).ID 
                        && currCase.CloseNotes__c != null && (mapOldCase == null ||isChangedField(currCase, Case.CloseNotes__c))) {
                            currCase.CloseNotes__c = BWC_Utils.maskSentence(currCase.CloseNotes__c);
                        }
                    if (currCase.Comments != null && (mapOldCase == null || isChangedField(currCase, Case.Comments))) {
                        currCase.Comments = BWC_Utils.maskSentence(currCase.Comments);
                    }
            }
            
            if(isBefore!=null && isUpdate!=null)	
            {
                if(isBefore && isUpdate)
                {
                //Make sure not to execute the logic when it comes from a batch job - ParentChildCaseBatch
                if(!system.isBatch()){ 
                    Set<ID> accountId_Set = new Set<ID>();
                    OOPCase_List = new List<Case>();
                    List<Case> responseCaseList = new List<Case>();
                    List<Case_Action__c> responseCaseActionList = new List<Case_Action__c>();
                    List<Case> closingParentCases = new List<Case>();
                    List<Case> pendingParentCases = new List<Case>();
                    List<Case> mergingCases = new List<Case>();
                    List<Case> masterCases = new List<Case>();
                    List<Case> casesWOFirstInteraction = BWC_CreateInteraction.filterCasesWOInteraction((List<Case>)records);
                    List<Case> casesWAccountUpdated = BWC_CreateInteraction.filterUpdatedAccCases((Map<Id, Case>)newMap , (Map<Id, Case>)oldMap);
                    Id escalationRectypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(CaseConstants.ESCALATION_RECORD_TYPE).getRecordTypeId();
                    String escalationRtId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.ESCALATION_RECORD_TYPE).ID;
                    Set<Id> queueIds = new Set<Id>();
                    List<Case> workGroupCases = new List<Case>();
                    List<Case> tier2Cases = new List<Case>();
                    Set<String> queueNames = new Set<String>();
           
            	//for escaltion cases when closed copy Comments info to Close Notes field
            	for(Case currentCase : (List<Case>)records){
                    if(currentCase.Status == CaseConstants.MERGED_STATUS) {
                        mergingCases.add(currentCase);
                    } else if(currentCase.Id == CaseMergeHelper.sMasterRecordId) {
                        masterCases.add(currentCase);
                    }
                    //for escaltion cases when closed copy Comments info to Close Notes field
                    if(currentCase.recordTypeId == escalationRtId && currentCase.Status == CaseConstants.CLOSED_STATUS && String.isNotBlank(currentCase.Comments)){
                        currentCase.CloseNotes__c = currentCase.Comments;
                    }
                
                    if(currentCase.recordTypeId == escalationRtId 
                    && !String.isBlank(currentCase.Type)  
                    && isChangedField(currentCase, Case.Type)){
                        currentCase.subject =  currentCase.Type + ' ' + currentCase.CaseCategory__c;
                    }
                
                    //4558 user story - when OOP case is closed or Pending Closed then it should have only one product 
                    if(currentCase.recordTypeId == MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RECORD_TYPE).ID ||
                    currentCase.recordTypeId == MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_CLOSED_READ_ONLY_RECORD_TYPE).ID){
                        if((currentCase.Status == CaseConstants.CASE_STATUS_CLOSED || currentCase.Status == CaseConstants.CASE_STATUS_PENDING_CLOSED) && isChangedField(currentCase, Case.Status) && currentCase.Product__c.contains(';')){       
                                addError(currentCase,System.Label.Case_OPP_Closed); 
                            }
                    }    
                
                    if(currentCase.recordTypeId == MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RECORD_TYPE).ID){                
                        if((isChangedField(currentCase, Case.State__c)&& (String.isBlank(currentCase.State__c)|| MetadataSelector.getCaseAdminStatesToCompositeKey_Map().containsKey(currentCase.SubmissionSourceCode__c+'-'+currentCase.State__c)))|| (String.isNotBlank(currentCase.SubmissionSourceCode__c)
                   			 && isChangedField(currentCase, Case.SubmissionSourceCode__c))){
                            currentCase.AdminCloseDate__c=null;
                            currentCase.AdminResponseDate__c=null;
                            OOPCase_List.add(currentCase);
                        }
                    	else if((currentCase.AdminCloseDate__c!=null && isChangedField(currentCase, Case.AdminCloseDate__c))
                            || (currentCase.AdminResponseDate__c!=null && isChangedField(currentCase, Case.AdminResponseDate__c))){
                                if(currentCase.AdminCloseDate__c!=null && isChangedField(currentCase, Case.AdminCloseDate__c)){
                                    currentCase.ExpectedCloseDate__c = currentCase.AdminCloseDate__c;
                                }
                                if(currentCase.AdminResponseDate__c!=null && isChangedField(currentCase, Case.AdminResponseDate__c)){
                                    currentCase.ExpectedResponseDate__c =  currentCase.AdminResponseDate__c;
                                }
                            }
                        // show error when eligibility is not met to open closed case
                   		 if(isChangedField(currentCase, Case.OwnerId)){
                            if(MetadataSelector.checkUserEligibilityToOpenClosedCase()){
                                return;
                            }
                            addError(currentCase,System.Label.TransferCaseError);
                        }
                    // parent closure with open child cases
                    if((currentCase.Status.equalsIgnoreCase(CaseConstants.CASE_STATUS_CLOSED) || currentCase.Status.equalsIgnoreCase(CaseConstants.CASE_STATUS_CANCELLED))
                    && currentCase.recordTypeId == MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RECORD_TYPE).ID
                    && isChangedField(currentCase, Case.Status)) { 
                        closingParentCases.add(currentCase);
                        ChildCaseHelper.preventClosureWithOpenChildCases(currentCase);
                    }
                    else if(currentCase.Status.equalsIgnoreCase(CaseConstants.PENDING_CLOSED_STATUS)
                            && currentCase.recordTypeId == MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RECORD_TYPE).ID
                            && isChangedField(currentCase, Case.Status)){
                            pendingParentCases.add(currentCase);
                            responseCaseActionList = ChildCaseHelper.handlePendingClosureVersion2(currentCase);
                            if(responseCaseActionList.size()>0) currentCase.AllChildCasesClosed__c = false;
                    }
                        
                Map<ID,Case> oldMap = ((Map<ID,Case>)(oldMap));
                if(((currentCase.Status.equalsIgnoreCase(CaseConstants.CASE_STATUS_CLOSED)&& oldMap!=null && isChangedField(currentCase, Case.status))||(currentCase.Status.equalsIgnoreCase(CaseConstants.CASE_STATUS_IN_PROGRESS) 
                    && oldMap!=null  && oldMap.get(currentCase.ID).Status.equalsIgnoreCase(CaseConstants.CASE_STATUS_CLOSED))) && MetadataSelector.getCaseAdminToSubmissionSourceCodeMap()!=null
                && MetadataSelector.getCaseAdminToSubmissionSourceCodeMap().containsKey(currentCase.SubmissionSourceCode__c)){
                    currentCase.SendCommunication__c = MetadataSelector.getCaseAdminToSubmissionSourceCodeMap().get(currentCase.SubmissionSourceCode__c).SendCommunication__c;
                }
                }
                CaseBusinessProcess.validateStatusChange(currentCase);
                if(String.isNotBlank(currentCase.Status) && String.isNotBlank(((Case)oldMap.get(currentCase.ID)).Status)&& !currentCase.Status.equalsIgnoreCase(CaseConstants.CLOSED_STATUS)
           		 && ((Case)oldMap.get(currentCase.ID)).Status.equalsIgnoreCase(CaseConstants.CLOSED_STATUS)&& MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_CLOSED_READ_ONLY_RECORD_TYPE).ID == currentCase.RecordTypeId) {
                currentCase.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RECORD_TYPE).ID;
            	}
                if(String.isNotBlank(currentCase.Status) && String.isNotBlank(((Case)oldMap.get(currentCase.ID)).Status)&& !currentCase.Status.equalsIgnoreCase(CaseConstants.CASE_STATUS_CANCELLED)
           		 && ((Case)oldMap.get(currentCase.ID)).Status.equalsIgnoreCase(CaseConstants.CASE_STATUS_CANCELLED)&& MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_CLOSED_READ_ONLY_RECORD_TYPE).ID == currentCase.RecordTypeId) {
                currentCase.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RECORD_TYPE).ID;
            	}
                CaseBusinessProcess.populateAddress(currentCase);        
                //Queue Owner checks
                if(currentCase.RecordTypeId == escalationRtId){
                    // determine if we should assign the case based on the Tier 2 pick-list
                    // if Tier 2 is not null AND Routing Action is Pre/Post-Dispatch AND (Routing Action changed OR Tier 2 has changed)
                    if (currentCase.Tier2__c != Null &&
                        (currentCase.RoutingAction__c.equalsIgnoreCase(CaseConstants.ROUTE_ACTION_TIER_PRE) || (currentCase.RoutingAction__c.equalsIgnoreCase(CaseConstants.ROUTE_ACTION_TIER_POST))) &&
                        (isChangedField(currentCase, Case.RoutingAction__c) || isChangedField(currentCase, Case.Tier2__c)))
                    {
                        tier2Cases.add(currentCase);
                        queueNames.add(currentCase.Tier2__c);
                    }
                }
                //checking to see if we need to fire SLA 2 case mapping logic
                if(!BWC_SLA_Entitlement.doesCaseHaveMilestones(currentCase.Id) && currentCase.recordTypeId == MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.ESCALATION_RECORD_TYPE).ID)
                {
                    currentCase.EntitlementId = BWC_SLA_Entitlement.handleSLA(currentCase.Type);
                }
                // SPTSFDCSPT - 9879, auto Update case status to New whenever the Owner is changed to user or Queue
                if(isChangedField(currentCase, Case.OwnerId) && currentCase.recordTypeId == escalationRectypeId && CurrentCase.Type == CaseConstants.CASE_TYPE_BILLING_ADJUSTMENT) {
                    currentCase.Status = CaseConstants.NEW_STATUS;     
                }
            }
            
            if(accountId_Set.size()>0){
                fetchParentAccounts(accountId_Set);
            }

            if(responseCaseActionList.size() > 0) {
                ChildCaseHelper.insertResponseCases(responseCaseActionList);
            }
            
            if(OOPCase_List!=null && OOPCase_List.size()>0){
                CaseBusinessProcess.populateDates(OOPCase_List);
            }
            
            if(mergingCases.size() > 0) {
                CaseMergeHelper.validateMerge(mergingCases);
            }
            
            if(masterCases.size() > 0) {
                for(Case masterCase: masterCases) {
                    CaseMergeHelper.updateMergedDates(masterCase);
                }
            }
            
            if(!casesWOFirstInteraction.isEmpty()){
                BWC_CreateInteraction.createInteractionFromCases(casesWOFirstInteraction);
            }
            
            if(!casesWAccountUpdated.isEmpty()){
                BWC_CreateInteraction.updateInteractionsFromCases(casesWAccountUpdated);
            }
            }
                // Set Product_Type_OOP__c field on case update,updated product is any of Video product then fill this value as video ,if not make this value as blank
                String metadataVideoProducts = [SELECT Products__c FROM OOP_Case_Owner_Queue_Assignment__mdt where Queue__c = :CaseConstants.OOP_QUEUE_DTVINTAKE LIMIT 1].Products__c;
                set<String> metadataProducts = new set<String>(metadataVideoProducts.Split(';'));
                ID oopRecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RECORD_TYPE).Id;
                for(Case caseRec:caseList){
                    if(caseRec.RecordTypeId == oopRecordTypeId){
                        set<String> caseProducts = string.isBlank(caseRec.Product__c)?new Set<string>():new set<String>(caseRec.Product__c.split(';'));
                        Boolean videoProduct = false;
                        for(String productName:caseProducts){
                            if(String.isNotBlank(productName) && metadataProducts.contains(productName)) {
                                videoProduct = true;
                            }
                            else{
                                videoProduct = false; 
                                break;
                            }
                        }
                        if(videoProduct){
                            caseRec.Product_Type_OOP__c = CaseConstants.CASE_VIDEO_TYPE_OF_OOP;
                        }
                        else{
                            caseRec.Product_Type_OOP__c = '';
                        }
                    }
                }
            }
        }
    } // End of Before insert or Before update
    
        /**
         * This will run only before insert.
         * Use this when you need to do some action only before a record is inserted.
         * @param records  The list of trigger records. Use this instead of Trigger.new.
         */ 
    	 //filter case with record type : OOP - OOP Case
        protected override void initialize(List<SObject> records) {
            Set<ID> accountId_Set = new Set<ID>();
            OOPCase_List = new List<Case>();
            List<Case> webToCaseList = new List<Case>();
            List<Case> oopResponseCaseList = new List<Case>();
            Set<Id> billingAcctIds = new Set<Id>();
            List<Case> caseswithBillAcct = new List<Case>();
            
            //filter case with record type : OOP
            for(Case currentCase : (List<Case>)records){
                //OOP RT Case
                if(currentCase.recordTypeId == MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RECORD_TYPE).ID ){
                    if(currentCase.ParentId==null){
                        currentCase.AdminCloseDate__c=null;
                        currentCase.AdminResponseDate__c=null;
                        currentCase.BusinessHoursId = MetadataSelector.oopBusinessHourId;
                        OOPCase_List.add(currentCase);
                        if(String.isBlank(currentCase.State__c) && currentCase.AccountId!=null){
                            accountId_Set.add(currentCase.AccountId);
                        }
                    }
                    if(currentCase.Billing_Account__c!= Null){
                        billingAcctIds.add(currentCase.Billing_Account__c);
                        caseswithBillAcct.add(currentCase);
                    }
                }// OOP RT Case ends..
                //Getting the List of Case created from Web	
                if(currentCase.Origin == CaseConstants.WEB_FORM) {
                    webToCaseList.add(currentCase);
                }
                CaseBusinessProcess.populateAddress(currentCase);
            }//for ends -- iteration over new records

                if(accountId_Set.size()>0){
                    fetchParentAccounts(accountId_Set);
                }
            
                if(OOPCase_List!=null && OOPCase_List.size()>0){
                    populateDates(OOPCase_List);
                }
            //Update web to case billing information
            if(webToCaseList.size() > 0) {
                for(Case currentCase : webToCaseList) {
                if(currentCase.Origin == CaseConstants.WEB_FORM) {
                    currentCase.ServiceEmail__c = currentCase.SuppliedEmail;
                    currentCase.BillingCity__c = currentCase.City__c;
                    currentCase.BillingCountry__c = currentCase.Country__c;
                    currentCase.BillingCustFirstName__c = currentCase.ServiceCustFirstName__c;
                    currentCase.BillingCustLastName__c = currentCase.ServiceCustLastName__c;
                    currentCase.BillingEmail__c = currentCase.ServiceEmail__c;
                    currentCase.BillingPhone__c = currentCase.ServicePhone__c;
                    currentCase.BillingState__c = currentCase.State__c;
                    currentCase.BillingStreet__c = currentCase.StreetName__c;
                    currentCase.BillingZip__c = currentCase.ZipPostalCode__c;
                    if(!String.isNotBlank(currentCase.SubmissionSourceCode__c) && String.isBlank(currentCase.RecordTypeId)) {
                        // Case Default Owner may prevent record type
                        currentCase.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RECORD_TYPE).ID;
                    }
                    Schema.DescribeFieldResult fieldResult = Case.Language.getDescribe();
                    List<Schema.PicklistEntry> pleList = fieldResult.getPicklistValues();
                    for(Schema.PicklistEntry ple:pleList) {
                        if(ple.getLabel() == currentCase.LanguagePreference__c) {
                            currentCase.Language = ple.getValue();
                            break;
                        }
                    }
                }
            }
            } // End of Web to case billing information
            
            //logic to populate routing override for OOP
            if(billingAcctIds.size()>0){
                Map<Id,Integer> billingAcctWithCaseCount = DaysToClose.getBillingAcctCasesCount(billingAcctIds);
                    if(billingAcctWithCaseCount.size()>0){
                        for(Case c: caseswithBillAcct){
                            if(billingAcctWithCaseCount.containsKey(c.Billing_Account__c)){
                                c.Routing_Override__c = CaseConstants.CASE_ROUTING_OVERRIDE_INTAKE;
                            }
                        }
                    } 
            }   
            //Populating order fallout escalation case details when a case is getting created from Mule.
            Profile userProfile = getIntegrationProfile();
            List<Case> newCaseList = new List<Case>();
            List<Case> caseList = (List<Case>)records;
            for(Case currentCase : caseList){
                if(currentCase.Type != NULL && currentCase.Type == CaseConstants.CASE_TYPE_ORDER_FALLOUT){
                    newCaseList.add(currentCase);
                }
            }
            
            if(UserInfo.getProfileId() == userProfile.Id && !newCaseList.isEmpty()){
            Set<Id> casebillingAcctIds = new Set<Id>();
            //filter case with record type : Escalation
            	for(Case eCase : (List<Case>)records){
                //Escalation RT Case
                	if(eCase.recordTypeId == MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.ESCALATION_RECORD_TYPE).ID ){
                        if(eCase.Billing_Account__c!= Null){
                            casebillingAcctIds.add(eCase.Billing_Account__c);
                        }
                    eCase.CaseCategory__c = CaseConstants.CASE_CATEGORY;
                    if(casebillingAcctIds.size()>0){
                        Asset assetRetrieved = getAssets(casebillingAcctIds);
                        Map<Id, Plan__c> planMapRetrieved = new Map<Id, Plan__c> (BWC_Plan_Selector.getPlansForBillingAccounts(casebillingAcctIds));
                        Map<Id,Billing_Account__c> baMapRetrieved = new Map<Id,Billing_Account__c>([Select id,Fan_Name__c,Fan_Id__c,Account_Type__c, Billing_Account_Number__c  FROM Billing_Account__c where ID IN:casebillingAcctIds]);
                       
                        if (assetRetrieved != null) {
                            eCase.Anchor_CTN__c = assetRetrieved.Phone_Number__c;
                            eCase.Mobile_Number_MDN__c = assetRetrieved.Phone_Number__c;
                            eCase.Mobile_Status__c = assetRetrieved.Status;
                            eCase.User_Subscriber_Name__c = assetRetrieved.User__c;
                                if (assetRetrieved.Plan__c != null) {
                                    eCase.Price_Plan_Code__c = assetRetrieved ?.Plan__r ?.Plan_Price_Code__c;
                                    eCase.Price_Plan_Effective_Date__c = assetRetrieved ?.Plan__r ?.Plan_Effective_Date__c;
                                    eCase.Price_Plan_Description__c = assetRetrieved ?.Plan__r ?.Plan_Name__c;
                                }
                            eCase.User_Subscriber_Name__c = assetRetrieved.User__c;
                            eCase.Sub_Market_Site__c = assetRetrieved.Submarket__c;
                            eCase.Device_Type__c = assetRetrieved.Device_Type__c;
                            eCase.Device_Make_Model__c  = assetRetrieved.Make_And_Model__c;
                            eCase.New_Device_Product_Code__c  = assetRetrieved.Plan__r?.Plan_Code__c;
                            eCase.Device_Manufacturer__c  = assetRetrieved.Manufacturer__c;
                            eCase.Device_IMEI__c  = assetRetrieved.IMEI__c;
                            eCase.SIM_Smart_Chip__c  = assetRetrieved.SIM__c;
                            eCase.Rate_Plan__c  = (assetRetrieved.Plan__r.Billing_Account__c == eCase.Billing_Account__c) ? assetRetrieved.Plan__r.Product__c : '';
                            eCase.Rate_Plan_Code__c   = (assetRetrieved.Plan__r.Billing_Account__c == eCase.Billing_Account__c) ? assetRetrieved.Plan__r.Plan_Code__c : '';
                        	}
                            eCase.EntitlementId = BWC_SLA_Entitlement.handleSLA(eCase.Type);
                        
                        	if(baMapRetrieved.size()>0){
                            eCase.FAN__c = baMapRetrieved.get(eCase.Billing_Account__c).Fan_Name__c;
                            eCase.FAN_Number__c = baMapRetrieved.get(eCase.Billing_Account__c).Fan_Id__c;
                                if (planMapRetrieved.size() > 0) {
                                    eCase.Product__c = BWC_CreateCase.getProductInfo(baMapRetrieved.get(eCase.Billing_Account__c), planMapRetrieved); //ba.Product_Name_360__c; 
                                }
                        }
                    }
                }// Escalation RT Case ends..
            }//for ends -- iteration over new records
        }
       	} // Logic ends for Order Fallout Escalate Case Creation from Mule/API......End of Before Insert
			
        /**
         * This will run only after insert.
         * Use this when you need to do some action only after a record is inserted.
         * @param records  The list of trigger records. Use this instead of Trigger.new.
         */
        protected override void postInsert(List<SObject> records) {
            List<Case> oopCaseForSharing_List = new List<Case>();
            List<Case> oopFieldCase_List = new List<Case>();
            String oopRtId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RECORD_TYPE).ID;
            Set<ID> caseId_Set = new Set<ID>();
            List<Case> escalatedCase_List = new List<Case>();
            Map<Id,Case> interactionCases = new Map<Id,Case>();
            Id escalationRectypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(CaseConstants.ESCALATION_RECORD_TYPE).getRecordTypeId();
            Profile userProfile = getIntegrationProfile();
            List<Case> newCaseList = new List<Case>();
            List<Case> caseList = (List<Case>)records;
            // Filter case after Insert - OOP RT and Escalation RT
            for(Case currentCase : (List<Case>)records){
                if(currentCase.recordTypeId == MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RECORD_TYPE).ID){
                    oopCaseForSharing_List.add(currentCase);
                }
                if(currentCase.recordTypeId == oopRtId){
                    caseId_Set.add(currentCase.ID);
                }
                if(currentCase.Last_Interaction__c != Null){
                    interactionCases.put(currentCase.Id,currentCase);
                }
                if(currentCase.recordTypeId == escalationRectypeId && currentCase.CaseAction__c != null){
                    escalatedCase_List.add(currentCase);
                }
            }
            if(!Test.isRunningTest() && caseId_Set.size()>0){
                system.enQueueJob(new SyncCaseWithAccount(caseId_Set));
            }
            //creation of case interactions
            if(interactionCases.size()>0){
                CaseInteractionUtility.checkCreateCaseInteractions(interactionCases);
            }

            // Update Target Close Date on Case from Case Milestone
            if (escalatedCase_List.size() > 0) {
                updateTargetCloseDate(escalatedCase_List);
            }
            
            //CDEX-82419 - Allowing order fallout escalation case to be routed via case assignment Rules when created via API.
            for(Case currentCase : caseList){
                if(currentCase.Type != NULL && currentCase.Type == CaseConstants.CASE_TYPE_ORDER_FALLOUT){
                    newCaseList.add(currentCase);
                }
            }
            if(UserInfo.getProfileId() == userProfile.Id && !newCaseList.isEmpty()){
                List<Case> escalationCasesAssignment = new List<Case>();
                String escalationRtId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.ESCALATION_RECORD_TYPE).ID;
                // get the recordTypeId from Case Object
                for(Case currentCase : (List<Case>)records) {
                    // Checking escalation cases eligibility for assignment rules
                    if (currentCase.RecordTypeId == escalationRtId && currentCase.CaseAction__c != NULL 
                        && currentCase.RoutingAction__c != NULL && currentCase.RoutingAction__c == CaseConstants.ROUTE_ACTION_TIER_1
                    )
                    {
                        escalationCasesAssignment.add(currentCase);
                    }
                }
                //Assignment Rules Fire
                if(escalationCasesAssignment.size()>0 && CaseConstants.runCheckAssignment){
                    assignmentRuleFire(escalationCasesAssignment);
                }
            } 
        }//End of After Insert
        
        /**
         * This will run only after update (not after insert or delete).
         * Use this when you need to do some action only after a record is updated.
         * @param records  The list of trigger records. Use this instead of Trigger.new.
         */
        protected override void postUpdate(List<SObject> records) {
            //Make sure not to execute the logic when it comes from a batch job - ParentChildCaseBatch
            if(!system.isBatch()){ 
                List<Id> rejectedParentIds = new List<Id>();
                List<Id> parentIdsToClose = new List<Id>();
                List<Id> misdirectedParentIds = new List<Id>();
                Set<ID> caseId_Set = new Set<ID>();
                Map<Id,Case> interactionCases = new Map<Id,Case>();
                Map<ID,Case> oldMap = ((Map<ID,Case>) (oldMap));
                List<Case> escalationCasesAssignment = new List<Case>();
                List<Case> escalatedCase_List = new List<Case>();
                String oopRtId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RECORD_TYPE).ID;
                String escalationRtId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.ESCALATION_RECORD_TYPE).ID;
                Id escalationRectypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(CaseConstants.ESCALATION_RECORD_TYPE).getRecordTypeId();
                //Check if the current case is OOP Record Type and Check Validity for Share
                for(Case currentCase : (List<Case>)records) {
                        if(currentCase.recordTypeId == oopRtId){
                            	Map<ID, Case> oldMapCase = ((Map<ID,Case>)oldMap);
                                if(caseToShare_List==null){
                                    caseToShare_List = new List<Case>();
                                }
                                if(currentCase!=null && Case.OwnerId!=null && isUpdate!=null)
                                {
                                    if( isUpdate && isChangedField(currentCase, Case.OwnerId)){
                                        caseToShare_List.add(currentCase);
                                    }
                                }
                            caseId_Set.add(currentCase.ID);
                            }
                            //Comparing Last interaction field value
                            if(currentCase.Last_Interaction__c != Null &&  isChangedField(currentCase, Case.Last_Interaction__c)){
                                interactionCases.put(currentCase.Id,currentCase);
                            }
                           //Checking escalation cases eligibility for assignment rules
                           if(currentCase.RecordTypeId == escalationRtId &&(isChangedField(currentCase, Case.CaseAction__c) || (isChangedField(currentCase, Case.RoutingAction__c)
                                    && ( currentCase.RoutingAction__c.equalsIgnoreCase(CaseConstants.ROUTE_ACTION_TIER_1)  
                                        && currentCase.Is_Response_Required__c == true )))&& (currentCase.Tier2__c==null && currentCase.Tier3__c == null))
                            {
                                escalationCasesAssignment.add(currentCase);
                            }
                           if(currentCase.recordTypeId == escalationRectypeId && ((isChangedField(currentCase, Case.CaseAction__c) && currentCase.CaseAction__c != null) || 
                            (isChangedField(currentCase, Case.Status) && currentCase.Status == CaseConstants.CLOSED_STATUS) ||(isChangedField(currentCase, Case.External_SLA_Violated__c) && currentCase.External_SLA_Violated__c != null && currentCase.IsClosed == false)))
                            {
                                escalatedCase_List.add(currentCase);
                            }
            		}
            
            if(rejectedParentIds != NULL && rejectedParentIds.size() > 0) {
                ChildCaseHelper.updateRejectedParents(rejectedParentIds);
            }
            
            //creation of case interactions
            if(interactionCases.size()>0){
                CaseInteractionUtility.checkCreateCaseInteractions(interactionCases);
            }
            
            //Assignment Rules Fire
            if(escalationCasesAssignment.size()>0 && CaseConstants.runCheckAssignment){
                assignmentRuleFire(escalationCasesAssignment);
            }
            
            // Update Target Close Date on Case from Case Milestone
            if (escalatedCase_List.size() > 0) {
                updateTargetCloseDate(escalatedCase_List);
            }
         }
        } // End of After Update
    
        /**
         * This will run only after insert or update 
         * Use this when you need to do some action only after a record is inserted or updated.
         * @param records  The list of trigger records. Use this instead of Trigger.new.
         */
        protected override void postUpsert(List<SObject> records) {
            List<Case> newCaseList = (List<Case>)records;
            Map<Id,Case> oldCases = (Map<Id,Case>)oldMap;      
            Id escalationRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get(CaseConstants.ESCALATION_RECORD_TYPE).getRecordTypeId();
            List<Case> cases = new List<Case>();
            List<Case> closedCases = new List<Case>();
            Set<Id> closedCasesBanSet = new Set<Id>();
            //Check if the Case is of Type “Billing | Adjustment”  and Record type is Escalation
            for(Case c: newCaseList) {
                    if(c.RecordTypeId == escalationRecordTypeId && c.Type == CaseConstants.CASE_TYPE_BILLING_ADJUSTMENT &&(isInsert!=null || isUpdate!=null)) {
                    if (isInsert) {
                        cases.add(c);
                    } else if (isUpdate && c.status == CaseConstants.CLOSED_STATUS && isChangedField(c, Case.Status)) {
                        closedCases.add(c);
                        closedCasesBanSet.add(c.Billing_Account__c);
                    }
                }
            }
            //Get the list of Record for which Case Record Type is Escalation and Case is not Closed to get the List of not closed cases for the Ban 
                if (closedCasesBanSet.size() > 0) {
                Map<String, Integer> notClosedCasesPerBANMap = New Map<String, Integer>();
                List<AggregateResult> resultList = [SELECT Billing_Account__c, Status, Count(Id) recordCount  FROM Case WHERE RecordTypeId =:escalationRecordTypeId AND Type =: CaseConstants.CASE_TYPE_BILLING_ADJUSTMENT AND Billing_Account__c IN :closedCasesBanSet AND Status <> 'Closed' GROUP BY Billing_Account__c, Status];
                for (AggregateResult ar : resultList) {
                    notClosedCasesPerBANMap.put((String)ar.get(CaseConstants.BILLING_ACC), (Integer)ar.get(CaseConstants.RECORD_COUNT));
                }
                for (Case cCase : closedCases) {
                    if (!(notClosedCasesPerBANMap.containsKey(cCase.Billing_Account__c) && notClosedCasesPerBANMap.get(cCase.Billing_Account__c) > 0)) {
                        cases.add(cCase);
                    }
                }    
            }
			//Publish the cases using BWC_CaseEvents for the list of records retrieved from Insert and update         
            if(!cases.isEmpty()){
                BWC_CaseEvents.publishEvents(cases);      
            }
        } // End of After Insert or Update
   
//Helper Methods Starts       
        //Get Equipments related to billing account
        public static Asset getAssets(Set<Id> billAcctId) {
            List<Asset> assets = BWC_Asset_Selector.getAssetsForBillingAccounts(billAcctId);
            Asset activeAsset;
            if(assets.isEmpty()){
                return null;
            }
            for (Asset asst : assets) {
                if(asst.Status!= CaseConstants.ASSET_STATUS && activeAsset==null){
                    activeAsset=asst;
                }
                if (asst.Is_Primary__c) {
                    return asst;
                }
            }
            return activeAsset;
        } 
    
        //get ID and name of the Integration profile
    	@TestVisible
        public static Profile getIntegrationProfile()
        {
            Profile userProfile;
            userProfile = [SELECT Id,Name FROM Profile WHERE Name=:CaseConstants.INT_PROFILE];
            return userProfile;
        }
    
        //Assignment rule firing based on ready for routing
        @TestVisible
        private static void assignmentRuleFire(List<Case> cases){
            List<Case> updateCases = new List<Case>();
            AssignmentRule AR = new AssignmentRule();
            //check whether Assignment Rule exists
            AR = [select id from AssignmentRule where SobjectType =: CaseConstants.CASE_ASSIGNMENT and Active = true limit 1];
            if(AR!=NUll && AR.Id != Null){
                //Creating the DMLOptions for "Assign using active assignment rules" checkbox
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
                for(Case c:cases){
                    Case newCase = new Case(Id = c.Id);
                    //Setting the DMLOption on Case instance
                    newCase.setOptions(dmlOpts);
                    updateCases.add(newCase);
                }
                if(updateCases.size()>0){
                    update updateCases;
                    CaseConstants.runCheckAssignment = false;
                }
            }
        }
    
        //Method to assign case to Tier2
        @TestVisible
        private static void caseOwnerToTier2(List<Case> cases, Set<String> tier2Names){
            //Retrieve queue name from queue ids
            Map<Id,Group> groupMap = new Map<Id,Group>([Select Id, Type, Name from Group where Type = : CaseConstants.GROUP_MAP AND Name IN :tier2Names]);
            if(groupMap != Null){
                Map<String,Group> queueNameMap = new Map<String,Group>();
                for(Group gp : groupMap.values()){
                    queueNameMap.put(gp.Name, gp);
                }
                for(Case c : cases){
                    if(queueNameMap.containsKey(c.Tier2__c)){
                        c.OwnerId = queueNameMap.get(c.Tier2__c).Id;
                    }
                }
            }
        }

        //Populate Expected Closed Date , Expected Response Date , Feature Type , Feature and Comunication
   		 @TestVisible
        private static void populateDates(List<Case> OOPCase_List){
            CaseAdminState__c currentCaseAdminState;
            CaseAdmin__c currentCaseAdmin;
            String currentState;
            for(Case currentCase : OOPCase_List){
                if(String.isNotBlank(currentCase.SubmissionSourceCode__c)
                && ( String.isNotBlank(currentCase.State__c) || (currentCase.AccountId!=null && accountToAccountId_Map!=null && accountToAccountId_Map.size()>0 && accountToAccountId_Map.containsKey(currentCase.AccountId) && String.isNotBlank(accountToAccountId_Map.get(currentCase.AccountId).BillingState)))
                && MetadataSelector.getCaseAdminStatesToCompositeKey_Map()!=null
                && ( (String.isNotBlank(currentCase.State__c) && MetadataSelector.getCaseAdminStatesToCompositeKey_Map().containsKey(currentCase.SubmissionSourceCode__c+'-'+currentCase.State__c))
                    ||  (accountToAccountId_Map!=null && currentCase.AccountId!=null && String.isNotBlank(accountToAccountId_Map.get(currentCase.AccountId).BillingState) && MetadataSelector.getCaseAdminStatesToCompositeKey_Map().containsKey(currentCase.SubmissionSourceCode__c+'-'+accountToAccountId_Map.get(currentCase.AccountId).BillingState) ))){
                        currentState = String.isNotBlank(currentCase.State__c) ? currentCase.State__c : accountToAccountId_Map.get(currentCase.AccountId).BillingState;
                        currentCaseAdminState = new CaseAdminState__c();
                        currentCaseAdminState = MetadataSelector.getCaseAdminStatesToCompositeKey_Map().get(currentCase.SubmissionSourceCode__c+'-'+currentState);
                        
                        if(currentCaseAdminState.ExpectedCloseDays__c!=null){
                            currentCase.ExpectedCloseDate__c =   addDays(currentCase.BusinessHoursId, system.now(),Integer.valueOf(currentCaseAdminState.ExpectedCloseDays__c)).date();
                        }
                        else{
                            currentCase.ExpectedCloseDate__c = null;
                        }
                        if(currentCaseAdminState.ExpectedResponseDays__c!=null){
                            currentCase.ExpectedResponseDate__c = addDays(currentCase.BusinessHoursId, system.now(),Integer.valueOf(currentCaseAdminState.ExpectedResponseDays__c)).date();
                        }
                        else{
                            currentCase.ExpectedResponseDate__c = null;
                        }
                        if(String.isNotBlank(currentCaseAdminState.CaseAdminFeature__c) && String.isNotBlank(currentCaseAdminState.CaseAdminFeatureType__c)){
                            currentCase.Feature__c = currentCaseAdminState.CaseAdminFeature__c;
                            currentCase.FeatureType__c = currentCaseAdminState.CaseAdminFeatureType__c;
                        }
                        currentCase.SendCommunication__c = currentCaseAdminState.SendCommunication__c;
                    }
                else if(String.isNotBlank(currentCase.SubmissionSourceCode__c)
                        && MetadataSelector.getCaseAdminToSubmissionSourceCodeMap()!=null
                        && MetadataSelector.getCaseAdminToSubmissionSourceCodeMap().containsKey(currentCase.SubmissionSourceCode__c)){
                            currentCaseAdmin = new CaseAdmin__c();
                            currentCaseAdmin = MetadataSelector.getCaseAdminToSubmissionSourceCodeMap().get(currentCase.SubmissionSourceCode__c);
                            
                            if(currentCaseAdmin.ExpectedCloseDays__c!=null){
                                currentCase.ExpectedCloseDate__c =  addDays(currentCase.BusinessHoursId, system.now(),Integer.valueOf(currentCaseAdmin.ExpectedCloseDays__c)).date();
                            }
                            else{
                                currentCase.ExpectedCloseDate__c = null;
                            }
                            if(currentCaseAdmin.ExpectedResponseDays__c!=null){
                                currentCase.ExpectedResponseDate__c = addDays(currentCase.BusinessHoursId, system.now(),Integer.valueOf(currentCaseAdmin.ExpectedResponseDays__c)).date();
                            }
                            else{
                                currentCase.ExpectedResponseDate__c=null;
                            }
                            if(String.isNotBlank(currentCaseAdmin.Feature__c) && String.isNotBlank(currentCaseAdmin.FeatureType__c)){
                                currentCase.Feature__c = currentCaseAdmin.Feature__c;
                                currentCase.FeatureType__c = currentCaseAdmin.FeatureType__c;
                            }
                            currentCase.SendCommunication__c = currentCaseAdmin.SendCommunication__c;
                        }
            }
        }
    
        //fetch parent accounts of billing Account
        @TestVisible
        private static void fetchParentAccounts(Set<ID> accountId_Set){
            accountToAccountId_Map = new Map<ID,Account>([Select BillingState From Account Where ID IN :accountId_Set]);
        }
    
        //add Days to determine the next start date
        public static Datetime addDays(Id businessHrsId, Datetime startDate, Integer days){
            startDate = BusinessHours.nextStartDate(businessHrsId, startDate);
            for (Integer elapsed = 0; elapsed < days; elapsed++){
                startDate = startDate.addDays(1);
                if (!BusinessHours.isWithin(businessHrsId, startDate)){
                    startDate = BusinessHours.nextStartDate(businessHrsId, startDate);
                }
            }
            return startDate;
        }

        // Update Target Close Date on Escalation Cases using Case Milestone
        // After the Target Close Date is populated, it will fire the SMS and email logic
        private void updateTargetCloseDate(List<Case> caseList) {
            // List to hold event objects to be published.
            List<Case_Milestone_Event__e> caseMilestoneEventList = new List<Case_Milestone_Event__e>();

            // Checking if the user has the ability to send emails
            Boolean checkPermission = FeatureManagement.checkPermission(CaseConstants.EMAIL_CUSTOM_PERMISSION);

            // Create event objects.
            for (Case escCase : caseList) {
                if (escCase.EntitlementId != null && escCase.Target_Close_Date__c == null) {
                    Case_Milestone_Event__e milestoneEvent = new Case_Milestone_Event__e(Case_ID__c = escCase.Id, Send_Communication__c = checkPermission);
                    caseMilestoneEventList.add(milestoneEvent);
                }
                else if(checkPermission){
                      BWC_CaseEmailAlertsUtility.sendEmailFromCase(caseList, null);
                }
            }

            // Call method to publish events.
            List<Database.SaveResult> results = EventBus.publish(caseMilestoneEventList);
            List<Exception__c> exceptionList = new List<Exception__c>();

            // Logging errors
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        // Adding to Exception object
                        exceptionList.add(new Exception__c(Message__c = err.getMessage()));
                    }
                }
            }

            // Insesrting exceptions ,if they exist
            insert exceptionList;
        }
    }
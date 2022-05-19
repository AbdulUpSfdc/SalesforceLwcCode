//PBCNTRSENT-520
public with sharing class CaseBusinessProcess {
    Static Profile sysAdmin = [Select ID From Profile where Name='System Administrator'];
    public static void validateStatusChange(Case currentCase){
        if(currentCase.status.equalsIgnoreCase('Cancelled')){
            validateCancelledCase(currentCase);
        }
        else if(currentCase.status.equalsIgnoreCase('Closed')){
            validateClosedCase(currentCase);
        }
    }
    @TestVisible
    private static void validateCancelledCase(Case currentCase){
        if(MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID == currentCase.RecordTypeId){
            if(currentCase.OwnerId != null && (String.valueOf(currentCase.OwnerId)).startsWith(CaseConstants.OOP_QUEUE_OWNER_CHECK) && sysAdmin.Id != UserInfo.getProfileId()){
                currentCase.addError(Label.CaseCancellationMessage); 
                return;
            } 
            if(MetadataSelector.rolesToDeveloperName_Map.get('OOPAdmin').ID == UserInfo.getUserRoleId()
               || MetadataSelector.rolesToDeveloperName_Map.get('IntakeAdmin').ID == UserInfo.getUserRoleId()
               || sysAdmin.Id == UserInfo.getProfileId()){
                   changeCancelledCaseRecordType(currentCase);
                   return;
               }
            else{
             currentCase.addError(Label.CaseCancellationMessage);
            }
        }
        /*else if(MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOPField').ID == currentCase.RecordTypeId){
            if(MetadataSelector.rolesToDeveloperName_Map.get('OOPAdmin').ID == UserInfo.getUserRoleId()
               || MetadataSelector.rolesToDeveloperName_Map.get('IntakeAdmin').ID == UserInfo.getUserRoleId()
               || sysAdmin.Id == UserInfo.getProfileId()){
                   changeCancelledCaseRecordType(currentCase);
                   return;
               }
            else if(MetadataSelector.rolesToDeveloperName_Map.get('FieldAdmin').ID == UserInfo.getUserRoleId()){
                Set<ID> memberId_Set = MetadataSelector.fetchUsers(currentCase.WorkGroup__c);
                if(!memberId_Set.contains(UserInfo.getUserId())){
                    currentCase.addError(Label.ChildCaseCancellationError);
                    return;
                }
                changeCancelledCaseRecordType(currentCase);
            }
            else{
                currentCase.addError(Label.ChildCaseCancellationErrorForNonAdmin);
            }
        }
        else if(MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOPResponse').ID == currentCase.RecordTypeId){
            if(MetadataSelector.rolesToDeveloperName_Map.get('OOPAdmin').ID == UserInfo.getUserRoleId()
               || MetadataSelector.rolesToDeveloperName_Map.get('IntakeAdmin').ID == UserInfo.getUserRoleId()
               || sysAdmin.Id == UserInfo.getProfileId()){
                   changeCancelledCaseRecordType(currentCase);
                   return;
               }
            else if(MetadataSelector.rolesToDeveloperName_Map.get('FieldAdmin').ID == UserInfo.getUserRoleId()){
                Set<ID> memberId_Set = MetadataSelector.fetchUsers(currentCase.WorkGroup__c);
                if(!memberId_Set.contains(UserInfo.getUserId())){
                    currentCase.addError(Label.ChildCaseCancellationError);
                    return;
                }
                changeCancelledCaseRecordType(currentCase);
            }
            else{
                currentCase.addError(Label.ChildCaseCancellationErrorForNonAdmin);
            }
        }*/
    }
	@TestVisible
    private static void validateClosedCase(Case currentCase){
        if(MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID == currentCase.RecordTypeId){
            if(currentCase.OwnerId != null && (String.valueOf(currentCase.OwnerId)).startsWith(CaseConstants.OOP_QUEUE_OWNER_CHECK) && sysAdmin.Id != UserInfo.getProfileId()){
                currentCase.addError(Label.CaseCloseErrorForOOP); 
                return;
            } 
            if(MetadataSelector.rolesToDeveloperName_Map.get('OOPAdmin').ID == UserInfo.getUserRoleId()
               || MetadataSelector.rolesToDeveloperName_Map.get('IntakeAdmin').ID == UserInfo.getUserRoleId()
               || MetadataSelector.rolesToDeveloperName_Map.get('OOPAgent').ID == UserInfo.getUserRoleId()
               || MetadataSelector.rolesToDeveloperName_Map.get('IntakeAgent').ID == UserInfo.getUserRoleId()
               || sysAdmin.Id == UserInfo.getProfileId()){
                   changeClosedCaseRecordType(currentCase);
                   return;    
               }
            else{
             currentCase.addError(Label.CaseCloseErrorForOOP);  // replace error 
            }
        }
        /*else if(MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOPField').ID == currentCase.RecordTypeId){
            if(MetadataSelector.rolesToDeveloperName_Map.get('OOPAdmin').ID == UserInfo.getUserRoleId()
               || MetadataSelector.rolesToDeveloperName_Map.get('IntakeAdmin').ID == UserInfo.getUserRoleId()
               || MetadataSelector.rolesToDeveloperName_Map.get('IntakeAgent').ID == UserInfo.getUserRoleId()
               || MetadataSelector.rolesToDeveloperName_Map.get('OOPAgent').ID == UserInfo.getUserRoleId()
               || sysAdmin.Id == UserInfo.getProfileId()){
                   changeClosedCaseRecordType(currentCase);
                   return;
            }
            else if(MetadataSelector.rolesToDeveloperName_Map.get('FieldAdmin').ID == UserInfo.getUserRoleId()
                    || MetadataSelector.rolesToDeveloperName_Map.get('FieldAgent').ID == UserInfo.getUserRoleId()){
                Set<ID> memberId_Set = MetadataSelector.fetchUsers(currentCase.WorkGroup__c);
                if(!memberId_Set.contains(UserInfo.getUserId())){
                    currentCase.addError(Label.CaseCloseErrorForChildCases); // replace
                    return;
                }
                changeClosedCaseRecordType(currentCase);
            }
            else{
                currentCase.addError(Label.CaseCloseErrorForChildCases);
            }
        }
        else if(MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOPResponse').ID == currentCase.RecordTypeId){
            if(MetadataSelector.rolesToDeveloperName_Map.get('OOPAdmin').ID == UserInfo.getUserRoleId()
               || MetadataSelector.rolesToDeveloperName_Map.get('IntakeAdmin').ID == UserInfo.getUserRoleId()
               || MetadataSelector.rolesToDeveloperName_Map.get('IntakeAgent').ID == UserInfo.getUserRoleId()
               || MetadataSelector.rolesToDeveloperName_Map.get('OOPAgent').ID == UserInfo.getUserRoleId()
               || sysAdmin.Id == UserInfo.getProfileId()){
                   changeClosedCaseRecordType(currentCase);
                   return;
            }
            else if(MetadataSelector.rolesToDeveloperName_Map.get('FieldAdmin').ID == UserInfo.getUserRoleId() 
                    || MetadataSelector.rolesToDeveloperName_Map.get('FieldAgent').ID == UserInfo.getUserRoleId()){
                Set<ID> memberId_Set = MetadataSelector.fetchUsers(currentCase.WorkGroup__c);
                if(!memberId_Set.contains(UserInfo.getUserId())){
                    currentCase.addError(Label.CaseCloseErrorForChildCases); // replace
                    return;
                }
                changeClosedCaseRecordType(currentCase);
            }
            else{
                currentCase.addError(Label.CaseCloseErrorForChildCases);
            }
        }*/
    }// method validateClosedCase ends...

    private static void changeClosedCaseRecordType(Case currentCase){
        if(String.isNotBlank(currentCase.Status) && currentCase.Status.equalsIgnoreCase('closed')){
            if(MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID == currentCase.RecordTypeId){
                currentCase.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOPClosedReadOnly').ID;
            }
       /*     if(MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOPField').ID == currentCase.RecordTypeId){
                currentCase.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOPFieldReadOnly').ID;
            }
            if(MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOPResponse').ID == currentCase.RecordTypeId){
                currentCase.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOPResponseReadOnly').ID;
            }   */      
        }    
    }//changeClosedCaseRecordType

    private static void changeCancelledCaseRecordType(Case currentCase){
        if(String.isNotBlank(currentCase.Status) && currentCase.Status.equalsIgnoreCase(CaseConstants.CASE_STATUS_CANCELLED)){  
                    
            //When OOP Case is cancelled then its record type is changed to OOPClosedReadOnly - 3105 user story - initially its OOPReadOnly
            if(MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RECORD_TYPE).ID == currentCase.RecordTypeId){
                currentCase.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_CLOSED_READ_ONLY_RECORD_TYPE).ID; 
            }
     /*       //When OOPField Case is cancelled then its record type is changed to OOPFieldReadOnly - initially its OOPFieldReadOnly
            if(MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_FIELD_RECORD_TYPE).ID == currentCase.RecordTypeId){
                currentCase.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_FIELD_READ_ONLY_RECORD_TYPE ).ID;
            }
            //When OOPResponse Case is cancelled then its record type is changed to OOPResponseReadOnly - initially its OOPResponseReadOnly
            if(MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RESPONSE_RECORD_TYPE).ID == currentCase.RecordTypeId){
                currentCase.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get(CaseConstants.OOP_RESPONSE_READ_ONLY_RECORD_TYPE).ID;
            }*/
            
        }
    }// method ends...

    public static void populateAddress(Case currentCase){
        Boolean validRecordType = false;
        if(!(currentCase.recordTypeId == MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID
           /* || currentCase.recordTypeId == MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOPField').ID
            || currentCase.recordTypeId == MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOPResponse').ID*/)){
            return;
        }
        if(String.isBlank(currentCase.BillingCustLastName__c)
            && String.isBlank(currentCase.BillingStreet__c)
            && String.isBlank(currentCase.BillingCity__c)
            && (String.isNotBlank(currentCase.ServiceCustLastName__c) 
                || String.isNotBlank(currentCase.StreetName__c) 
                || String.isNotBlank(currentCase.City__c))){
            //name
            if(String.isNotBlank(currentCase.ServiceCustLastName__c)){
                currentCase.BillingCustLastName__c = currentCase.ServiceCustLastName__c;
            }
            if(String.isNotBlank(currentCase.ServiceCustFirstName__c)){
                currentCase.BillingCustFirstName__c = currentCase.ServiceCustFirstName__c;
            }  
            //name

            //address
            if(String.isNotBlank(currentCase.StreetName__c)){
                currentCase.BillingStreet__c = currentCase.StreetName__c;
            }
            if(String.isNotBlank(currentCase.City__c)){
                currentCase.BillingCity__c = currentCase.City__c;
            }
            if(String.isNotBlank(currentCase.State__c)){
                currentCase.BillingState__c = currentCase.State__c;
            }
            if(String.isNotBlank(currentCase.ZipPostalCode__c)){
                currentCase.BillingZip__c = currentCase.ZipPostalCode__c;
            }
            if(String.isNotBlank(currentCase.Country__c)){
                currentCase.BillingCountry__c = currentCase.Country__c;
            }
            //address
            //contact details
            if(String.isNotBlank(currentCase.ServiceEmail__c)){
                currentCase.BillingEmail__c = currentCase.ServiceEmail__c;
            }
            if(String.isNotBlank(currentCase.ServicePhone__c)){
                currentCase.BillingPhone__c = currentCase.ServicePhone__c;
            }
            //contact details   
        }
    }//method ends...

    public static void populateDates(List<Case> OOPCase_List){
        CaseAdminState__c currentCaseAdminState;
        CaseAdmin__c currentCaseAdmin;
        String currentState;
        for(Case currentCase : OOPCase_List){
           if(String.isNotBlank(currentCase.SubmissionSourceCode__c) 
                && String.isNotBlank(currentCase.State__c) 
                && MetadataSelector.getCaseAdminStatesToCompositeKey_Map()!=null
                && ((String.isNotBlank(currentCase.State__c) && MetadataSelector.getCaseAdminStatesToCompositeKey_Map().containsKey(currentCase.SubmissionSourceCode__c+'-'+currentCase.State__c)))){
                       currentState = currentCase.State__c;
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
                            system.debug('currentCaseAdmin==>'+currentCaseAdmin);
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
    }//method ends...
    
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
}
/*
*
* test Class: Utility_tst
*/
public with sharing class Utility {
    public static Date populateDates(Case currentCase){
        CaseAdminState__c currentCaseAdminState;
        CaseAdmin__c currentCaseAdmin;
        String currentState;
        List<Account> accountList;
        Account currentAccount;
        Date expectedCloseDate=null;
        
        if(currentCase == NULL) {
            return expectedCloseDate;
        }
        
        if(currentCase.AccountId!=null){
            accountList = [Select ID, BillingState From Account Where ID = :currentCase.AccountId];    
            currentAccount = new Account();
            currentAccount = accountList[0];
        }
        system.debug('===currentCase==='+currentCase);
        if(String.isNotBlank(currentCase.SubmissionSourceCode__c) 
           && ( String.isNotBlank(currentCase.State__c) || (currentCase.AccountId!=null && currentAccount!=null && String.isNotBlank(currentAccount.BillingState))) 
           && MetadataSelector.getCaseAdminStatesToCompositeKey_Map()!=null
           && ( (String.isNotBlank(currentCase.State__c) && MetadataSelector.getCaseAdminStatesToCompositeKey_Map().containsKey(currentCase.SubmissionSourceCode__c+'-'+currentCase.State__c))
               ||  (currentAccount!=null && currentCase.AccountId!=null && String.isNotBlank(currentAccount.BillingState) && MetadataSelector.getCaseAdminStatesToCompositeKey_Map().containsKey(currentCase.SubmissionSourceCode__c+'-'+currentAccount.BillingState) ))){
                   currentState = String.isNotBlank(currentCase.State__c) ? currentCase.State__c : currentAccount.BillingState;
                   currentCaseAdminState = new CaseAdminState__c();
                   currentCaseAdminState = MetadataSelector.getCaseAdminStatesToCompositeKey_Map().get(currentCase.SubmissionSourceCode__c+'-'+currentState);
                   
                   if(currentCaseAdminState.ExpectedCloseDaysChild__c!=null){
                       expectedCloseDate = addDays(currentCase.BusinessHoursId, system.now(),Integer.valueOf(currentCaseAdminState.ExpectedCloseDaysChild__c)).date();
                   }
                   
               }
        else if(String.isNotBlank(currentCase.SubmissionSourceCode__c) 
                && MetadataSelector.getCaseAdminToSubmissionSourceCodeMap()!=null
                && MetadataSelector.getCaseAdminToSubmissionSourceCodeMap().containsKey(currentCase.SubmissionSourceCode__c)){
                    currentCaseAdmin = new CaseAdmin__c();
                    currentCaseAdmin = MetadataSelector.getCaseAdminToSubmissionSourceCodeMap().get(currentCase.SubmissionSourceCode__c);
                    
                    if(currentCaseAdmin.ExpectedCloseDaysChild__c!=null){
                        system.debug('currentCaseAdmin==>'+currentCaseAdmin);
                        expectedCloseDate = addDays(currentCase.BusinessHoursId, system.now(),Integer.valueOf(currentCaseAdmin.ExpectedCloseDaysChild__c)).date();
                    }
                }
        return expectedCloseDate;
    }
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
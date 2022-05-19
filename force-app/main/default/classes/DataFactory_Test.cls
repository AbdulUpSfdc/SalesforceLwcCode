@isTest
public class DataFactory_Test {
    public static Case createParentCase(){
        BusinessHours businessHours = [Select ID From BusinessHours Where Name='OOP Business Hour' Limit 1];
        List<CaseAdminState__c> caseAdminState_List = [Select 
                                                           CaseAdminValue__c,
                                                           SubmissionSourceCode__c,
                                                           ExpectedCloseDays__c,
                                                           ExpectedCloseDaysChild__c,
                                                           ExpectedResponseDays__c,
                                                           State__c,
                                                           CaseAdminFeature__c,
                                                           CaseAdminFeatureType__c
                                                           From CaseAdminState__c 
                                                           Where State__c!='' And ExpectedCloseDays__c!=null And ExpectedResponseDays__c!=null];
        
        Case caseWithState = new Case();
        caseWithState.SubmissionSourceCode__c = caseAdminState_List[0].SubmissionSourceCode__c;
        caseWithState.State__c = caseAdminState_List[0].State__c;
        caseWithState.Type='OOP';
        caseWithState.Origin='Phone';
        caseWithState.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
        caseWithState.Description = 'Test scenario one';
        caseWithState.Status = 'New';
        caseWithState.Priority='Medium';
        //caseWithState.CustomerType__c='Consumer';
        caseWithState.BusinessHoursId = businessHours.ID;
        
        return caseWithState;
    }
}
/*
*Test Class for: Utility
*/
@isTest
private class Utility_Tst {
    @testSetup
    private static void testSetup(){
        Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
        UserRole fieldAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='FieldAdmin'];
        User oppAdministratorUser = Utility_Test.createTestUserWithRole(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin', fieldAdminRole.Id);
        insert oppAdministratorUser;

        List<Utility_Test.UserPermissionSetWrapper> wrapperList = new List<Utility_Test.UserPermissionSetWrapper>();
        Utility_Test.UserPermissionSetWrapper wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = oppAdministratorUser;
        wrapper.permissionSetNames.add('OOPCaseFullPermission');
        wrapperList.add(wrapper);
        system.runAs(new User(Id=UserInfo.getUserId())){
            Utility_Test.assignPermissionSet(wrapperList);
        }
        Utility_Test.createCaseAdminRecords();
    }

    @isTest
    private static void populateDates_Test1(){
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
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

            BusinessHours businessHours = [Select ID From BusinessHours Where Name='OOP Business Hour' Limit 1];
            if(caseAdminState_List!=null && caseAdminState_List.size()>0){
            if(caseAdminState_List[0].ExpectedResponseDays__c!=null && caseAdminState_List[0].ExpectedCloseDays__c!=null){
            Date expectedResponseDate = CaseTriggerHelper.addDays(businessHours.ID, System.now(), Integer.valueOf(caseAdminState_List[0].ExpectedResponseDays__c)).date();
            Date expectedCloseDate = CaseTriggerHelper.addDays(businessHours.ID, System.now(),Integer.valueOf(caseAdminState_List[0].ExpectedCloseDays__c)).date();
            }
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
            insert caseWithState;

            Case childCase = caseWithState.clone(false,false,false,false);
            childCase.ExpectedCloseDate__c = null;
            childCase.ExpectedResponseDate__c = null;
            childCase.ParentId = caseWithState.ID;

            test.startTest();
            Date expectedCloseDateForChild = Utility.populateDates(childCase);
            test.stopTest();
       //     system.assert(expectedCloseDateForChild!=null);
        }
       }
    }

    @isTest
    private static void populateDates_Test2(){
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
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

            BusinessHours businessHours = [Select ID From BusinessHours Where Name='OOP Business Hour' Limit 1];
            if(caseAdminState_List!=null && caseAdminState_List.size()>0){
            if(caseAdminState_List[0].ExpectedResponseDays__c!=null && caseAdminState_List[0].ExpectedCloseDays__c!=null){
            Date expectedResponseDate = CaseTriggerHelper.addDays(businessHours.ID, System.now(), Integer.valueOf(caseAdminState_List[0].ExpectedResponseDays__c)).date();
            Date expectedCloseDate = CaseTriggerHelper.addDays(businessHours.ID, System.now(),Integer.valueOf(caseAdminState_List[0].ExpectedCloseDays__c)).date();
            }
            Case caseWithState = new Case();
            caseWithState.SubmissionSourceCode__c = caseAdminState_List[0].SubmissionSourceCode__c;
            //caseWithState.State__c = caseAdminState_List[0].State__c;
            caseWithState.Type='OOP';
            caseWithState.Origin='Phone';
            caseWithState.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
            caseWithState.Description = 'Test scenario one';
            caseWithState.Status = 'New';
            caseWithState.Priority='Medium';
            //caseWithState.CustomerType__c='Consumer';
            caseWithState.BusinessHoursId = businessHours.ID;
            insert caseWithState;

            Case childCase = caseWithState.clone(false,false,false,false);
            childCase.ExpectedCloseDate__c = null;
            childCase.ExpectedResponseDate__c = null;
            childCase.ParentId = caseWithState.ID;

            test.startTest();
            Date expectedCloseDateForChild = Utility.populateDates(childCase);
            test.stopTest();
      //      system.assert(expectedCloseDateForChild!=null);
        }
        }
    }

     @isTest
    private static void populateDates_Test3(){
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            List<CaseAdminState__c> caseAdminState_List = [SELECT
                                                           CaseAdminValue__c,
                                                           SubmissionSourceCode__c,
                                                           ExpectedCloseDays__c,
                                                           ExpectedCloseDaysChild__c,
                                                           ExpectedResponseDays__c,
                                                           State__c,
                                                           CaseAdminFeature__c,
                                                           CaseAdminFeatureType__c
                                                           FROM CaseAdminState__c
                                                           WHERE State__c = 'Alaska' AND ExpectedCloseDays__c != null AND ExpectedResponseDays__c != null];

            BusinessHours businessHours = [Select ID From BusinessHours Where Name='OOP Business Hour' Limit 1];
            if(caseAdminState_List!=null && caseAdminState_List.size()>0){
            if(caseAdminState_List[0].ExpectedResponseDays__c!=null && caseAdminState_List[0].ExpectedCloseDays__c!=null){
            Date expectedResponseDate = CaseTriggerHelper.addDays(businessHours.ID, System.now(), Integer.valueOf(caseAdminState_List[0].ExpectedResponseDays__c)).date();
            Date expectedCloseDate = CaseTriggerHelper.addDays(businessHours.ID, System.now(),Integer.valueOf(caseAdminState_List[0].ExpectedCloseDays__c)).date();
            }

            Account accountWithState = new Account();
            accountWithState.Name='AccountWithState';
            // Hard-code the state code to avoid an inconsistency between environments around the integration value of state pick-lists
            // accountWithState.BillingState=caseAdminState_List[0].State__c;
            // This must be hard-coded to the same state as is in the query above
            accountWithState.BillingStateCode = 'AK';
            accountWithState.BillingCountry='United States';
            insert accountWithState;

            Case caseWithState = new Case();
            caseWithState.SubmissionSourceCode__c = caseAdminState_List[0].SubmissionSourceCode__c;
            caseWithState.Type='OOP';
            caseWithState.Origin='Phone';
            caseWithState.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
            caseWithState.Description = 'Test scenario one';
            caseWithState.Status = 'New';
            caseWithState.Priority='Medium';
            //caseWithState.CustomerType__c='Consumer';
            caseWithState.BusinessHoursId = businessHours.ID;
            caseWithState.AccountId = accountWithState.ID;
            insert caseWithState;

            Case childCase = caseWithState.clone(false,false,false,false);
            childCase.ExpectedCloseDate__c = null;
            childCase.ExpectedResponseDate__c = null;
            childCase.ParentId = caseWithState.ID;

            test.startTest();
            Date expectedCloseDateForChild = Utility.populateDates(childCase);
            test.stopTest();
         //   system.assert(expectedCloseDateForChild!=null);
        }
        }
    }
}
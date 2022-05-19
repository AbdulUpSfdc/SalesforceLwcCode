@isTest
public class CaseMergeHelper_Test {
    
    @testSetup
    private static void testSetup(){
        Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
        Profile sysAdminProfile = [Select ID From Profile Where Name='System Administrator'];
        
        UserRole oopAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='OOPAdmin'];
        UserRole fieldAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='FieldAdmin'];
        UserRole fieldIntakeAdminRole = [SELECT Id FROM UserRole WHERE UserRole.Name='Intake Admin'];
        List<User> userList = new List<User>();
        
        User oppAdministratorUser = Utility_Test.createTestUserWithRole(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin', oopAdminRole.Id);
        User intakeAdministratorUser = Utility_Test.createTestUserWithRole(sysAdminProfile.ID, 'firstName_intakeAdmin', 'lastName_intakeAdmin', fieldIntakeAdminRole.Id);
        userList.add(oppAdministratorUser);
        userList.add(intakeAdministratorUser);
        insert userList;
        
        List<Utility_Test.UserPermissionSetWrapper> wrapperList = new List<Utility_Test.UserPermissionSetWrapper>();
        
        // oopAdmin
        Utility_Test.UserPermissionSetWrapper wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = userList[0];
        wrapper.permissionSetNames.add('OOPCaseAdmin');
        wrapper.permissionSetNames.add('OOPCaseTransfer');
        wrapper.permissionSetNames.add('OOPCaseFullPermission');
        wrapperList.add(wrapper);
        
        system.runAs(new User(Id=UserInfo.getUserId())){
            Utility_Test.assignPermissionSet(wrapperList);
        }
        Utility_Test.createCaseAdminRecords();
    }
    
    
    @isTest
    public static void mergeHelperTest(){
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            String postBody = 'Social: 999/99/9999';
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
            Case testCase = new Case();
            testCase.SubmissionSourceCode__c = caseAdminState_List[0].SubmissionSourceCode__c;
            testCase.State__c = caseAdminState_List[0].State__c;
            testCase.Type='OOP';
            testCase.Origin='Phone';
            testCase.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
            testCase.Description = 'Test scenario one';
            testCase.Status = 'New';
            testCase.Priority='Medium';
            //testCase.CustomerType__c='Consumer';
            testCase.BusinessHoursId = businessHours.ID;
            insert testCase;
            
            Case testCase1 = new Case();
            testCase1.SubmissionSourceCode__c = caseAdminState_List[0].SubmissionSourceCode__c;
            testCase1.State__c = caseAdminState_List[0].State__c;
            testCase1.Type='OOP';
            testCase1.Origin='Email';
            testCase1.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
            testCase1.Description = 'Test scenario two';
            testCase1.Status = 'In Progress';
            testCase1.Priority='Medium';
            //testCase1.CustomerType__c='Consumer';
            testCase1.BusinessHoursId = businessHours.ID;
            insert testCase1;
        }
        
        User intakeAdministratorUser = [Select ID From User Where LastName='lastName_intakeAdmin'];
        system.runAs(intakeAdministratorUser){
            List<Case> caseListToUpdate = new List<Case>();
            Case theCase = [SELECT Id, Status from Case WHERE Type= 'OOP' AND Status = 'New' LIMIT 1];
            Case masterCase = [SELECT Id, Status from Case WHERE Type= 'OOP' AND Status = 'In Progress' LIMIT 1];
            
            Database.MergeResult result = Database.merge(masterCase, theCase, false);
            if (result.isSuccess()) {
                // Get the master ID from the result and validate it
                System.debug('Master record ID: ' + result.getId());
                System.assertEquals(masterCase.Id, result.getId());
            }
            else {
                for(Database.Error err : result.getErrors()) {
                    // Write each error to the debug output
                    System.debug(err.getMessage());
                }
            }
            
        }
        
    }
}
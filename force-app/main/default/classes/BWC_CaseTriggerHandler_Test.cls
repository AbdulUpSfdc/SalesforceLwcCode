@isTest
    public class BWC_CaseTriggerHandler_Test {
        
    @testSetup
        private static void testSetup(){
            Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
            Profile oopAgentProfile = [Select ID From Profile Where Name='Minimum Access OOP Agent'];
            Profile sysAdminProfile = [Select ID From Profile Where Name='System Administrator'];
            //Order Fallout Integration profile
            Profile integrationProfile = [Select ID From Profile Where Name='Integration Profile'];
            UserRole oopAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='OOPAdmin'];
            UserRole fieldAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='FieldAdmin'];
            UserRole fieldAgentRole = [SELECT Id FROM UserRole WHERE DeveloperName='FieldAgent'];
            UserRole fieldIntakeAdminRole = [SELECT Id FROM UserRole WHERE UserRole.Name='Intake Admin'];
            List<User> userList = new List<User>();
            
            User oppAdministratorUser = Utility_Test.createTestUserWithRole(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin', oopAdminRole.Id);
            User intakeAdministratorUser = Utility_Test.createTestUserWithRole(sysAdminProfile.ID, 'firstName_intakeAdmin', 'lastName_intakeAdmin', fieldIntakeAdminRole.Id);
            userList.add(intakeAdministratorUser);
            userList.add(oppAdministratorUser);        
            oppAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_oopAdmin2', 'lastName_oopAdmin2');
            oppAdministratorUser.UserRoleId = fieldAdminRole.ID;
            userList.add(oppAdministratorUser);
            
            //Agent
            User oopAgent = Utility_Test.createTestUser(oopAgentProfile.ID, 'firstName_oppAgent', 'lastName_oopAgent');
            oppAdministratorUser.UserRoleId = fieldAgentRole.ID;
            userList.add(oopAgent);
            
            //Integration Profile user
            User integration_user = Utility_Test.createTestUser(integrationProfile.ID, 'firstName_integration', 'lastName_integrationAdmin');
            userList.add(integration_user);
            
            //Billing Ajustment user
            User billingAdmin = Utility_Test.createTestUserWithRole(sysAdminProfile.ID, 'firstName_BillingAdmin', 'lastName_BillingAdmin', fieldIntakeAdminRole.Id);
            userList.add(billingAdmin);
            
            insert userList;
            
            List<GroupMember> groupMember_List = new List<GroupMember>();
            Group intakeQueue = [Select ID From Group Where DeveloperName='IntakeQueue' And Type='Queue' Limit 1];
            GroupMember member = new GroupMember();
            member.UserOrGroupId = userList[0].ID;
            member.GroupId = intakeQueue.ID;
            groupMember_List.add(member);
            
            member = new GroupMember();
            member.UserOrGroupId = userList[1].ID;
            member.GroupId = intakeQueue.ID;
            groupMember_List.add(member);
            
            member = new GroupMember();
            member.UserOrGroupId = oopAgent.ID;
            member.GroupId = intakeQueue.ID;
            groupMember_List.add(member);
            
            member = new GroupMember();
            member.UserOrGroupId = oopAgent.ID;
            member.GroupId = [Select ID From Group Where DeveloperName='OOPAgents' And Type='Regular'][0].ID;
            groupMember_List.add(member);
            List<Utility_Test.UserPermissionSetWrapper> wrapperList = new List<Utility_Test.UserPermissionSetWrapper>();
            
            // oopAdmin
            Utility_Test.UserPermissionSetWrapper wrapper = new Utility_Test.UserPermissionSetWrapper();
            wrapper.user = userList[0];
            wrapper.permissionSetNames.add('OOPCaseAdmin');
            wrapper.permissionSetNames.add('OOPCaseTransfer');
            wrapper.permissionSetNames.add('OOPCaseFullPermission');
            wrapperList.add(wrapper);
            
            //oopAdmin2
            wrapper = new Utility_Test.UserPermissionSetWrapper();
            wrapper.user = userList[1];
            wrapper.permissionSetNames.add('OOPCaseAdmin');
            wrapper.permissionSetNames.add('OOPCaseTransfer');
            wrapper.permissionSetNames.add('OOPCaseFullPermission');
            wrapperList.add(wrapper);
            
            wrapper = new Utility_Test.UserPermissionSetWrapper();
            wrapper.user = oopAgent;
            wrapper.permissionSetNames.add('OOPCaseCreate');
            wrapper.permissionSetNames.add('OOPCaseTransfer');
            wrapperList.add(wrapper);
            
            //Integration user
            wrapper = new Utility_Test.UserPermissionSetWrapper();
            wrapper.user = integration_user;
            wrapper.permissionSetNames.add('Order_Fallout_Case_Creation_Access');
            wrapper.permissionSetNames.add('C360_Admin');
            wrapper.permissionSetNames.add('C360_Agent'); 
            wrapper.permissionSetNames.add('EscalationCases'); 
            wrapper.permissionSetNames.add('Customer_360_App_Access');
            wrapper.permissionSetNames.add('KM_Mulesoft_Permissions');
            wrapper.permissionSetNames.add('SOA_Fields');
            wrapperList.add(wrapper);
            
            //Billing Admin
            wrapper = new Utility_Test.UserPermissionSetWrapper();
            wrapper.user = billingAdmin;
            wrapper.permissionSetNames.add('Billing_Adjustments_Read_Write');
            wrapper.permissionSetNames.add('EscalationCases');
            wrapper.permissionSetNames.add('C360_Admin');
            wrapper.permissionSetNames.add('C360_Agent'); 
            wrapper.permissionSetNames.add('EscalationCases'); 
            wrapper.permissionSetNames.add('Customer_360_App_Access'); 
            wrapper.permissionSetNames.add('SOA_Fields');
            wrapperList.add(wrapper);
        
            system.runAs(new User(Id=UserInfo.getUserId())){
                Utility_Test.assignPermissionSet(wrapperList);
                insert groupMember_List;
            }
            Utility_Test.createCaseAdminRecords();
        }
        
        @isTest
        private static void testCaseWithStatePopulated(){
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
                Date expectedResponseDate = BWC_CaseTriggerHandler.addDays(businessHours.ID, System.now(), Integer.valueOf(caseAdminState_List[0].ExpectedResponseDays__c)).date();
                Date expectedCloseDate = BWC_CaseTriggerHandler.addDays(businessHours.ID, System.now(),Integer.valueOf(caseAdminState_List[0].ExpectedCloseDays__c)).date();
                
                Case caseWithState = new Case();
                caseWithState.SubmissionSourceCode__c = caseAdminState_List[0].SubmissionSourceCode__c;
                caseWithState.State__c = caseAdminState_List[0].State__c;
                caseWithState.Type='OOP';
                caseWithState.Origin='Phone';
                caseWithState.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
                caseWithState.Description = 'Test scenario one';
                caseWithState.Status = 'New';
                caseWithState.Priority='Medium';
                caseWithState.BusinessHoursId = businessHours.ID;
                
                test.startTest();
                insert caseWithState;
                test.stopTest();
                caseWithState = [Select SubmissionSourceCode__c,State__c, ExpectedCloseDate__c, ExpectedResponseDate__c,Feature__c,FeatureType__c From Case Where ID = :caseWithState.Id];
                
                Group oopAdminGroup = new Group();
                oopAdminGroup = MetadataSelector.publicGroupToDeveloperName_Map.get('OOPAdmins');
                Group oopAgentGroup = new Group();
                oopAgentGroup = MetadataSelector.publicGroupToDeveloperName_Map.get('OOPAgents');
                
                system.assertEquals(expectedResponseDate, caseWithState.ExpectedResponseDate__c);
                system.assertEquals(expectedCloseDate, caseWithState.ExpectedCloseDate__c);
                system.assertEquals(caseAdminState_List[0].CaseAdminFeature__c, caseWithState.Feature__c);
                system.assertEquals(caseAdminState_List[0].CaseAdminFeatureType__c, caseWithState.FeatureType__c);
            }
        }
        
        @isTest
        private static void testCaseWithoutState(){
            User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
            system.runAs(oppAdministratorUser){
                List<CaseAdmin__c> caseAdmin_List = [Select
                                                    ExpectedCloseDays__c,
                                                    ExpectedResponseDays__c,
                                                    Feature__c,
                                                    FeatureType__c,
                                                    SubmissionSource__c
                                                    From CaseAdmin__c
                                                    Where ExpectedCloseDays__c!=null And ExpectedResponseDays__c!=null];
                
                BusinessHours businessHours = [Select ID From BusinessHours Where Name='OOP Business Hour' Limit 1];
                Date expectedResponseDate = BWC_CaseTriggerHandler.addDays(businessHours.ID, System.now(), Integer.valueOf(caseAdmin_List[0].ExpectedResponseDays__c)).date();
                Date expectedCloseDate = BWC_CaseTriggerHandler.addDays(businessHours.ID, System.now(),Integer.valueOf(caseAdmin_List[0].ExpectedCloseDays__c)).date();
                
                Account accountWithState = new Account();
                accountWithState.Name='AccountWithState';
                insert accountWithState;
                
                Case caseWithState = new Case();
                caseWithState.SubmissionSourceCode__c = caseAdmin_List[0].SubmissionSource__c;
                caseWithState.Type='OOP';
                caseWithState.Origin='Phone';
                caseWithState.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
                caseWithState.Description = 'Test scenario one';
                caseWithState.Status = 'New';
                caseWithState.Priority='Medium';
                caseWithState.BusinessHoursId = businessHours.ID;
                caseWithState.AccountId = accountWithState.ID;
                
                test.startTest();
                insert caseWithState;
                test.stopTest();
                caseWithState = [Select SubmissionSourceCode__c,State__c, ExpectedCloseDate__c, ExpectedResponseDate__c,Feature__c,FeatureType__c From Case Where ID = :caseWithState.Id];
                system.assertEquals(expectedResponseDate, caseWithState.ExpectedResponseDate__c);
                system.assertEquals(expectedCloseDate, caseWithState.ExpectedCloseDate__c);
                system.assertEquals(caseAdmin_List[0].Feature__c, caseWithState.Feature__c);
                system.assertEquals(caseAdmin_List[0].FeatureType__c, caseWithState.FeatureType__c);
            }
        }
        
        @isTest
        private static void testCaseWithoutStateOnUpdate(){
            User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
            system.runAs(oppAdministratorUser){
                List<CaseAdmin__c> caseAdmin_List = [Select
                                                    ExpectedCloseDays__c,
                                                    ExpectedResponseDays__c,
                                                    Feature__c,
                                                    FeatureType__c,
                                                    SubmissionSource__c
                                                    From CaseAdmin__c
                                                    Where ExpectedCloseDays__c!=null And ExpectedResponseDays__c!=null];
                
                BusinessHours businessHours = [Select ID From BusinessHours Where Name='OOP Business Hour' Limit 1];
                Date expectedResponseDate = BWC_CaseTriggerHandler.addDays(businessHours.ID, System.now(), Integer.valueOf(caseAdmin_List[0].ExpectedResponseDays__c)).date();
                Date expectedCloseDate = BWC_CaseTriggerHandler.addDays(businessHours.ID, System.now(),Integer.valueOf(caseAdmin_List[0].ExpectedCloseDays__c)).date();
                
                Account accountWithState = new Account();
                accountWithState.Name='AccountWithState';
                insert accountWithState;
                
                Case caseWithState = new Case();
                caseWithState.SubmissionSourceCode__c = caseAdmin_List[0].SubmissionSource__c;
                caseWithState.Type='OOP';
                caseWithState.Origin='Phone';
                caseWithState.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
                caseWithState.Description = 'Test scenario one';
                caseWithState.Status = 'New';
                caseWithState.Priority='Medium';
                caseWithState.BusinessHoursId = businessHours.ID;
                caseWithState.AccountId = accountWithState.ID;
                insert caseWithState;
                caseWithState = [Select SubmissionSourceCode__c,State__c, ExpectedCloseDate__c, ExpectedResponseDate__c From Case Where ID = :caseWithState.Id];
                system.assertEquals(expectedResponseDate, caseWithState.ExpectedResponseDate__c);
                system.assertEquals(expectedCloseDate, caseWithState.ExpectedCloseDate__c);
                
                test.startTest();
                caseWithState.SubmissionSourceCode__c = caseAdmin_List[1].SubmissionSource__c;
                update caseWithState;
                
                expectedResponseDate = BWC_CaseTriggerHandler.addDays(businessHours.ID, System.now(), Integer.valueOf(caseAdmin_List[1].ExpectedResponseDays__c)).date();
                expectedCloseDate = BWC_CaseTriggerHandler.addDays(businessHours.ID, System.now(),Integer.valueOf(caseAdmin_List[1].ExpectedCloseDays__c)).date();
                
                caseWithState = [Select SubmissionSourceCode__c,State__c, ExpectedCloseDate__c, ExpectedResponseDate__c,Feature__c,FeatureType__c From Case Where ID = :caseWithState.Id];
                system.assertEquals(expectedResponseDate, caseWithState.ExpectedResponseDate__c);
                system.assertEquals(expectedCloseDate, caseWithState.ExpectedCloseDate__c);
                system.assertEquals(caseAdmin_List[1].Feature__c, caseWithState.Feature__c);
                system.assertEquals(caseAdmin_List[1].FeatureType__c, caseWithState.FeatureType__c);
                test.stopTest();
                
            }
        }
        
        @isTest
        private static void testCaseWithAdminOverride(){
            User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
            system.runAs(oppAdministratorUser){
                List<CaseAdmin__c> caseAdmin_List = [Select
                                                    ExpectedCloseDays__c,
                                                    ExpectedResponseDays__c,
                                                    Feature__c,
                                                    FeatureType__c,
                                                    SubmissionSource__c
                                                    From CaseAdmin__c
                                                    Where ExpectedCloseDays__c!=null And ExpectedResponseDays__c!=null];
                
                BusinessHours businessHours = [Select ID From BusinessHours Where Name='OOP Business Hour' Limit 1];
                
                Account accountWithState = new Account();
                accountWithState.Name='AccountWithState';
                insert accountWithState;
                
                Case caseWithState = new Case();
                caseWithState.SubmissionSourceCode__c = caseAdmin_List[0].SubmissionSource__c;
                caseWithState.Type='OOP';
                caseWithState.Origin='Phone';
                caseWithState.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
                caseWithState.Description = 'Test scenario one';
                caseWithState.Status = 'New';
                caseWithState.Priority='Medium';
                caseWithState.BusinessHoursId = businessHours.ID;
                caseWithState.AccountId = accountWithState.ID;
                insert caseWithState;
                
                test.startTest();
                caseWithState.AdminCloseDate__c=System.today();
                caseWithState.AdminResponseDate__c=System.today();
                
                update caseWithState;
                
                caseWithState = [Select SubmissionSourceCode__c,State__c, ExpectedCloseDate__c, ExpectedResponseDate__c From Case Where ID = :caseWithState.Id];
                system.assertEquals(System.today(), caseWithState.ExpectedResponseDate__c);
                system.assertEquals(System.today(), caseWithState.ExpectedCloseDate__c);
                test.stopTest();
            }
        }
        
        @isTest
        private static void testCaseWithoutStateAndOnlyCloseDate(){
            User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
            system.runAs(oppAdministratorUser){
                List<CaseAdmin__c> caseAdmin_List = [Select
                                                    ExpectedCloseDays__c,
                                                    ExpectedResponseDays__c,
                                                    Feature__c,
                                                    FeatureType__c,
                                                    SubmissionSource__c
                                                    From CaseAdmin__c
                                                    Where ExpectedCloseDays__c!=null And ExpectedResponseDays__c=null];
                
                BusinessHours businessHours = [Select ID From BusinessHours Where Name='OOP Business Hour' Limit 1];
                Date expectedCloseDate = BWC_CaseTriggerHandler.addDays(businessHours.ID, System.now(),Integer.valueOf(caseAdmin_List[0].ExpectedCloseDays__c)).date();
                
                Account accountWithState = new Account();
                accountWithState.Name='AccountWithState';
                insert accountWithState;
                
                Case caseWithState = new Case();
                caseWithState.SubmissionSourceCode__c = caseAdmin_List[0].SubmissionSource__c;
                caseWithState.Type='OOP';
                caseWithState.Origin='Phone';
                caseWithState.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
                caseWithState.Description = 'Test scenario one';
                caseWithState.Status = 'New';
                caseWithState.Priority='Medium';
                caseWithState.BusinessHoursId = businessHours.ID;
                caseWithState.AccountId = accountWithState.ID;
                
                test.startTest();
                insert caseWithState;
                test.stopTest();
                caseWithState = [Select SubmissionSourceCode__c,State__c, ExpectedCloseDate__c, ExpectedResponseDate__c,Feature__c,FeatureType__c From Case Where ID = :caseWithState.Id];
                system.assertEquals(null, caseWithState.ExpectedResponseDate__c);
                system.assertEquals(expectedCloseDate, caseWithState.ExpectedCloseDate__c);
                system.assertEquals(caseAdmin_List[0].Feature__c, caseWithState.Feature__c);
                system.assertEquals(caseAdmin_List[0].FeatureType__c, caseWithState.FeatureType__c);
            }
        }
        
        @isTest
        private static void testcheckCancelledCase(){
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
                Date expectedResponseDate = BWC_CaseTriggerHandler.addDays(businessHours.ID, System.now(), Integer.valueOf(caseAdminState_List[0].ExpectedResponseDays__c)).date();
                Date expectedCloseDate = BWC_CaseTriggerHandler.addDays(businessHours.ID, System.now(),Integer.valueOf(caseAdminState_List[0].ExpectedCloseDays__c)).date();
                
                Case caseWithState = new Case();
                caseWithState.SubmissionSourceCode__c = caseAdminState_List[0].SubmissionSourceCode__c;
                caseWithState.State__c = caseAdminState_List[0].State__c;
                caseWithState.Type='OOP';
                caseWithState.Origin='Phone';
                caseWithState.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
                caseWithState.Description = 'Test scenario one';
                caseWithState.Status = 'New';
                caseWithState.Priority='Medium';
                caseWithState.BusinessHoursId = businessHours.ID;
                insert caseWithState;
                caseWithState = [Select SubmissionSourceCode__c,State__c, ExpectedCloseDate__c, ExpectedResponseDate__c,Feature__c,FeatureType__c From Case Where ID = :caseWithState.Id];
                system.assertEquals(expectedResponseDate, caseWithState.ExpectedResponseDate__c);
                system.assertEquals(expectedCloseDate, caseWithState.ExpectedCloseDate__c);
                system.assertEquals(caseAdminState_List[0].CaseAdminFeature__c, caseWithState.Feature__c);
                system.assertEquals(caseAdminState_List[0].CaseAdminFeatureType__c, caseWithState.FeatureType__c);
                
                caseWithState.Status = 'Cancelled';
                caseWithState.CancelReason__c = 'Duplicate';
                
                test.startTest();
                update caseWithState;
                system.assertEquals('OOPClosedReadOnly', [Select RecordType.DeveloperName From Case Where ID = :caseWithState.Id].RecordType.DeveloperName);
                test.stopTest();
                
            }
        }
        
        @isTest
        private static void testCaseWebToCase() {
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
                Date expectedResponseDate = BWC_CaseTriggerHandler.addDays(businessHours.ID, System.now(), Integer.valueOf(caseAdminState_List[0].ExpectedResponseDays__c)).date();
                Date expectedCloseDate = BWC_CaseTriggerHandler.addDays(businessHours.ID, System.now(),Integer.valueOf(caseAdminState_List[0].ExpectedCloseDays__c)).date();
                
                Case webCase = new Case();
                webCase.SubmissionSourceCode__c = caseAdminState_List[0].SubmissionSourceCode__c;
                webCase.State__c = caseAdminState_List[0].State__c;
                webCase.Type = 'OOP';
                webCase.Origin = 'Web Form';
                webCase.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
                webCase.Description = 'Test scenario: Web-to-Case';
                webCase.Status = 'New';
                webCase.Priority = 'Medium';
                webCase.BusinessHoursId = businessHours.ID;
                webCase.SuppliedEmail = 'email@example.com';
                webCase.LanguagePreference__c = 'English';
                
                // Service Address
                webCase.City__c = 'City';
                webCase.Country__c = 'United States';
                webCase.ServiceCustFirstName__c = 'First';
                webCase.ServiceCustLastName__c = 'Last';
                webCase.ServicePhone__c = '9995551212';
                webCase.StreetName__c = '123 Main St';
                webCase.ZipPostalCode__c = '55555';
                
                test.startTest();
                insert webCase;
                test.stopTest();
                
                Case newCase = [SELECT ServiceEmail__c,
                                BillingCity__c,
                                BillingCountry__c,
                                BillingCustFirstName__c,
                                BillingCustLastName__c,
                                BillingEmail__c,
                                BillingPhone__c,
                                BillingState__c,
                                BillingStreet__c,
                                BillingZip__c,
                                Language
                                FROM Case WHERE Id=:webCase.Id];
                
                // verify address and languge were updated
                System.assertEquals(webCase.City__c, newCase.BillingCity__c);
                System.assertEquals(webCase.ServicePhone__c, newCase.BillingPhone__c);
                System.assertEquals(webCase.SuppliedEmail, newCase.BillingEmail__c);
                System.assertEquals(webCase.SuppliedEmail, newCase.ServiceEmail__c);
                System.assertEquals(webCase.StreetName__c, newCase.BillingStreet__c);
                System.assertEquals(webCase.ZipPostalCode__c, newCase.BillingZip__c);
                System.assertEquals('en_US', newCase.Language);
            }
        }
        
        @isTest
        private static void testHandlePendingClosure() {
            Case testCase = TestData_Case.generateCase();
            try {
                Test.startTest();
                TestData_Case.closeCase(testCase, 'Pending Closed');
                Test.stopTest();
            }
            catch(Exception e) {
                System.assert(true, 'Exception not handled.');
            }
        }

        @isTest
        private static void testCaseMerge() {
            Account anAccount = BWC_TestDataFactory.createAccount();
            
            Case masterCase = TestData_Case.generateCase();
            Case case01 = TestData_Case.generateCase();
            Case case02 = TestData_Case.generateCase();
            
            masterCase.AccountId = anAccount.Id;
            case01.AccountId = anAccount.Id;
            case02.AccountId = anAccount.Id;
            
            String accountIdentifier1 = '177066919983';
            String accountIdentifier2 = '633011194';
            masterCase.AccountIdentifier__c = accountIdentifier1;
            case01.AccountIdentifier__c = accountIdentifier1;
            case02.AccountIdentifier__c = accountIdentifier1;
            
            masterCase.ExpectedCloseDate__c = Date.today() + 12;
            masterCase.ExpectedResponseDate__c = Date.today() + 2;
            case01.ExpectedCloseDate__c = Date.today() + 11;
            case01.ExpectedResponseDate__c = Date.today() + 1;
            case02.ExpectedCloseDate__c = Date.today();
            case02.ExpectedResponseDate__c = Date.today();
            
            List<Case> cases = new List<Case>{masterCase, case01, case02};
                update cases;
            
            List<Case> duplicates = new List<Case>{case01, case02};
                Database.MergeResult[] results = Database.merge(masterCase, duplicates, false);
            for(Database.MergeResult result : results) {
                if (result.isSuccess()) {
                    // Get the master ID from the result and validate it
                    System.debug('Master record ID: ' + result.getId());
                    System.assertEquals(masterCase.Id, result.getId());
                    
                    // Get the IDs of the merged records and display them
                    List<Id> mergedIds = result.getMergedRecordIds();
                    System.debug('IDs of merged records: ' + mergedIds);
                    
                    // Get the ID of the reparented record and
                    // validate that this the contact ID.
                    System.debug('Reparented record ID: ' + result.getUpdatedRelatedIds());
                    
                    // Validate expected close and response dates were updated
                    List<Case> updatedList = [SELECT ExpectedCloseDate__c,ExpectedResponseDate__c FROM Case WHERE Id = :masterCase.Id];
                    System.assertEquals(Date.today(), updatedList[0].ExpectedCloseDate__c);
                    System.assertEquals(Date.today(), updatedList[0].ExpectedResponseDate__c);
                }
                else {
                    for(Database.Error err : result.getErrors()) {
                        // Write each error to the debug output
                        System.debug(err.getMessage());
                    }
                }
            }
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
                testCase.Comments = 'Visa 1234 1234 1345 4567';
                testCase.Status = 'New';
                testCase.Priority='Medium';
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
        @isTest
        public static void testAssignmentRulesFire(){
            List<Case> caseList = new List<Case>();
            caseList.add(DataFactory_Test.createParentCase());
            insert caseList;
            BWC_CaseTriggerHandler.assignmentRuleFire(caseList);
        }
        
        @isTest
        public static Asset testGetAsset(){
            Account acc = BWC_TestDataFactory.createAccount();
            Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('wireless', acc);
            Set<Id> billAccId = new Set<Id>();
            billAccId.add(billAcc.Id);
            Asset assetRetrieved = BWC_CaseTriggerHandler.getAssets(billAccId);
            return assetRetrieved;
        }
        @isTest
        public static void testFetchParentaccount(){
            Account acc = BWC_TestDataFactory.createAccount();
            Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('wireless', acc);
            Set<Id> billAccId = new Set<Id>();
            billAccId.add(billAcc.Id);
            BWC_CaseTriggerHandler.fetchParentAccounts(billAccId);
        }
        @isTest
        public static void testcaseOwnerToTier2(){
            Set<String> tier2ListNames = new Set<String>();
            List<Case> caseList = new List<Case>();
            caseList.add(DataFactory_Test.createParentCase());
            BWC_CaseTriggerHandler.caseOwnerToTier2(caseList,tier2ListNames);
        }
        
        @isTest
        public static void testPopulateDate(){
            List<Case> caseList = new List<Case>();
            Account acc = BWC_TestDataFactory.createAccount();
            Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('wireless', acc);
            Case testCase = new Case();
                        testCase.Type='Order Action | Online fallout Wireless';
                        testCase.Billing_Account__c = billAcc.ID;
                        testCase.Origin='Phone';
                        testCase.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('Escalation').ID;
                        testCase.Description = 'Test scenario one';
                        testCase.Comments = 'Visa 1234 1234 1345 4567';
                        testCase.Status = 'New';
                        testCase.Priority='Medium';
                        testCase.CaseAction__c ='Wireless order fallout | DF';
                        testCase.RoutingAction__c='Tier 1';
            caseList.add(testcase);
            caseList.add(DataFactory_Test.createParentCase());
            insert caseList;
        }
        
        @isTest
        public static void testPostUpsert(){
            List<Case> caseList = new List<Case>();
            Account acc = BWC_TestDataFactory.createAccount();
            Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('wireless', acc);
            Case testCase = new Case();
                        testCase.Type='Order Action | Online fallout Wireless';
                        testCase.Billing_Account__c = billAcc.ID;
                        testCase.Origin='Phone';
                        testCase.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('Escalation').ID;
                        testCase.Description = 'Test scenario one';
                        testCase.Comments = 'Visa 1234 1234 1345 4567';
                        testCase.Status = 'New';
                        testCase.Priority='Medium';
                        testCase.CaseAction__c ='Wireless order fallout | DF';
                        testCase.RoutingAction__c='Tier 1';
            caseList.add(testcase);
            caseList.add(DataFactory_Test.createParentCase());
            upsert caseList;
        }
        
        @isTest
        public static void testPostUpdate(){
        List<Case> caseList = new List<Case>();
            caseList.add(DataFactory_Test.createParentCase());
            insert caseList;
        }
        
        @isTest
        public static void testPostInsert(){
            List<Case> caseList = new List<Case>();
            Account acc = BWC_TestDataFactory.createAccount();
            Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('wireless', acc);
            Case testCase = new Case();
                        testCase.Type='Order Action | Online fallout Wireless';
                        testCase.Billing_Account__c = billAcc.ID;
                        testCase.Origin='Phone';
                        testCase.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('Escalation').ID;
                        testCase.Description = 'Test scenario one';
                        testCase.Comments = 'Visa 1234 1234 1345 4567';
                        testCase.Status = 'New';
                        testCase.Priority='Medium';
                        testCase.CaseAction__c ='Wireless order fallout | DF';
                        testCase.RoutingAction__c='Tier 1';
            caseList.add(testcase);
            caseList.add(DataFactory_Test.createParentCase());
            insert caseList;
        }
        
        @isTest
        public static void testIntialize(){
            List<Case> caseList = new List<Case>();
            Account acc = BWC_TestDataFactory.createAccount();
            Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('wireless', acc);
            Case testCase = new Case();
                        testCase.Type='Order Action | Online fallout Wireless';
                        testCase.Billing_Account__c = billAcc.ID;
                        testCase.Origin='Phone';
                        testCase.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('Escalation').ID;
                        testCase.Description = 'Test scenario one';
                        testCase.Comments = 'Visa 1234 1234 1345 4567';
                        testCase.Status = 'New';
                        testCase.Priority='Medium';
                        testCase.CaseAction__c ='Wireless order fallout | DF';
                        testCase.RoutingAction__c='Tier 1';
            caseList.add(testcase);
            caseList.add(DataFactory_Test.createParentCase());
            insert caseList;
        }
        
        @isTest
        public static void testCalculate(){
            List<Case> caseList = new List<Case>();
            Account acc = BWC_TestDataFactory.createAccount();
            Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('wireless', acc);
            Case testCase = new Case();
                        testCase.Type='Order Action | Online fallout Wireless';
                        testCase.Billing_Account__c = billAcc.ID;
                        testCase.Origin='Phone';
                        testCase.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('Escalation').ID;
                        testCase.Description = 'Test scenario one';
                        testCase.Comments = 'Visa 1234 1234 1345 4567';
                        testCase.Status = 'Closed';
                        testCase.Priority='Medium';
                        testCase.CaseAction__c ='Wireless order fallout | DF';
                        testCase.RoutingAction__c='Tier 1';
            caseList.add(testcase);
            insert caseList;
        }
        
        //Filtering cases escalation & Handleing OrderFallout escalation case
        @isTest
        private static void filterCaseAfterInsertion() {
            System.debug('Inside the Filtering cases escalation');
            
            Account acc = BWC_TestDataFactory.createAccount();
            Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('wireless', acc);
            
            Plan__c pl = new Plan__c();
            pl.Plan_Name__c = 'test_plan';
            pl.Plan_Price_Code__c = 'Test_plan_Code';
            insert pl;
            
            Asset t_as = new Asset();
            t_as.Name = 't_as';
            t_as.Phone_Number__c ='99999999999';
            t_as.Billing_Account__c = billAcc.Id;
            t_as.Plan__c = pl.Id;
            insert t_as;
            
            Case testCase = new Case();
                    User oppAdministratorUser = [Select ID From User Where LastName='lastName_integrationAdmin' limit 1];
                    system.runAs(oppAdministratorUser){
                        testCase.Type='Order Action | Online fallout Wireless';
                        testCase.Billing_Account__c = billAcc.ID;
                        testCase.Origin='Phone';
                        testCase.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('Escalation').ID;
                        testCase.Description = 'Test scenario one';
                        testCase.Comments = 'Visa 1234 1234 1345 4567';
                        testCase.Status = 'New';
                        testCase.Priority='Medium';
                        testCase.CaseAction__c ='Wireless order fallout | DF';
                        testCase.RoutingAction__c='Tier 1';
                        Test.startTest();
                        insert testCase;
                        Test.stopTest();
                        Case c = [Select ID,Anchor_CTN__c,Price_Plan_Code__c From Case Where ID = :testCase.Id];
                        system.assertEquals(t_as.Phone_Number__c, c.Anchor_CTN__c);
                        system.assertEquals(pl.Plan_Price_Code__c, c.Price_Plan_Code__c);
            }
        }
        
        //Process Escalation case update for Billing Adjustment Cases 
        @isTest
        private static void processEscalationCase() {
                    Case testCase = new Case();
                    Account acct = BWC_TestDataFactory.createAccount();
                    Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('wireless', acct);
                    User oppAdministratorUser = [Select ID From User Where LastName='lastName_BillingAdmin' limit 1];
                    
                    system.runAs(oppAdministratorUser){
                        testCase.Type='Billing | Adjustment';
                        testCase.Billing_Account__c = billAcc.Id;
                        testCase.Origin='Phone';
                        testCase.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('Escalation').ID;
                        testCase.Description = 'Test scenario one';
                        testCase.Comments = 'Visa 1234 1234 1345 4567';
                        testCase.Status = 'New';
                        testCase.Priority='Medium';
                    insert testCase;
                    testCase.Status = 'Closed';
                    testCase.CloseNotes__c = 'Test Close';
                    testcase.Resolution__c = 'Corrected';
                        
                    Test.startTest();
                    update testCase;
                    Test.stopTest();
            }
        }
        
        //UpdateRountingOveride for cases with billing account.
    @isTest
        private static void testUpdateRoutingOverride(){
            Case testCase = new Case();
            Case testCase2 = new Case();
            Case testCase3 = new Case();
            
            List<Case> cList = new List<case>();
            Account acct = BWC_TestDataFactory.createAccount();
            Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('wireless', acct);
            User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
                system.runAs(oppAdministratorUser){
                        testCase.Type='OOP';
                        testCase.Billing_Account__c = billAcc.Id;
                        testCase.Origin='Phone';
                        testCase.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
                        testCase.Description = 'Test scenario one';
                        testCase.Comments = 'Visa 1234 1234 1345 4567';
                        testCase.Status = 'New';
                        testCase.Priority='Medium';
                        testCase.ExpectedCloseDate__c = system.today()+2;
                        cList.add(testCase);
                        testCase2.Type='OOP';
                        testCase2.Billing_Account__c = billAcc.Id;
                        testCase2.Origin='Phone';
                        testCase2.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
                        testCase2.Description = 'Test scenario two';
                        testCase2.Comments = 'Visa 1224 1234 1345 4567';
                        testCase2.Status = 'New';
                        testCase2.Priority='Medium';
                        testCase2.ExpectedCloseDate__c = system.today()+3;
                        cList.add(testCase2);
                        testCase3.Type='OOP';
                        testCase3.Billing_Account__c = billAcc.Id;
                        testCase3.Origin='Phone';
                        testCase3.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
                        testCase3.Description = 'Test scenario two';
                        testCase3.Comments = 'Visa 1224 1234 1345 4567';
                        testCase3.Status = 'New';
                        testCase3.Priority='Medium';
                        testCase3.ExpectedCloseDate__c = system.today()+9;
                        insert cList;
                        
                    Test.startTest();
                    insert testCase3;
                    Test.stopTest();
                    Case c = [Select ID,Routing_Override__c From Case Where ID = :testCase3.Id];
                    system.assertEquals('Intake', c.Routing_Override__c); 
                    }
        }
    }
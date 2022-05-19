@isTest
private class EvaluateAgentWorkLoad_CaseAction_tst {

 @testSetup
private static void testSetup(){
        Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
        Profile oopAgentProfile = [Select ID From Profile Where Name='Minimum Access OOP Agent'];
        Profile sysAdminProfile = [Select ID From Profile Where Name='System Administrator'];
        
        UserRole oopAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='OOPAdmin'];
        UserRole fieldAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='FieldAdmin'];
        UserRole fieldAgentRole = [SELECT Id FROM UserRole WHERE DeveloperName='FieldAgent'];
        UserRole fieldIntakeAdminRole = [SELECT Id FROM UserRole WHERE UserRole.Name='Intake Admin'];
        List<User> userList = new List<User>();
        
        User oppAdministratorUser = Utility_Test.createTestUserWithRole(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin', oopAdminRole.Id);
        User intakeAdministratorUser = Utility_Test.createTestUserWithRole(sysAdminProfile.ID, 'firstName_intakeAdmin', 'lastName_intakeAdmin', fieldIntakeAdminRole.Id);
        userList.add(intakeAdministratorUser);
        userList.add(oppAdministratorUser);
        //insert oppAdministratorUser;
        
        oppAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_oopAdmin2', 'lastName_oopAdmin2');
        oppAdministratorUser.UserRoleId = fieldAdminRole.ID;
        userList.add(oppAdministratorUser);
        
        //Agent
        User oopAgent = Utility_Test.createTestUser(oopAgentProfile.ID, 'firstName_oppAgent', 'lastName_oopAgent');
        oppAdministratorUser.UserRoleId = fieldAgentRole.ID;
        userList.add(oopAgent);
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
    	wrapper.permissionSetNames.add('OOPAgent');
    	wrapper.permissionSetNames.add('OOP_Agent');
        wrapperList.add(wrapper);
        
        wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = oopAgent;
        wrapper.permissionSetNames.add('OOPCaseCreate');
        wrapper.permissionSetNames.add('OOPCaseTransfer');
        wrapperList.add(wrapper);
        
        system.runAs(new User(Id=UserInfo.getUserId())){
            Utility_Test.assignPermissionSet(wrapperList);
            insert groupMember_List;
        }
        Utility_Test.createCaseAdminRecords();
        
    
    }//testSetup ends...
     @isTest
    private static void batch_test1(){
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
    
    
            Case caseWithState = new Case();
            caseWithState.SubmissionSourceCode__c = caseAdminState_List[0].SubmissionSourceCode__c;
            caseWithState.State__c = caseAdminState_List[0].State__c;
            caseWithState.ExpectedCloseDate__c = Date.parse('08/28/21');
            caseWithState.Type='OOP';
            caseWithState.Origin='Phone';
            caseWithState.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
            caseWithState.Description = 'Test scenario one';
            caseWithState.Status = 'New';
            //caseWithState.Source__c='Customer';
            caseWithState.Priority='Medium';
            caseWithState.CustomerType__c='Consumer';
            caseWithState.ownerid=UserInfo.getUserId();
            insert caseWithState;
            Case c=[select id,ownerid,ExpectedCloseDate__c from case where id=:caseWithState.id];
            c.ownerid=oppAdministratorUser.id;
            update c;
            Case_Action__c CA=new Case_Action__c();
            CA.case__c=c.id;
            CA.Expected_Close_Date__c=c.ExpectedCloseDate__c;
            CA.recordTypeId=Schema.SObjectType.Case_Action__c.getRecordTypeInfosByName().get('Field').getRecordTypeId();
            insert CA;
            CA.ownerid=oppAdministratorUser.id;
             update CA;
            
           test.startTest();
            EvaluateAgentWorkLoad_CaseAction_btc batch = new EvaluateAgentWorkLoad_CaseAction_btc();
            Database.executeBatch(batch);
           test.stopTest();
           }
    
    }
    }
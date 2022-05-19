/* ================================================* 
* @date :   4/22/2021   
* @group : Event
* @description : Test Class for Event trigger, EventTriggerhandler, EventTriggerHelper, CaseOOP_Service
================================================*/

@isTest
private class EventTriggerHandler_Test {
    
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
        
    }
    
    @isTest
    private static void testEventOPP(){
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
            Date expectedResponseDate = CaseTriggerHelper.addDays(businessHours.ID, System.now(), Integer.valueOf(caseAdminState_List[0].ExpectedResponseDays__c)).date();
            Date expectedCloseDate = CaseTriggerHelper.addDays(businessHours.ID, System.now(),Integer.valueOf(caseAdminState_List[0].ExpectedCloseDays__c)).date();
            
            Case oopCase = new Case();
            oopCase.SubmissionSourceCode__c = caseAdminState_List[0].SubmissionSourceCode__c;
            oopCase.State__c = caseAdminState_List[0].State__c;
            oopCase.Type='OOP';
            oopCase.Origin='Phone';
            oopCase.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
            oopCase.Description = 'Test scenario one';
            oopCase.Status = 'New';
            oopCase.Priority='Medium';
            oopCase.BusinessHoursId = businessHours.ID;
            
            test.startTest();
            insert oopCase;
            test.stopTest();
            
            Event e = new Event();
            e.OwnerId = oppAdministratorUser.Id;
            e.Subject='Test OPP Event';
            e.StartDateTime = System.today();
            e.EndDateTime = System.today()+5;
            e.WhatId = oopCase.Id;
    
            insert e;       
            
            oopCase = [Select Last_Activity_Date__c, SubmissionSourceCode__c,State__c, ExpectedCloseDate__c, ExpectedResponseDate__c,Feature__c,FeatureType__c From Case Where ID = :oopCase.Id];
            
            
            //system.assert(caseShare_List.size()>0);
            system.assertEquals(expectedResponseDate, oopCase.ExpectedResponseDate__c);
            system.assertEquals(expectedCloseDate, oopCase.ExpectedCloseDate__c);
            system.assertEquals(caseAdminState_List[0].CaseAdminFeature__c, oopCase.Feature__c);
            system.assertEquals(caseAdminState_List[0].CaseAdminFeatureType__c, oopCase.FeatureType__c);
            
            system.assertEquals(Date.today(), oopCase.Last_Activity_Date__c.date());
        }
    }
    
    
    
}
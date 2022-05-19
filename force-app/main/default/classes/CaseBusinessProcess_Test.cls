/*
* Class: CaseBusinessProcess
*/
@isTest
private class CaseBusinessProcess_Test{
    @TestSetup
    static void makeData(){
        List<Profile> profileList = [Select ID, Name From Profile Where ( Name='Minimum Access OOP Admin' OR Name='Minimum Access OOP Agent')];
        List<UserRole> userRoleList = [Select ID,DeveloperName From UserRole Where (DeveloperName='FieldAdmin' OR DeveloperName='FieldAgent' OR DeveloperName='OOPAdmin' OR DeveloperName='OOPAgent' OR DeveloperName='IntakeAdmin' OR DeveloperName='IntakeAgent')];
        
        List<User> userList = new List<User>();
        
        Profile oopAdminProfile, oopAgentProfile;
        for(Profile prof : profileList){
            if(prof.Name=='Minimum Access OOP Admin'){
                oopAdminProfile = prof;
            }
            else if(prof.Name=='Minimum Access OOP Agent'){
                oopAgentProfile = prof;
            }
        }

        UserRole oopAgent, oopAdmin, fieldAgent, fieldAdmin, intakeAdmin, intakeAgent;
        for(UserRole userRole : userRoleList){
            if(userRole.DeveloperName == 'OOPAgent'){
                oopAgent = userRole;
            }
            else if(userRole.DeveloperName == 'OOPAdmin'){
                oopAdmin = userRole;
            }
            else if(userRole.DeveloperName == 'FieldAdmin'){
                fieldAdmin = userRole;        
            }
            else if(userRole.DeveloperName == 'FieldAgent'){
                fieldAgent = userRole;
            }
            else if(userRole.DeveloperName == 'IntakeAgent'){
                intakeAgent = userRole;
            }
            else if(userRole.DeveloperName == 'IntakeAdmin'){
                intakeAdmin = userRole;
            }
        }

        User oppAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin');
        oppAdministratorUser.UserRoleId = oopAdmin.ID;
        userList.add(oppAdministratorUser);

        User intakeAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_intakeAdmin', 'lastName_intakeAdmin');
        intakeAdministratorUser.UserRoleId = intakeAdmin.ID;
        userList.add(intakeAdministratorUser);

        User fieldAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_fieldAdmin', 'lastName_fieldAdmin');
        fieldAdministratorUser.UserRoleId = fieldAdmin.ID;
        userList.add(fieldAdministratorUser);

        
        User oopAgentUser = Utility_Test.createTestUser(oopAgentProfile.ID, 'firstName_oppAgent', 'lastName_oopAgent');
        oopAgentUser.UserRoleId = oopAgent.ID;
        userList.add(oopAgentUser);

        User intakeAgentUser = Utility_Test.createTestUser(oopAgentProfile.ID, 'firstName_intakeAgent', 'lastName_intakeAgent');
        intakeAgentUser.UserRoleId = intakeAgent.ID;
        userList.add(intakeAgentUser);

        User fieldAgentUser = Utility_Test.createTestUser(oopAgentProfile.ID, 'firstName_fieldAgent', 'lastName_fieldAgent');
        fieldAgentUser.UserRoleId = fieldAgent.ID;
        userList.add(fieldAgentUser);

        insert userList;

        List<Utility_Test.UserPermissionSetWrapper> wrapperList = new List<Utility_Test.UserPermissionSetWrapper>();
        Utility_Test.UserPermissionSetWrapper wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = userList[0];
        wrapper.permissionSetNames.add('OOPCaseAdmin');
        wrapper.permissionSetNames.add('OOPCaseTransfer');
        wrapperList.add(wrapper);
        
        wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = userList[1];
        wrapper.permissionSetNames.add('OOPCaseAdmin');
        wrapper.permissionSetNames.add('OOPCaseTransfer');
        wrapperList.add(wrapper);

        wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = userList[2];
        wrapper.permissionSetNames.add('OOPCaseAdmin');
        wrapper.permissionSetNames.add('OOPCaseTransfer');
        wrapperList.add(wrapper);
        
        wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = userList[3];
        wrapper.permissionSetNames.add('OOPCaseCreate');
        wrapper.permissionSetNames.add('OOPCaseTransfer');
        wrapperList.add(wrapper);

        wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = userList[4];
        wrapper.permissionSetNames.add('OOPCaseCreate');
        wrapper.permissionSetNames.add('OOPCaseTransfer');
        wrapperList.add(wrapper);

        wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = userList[5];
        wrapper.permissionSetNames.add('OOPCaseCreate');
        wrapper.permissionSetNames.add('OOPCaseTransfer');
        wrapperList.add(wrapper);


        List<GroupMember> groupMember_List = new List<GroupMember>();
        Group intakeQueue = [Select ID From Group Where DeveloperName='IntakeQueue' And Type='Queue' Limit 1];
        Group oopAdminsGrp = [Select ID From Group Where DeveloperName='OOPAdmins' And Type='Regular'];
        Group oopAgentGrp = [Select ID From Group Where DeveloperName='OOPAgents' And Type='Regular'];
        Group WTRT = [Select ID From Group Where DeveloperName='WTRT' And Type='Queue'];
        Group OOPRegRespOther = [Select ID From Group Where DeveloperName='OOPRegRespOther' And Type='Queue'];

        GroupMember member = new GroupMember();
        member.UserOrGroupId = userList[1].ID;
        member.GroupId = intakeQueue.ID;
        groupMember_List.add(member);

        member = new GroupMember();
        member.UserOrGroupId = userList[2].ID;
        member.GroupId = oopAdminsGrp.ID;

        member = new GroupMember();
        member.UserOrGroupId = userList[3].ID;
        member.GroupId = oopAdminsGrp.ID; 
        groupMember_List.add(member);

         member = new GroupMember();
        member.UserOrGroupId = userList[4].ID;
        member.GroupId = oopAdminsGrp.ID; 
        groupMember_List.add(member);

         member = new GroupMember();
        member.UserOrGroupId = userList[5].ID;
        member.GroupId = oopAdminsGrp.ID; 
        groupMember_List.add(member);

        member = new GroupMember();
        member.UserOrGroupId = fieldAdministratorUser.ID;
        member.GroupId =  WTRT.ID;
        groupMember_List.add(member);
        
        member = new GroupMember();
        member.UserOrGroupId = fieldAdministratorUser.ID;
        member.GroupId =  OOPRegRespOther.ID;
        groupMember_List.add(member);

        system.runAs(new User(Id=UserInfo.getUserId())){
            Utility_Test.assignPermissionSet(wrapperList);
            insert groupMember_List;
        }
        Utility_Test.createCaseAdminRecords();
    }


    @isTest
    private static void populateAddress_test1(){
        //intakeAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_intakeAdmin', 'lastName_intakeAdmin');
        User intakeAdministratorUser = [Select ID From User Where LastName='lastName_intakeAdmin'];
        system.runAs(intakeAdministratorUser){
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
            
            Case caseWithState = new Case();
            caseWithState.SubmissionSourceCode__c = caseAdminState_List[0].SubmissionSourceCode__c;
            caseWithState.State__c = caseAdminState_List[0].State__c;
            caseWithState.Type='OOP';
            caseWithState.Origin='Phone';
            caseWithState.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
            caseWithState.Description = 'Test scenario one';
            caseWithState.Status = 'New';
            caseWithState.Priority='Medium';
            caseWithState.CustomerType__c='Consumer';
            caseWithState.BusinessHoursId = businessHours.ID;
            caseWithState.city__c='Phoenix';
            //caseWithState.ServiceCustLastName__c='test';
            caseWithState.StreetName__c='test';
            
            
            
            test.startTest();
            insert caseWithState;
            test.stopTest();
            //caseWithState = new Case();
            caseWithState = [Select city__c, BillingCity__c From Case Where ID = :caseWithState.ID];
            system.assertEquals(caseWithState.city__c,caseWithState.BillingCity__c);
            
        }
    }

    /*
     @isTest
    private static void validateClosedCase_test1(){
        CaseAdmin__c newCaseAdmin =  new CaseAdmin__c();
        newCaseAdmin.SubmissionSource__c ='3C-State Commission';
        newCaseAdmin.ExpectedCloseDays__c=17;
        newCaseAdmin.ExpectedResponseDays__c=17;
        newCaseAdmin.Feature__c='Regulatory';
        newCaseAdmin.FeatureType__c='FCC';
        newCaseAdmin.ResponseRequired__c=true;
        newCaseAdmin.Name='4 FCC';
        newCaseAdmin.Subject__c='External';
        //newCaseAdmin.State__c = 'Alaska';
        insert newCaseAdmin;
        
        CaseAdminState__c adminstate = new CaseAdminState__c();
        adminstate.CaseAdminValue__c = newCaseAdmin.id;
        adminstate.State__c = 'Guam';
        adminstate.ExpectedResponseDays__c = 17;
        adminstate.ExpectedCloseDays__c = 17;
        insert adminstate;
                //intakeAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_intakeAdmin', 'lastName_intakeAdmin');
        User intakeAdministratorUser = [Select ID From User Where LastName='lastName_intakeAdmin'];
        system.runAs(intakeAdministratorUser){
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
            
            Case caseWithState = new Case();
            caseWithState.SubmissionSourceCode__c = caseAdminState_List[0].SubmissionSourceCode__c;
            caseWithState.State__c = caseAdminState_List[0].State__c;
            caseWithState.Type='OOP';
            caseWithState.Origin='Phone';
            caseWithState.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
            caseWithState.Description = 'Test scenario one';
            caseWithState.Status = 'Pending Closed';
            caseWithState.Priority='Medium';
            caseWithState.CustomerType__c='Consumer';
            caseWithState.BusinessHoursId = businessHours.ID;
            caseWithState.City__c='Phoenix';
            caseWithState.ServiceCustLastName__c='test';
            caseWithState.StreetName__c='test';
            caseWithState.ZipPostalCode__c='30564';
            caseWithState.ServiceEmail__c='test@test.com';
            caseWithState.Country__c='United States';
            caseWithState.ServicePhone__c='7865437265';
            caseWithState.Product__c = 'DIRECTV STREAM';

           	caseWithState.ProblemCode__c = 'Billing';
            caseWithState.ProblemCode2__c = 'Equipment/device/Next credits';
           	caseWithState.ProblemCode3__c = 'Disputing cost for equipment (phone sales tax, Next credits, Next Up charges, etc.)';
            caseWithState.Resolution__c='Corrected';
            caseWithState.Resolution2__c='Adjustment';
            caseWithState.SatisfactionIndicator__c='Satisfied';
            caseWithState.CloseNotes__c ='Testing';
            test.startTest();
            insert caseWithState;
            caseBusinessProcess.validateCancelledCase(caseWithState);
            caseBusinessProcess.validateClosedCase(caseWithState);
            caseWithState.State__c = 'Guam';
            caseWithState.status ='Closed';
            caseWithState.CloseNotes__c = 'testclosenote';
           	caseWithState.ProblemCode__c = 'Billing';
            caseWithState.SatisfactionIndicator__c = 'Satisfied';
            caseWithState.Product__c = 'DIRECTV STREAM';
            caseWithState.Resolution__c='Corrected';
            caseWithState.Resolution2__c='Adjustment';
            caseWithState.Root_Cause__c = 'Other';
            update caseWithState;
            system.debug('SubmissionSourceCode__c****'+caseAdminState_List[0].SubmissionSourceCode__c);
            system.debug('State__c****'+caseAdminState_List[0].State__c);
            test.stopTest();
      }
    }
    */

    @isTest
    private static void validateClosedCase_test2(){
        CaseAdmin__c newCaseAdmin =  new CaseAdmin__c();
        newCaseAdmin.SubmissionSource__c ='3C-State Commission';
        newCaseAdmin.ExpectedCloseDays__c=17;
        newCaseAdmin.ExpectedResponseDays__c=17;
        newCaseAdmin.Feature__c='Regulatory';
        newCaseAdmin.FeatureType__c='FCC';
        newCaseAdmin.ResponseRequired__c=true;
        newCaseAdmin.Name='4 FCC';
        newCaseAdmin.Subject__c='External';
        //newCaseAdmin.State__c = 'Alaska';
        insert newCaseAdmin;
        
        CaseAdminState__c adminstate = new CaseAdminState__c();
        adminstate.CaseAdminValue__c = newCaseAdmin.id;
        adminstate.State__c = 'Guam';
        adminstate.ExpectedResponseDays__c = 17;
        adminstate.ExpectedCloseDays__c = 17;
        //insert adminstate;
                //intakeAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_intakeAdmin', 'lastName_intakeAdmin');
        User intakeAdministratorUser = [Select ID From User Where LastName='lastName_intakeAdmin'];
        system.runAs(intakeAdministratorUser){
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
            
            Case caseWithState = new Case();
            caseWithState.SubmissionSourceCode__c = caseAdminState_List[0].SubmissionSourceCode__c;
            caseWithState.State__c = caseAdminState_List[0].State__c;
            caseWithState.Type='OOP';
            caseWithState.Origin='Phone';
            caseWithState.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
            caseWithState.Description = 'Test scenario one';
            caseWithState.Status = 'New';
            caseWithState.Priority='Medium';
            caseWithState.CustomerType__c='Consumer';
            caseWithState.BusinessHoursId = businessHours.ID;
            caseWithState.city__c='Phoenix';
            caseWithState.ServiceCustLastName__c='test';
            caseWithState.StreetName__c='test';
            test.startTest();
            insert caseWithState;
            caseBusinessProcess.validateCancelledCase(caseWithState);
            caseBusinessProcess.validateClosedCase(caseWithState);
            caseWithState.State__c = '';
            caseWithState.status = 'Cancelled';
            caseWithState.CancelReason__c = 'Duplicate';
            update caseWithState;
            system.debug('SubmissionSourceCode__c****'+caseAdminState_List[0].SubmissionSourceCode__c);
            system.debug('State__c****'+caseAdminState_List[0].State__c);
            test.stopTest();
      }
    }
}
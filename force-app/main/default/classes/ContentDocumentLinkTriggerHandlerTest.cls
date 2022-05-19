/*------------------------------------------------------------------------
Positive and negative tests for the business logic implemented in ContentDocumentLink Trigger context to restrict ContentDocumentLink deletion for Content Notes.

History
<Date>      <Authors Name>     <Brief Description of Change>
26-May-2020  Mammet Developer   Test Class for ContentDocumentLink Trigger, ContentDocumentLinkTriggerHelper, ContentDocumentLinkTriggerHandler. 
 
----------------------------------------------------------------------------*/
@isTest
private class ContentDocumentLinkTriggerHandlerTest {
    
    @testSetup
    private static void testSetup(){
        List<Profile> profileList = [Select ID,Name From Profile Where Name IN ('Minimum Access OOP Admin','Minimum Access OOP Agent')];
        User oppAdministratorUser, oopAgent;
        List<User> oopUser_List = new List<User>();
        for(Profile oppProfile : profileList ){
            if(oppProfile.Name.equalsIgnoreCase('Minimum Access OOP Admin')){
                oppAdministratorUser = Utility_Test.createTestUser(oppProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin');
                oopUser_List.add(oppAdministratorUser);
            }
            if(oppProfile.Name.equalsIgnoreCase('Minimum Access OOP Agent')){
                oopAgent = Utility_Test.createTestUser(oppProfile.ID, 'firstName_oppAgent', 'lastName_oopAgent');    
                oopUser_List.add(oopAgent);
            } 
            
        }
        insert oopUser_List;
        List<Utility_Test.UserPermissionSetWrapper> wrapperList = new List<Utility_Test.UserPermissionSetWrapper>();
        Utility_Test.UserPermissionSetWrapper wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = oopUser_List[0];
        wrapper.permissionSetNames.add('OOPCaseFullPermission');
        wrapperList.add(wrapper);
            
        wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = oopUser_List[1];
        wrapper.permissionSetNames.add('OOPCaseCreate');
        wrapper.permissionSetNames.add('OOPCaseTransfer');
        wrapperList.add(wrapper);
        
        GroupMember groupMember = new GroupMember();
        groupMember.GroupId = MetadataSelector.queueToDeveloperName_Map.get('IntakeQueue').ID;
        groupMember.UserOrGroupId = oopUser_List[1].ID;
        system.runAs(new User(Id=UserInfo.getUserId())){
            Utility_Test.assignPermissionSet(wrapperList);
            insert groupMember;
        }
        Utility_Test.createCaseAdminRecords();
    }
    
    @isTest
    private static void filterBeforeDeleteForOOPAdminUser(){
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
            
            ContentNote caseNotes = new ContentNote();
            caseNotes.Content = Blob.valueOf('Test Note..');
            caseNotes.OwnerId = oppAdministratorUser.Id;
            caseNotes.Title = 'test note';
            insert caseNotes;
            
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = caseNotes.Id;
            contentDocumentLink.LinkedEntityId = caseWithState.Id;
            test.startTest();
            try{
                delete caseNotes;
            }
            catch(DmlException dmlExe){
                system.assert(dmlExe.getMessage().containsIgnoreCase(Label.NotesCaseDeletion));
                system.debug('DML exe:: '+dmlExe.getCause()+'--'+dmlExe.getMessage());
            }
            test.stopTest();
        }
    }
     @isTest
    private static void filterBeforeDeleteForOOPAgentUser(){
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAgent'];
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
            
            ContentNote caseNotes = new ContentNote();
            caseNotes.Content = Blob.valueOf('Test Note..');
            caseNotes.OwnerId = oppAdministratorUser.Id;
            caseNotes.Title = 'test note';
            insert caseNotes;
            
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = caseNotes.Id;
            contentDocumentLink.LinkedEntityId = caseWithState.Id;
            insert contentDocumentLink;
            test.startTest();
            try{
                delete contentDocumentLink;
            }
            catch(DmlException dmlExe){
                system.assert(dmlExe.getMessage().containsIgnoreCase(Label.NotesCaseDeletion));
                system.debug('DML exe:: '+dmlExe.getCause()+'--'+dmlExe.getMessage());
            }
            test.stopTest();
        }
    }
}
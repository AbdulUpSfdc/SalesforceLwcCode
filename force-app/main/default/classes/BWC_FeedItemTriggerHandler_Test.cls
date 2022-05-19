/*user story: 1675
Initial version - 03/22/2021
*/
@isTest
public class BWC_FeedItemTriggerHandler_Test {
    
    
    @isTest
    private static void testSetup(){
        Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
        
        UserRole oopAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='OOPAdmin'];
        UserRole fieldAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='FieldAdmin'];
        
        List<User> userList = new List<User>();

        User oppAdministratorUser = Utility_Test.createTestUserWithRole(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin', oopAdminRole.Id);
        userList.add(oppAdministratorUser);
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
    
    @IsTest(SeeAllData=true)
    public static void maskBodyTest(){
        User oppAdministratorUser = [Select ID From User Where Id=:UserInfo.getUserId()];
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
            //testCase.SubmissionSourceCode__c = caseAdminState_List[0].SubmissionSourceCode__c;
            //testCase.State__c = caseAdminState_List[0].State__c;
        testCase.Type='OOP';
            testCase.Origin='Phone';
            testCase.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
            testCase.Description = 'Test scenario one';
            testCase.Status = 'New';
            testCase.Priority='Medium';
            //testCase.CustomerType__c='Consumer';
            testCase.BusinessHoursId = businessHours.ID;
            insert testCase;
            
            
            FeedItem feedPost = new FeedItem();
            feedPost.ParentId = [SELECT ID FROM CASE WHERE ID = :testCase.Id ].Id;
            feedPost.Body = postBody;
            
            test.startTest();
            insert feedPost;
            test.stopTest();
            
            feedPost = [SELECT Id, Body, ParentId from FeedItem WHERE Id = :feedPost.Id];
            //BWC_FeedItemTriggerHelperClass.postFeedItemWithMentions('Test Message', Userinfo.getUserId(), testCase.id);
            System.assertEquals('Social: xxxxx9999', feedPost.Body);
    }
    }

}
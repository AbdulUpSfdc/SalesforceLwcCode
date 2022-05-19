@isTest
public class BWC_CustomRelatedListControllerTest {
    
    
    @isTest
    private static void testSetup(){
        Profile oopAdminProfile = [Select ID From Profile Where Name='System Administrator'];
        
        UserRole oopAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='OOPAdmin'];
        UserRole fieldAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='FieldAdmin'];
        
        List<User> userList = new List<User>();
        User oppAdministratorUser = Utility_Test.createTestUserWithRole(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin', oopAdminRole.Id);
        userList.add(oppAdministratorUser);
        insert userList;
    }
    
    @IsTest(SeeAllData=true)
    public static void contentDocumentTst(){
        User oppAdministratorUser = [Select ID From User Where Id=:UserInfo.getUserId()];
        Test.startTest();
        system.runAs(oppAdministratorUser){
            Case accRecord = TestData_Case.generateCase();

            Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body to be insert in test class for testing the'); 
            
            ContentVersion contentVersion_1 = new ContentVersion(
                Title='SampleTitle', 
                PathOnClient ='SampleTitle.jpg',
                VersionData = bodyBlob, 
                origin = 'H'
            );
            insert contentVersion_1;
            
            ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId 
                                               FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];
            
            ContentDocumentLink contentlink = new ContentDocumentLink();
            contentlink.LinkedEntityId = accRecord.id;
            contentlink.contentdocumentid = contentVersion_2.contentdocumentid;
            contentlink.ShareType = 'V';
            insert contentlink;
            
            System.assertEquals(contentlink.ContentDocumentId,contentVersion_2.ContentDocumentId );
            BWC_CustomRelatedListController.getFilesList(accRecord.id);
            BWC_CustomRelatedListController.removeFromRecord(contentVersion_2.ContentDocumentId,accRecord.id);
            BWC_CustomRelatedListController.deleteFile(contentVersion_2.ContentDocumentId);
            Test.stopTest();
        }
    }
    
}
@isTest
public class KnowledgePublishControllerTest {
    public static final String ROLE_NAME = 'TestingTeam';
    private static final String DATE_FORMAT = 'ssSSS';
    @testSetup
    public static void testData(){
        
        User u = KM_TestDataFactory.createContentSponsorUser('rt12345');
        Knowledge__kav  knowledgeFrontlineOnly = new Knowledge__kav(
            BW_Is_Urgent__c =  false,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test-fromline',
            UrlName = 'Frontline-Test-fromline',
            ContentSponsor__c = u.ATTUID__c,
            CustomPublicationStatus__c = 'Ready For Archiving',
            CustomValidationStatus__c = TRUE
        );
        insert knowledgeFrontlineOnly;
    }
    
    public static String generateEmail() {
        String orgId = UserInfo.getOrganizationId();
        String seconds = system.now().format(DATE_FORMAT);
        return orgId + seconds + '@att.test.com';
    }     
    
    public static testmethod void testUnitOne(){
            User u = KM_TestDataFactory.createContentSponsorUser('rt12345');

        	PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'KM_Admin_Custom'];
            insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);
            
            Group gp = new Group();
            gp.Name = 'Test';
            insert gp;
            
            GroupMember gpm = new GroupMember();
            gpm.GroupId = gp.Id;
            gpm.UserOrGroupId = u.Id;
            insert gpm;
            
       
        System.runAs(u) {
            Knowledge__kav  knowledgeFrontlineOnly = new Knowledge__kav(
                BW_Is_Urgent__c =  false,
                BW_FrontLine_Focus__c = true,
                Title = 'Frontline-Test-fromlineUnit',
                UrlName = 'Frontline-Test-fromlineUnit',
                ContentSponsor__c = u.ATTUID__c,
                CustomPublicationStatus__c = 'Ready for Publication',
                // NumberOfArchivedArticles__c = 0,
                CustomValidationStatus__c = FALSE
            );
            test.startTest();
            insert knowledgeFrontlineOnly;
            Knowledge__kav knw = [
                SELECT Id, BW_Is_Urgent__c,NumberOfArchivedArticles__c,CustomValidationStatus__c,CustomPublicationStatus__c
                from Knowledge__kav
                WHERE Title = 'Frontline-Test-fromlineUnit'
            ];
            system.debug('Test knw'+knw);
            try {
                KnowledgePublishController.updateKnowledgeRecord(knw.Id);
            } catch (AuraHandledException e) {
                //  System.assertEquals(0, knw.NumberOfArchivedArticles__c);
                System.assert(e.getMessage().contains('Custom Validation Status must be set to true to publish article'));
            }
        }
        test.stopTest();
    }
    public static testmethod void testUnitTwo(){ 
          User u = KM_TestDataFactory.createContentSponsorUser('rt12345');

        	PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'KM_Admin_Custom'];
            insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);
            
            Group gp = new Group();
            gp.Name = 'Test';
            insert gp;
            
            GroupMember gpm = new GroupMember();
            gpm.GroupId = gp.Id;
            gpm.UserOrGroupId = u.Id;
            insert gpm;
            
       
        System.runAs(u) {
            Knowledge__kav  knowledgeFrontlineOnly = new Knowledge__kav(
                BW_Is_Urgent__c =  false,
                BW_FrontLine_Focus__c = true,
                Title = 'Frontline-Test-fromlineUnitFour',
                UrlName = 'Frontline-Test-fromlineUnitFour',
                ContentSponsor__c = u.ATTUID__c
                // CustomPublicationStatus__c = 'Ready for Publication',
                // NumberOfArchivedArticles__c = 0,
                // CustomValidationStatus__c = FALSE
            );
            test.startTest();
            insert knowledgeFrontlineOnly;
            BWKnowledgeArticleLink__c articleLink = new BWKnowledgeArticleLink__c(
                Knowledge_Article__c  = knowledgeFrontlineOnly.Id,
                Status__c = 'Archived'
            );
            INSERT articleLink;
            Knowledge__kav knw = [
                SELECT Id, BW_Is_Urgent__c,NumberOfArchivedArticles__c,CustomValidationStatus__c,CustomPublicationStatus__c
                from Knowledge__kav
                WHERE Title = 'Frontline-Test-fromlineUnitFour'
            ];
            system.debug('Test knw'+knw);
            try {
                KnowledgePublishController.updateKnowledgeRecord(knw.Id);
            } catch (AuraHandledException e) {
                //  System.assertEquals(0, knw.NumberOfArchivedArticles__c);
                //   System.assert(e.getMessage().contains('Validation failed due references to expired and/or archived articles within the article body. Please review the Status in the Knowledge Article Links list for errors and re-publish.'));
            }
        }
      test.stopTest();     
    }
    
    public static testmethod void testUnitThree(){
        User u = KM_TestDataFactory.createContentSponsorUser('rt12345');

        Knowledge__kav  knowledgeFrontlineOnly = new Knowledge__kav(
            BW_Is_Urgent__c =  false,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test-fromlineUnitFive',
            UrlName = 'Frontline-Test-fromlineUnitFive',
            ContentSponsor__c = u.ATTUID__c,
            CustomPublicationStatus__c = 'Ready for Publication',
            CustomValidationStatus__c = TRUE,
            BWScheduledArticlePublicationDate__c = system.now().addHours(1)
        );
        test.startTest();
        insert knowledgeFrontlineOnly;
        
        Knowledge__kav knw = [
            SELECT Id, BW_Is_Urgent__c,BWScheduledArticlePublicationDate__c,NumberOfArchivedArticles__c,CustomValidationStatus__c,CustomPublicationStatus__c
            from Knowledge__kav
            WHERE Title = 'Frontline-Test-fromlineUnitFive'
        ];
        system.debug('Test knw'+knw);
        try {
            KnowledgePublishController.updateKnowledgeRecord(knw.Id);
        } catch (AuraHandledException e) {
            //  System.assertEquals(0, knw.NumberOfArchivedArticles__c);
            //  System.assert(e.getMessage().contains('Article Scheduled for Publishing, cannot be published immediately.'));
        }
        test.stopTest();       
    }
    
    public static testmethod void testUnitGroup(){
          User u; 
  	User sysadminUser = KM_TestDataFactory.createSysAdminUser();
        System.runAs(SysadminUser) {
            u = KM_TestDataFactory.createContentSponsorUser('rt12345');
        // Insert group
            Group grp = new Group();
            grp.Name = 'Auto Publish Permission Authors';
            insert grp;
            
            //Create Group Member
            GroupMember grpMem1 = new GroupMember();
            grpMem1.UserOrGroupId = u.Id;
            grpMem1.GroupId = grp.Id;
            Insert grpMem1;
        }    
            
            Knowledge__kav  knowledgeFrontlineOnly = new Knowledge__kav(
                BW_Is_Urgent__c =  false,
                BW_FrontLine_Focus__c = true,
                Title = 'Frontline-Test-fromlineUnitGroup',
                UrlName = 'Frontline-Test-fromlineUnitGroup',
                ContentSponsor__c = u.ATTUID__c,
                CustomValidationStatus__c = TRUE
                //BWScheduledArticlePublicationDate__c = system.now()
            );
            test.startTest();
            insert knowledgeFrontlineOnly;
            
            Knowledge__kav knw = [
                SELECT Id, BW_Is_Urgent__c,PublishStatus,BWScheduledArticlePublicationDate__c,NumberOfArchivedArticles__c,CustomValidationStatus__c,CustomPublicationStatus__c
                from Knowledge__kav
                WHERE Title = 'Frontline-Test-fromlineUnitGroup'
            ];
            system.debug('Test knw'+knw);
            try {
                KnowledgePublishController.updateKnowledgeRecord(knw.Id);
            } catch (AuraHandledException e) {
                //  System.assertEquals(0, knw.NumberOfArchivedArticles__c);
                System.assert(e.getMessage().contains('You are not authorized to auto publish. Please assign to the content strategy team.'));
            }
       
        test.stopTest();
        
    }
    /*
     public static testmethod void testUnitFive(){
        User u;
         User sysadminUser = KM_TestDataFactory.createSysAdminUser();
        System.runAs(SysadminUser) {
           
          u = KM_TestDataFactory.createContentSponsorUser('rt12345');
  
        // Insert group
            Group grp = new Group();
            grp.Name = 'Auto Publish Permission Authors';
            insert grp;
            
            //Create Group Member
            GroupMember grpMem1 = new GroupMember();
            grpMem1.UserOrGroupId = u.Id;
            grpMem1.GroupId = grp.Id;
            Insert grpMem1;
            
        }
        System.runAs(u) {
            Knowledge__kav  knowledgeFrontlineOnly = new Knowledge__kav(
                BW_Is_Urgent__c =  false,
                BW_FrontLine_Focus__c = true,
                Title = 'Frontline-Test-fromlineUnit',
                UrlName = 'Frontline-Test-fromlineUnit',
                ContentSponsor__c = u.ATTUID__c,
                CustomPublicationStatus__c = 'Test',
                // NumberOfArchivedArticles__c = 0,
                CustomValidationStatus__c = FALSE
            );
            
            insert knowledgeFrontlineOnly;
             test.startTest();
            Knowledge__kav knw = [
                SELECT Id, BW_Is_Urgent__c,NumberOfArchivedArticles__c,CustomValidationStatus__c,CustomPublicationStatus__c
                from Knowledge__kav
                WHERE Title = 'Frontline-Test-fromlineUnit'
            ];
            system.debug('Test knw'+knw);
            try {
                KnowledgePublishController.updateKnowledgeRecord(knw.Id);
            } catch (AuraHandledException e) {
                 System.assertEquals(0, knw.NumberOfArchivedArticles__c);
               // System.assert(e.getMessage().contains('You are not authorized to auto publish. Please assign to the Content Strategy Team'));
               // System.assertEquals(e.getMessage(), e.getMessage());
            }
        }
        test.stopTest();  
    }
    */
     public static testmethod void testUnitException(){
        
        User u = KM_TestDataFactory.createContentSponsorUser('rt12345');
  
        // Insert group
           
            
           
                 
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'KM_Admin_Custom'];
            insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);
            
            Group gp = new Group();
            gp.Name = 'Test';
            insert gp;
            
            GroupMember gpm = new GroupMember();
            gpm.GroupId = gp.Id;
            gpm.UserOrGroupId = u.Id;
            insert gpm;
            
       
        
        System.runAs(u) {
            Knowledge__kav  knowledgeFrontlineOnly = new Knowledge__kav(
                BW_Is_Urgent__c =  false,
                BW_FrontLine_Focus__c = true,
                Title = 'Frontline-Test-fromlineUnit',
                UrlName = 'Frontline-Test-fromlineUnit',
                ContentSponsor__c = u.ATTUID__c,
                CustomPublicationStatus__c = 'Test',
                // NumberOfArchivedArticles__c = 0,
                CustomValidationStatus__c = FALSE
            );
            test.startTest();
            insert knowledgeFrontlineOnly;
            Knowledge__kav knw = [
                SELECT Id, BW_Is_Urgent__c,NumberOfArchivedArticles__c,CustomValidationStatus__c,CustomPublicationStatus__c
                from Knowledge__kav
                WHERE Title = 'Frontline-Test-fromlineUnit'
            ];
            system.debug('Test knw'+knw);
            try {
                KnowledgePublishController.updateKnowledgeRecord(knw.Id);
            } catch (AuraHandledException e) {
                 System.assertEquals(0, knw.NumberOfArchivedArticles__c);
            }
        }
        test.stopTest();  
        
    }
    
}
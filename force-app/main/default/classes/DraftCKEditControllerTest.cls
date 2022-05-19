@isTest
public class DraftCKEditControllerTest {
    public static final String ROLE_NAME = 'TestingTeam';
    private static final String DATE_FORMAT = 'ssSSS';
    
	@testSetup
    public static void testData(){
        
        User u;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            UserRole userRole;
            userRole = new UserRole(DeveloperName = ROLE_NAME, Name = ROLE_NAME);
            insert userRole;
            String  profileName = 'System Administrator';
            String emailName = generateEmail();
            
            u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id,
                LastName = 'last',
                FirstName = 'first',
                Email = emailName,
                Username = emailName,
                Alias = emailName.substring(18, 23),
                CompanyName = 'Testing',
                FederationIdentifier = 'ABCD',
                TimeZoneSidKey = 'America/Chicago',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                IsActive=true,
                UserPermissionsKnowledgeUser =true,
                UserRoleId = userRole.Id
            );
            
            insert u;
        }
        
        
        KT_Transformation__c KTTransformObj = new KT_Transformation__c(
            KT_Article_Number__c ='000019304-061703T',
            KT_Article_Title__c = 'Test KT Article',
            KT_Article_Summary__c = 'Test KT Article Summary'
        );
        insert KTTransformObj;
       
    }
    public static String generateEmail() {
        String orgId = UserInfo.getOrganizationId();
        String seconds = system.now().format(DATE_FORMAT);
        return orgId + seconds + '@att.test.com';
    }
    
    public static testmethod void testUnitOne(){
        
        
        User thisUser = [ select Id,name from User where Id = :UserInfo.getUserId() ];
        system.debug(thisUser.name);
        
        System.runAs(thisUser) {
            KT_Transformation__c testKtTransformObj = [Select id,KT_Article_Title__c from KT_Transformation__c limit 1];
            system.debug(testKtTransformObj.KT_Article_Title__c);
            KT_Draft__c  KTDraftObj = new KT_Draft__c(
                KT_Transformation__c = testKtTransformObj.Id
            );
            insert KTDraftObj;
            Test.startTest();
            try {
                ApexPages.StandardController sc = new ApexPages.StandardController(KTDraftObj);
                DraftCKEditController Testobj = new DraftCKEditController(sc);
                Boolean resultObtained = Testobj.isEditSourceFields;
                system.assertEquals(true, resultObtained);
            } catch (AuraHandledException e) {
                system.debug(e.getmessage());
            }
            Test.stopTest();
        }        
    }
    public static testmethod void testUnitTwo(){

        User u;
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            Profile p = [select id from profile where name='Bellwether Power User'];
            u = new User(alias = 'standt', email='standarduser@testorg.com', 
                         emailencodingkey='UTF-8', lastname='Testing', 
                         languagelocalekey='en_US', 
                         localesidkey='en_US', profileid = p.Id, 
                         timezonesidkey='America/Los_Angeles', IsActive=true,
                         UserPermissionsKnowledgeUser =true,
                         username='standarduser@testorg.com123');
            insert u;
            
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'KM_Admin_Custom'];
            insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);
        }
        System.runAs(u) {
            KT_Transformation__c testKtTransformObj = [Select id,KT_Article_Title__c from KT_Transformation__c limit 1];
            system.debug(testKtTransformObj.KT_Article_Title__c);
            KT_Draft__c  KTDraftObj = new KT_Draft__c(
                KT_Transformation__c = testKtTransformObj.Id
            );
            insert KTDraftObj;
            Test.startTest();
            try {
                ApexPages.StandardController sc = new ApexPages.StandardController(KTDraftObj);
                DraftCKEditController Testobj = new DraftCKEditController(sc);
                Boolean resultObtained = Testobj.isEditSourceFields;
                system.assertEquals(false, resultObtained);
            } catch (AuraHandledException e) {
                system.debug(e.getmessage());
            }
            Test.stopTest();
        }        
    }
    
    public static testmethod void testUnitPageReference(){
        User thisUser = [ select Id,name from User where Id = :UserInfo.getUserId() ];
        system.debug(thisUser.name);

        System.runAs(thisUser) {
            KT_Transformation__c testKtTransformObj = [Select id,KT_Article_Title__c from KT_Transformation__c limit 1];
            system.debug(testKtTransformObj.KT_Article_Title__c);
            KT_Draft__c  KTDraftObj = new KT_Draft__c(
                KT_Transformation__c = testKtTransformObj.Id
            );
            insert KTDraftObj;
            Test.startTest();
            try {
                ApexPages.StandardController sc = new ApexPages.StandardController(KTDraftObj);
                
                DraftCKEditController Testobj = new DraftCKEditController(sc);
                Boolean resultObtained = Testobj.isEditSourceFields;
                PageReference testPageRef = Testobj.DraftPageSave();
                
                system.assert(testPageRef!=null);
            } catch (AuraHandledException e) {
                system.debug(e.getmessage());
            }
            Test.stopTest();
        }        
    }
}
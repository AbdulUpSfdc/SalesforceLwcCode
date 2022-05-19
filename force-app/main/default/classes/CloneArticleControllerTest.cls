@isTest
public with sharing class CloneArticleControllerTest {
    @TestSetup
    public static void testData(){
        List<Knowledge__kav> knowledgeArticles = new List<Knowledge__kav>();
        List<User> users = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name='Minimum Access Admin'];
        for(Integer i=0; i<2; i++){
            User u =new User(   ATTUID__c = 'Test' + i,
                             FederationIdentifier = 'Test' + i,
                             username = 'testatt' + i + '@att.com',
                             Email = 'testatt@att.com',
                             ProfileId = p.Id,
                             LastName = 'ATT' + i,
                             Alias = 'Test'+i,
                             TimeZoneSidKey='America/New_York', 
                             LocaleSidKey='en_US', 
                             EmailEncodingKey='UTF-8', 
                             LanguageLocaleKey='en_US',
                             UserPermissionsKnowledgeUser = True,
                             IsActive=true
                            );
            users.add(u);
        }
        insert users;     
    }
    
    public static testMethod void testDraftArticle()
    { 
        Exception caughtException = null;
        Knowledge__kav  knowledgedraftArticle = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            BW_Home_Page_Display__c = false,
            Title = 'Frontline-Test-Article-',
            urlName ='Frontline-Test--Article',
            ContentSponsor__c = 'ABCD'
        );
        
        KM_TestDataFactory.createContentSponsorUser('ABCD');
        insert knowledgedraftArticle;
        
        try {
            Test.startTest();
            Knowledge__kav ka = [SELECT KnowledgeArticleId FROM Knowledge__kav WHERE Title = :'Frontline-Test-Article-'];
            String knID=CloneArticleController.cloneArticle(ka.Id);
            System.assertNotEquals(null, knID);
            Test.stopTest(); 
        }  catch(System.Exception ex){
            caughtException = ex;
            KMErrorHandlingUtility.logError('Error cloning article', 'KMCloneException');
            //throw new AuraHandledException('error: '+ex.getMessage());
        }
        System.assertEquals(null, caughtException);
    }
    
    public static testMethod void testPublishedArticle()
    {
        Exception caughtException = null;
        Knowledge__kav  knowledgedraftArticle = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            BW_Home_Page_Display__c = false,
            Title = 'Frontline-Test-Article1-',
            UrlName ='Frontline-Test-Article1',
            ContentSponsor__c = 'ABCD'
        );
        
        KM_TestDataFactory.createContentSponsorUser('ABCD');
        insert knowledgedraftArticle;  
        
        try {
            Test.startTest();
            Knowledge__kav ka = [SELECT KnowledgeArticleId FROM Knowledge__kav WHERE Title = :'Frontline-Test-Article1-'];
            KbManagement.PublishingService.publishArticle(ka.KnowledgeArticleId, true);
            String knID=CloneArticleController.cloneArticle(ka.Id);
            System.assertNotEquals(null, knID);
            Test.stopTest();  
        } catch(System.Exception ex){
            caughtException = ex;
            KMErrorHandlingUtility.logError('Error cloning article', 'KMCloneException');
            //throw new AuraHandledException('error: '+ex.getMessage());
        }
        System.assertEquals(null, caughtException);
    }
    
    public static testMethod void testArchivedArticle()
    { 
        Exception caughtException = null;
        Knowledge__kav  knowledgedraftArticle = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            BW_Home_Page_Display__c = false,
            Title = 'Frontline-Test-Article2-',
            UrlName ='Frontline-Test-Article2',
            ContentSponsor__c = 'ABCD'
        );
        
        KM_TestDataFactory.createContentSponsorUser('ABCD');
        insert knowledgedraftArticle;
        try
        { 
            Test.startTest();            
            Knowledge__kav ka = [SELECT KnowledgeArticleId,PublishStatus FROM Knowledge__kav WHERE Title = :'Frontline-Test-Article2-'];
            KbManagement.PublishingService.publishArticle(ka.KnowledgeArticleId, true);
            KbManagement.PublishingService.archiveOnlineArticle(ka.KnowledgeArticleId, null);
            
            String status=CloneArticleController.getPublishStatus(ka.Id);
            System.assertEquals('Archived',status);
            
            String publishedStatus=CloneArticleController.cloneArticle(ka.Id);
            System.assertEquals('error: Archived Articles cannot be cloned.',publishedStatus);    
            Test.stopTest();  
        }
        catch(System.Exception ex){
            caughtException = ex;
            KMErrorHandlingUtility.logError('Error cloning article', 'KMCloneException');
            //throw new AuraHandledException('error: '+ex.getMessage()); 
        }
         System.assertNotEquals(null, caughtException);
    }
    
    public static testMethod void testException()
    {
        Exception caughtException = null;
        try{
            Test.startTest();
            String statusfailure=CloneArticleController.getPublishStatus(NULL);
            system.assertEquals(null, statusfailure);
            String publishedStatusfailure=CloneArticleController.cloneArticle(NULL);  
            system.assertEquals(null, publishedStatusfailure);
            Test.stopTest();
        } catch(System.Exception ex){
            caughtException = ex;
            // KMErrorHandlingUtility.logError('Error cloning article', 'KMCloneException');
            //throw new AuraHandledException('error: '+ex.getMessage());
        }
         System.assertNotEquals(null, caughtException);
    }
    
}
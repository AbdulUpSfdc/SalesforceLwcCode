/*********
    Name                : KnowledgeFrontlineController
    Descritption        : This is a test class for KnowledgeFrontlineController.
*********/

@isTest
public class KnowledgeFrontlineControllerTest{
    @testSetup
    public static void testData(){
        KM_TestDataFactory.createContentSponsorUser('ABC');   

        Knowledge__kav  knowledgeFrontline = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test',
            UrlName = 'Frontline-Test',
            ContentSponsor__c = 'ABC'
            
        );
        insert knowledgeFrontline;
        Knowledge__kav knFrnt = [SELECT KnowledgeArticleId FROM Knowledge__kav where Id = :knowledgeFrontline.Id];
        KbManagement.PublishingService.publishArticle(knFrnt.KnowledgeArticleId, true);
        
        Knowledge__kav  knowledgeAssigned = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            BW_Home_Page_Display__c = true,
            Title = 'Assigned-Test',
            UrlName = 'Assigned-Test',
            ContentSponsor__c = 'ABC',
            BW_Article_Summary__c = 'askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf',
            RecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId()
            
        );
        insert knowledgeAssigned;
        Knowledge__kav knAssign = [select KnowledgeArticleId from Knowledge__kav where Id = :knowledgeAssigned.Id];
        KbManagement.PublishingService.publishArticle(knAssign.KnowledgeArticleId, true);
        KM_Article_Feedback__c feedback = new KM_Article_Feedback__c(
            knowledge__c = knowledgeAssigned.Id
        );
        INSERT feedback;
    }
    
    public static testMethod void testGetViewAsAssignedKnowledgeArticles() {
      String channel = '';
      String market = '';  
      String employeeRole = ''; 
      String resourceType = '';
      String requestSource = '';  
     KnowledgeFrontlineController.ResponseHandler rh =  KnowledgeFrontlineController.getViewAsAssignedKnowledgeArticles(channel, market,  
                                                                employeeRole, resourceType,requestSource);
      System.assertNotEquals(null, rh);
  
    }
    
    public static testMethod void testGetFrontLineKnowledgeArticles() {
      String channel = '';
      String market = '';  
      String employeeRole = ''; 
      String resourceType = '';
      String requestSource = '';  
     KnowledgeFrontlineController.ResponseHandler rh =  KnowledgeFrontlineController.getFrontLineKnowledgeArticles(channel, market,  
                                                                employeeRole, resourceType,requestSource);
      System.assertNotEquals(null, rh);
  
    }
    
    public static testMethod void testGetCPSId() {
        System.assertEquals('', KnowledgeFrontlineController.getCSPId(''));
        System.assertEquals('test', KnowledgeFrontlineController.getCSPId('_test'));
        
    }
   	
    public static testMethod void testUnitOne(){
        KnowledgeFrontlineController.getFrontLineKnowledgeArticles();
        KnowledgeFrontlineController.getAssignedKnowledgeArticles();
        Knowledge__kav knAssign = [
            select KnowledgeArticleId 
            from Knowledge__kav 
            LIMIT 1
        ];
        KnowledgeFrontlineController.markArticleReaded(knAssign.Id);
    }
    
    public static testMethod void testGetAssignedArticlesNew() {
     	KnowledgeFrontlineController.ResponseHandler rh = KnowledgeFrontlineController.getAssignedKnowledgeArticlesNew();
        System.assertNotEquals(null, rh);
    }
    
    public static testMethod void testUnitTwo(){
        KnowledgeFrontlineController.markArticleReaded('ad');
        KnowledgeFrontlineController.CompWrapper obj = new KnowledgeFrontlineController.CompWrapper();
        Integer compare = obj.compareTo(obj);
        obj.isReadNumber = 10;
        Integer compare2 = obj.compareTo(obj);
    }
}
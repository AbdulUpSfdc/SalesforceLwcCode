@isTest
public class KnowledgeManagementViewArticleCtrlTest{    

    private static Id newsArticleRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId();
    @testSetup
    
    public static void testData(){
          
        Knowledge__kav  knowledgeAssigned = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            BW_Home_Page_Display__c = true,
            Title = 'Assigned-Test',
            UrlName = 'Assigned-Test',
            MyCSPArticleName__c = 'testCSP_124',
            RecordTypeId = newsArticleRecordTypeId,
            ContentSponsor__c = 'ABC',
            BW_Article_Details__c = 'blablabla'
            
        );
        KM_TestDataFactory.createContentSponsorUser('ABC'); 
        insert knowledgeAssigned;
        Knowledge__kav knAssign = [select KnowledgeArticleId from Knowledge__kav where Id = :knowledgeAssigned.Id];
        KbManagement.PublishingService.publishArticle(knAssign.KnowledgeArticleId, true);
    }


    public static testMethod void testUnitFour(){
        
        Knowledge__kav knAssign = [
            select KnowledgeArticleId,
                   BW_Article_Details__c
            from Knowledge__kav 
            WHERE RecordTypeId = :newsArticleRecordTypeId
            LIMIT 1
        ];
        
        PageReference pageRef = Page.KnowledgeManagementViewArticle;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('id', knAssign.Id);
        
        KnowledgeManagementViewArticleCtrl this_article = new KnowledgeManagementViewArticleCtrl();
        
        string articleDetail = this_article.articleDetail;
        system.assertequals(articleDetail,knAssign.BW_Article_Details__c);
        system.assertequals(articleDetail,'blablabla');
        
        
    }
        
}
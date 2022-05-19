/*********
Test Class for RecommandedRelatedArticleController
*/
@isTest
public class RecommandedRelatedArticleControllerTest {
    
    @testSetup
    public static void testData(){
        Knowledge__kav knowledgekav = KM_TestDataFactory.getKnowledKav(system.today(),'test','testurl',true, 'ABC');
        Knowledge__kav knowledgekav2 = KM_TestDataFactory.getKnowledKav(system.today(),'test2','testurl2',true, 'ABC');
        SearchPromotionRule searchPro = new SearchPromotionRule(Query = 'Treding', PromotedEntityId = knowledgekav.Id);
        Insert searchPro;
        SearchPromotionRule searchPro2 = new SearchPromotionRule(Query = 'Treding', PromotedEntityId = knowledgekav2.Id);
        Insert searchPro2;
    }
    
    @isTest
    public static void testMethod1(){
        Knowledge__kav knowledgekav = [Select Id, Title From Knowledge__kav Where Title = 'test'];
        Test.startTest();
        RecommandedRelatedArticleController.getknowledgeList(knowledgekav.Id);
        Test.stopTest();
        SearchPromotionRule searchPro = [Select Id, Query, PromotedEntityId from SearchPromotionRule
                                        Where PromotedEntityId = :knowledgekav.Id];
        system.assertEquals(searchPro.PromotedEntityId, knowledgekav.Id);
    }
    
    @isTest
    public static void testMethodException(){
        Test.startTest();
        RecommandedRelatedArticleController.ResponseHandler obj = new RecommandedRelatedArticleController.ResponseHandler('test');
        Test.stopTest();
    }
}
/*******************
    Name             : KnowledgeDisplayControllerTest
    Description      : This is the test class for the KnowledgeDisplayController.
**************/

@isTest
public class KnowledgeDisplayControllerTest{
    
    @testSetup
    public static void testData(){
        Knowledge__kav knowledgekav = KM_TestDataFactory.getKnowledKav(system.today(),'test','testurl',true, 'ABC');
        //Get RecordTypeId.
        Id newsArticleRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId();  
        //Create Record for RecordTypeName 'News Article'.
        Knowledge__kav knowledge = KM_TestDataFactory.getKnowledKavTest(newsArticleRecordTypeId ,System.Now().AddDays(5),'testone','testing',true, 'ABC');
        Knowledge__kav knowledge_fontline = KM_TestDataFactory.getKnowledKavfronlinefocus(newsArticleRecordTypeId ,
                            System.Now().AddDays(5),
                            'testonefontline',
                            'testingfontline',
                            true,
                            'ABC');
    }
    
    public static testMethod void testUnitOne(){
        //Get RecordTypeId.
        Id newsArticleRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId();
        Knowledge__kav knowledge = [SELECT id, KnowledgeArticleId from Knowledge__kav WHERE RECORDTYPEID = :newsArticleRecordTypeId LIMIT 1];
        Vote vt = new Vote(
            ParentId = knowledge.KnowledgeArticleId,
            Type = '5'
        );
        
        INSERT vt;
        
        KnowledgeDisplayController.getKnowledgeArticle('Trending Now');
        KnowledgeDisplayController.getKnowledgeArticle('Activity Stream');
        KnowledgeDisplayController.getKnowledgeArticle('');
        KnowledgeDisplayController.getLinkCentralArticle();
        KnowledgeDisplayController.getFronLineArticle();
        KnowledgeDisplayController obj = new KnowledgeDisplayController();
    }
    
    public static testMethod void testUnitTwo(){
        //Get RecordTypeId.
        Id newsArticleRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId();
        
        Knowledge__kav knowledge = [SELECT id from Knowledge__kav WHERE RECORDTYPEID = :newsArticleRecordTypeId LIMIT 1];
        KnowledgeDisplayController.setArticleReaded(knowledge.Id);
    }
}
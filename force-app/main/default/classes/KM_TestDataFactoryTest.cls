/*******
Name : KM_TestDataFactoryTest
*******/
@isTest

public class KM_TestDataFactoryTest{
    public static testmethod void testUnit(){
        Knowledge__kav knowledgekav = KM_TestDataFactory.getKnowledKav(system.today(),'test','testurl',true,'ABC');
        //Get RecordTypeId.
        Id newsArticleRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId();
        //Create Record for RecordTypeName 'News Article'.
        Knowledge__kav knowledKavTest= KM_TestDataFactory.getKnowledKavTest(newsArticleRecordTypeId ,System.Now().AddDays(5),'testone','testing',true,'ABC');
        Knowledge__kav knowledKavTest2= KM_TestDataFactory.getKnowledKavdata(system.today(),'test','testurlnew',true,'ABC');
        Knowledge__kav knowledge_fontline = KM_TestDataFactory.getKnowledKavfronlinefocus(newsArticleRecordTypeId ,
            System.Now().AddDays(5),
            'testonefontline',
            'testingfontline',
            true,'ABC'
        );
        Knowledge__kav knowledKavDataForDeleteArchiveBat= KM_TestDataFactory.getKnowledKavDataForDeleteArchiveBat(system.today(),System.today().AddDays(-2),'test','testurlbat',true,'ABC');
        
    }
}
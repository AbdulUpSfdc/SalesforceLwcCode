@isTest
public with sharing class ArticleGeneratorTest {

     public static testMethod void testGenerator(){
       
        String objectType = 'KnowledgeArticleVersion';
        String categoryName = 'Channel';
        String KNOWLEDGE_CATEGORY_CHANNEL = 'Channel';
        String KNOWLEDGE_CATEGORY_ROLE = 'Role';
        String KNOWLEDGE_CATEGORY_RESOURCE_TYPE = 'Resource_Type';
        String timestamp = String.valueof(Datetime.now());
        timestamp = timestamp.replaceAll('\\D', '');
        System.debug(timestamp);   
        //ArticleSearchDataService.getDataCategoryFilterOptions(KNOWLEDGE_CATEGORY_RESOURCE_TYPE );
        Knowledge__kav knowledgeArticle = ArticleGenerator.testPublishArticle();
        System.debug('Id: ' + knowledgeArticle.Id);
     }
}
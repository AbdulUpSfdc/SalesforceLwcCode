@isTest
public class ArticleCopyMarketsTest {
    @isTest
    static void doPostTest(){
        Knowledge__kav  knowledgeFrontline = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test',
            UrlName = 'Frontline-Test',
            ContentSponsor__c = 'ASCD'
        );
        KM_TestDataFactory.createContentSponsorUser('ASCD');
        INSERT knowledgeFrontline;
        
        BWMarketMaster__c marketMaster = new BWMarketMaster__c(
            MarketPromotedSearchTerm__c = 'SEARCH TERM',
            MYCSPMarketId__c = '123ACVV'
        );
        INSERT marketMaster;
        
        BWMarketAssociation__c marketAssociation = new BWMarketAssociation__c(
            BWMarketMaster__c = marketMaster.Id,
            Knowledge__c = knowledgeFrontline.Id
        );
        INSERT marketAssociation;
        System.debug('marketAssociation for draft article: '+marketAssociation);
    	
        Knowledge__kav published = [Select Id, KnowledgeArticleId, Title, UrlName from Knowledge__kav
                               where Id =:knowledgeFrontline.Id];
        String articleId = published.KnowledgeArticleId;
        KbManagement.PublishingService.publishArticle(articleId, true);
        
        //Article is published!!!!!!!! ---------------
        
        Knowledge__kav draft = [Select Id, KnowledgeArticleId, Title, UrlName,PublishStatus from Knowledge__kav
                               where KnowledgeArticleId =:published.KnowledgeArticleId];
        System.debug('Published article:!!!!:   '+draft);
       	KbManagement.PublishingService.editOnlineArticle(draft.KnowledgeArticleId, false);
        System.assertEquals(draft.KnowledgeArticleId, published.KnowledgeArticleId);
		
        // New version of article is created!!! -----------------
        
        
        Knowledge__kav finalDraft = [Select Id, KnowledgeArticleId, Title, UrlName, PublishStatus from Knowledge__kav
                               where KnowledgeArticleId=:published.KnowledgeArticleId and PublishStatus = 'Draft'];
        System.debug('New Draft version of the article created !!!!:   '+finalDraft);
		System.debug('What is in finalDraft: '+finalDraft);
        
        List<knowledge__kav> publishedArticle= [Select Id,PublishStatus,UrlName,VersionNumber, KnowledgeArticleId,Title
                                      from knowledge__kav 
                                      where KnowledgeArticleId=:draft.KnowledgeArticleId
                                          order by versionnumber]; 
        
        System.debug('publishedArticle:'+publishedArticle);
        System.assertNotEquals(Null, publishedArticle);
        
        String instance = URL.getSalesforceBaseUrl().toExternalForm();
        
        System.debug(instance+'/services/apexrest/ArticleCopyMarkets');
        
       	String myJSON = JSON.serialize(finalDraft);

        RestRequest request = new RestRequest();
        RestResponse res = new RestResponse();
        request.requestUri = instance+'/services/apexrest/ArticleCopyMarkets';
        request.httpMethod = 'POST';
		request.requestBody = Blob.valueof(myJSON);
		
        RestContext.request = request;
    	RestContext.response= res;
        Test.startTest();
		ArticleCopyMarkets.doPost(finalDraft.Id);
        Test.stopTest();
        
    }
}
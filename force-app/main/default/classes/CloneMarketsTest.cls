/********
        Name             : CloneMarketsTest
        Description      : This is the test class for the class CloneMarkets
********/

@isTest
public class CloneMarketsTest{
    
    @testSetup
    public static void testData(){
        Knowledge__kav  knowledgeFrontline = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test',
            UrlName = 'Frontline-Test',
            ContentSponsor__c = 'Test123'
            
        );
        KM_TestDataFactory.createContentSponsorUser('Test123');
        INSERT knowledgeFrontline;
        
        Knowledge__kav knFrnt = [SELECT KnowledgeArticleId FROM Knowledge__kav LIMIT 1];
        KbManagement.PublishingService.publishArticle(knFrnt.KnowledgeArticleId, true);
        
        
        String knowledgeDraftid = KbManagement.PublishingService.editOnlineArticle(knFrnt.KnowledgeArticleId, false);
        Knowledge__kav  knowledgeFrontlineDrafted = new Knowledge__kav(
            id = knowledgeDraftid,
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test-edited',
            UrlName = 'Frontline-Test',
            ContentSponsor__c = 'Test123'
        );
        KM_TestDataFactory.createContentSponsorUser('Test123');
        UPDATE knowledgeFrontlineDrafted;
        
        //KbManagement.PublishingService.publishArticle(knFrntDraft.KnowledgeArticleId, true);
        
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
        
    }
    
    public static testMethod void testUnitOne(){
        System.debug([Select Id,PublishStatus,UrlName,VersionNumber, KnowledgeArticleId
                                      from knowledge__kav WHERE PublishStatus='Online']);
        Knowledge__kav knFrntDraft = [
            SELECT KnowledgeArticleId 
            FROM Knowledge__kav 
            WHERE Title = :'Frontline-Test-edited'
            LIMIT 1
        ];
        CloneMarkets.cloneMarkets(knFrntDraft.id);
        //System.assert([SELECT id from BWMarketAssociation__c].size() == 2);
    }
}
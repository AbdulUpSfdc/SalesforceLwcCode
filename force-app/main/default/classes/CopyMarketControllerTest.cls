/*********
Name                : CopyMarketControllergTest
Description         : This is a test class for the CopyMarketController
*********/

@isTest
public class CopyMarketControllerTest{
    
    @testSetup
    public static void testData(){
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
    }
    
    public static testmethod void testUnitOne(){
        Knowledge__kav knFrnt = [SELECT KnowledgeArticleId FROM Knowledge__kav LIMIT 1];
        CopyMarketController.copyMarket(knFrnt.Id);
    }
    
    public static testmethod void testUnitTwo(){
        CopyMarketController.copyMarket('abcd');
    }
}
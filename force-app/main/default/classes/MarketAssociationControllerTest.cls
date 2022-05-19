@isTest
public class MarketAssociationControllerTest {
    
    public static testmethod void testMarkets() {
        String timeStamp = String.valueOf(DateTime.now());
        timestamp = timestamp.replaceAll('\\D', '');
        Exception expectedException = null;
        Knowledge__kav  knowledgeFrontline = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test',
            UrlName = 'Frontline-Test' + timeStamp,
            ContentSponsor__c = 'Test123'
            
        );
        KM_TestDataFactory.createContentSponsorUser('Test123');
        INSERT knowledgeFrontline;
        
        BWMarketMaster__c marketMaster = new BWMarketMaster__c(
            MarketPromotedSearchTerm__c = 'SEARCH TERM',
            MYCSPMarketId__c = '123ACVV'
        );
       
        INSERT marketMaster;
        MarketAssociationController.ResponseHandler responseHandler = new MarketAssociationController.ResponseHandler(true);
        responseHandler = new MarketAssociationController.ResponseHandler('Error Message');
        MarketAssociationController.associateMarkets(knowledgeFrontline.Id); 
        List<BWMarketAssociation__c> marketAssociationList = MarketHelper.getMarketAssociationList(knowledgeFrontline.Id);
        System.assertEquals(1, marketAssociationList.size());
        
        MarketAssociationController.disassociateMarkets(knowledgeFrontline.Id);  
        marketAssociationList = MarketHelper.getMarketAssociationList(knowledgeFrontline.Id);
        System.assertEquals(0, marketAssociationList.size());        

        }
    
}
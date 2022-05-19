@isTest
public class MarketHelperTest {
/*
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
        
        BWMarketMaster__c marketMaster = new BWMarketMaster__c(
            MarketPromotedSearchTerm__c = 'SEARCH TERM',
            MYCSPMarketId__c = '123ACVV'
        );
        INSERT marketMaster;
        
        
        
        
    
    }*/
    
    
 	public static testmethod void testMarkets() {
        Exception expectedException = null;
        String timeStamp = String.valueOf(DateTime.now());
        timestamp = timestamp.replaceAll('\\D', '');
        KM_TestDataFactory.createContentSponsorUser('Test123'); 

        Knowledge__kav  knowledgeFrontline = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test',
            UrlName = 'Frontline-Test' + timeStamp,
            ContentSponsor__c = 'Test123'
            
        );
        INSERT knowledgeFrontline;
        
        BWMarketMaster__c marketMaster = new BWMarketMaster__c(
            MarketPromotedSearchTerm__c = 'SEARCH TERM',
            MYCSPMarketId__c = '123ACVV'
        );
        INSERT marketMaster;
        
        try {
            MarketHelper.associateAllMarkets(null);     
        } catch (Exception e) {
            expectedException = e;
        }
        System.assertNotEquals(null, expectedException);
        expectedException = null;
        
        try {
            MarketHelper.disassociateAllMarkets(null);     
        } catch (Exception e) {
            expectedException = e;
        }
        System.assertNotEquals(null, expectedException);
        expectedException = null;
        
        Integer associatedMarkets = MarketHelper.associateAllMarkets(knowledgeFrontline.Id); 
        System.assertEquals(1, associatedMarkets);
        List<BWMarketAssociation__c> marketAssociationList = MarketHelper.getMarketAssociationList(knowledgeFrontline.Id);
        System.assertEquals(1, marketAssociationList.size());
        
        associatedMarkets = MarketHelper.disassociateAllMarkets(knowledgeFrontline.Id); 
        marketAssociationList = MarketHelper.getMarketAssociationList(knowledgeFrontline.Id);
        System.assertEquals(0, marketAssociationList.size());
        knowledgeFrontline = MarketHelper.getArticle(knowledgeFrontline.Id);
        System.assertNotEquals(null, knowledgeFrontline);
        System.assertEquals(true, MarketHelper.isArticleDraft(knowledgeFrontline));
    }  
    

        
        
 
      
}
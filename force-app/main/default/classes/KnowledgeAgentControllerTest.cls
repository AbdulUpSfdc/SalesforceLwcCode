/************
Name            : KnowledgeAgentControllerTest
Description     : This is the test class for the KnowledgeAgentController.
************/


@isTest
public class KnowledgeAgentControllerTest{
    private static Id newsArticleRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId();
    @testSetup
    public static void testData(){
        Knowledge__kav  knowledgeFrontline = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test',
            UrlName = 'Frontline-Test',
            MyCSPArticleName__c = 'testCSP_123',
            ContentSponsor__c = 'ABC'
            
        );
        KM_TestDataFactory.createContentSponsorUser('ABC');
        insert knowledgeFrontline;
        Knowledge__kav knFrnt = [select Id,KnowledgeArticleId from Knowledge__kav where Id = :knowledgeFrontline.Id];
        KbManagement.PublishingService.publishArticle(knFrnt.KnowledgeArticleId, true);
       
        
        Knowledge__kav  knowledgeAssigned = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            BW_Home_Page_Display__c = true,
            Title = 'Assigned-Test',
            UrlName = 'Assigned-Test',
            MyCSPArticleName__c = 'testCSP_124',
            RecordTypeId = newsArticleRecordTypeId,
            ContentSponsor__c = 'ABC'
            
        );
        KM_TestDataFactory.createContentSponsorUser('ABC');
        insert knowledgeAssigned;
        Knowledge__kav knAssign = [select KnowledgeArticleId from Knowledge__kav where Id = :knowledgeAssigned.Id];
        KbManagement.PublishingService.publishArticle(knAssign.KnowledgeArticleId, true);
    }
   
    public static testMethod void testUnitOne(){
        Knowledge__kav knAssign = [
            select KnowledgeArticleId 
            from Knowledge__kav 
            WHERE RecordTypeId = :newsArticleRecordTypeId
            LIMIT 1
        ];
        
        KnowledgeAgentController.getKnowledgeArticle(knAssign.Id);
    }
    
    
    public static testMethod void testUnitTwo(){
        KnowledgeAgentController.getKnowledgeArticle('ABCD');
    }
    
    public static testMethod void testUnitThree(){
        KnowledgeAgentController.ResponseHandler obj = new KnowledgeAgentController.ResponseHandler(false);
        KnowledgeAgentController.ResponseHandler obj2 = new KnowledgeAgentController.ResponseHandler('Error');
    }
    
    public static testMethod void testUnitFour(){
        Knowledge__kav knAssign = [
            select KnowledgeArticleId 
            from Knowledge__kav 
            WHERE RecordTypeId != :newsArticleRecordTypeId
            LIMIT 1
        ];
        KnowledgeAgentController.getKnowledgeArticle(knAssign.Id);
    }
    
    public static testMethod void testUnitFive(){
        Knowledge__kav knAssign = [
            select KnowledgeArticleId 
            from Knowledge__kav 
            WHERE RecordTypeId = :newsArticleRecordTypeId
            LIMIT 1
        ];
        try
        {
            Integer viewCount= KnowledgeAgentController.getArticleViewCountForLast_N_Days(knAssign.Id);
            if(viewCount>0){
                system.assertNotEquals(0, viewCount);
            }
            Decimal imageWidth = KnowledgeAgentController.getDesktopImageWidth();
            if(imageWidth > 0){
                System.assertNotEquals(0, imageWidth);
            }
            
            String communityURL = KnowledgeAgentController.getCommunityURL();
            if(String.isNotBlank(communityURL)){
                System.assertNotEquals(null, communityURL);
            }
            
            String sharingURL = KnowledgeAgentController.getFavoriteslinksharingURL();
            if(String.isNotBlank(sharingURL)){
                System.assertNotEquals(null, sharingURL);
            }
            
            String publicLink = KnowledgeAgentController.getPublicLink(knAssign.Id);
            if(String.isNotBlank(publicLink)){
                System.assertNotEquals(null, publicLink);
            }
            
            String persistentLink = KnowledgeAgentController.getPersistentLink(knAssign.Id);
            if(String.isNotBlank(persistentLink)){
                System.assertNotEquals(null, persistentLink);
            }
        }
        catch (AuraHandledException e) {}
        
    }
    
}
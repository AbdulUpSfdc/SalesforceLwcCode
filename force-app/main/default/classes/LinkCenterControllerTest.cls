/************
    Name            : LinkCenterController
    Description     : This is a test class for LinkCenterController
    
************/

@isTest
public class LinkCenterControllerTest{
    @testSetup
    public static void testData(){
        //Create User
        User testUser = KM_TestDataFactory.createContentSponsorUser('rt12345');
        
        Knowledge__kav  knowledgeLinkCenter = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            BW_Link_Center_Article__c = true,
            Title = 'Assigned-Test',
            UrlName = 'Assigned-Test',
            ContentSponsor__c = testUser.attuid__c,
            BW_ExternalLinkURL__c = 'https://www.salesforce.com',
            BW_Article_Details__c = 'Click Select Tests to choose one or more Apex unit tests and run them. To see the current code coverage for an individual class or your organization, go to the Apex Classes page.'
            
        );
        insert knowledgeLinkCenter;
        Knowledge__kav knLink = [select KnowledgeArticleId from Knowledge__kav where Id = :knowledgeLinkCenter.Id];
        KbManagement.PublishingService.publishArticle(knLink.KnowledgeArticleId, true);
    }
    
    //Positive test for Searching the Positive search for the BW_ExternalLinkURL__c
    public static testMethod void PositiveTest(){
        LinkCenterController.getLinkCenterArticles('salesforce');
    }
    //Negative test for Searching the Negative search for the BW_ExternalLinkURL__c
    public static testMethod void NegativeTest(){
        LinkCenterController.getLinkCenterArticles('att');
        LinkCenterController.ResponseHandler obj = new LinkCenterController.ResponseHandler('Err');
    }
}
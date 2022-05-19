/************    
    Name            : KnowledgeTriggerTest
    Descrption      : This is the test class for the KnowledgeTrigger and KnowledgeTriggerHelper.
***********/

@isTest
public class KnowledgeTriggerTest{
    @testSetup
    public static void testData(){
        Knowledge__kav  knowledgeFrontlineOnly = new Knowledge__kav(
            BW_Is_Urgent__c =  false,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test-fromline',
            UrlName = 'Frontline-Test-fromline',
            ContentSponsor__c = 'ABCD'
        );
        KM_TestDataFactory.createContentSponsorUser('ABCD');
        insert knowledgeFrontlineOnly;
        
        Knowledge__kav  knowledgeFrontline = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test',
            UrlName = 'Frontline-Test',
            ContentSponsor__c = 'ABCD'
        );
        KM_TestDataFactory.createContentSponsorUser('ABCD');
        insert knowledgeFrontline;
        Knowledge__kav knFrnt = [SELECT KnowledgeArticleId FROM Knowledge__kav where Id = :knowledgeFrontline.Id];
        KbManagement.PublishingService.publishArticle(knFrnt.KnowledgeArticleId, true);
        
        Knowledge__kav  knowledgeAssigned = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            BW_Home_Page_Display__c = true,
            Title = 'Assigned-Test',
            UrlName = 'Assigned-Test',
            ContentSponsor__c = 'ABCD',
            BW_Article_Summary__c = 'askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf',
            RecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId()
        );
        KM_TestDataFactory.createContentSponsorUser('ABCD');
        insert knowledgeAssigned;
        Knowledge__kav knAssign = [select KnowledgeArticleId from Knowledge__kav where Id = :knowledgeAssigned.Id];
        KbManagement.PublishingService.publishArticle(knAssign.KnowledgeArticleId, true);
        KM_Article_Feedback__c feedback = new KM_Article_Feedback__c(
            knowledge__c = knowledgeAssigned.Id
        );
        INSERT feedback;
    }
    
    public static testmethod void testUnitOne(){
        
        Knowledge__kav knw = [
            SELECT Id, BW_Is_Urgent__c
            from Knowledge__kav
            WHERE Title = 'Frontline-Test-fromline'
        ];
        knw.BW_Is_Urgent__c = true;
        UPDATE knw;
    }
    
    public static testMethod void testScheduledDate() {
    	Exception caughtException = null;   
	    User agentUser = KM_TestDataFactory.createAgentUser();
        Knowledge__kav  knowledgeNoScheduledDate = new Knowledge__kav(
            BW_Is_Urgent__c =  false,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test-fromline',
            UrlName = 'Frontline-No-Scheduled-Date',
            ContentSponsor__c = 'ABCD'
        );
        insert knowledgeNoScheduledDate;
        
       Knowledge__kav  knowledgeGoodScheduledDate = new Knowledge__kav(
            BW_Is_Urgent__c =  false,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test-fromline',
            UrlName = 'Frontline-Good-Scheduled-Date',
            ContentSponsor__c = 'ABCD',
            BWScheduledArticlePublicationDate__c = System.Now().addMinutes(10)
        );
        insert knowledgeGoodScheduledDate;
        
         Knowledge__kav  knowledgeBadScheduledDate = new Knowledge__kav(
            BW_Is_Urgent__c =  false,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test-fromline',
            UrlName = 'Frontline-Bad-Scheduled-Date',
            ContentSponsor__c = 'ABCD',
            BWScheduledArticlePublicationDate__c = System.Now().addMinutes(-10)
        );
        // validation rules were suspended for admin users, so need to run this an agent to get the error.
        System.runAs(agentUser) {
            try {		
                insert knowledgeBadScheduledDate;
            } catch (Exception e) {
                caughtException =  e;
            }
        }
        System.assertNotEquals(Null, caughtException);
        
         Knowledge__kav  knowledgeBadScheduledDateNow = new Knowledge__kav(
            BW_Is_Urgent__c =  false,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test-fromline',
            UrlName = 'Frontline-Bad-Scheduled-Date-Now',
            ContentSponsor__c = 'ABCD',
            BWScheduledArticlePublicationDate__c = datetime.now()
        );
       caughtException = null;
       System.runAs(agentUser) {
            try {		
                insert knowledgeBadScheduledDate;
            } catch (Exception e) {
                caughtException =  e;
            }
        }
        System.assertNotEquals(Null, caughtException);
        
        
    }
}
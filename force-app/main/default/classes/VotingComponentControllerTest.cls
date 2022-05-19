/*********
    Name            : VotingComponentController
    Description     : This is a test class for VotingComponentController.
**********/

@isTest
public class VotingComponentControllerTest{
    @testSetup
    public static void testData(){
        try{ 
            Knowledge__kav  knowledgeFrontline = new Knowledge__kav(
                BW_Is_Urgent__c =  true,
                BW_FrontLine_Focus__c = true,
                Title = 'Frontline-Test',
                UrlName = 'Frontline-Test',
                ContentSponsor__c = 'ABC'
            );
            KM_TestDataFactory.createContentSponsorUser('ABC'); 
            insert knowledgeFrontline;

            Knowledge__kav knFrnt = [select KnowledgeArticleId from Knowledge__kav where Id = :knowledgeFrontline.Id];
            KbManagement.PublishingService.publishArticle(knFrnt.KnowledgeArticleId, true);
            
            Vote vt = new Vote(
                ParentId = knFrnt.KnowledgeArticleId,
                Type = '5'
            );
            INSERT vt;
            
            Knowledge__kav  knowledgeAssigned = new Knowledge__kav(
                BW_Is_Urgent__c =  true,
                BW_FrontLine_Focus__c = true,
                BW_Home_Page_Display__c = true,
                Title = 'Assigned-Test',
                UrlName = 'Assigned-Test',
                ContentSponsor__c = 'ABC'
            );
            KM_TestDataFactory.createContentSponsorUser('ABC');
            insert knowledgeAssigned;
            Knowledge__kav knAssign = [select KnowledgeArticleId from Knowledge__kav where Id = :knowledgeAssigned.Id];
            KbManagement.PublishingService.publishArticle(knAssign.KnowledgeArticleId, true);
            
            Vote vt2 = new Vote(
                ParentId = knAssign.KnowledgeArticleId,
                Type = '1'
            );
            INSERT vt2;
        } catch(Exception exceptionObject){
            System.debug('Error message=' + exceptionObject.getMessage());
            System.debug('Stack trace=' + exceptionObject.getStackTraceString());
            System.assert(false, 'Exception occurred in Test Setup');
        }
    }

    public static testMethod void testUnitThree(){
        VotingComponentController.ResponseHandler obj = new VotingComponentController.ResponseHandler('ad');
        VotingComponentController.ResponseHandler obj2 = new VotingComponentController.ResponseHandler();
    }
    
    public static testMethod void testDoVoting(){
        try{
            System.debug('Started testDoVoting()');
            Knowledge__kav knAssign = [
                select Id, KnowledgeArticleId
                from Knowledge__kav 
                LIMIT 1
            ];
            
            List<Vote> voteList = [
                SELECT Id,
                ParentId 
                FROM Vote WHERE ParentId =: knAssign.KnowledgeArticleId
            ];
            delete voteList;
            VotingComponentController.doVoting('', knAssign.Id, true);
            System.debug('Completed testDoVoting()');
        } catch(Exception exceptionObject){
            System.debug('Exception occurred. Error message=' + exceptionObject.getMessage());
            System.debug('Stack trace=' + exceptionObject.getStackTraceString());
            System.assert(false, 'Exception occurred in testDoVoting()');
        }
    }
    
    public static testMethod void testDoVotingForException(){
        try{
            System.debug('Started testDoVotingForException()');
            Knowledge__kav knAssign = [
                select Id, KnowledgeArticleId
                from Knowledge__kav 
                LIMIT 1
            ];  
            List<Vote> voteList = [
                SELECT Id,
                ParentId 
                FROM Vote WHERE ParentId =: knAssign.KnowledgeArticleId
            ];
            delete voteList;
            VotingComponentController.doVoting('', null, true);
            System.assert(false, 'Exception should have been thrown');
        } catch(Exception exceptionObject){
            system.debug('Exception message'+ exceptionObject.getMessage() );
            //System.assert(exceptionObject.getMessage().contains('Script-thrown exception'), 'Exception should contain correct message');
        }
    }
}
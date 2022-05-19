@isTest
public class knowledgeCreateTask_SendEmailBatchTest {
    public static final String ROLE_NAME = 'TestingTeam';
     	private static final String DATE_FORMAT = 'ssSSS';
    public static testMethod void testBatch(){
         List<Knowledge__kav> knowledgeArticles = new List<Knowledge__kav>();
        List<Task> taskList = new List<Task>();
         User u = KM_TestDataFactory.createContentSponsorUser('rt12345'); 

    
       
        for(Integer i=0; i<50; i++){
            Knowledge__kav  ka = new Knowledge__kav(
                Title = 'Frontline-Test-Article-' + i+1,
                UrlName = 'Frontline-Test-Article-' + i+1,
                ContentSponsor__c = u.ATTUID__c,
                BWSecContentSponsor__c = u.ATTUID__c,
                FutureReviewDate__c = null
            );
            knowledgeArticles.add(ka);
        }
        insert knowledgeArticles;

        
        for(Knowledge__kav ka : [SELECT Id,LastModifiedById,FutureReviewDate__c,PublishStatus, KnowledgeArticleId FROM Knowledge__kav LIMIT 40]){
            KbManagement.PublishingService.publishArticle(ka.KnowledgeArticleId, true);
            for(Integer i=0; i<2; i++){
                Task t = new Task();
                t.Subject = 'Test Review';
                t.Type = 'Outbound Call';
                t.Status = 'Open';
                t.Priority = 'Normal';
                t.ActivityDate= date.today();
                t.Knowledge__c = ka.Id;
                t.OwnerId = ka.LastModifiedById;
                t.Content_Sponsor_Email__c = 'xyz@test.com';
                t.Content_Sponsor_Name__c = u.FirstName;
                t.Secondary_Content_Sponsor_Name__c = u.FirstName;
                t.Description= 'Test';
                taskList.add(t);
            }
            
        }
        insert taskList;
        Map<Id, String> failedArticles = new Map<Id, String>();
        failedArticles.put(knowledgeArticles[0].Id,'NO BATCH SETTINGS FOUND');
        test.startTest();
        knowledgeCreateTask_SendEmailBatch.validateOverRideSetting();
        knowledgeCreateTask_SendEmailBatch.makeLog(null, 'NO BATCH SETTINGS FOUND');
        knowledgeCreateTask_SendEmailBatch.makeLog(null, failedArticles);
        CalloutException e = new CalloutException();
        knowledgeCreateTask_SendEmailBatch.getExceptionString(e);
        System.runAs(u){
            Database.executeBatch(new knowledgeCreateTask_SendEmailBatch(), 200);
        }
        test.stopTest();
        
    }
     public static String generateEmail() {
		String orgId = UserInfo.getOrganizationId();
    	String seconds = system.now().format(DATE_FORMAT);
    	return orgId + seconds + '@att.test.com';
    }    
    
    

}
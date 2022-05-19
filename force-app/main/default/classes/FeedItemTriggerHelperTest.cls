/**********
    
    Name            : FeedItemTriggerHelperTest
    Description     : This is the test class for FeedItemTriggerHelper.
    
***********/

@isTest
public with sharing class FeedItemTriggerHelperTest {

    @IsTest(SeeAllData=true)
    public static  void testunitone(){
        
        
        List<FeedComment> feedCommentList = new List<FeedComment>();
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser112@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standarduser112@testorg.com',
        ATTUID__c = 'ased1');
        INSERT u;
        
        
        Test.StartTest();
        
       	Knowledge__kav knFrnt = [SELECT ID,Title,ContentSponsor__c,/*BWSecContentSponsor__c,*/KnowledgeArticleId FROM Knowledge__kav where (NOT ContentSponsor__c LIKE '%@%') AND (NOT ContentSponsor__c LIKE '%,%')  LIMIT 1];
     //   Knowledge__ka kaFeed = [SELECT ID FROM Knowledge__ka LIMIT 1];
        
        FeedItem f = new FeedItem();
        f.ParentId = knFrnt.KnowledgeArticleId;
        f.body = 'test';
        insert f;
           
         
        FeedComment fc = new FeedComment();
        fc.CommentBody = 'legal test';
        fc.FeedItemId = f.Id;   // please add this
        insert fc;
        FeedComment fc1 = new FeedComment();
        fc1.CommentBody = 'legal test 1';
        fc1.FeedItemId = f.Id;   // please add this
        insert fc1;
        FeedComment fc2 = new FeedComment();
        fc2.CommentBody = 'legal test 2';
        fc2.FeedItemId = f.Id;   // please add this
        insert fc2;
        FeedComment fc3 = new FeedComment();
        fc3.CommentBody = 'legal test 3';
        fc3.FeedItemId = f.Id;   // please add this
        insert fc3;
        feedCommentList.add(fc);
        feedCommentList.add(fc1);
        feedCommentList.add(fc2);
        feedCommentList.add(fc3);
        
        Test.StopTest();

    }

}
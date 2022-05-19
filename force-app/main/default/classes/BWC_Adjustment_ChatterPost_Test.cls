@IsTest(SeeAllData=true)
private class BWC_Adjustment_ChatterPost_Test {
    @IsTest
    static void testManagerMessage() {
        // Creating adjustment and getting user
        Adjustment__c adj = BWC_TestDataFactory.createAdjustment();
        User man = [SELECT Id FROM User WHERE Id = :adj.Manager__c];

        System.runAs(man) {
            // Calling method
            BWC_Adjustment_ChatterPost.postSOAFailMessageForManager(adj.Id);

            // Verifying results
            List<FeedItem> feedList = [SELECT Id, ParentID FROM FeedItem WHERE ParentId = :adj.Case__c];
            System.assert(feedList.size() > 0, 'Chatter post failed.');
        }
    }

    @IsTest
    static void testQueueMessage() {
        // Creating adjustment and getting user
        Adjustment__c adj = BWC_TestDataFactory.createAdjustment();
        User man = [SELECT Id FROM User WHERE Id = :adj.Manager__c];

        // Creating queue and chatter group, but must be done in different context, hence runAs()
        Group soaQueue = new Group(Name = 'Test SOA Group', Type = 'Queue');
        insert soaQueue;

        System.runAs(man) {
            QueuesObject testQueue = new QueueSObject(QueueID = soaQueue.id, SObjectType = 'Case');
            insert testQueue;

            CollaborationGroup soaChatterGroup = new CollaborationGroup(
                Name = 'Test SOA Group',
                CollaborationType = 'Public'
            );
            insert soaChatterGroup;

            // Updating case owner to queue
            Case adjCase = [SELECT Id, OwnerId FROM Case WHERE Id = :adj.Case__c];
            adjCase.OwnerId = soaQueue.Id;
            update adjCase;

            // Calling method
            BWC_Adjustment_ChatterPost.postSOAFailMessageForQueue(adj.Id);

            // Verifying results
            List<FeedItem> feedList = [SELECT Id, ParentID FROM FeedItem WHERE ParentId = :adj.Case__c];
            System.assert(feedList.size() > 0, 'Chatter post failed.');
        }
    }

    @IsTest
    static void testConvertedAdjustmentPost() {
        // Creating adjustments
        Adjustment__c adj = BWC_TestDataFactory.createAdjustment();
        User man = [SELECT Id FROM User WHERE Id = :adj.Manager__c];
        Adjustment__c newAdj = adj.clone();

        System.runAs(man) {
            insert newAdj;
        }

        // Call method
        BWC_Adjustment_ChatterPost.postForConvertedAdjustment(adj.Case__c, newAdj.Case__c);

        // Verifying results
        List<FeedItem> feedList = [SELECT Id, ParentID FROM FeedItem WHERE ParentId = :newAdj.Case__c];
        System.assert(feedList.size() > 0, 'Chatter post failed.');
    }
}
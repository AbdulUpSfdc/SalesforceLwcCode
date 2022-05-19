@IsTest
private  class BWC_OverrideRoutingActionController_Test {
    @IsTest
    static void getQueueTest(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = BWC_TestDataFactory.createUser(p.Id);
        
        Group testGroup = new Group(Name='test group', Type='Queue');
		insert testGroup;
       
        System.runAs(testUser){
        	QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
            insert testQueue;
            
            BWC_OverrideRoutingActionController.getQueue();
            List<QueueSobject> queueList = [SELECT Id, QueueId, Queue.Name, Queue.DeveloperName, SobjectType 
                                            FROM QueueSobject where SobjectType = 'Case' AND (NOT Queue.Name like '%OOP %') 
                                            AND Id=:testQueue.Id];
            System.assert(queueList.size() > 0, 'Success');
        }
    } 

}
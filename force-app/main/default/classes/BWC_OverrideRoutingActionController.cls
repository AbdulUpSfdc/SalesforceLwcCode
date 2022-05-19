public without sharing class BWC_OverrideRoutingActionController {
    @AuraEnabled(cacheable=true)
    public static List<QueueSobject> getQueue()
    {
        List<QueueSobject> queueList = new List<QueueSobject>();
        try 
        {
            queueList = [SELECT Id, QueueId, Queue.Name, Queue.DeveloperName, SobjectType FROM QueueSobject where SobjectType = 'Case' AND (NOT Queue.Name like '%OOP%')ORDER BY Queue.Name];
            // Security enforcement is not required for the above query
            return queueList;
        } catch (Exception e) { BWC_ExceptionUtils.handleException(e, true); throw e; }
    }
}
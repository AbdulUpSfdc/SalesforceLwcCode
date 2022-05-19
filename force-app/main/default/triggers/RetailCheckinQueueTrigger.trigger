trigger RetailCheckinQueueTrigger on RetailCheckinQueue__c (after insert, after update,  before update, before insert) {
    new RetailCheckinQueueTriggerHandler().run();
}
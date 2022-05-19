/*
* This trigger is for any updates happening on Store object.
*  Delegation to Apex classes to perform actual execution of the logic
*/
trigger StoreTrigger on Store__c (before insert,before update,after insert,after update) {
	new StoreTriggerHandler().run();
}
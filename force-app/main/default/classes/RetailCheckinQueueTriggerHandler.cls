/*
* This class contains the framework for the DCI Retail Checkin Queue trigger
*/
public class RetailCheckinQueueTriggerHandler extends TriggerHandler {
    /**
     * This method handles the after insert operations
     */
    public override void afterInsert() {
        TriggerHelper.DCITriggerMap triggerMap = new TriggerHelper.DCITriggerMap();
        triggerMap = RetailCheckinQueueTriggerHelper.checkPriorConditions(triggerMap, Trigger.New, Trigger.Old, Trigger.NewMap, Trigger.OldMap);
        RetailCheckinQueueTriggerHelper.performOperations(triggerMap, Trigger.New, Trigger.Old, Trigger.NewMap, Trigger.OldMap);
    }
    /**
     * This method handles the after update operations
     */
    public override void afterUpdate() {
        TriggerHelper.DCITriggerMap triggerMap = new TriggerHelper.DCITriggerMap();
        triggerMap = RetailCheckinQueueTriggerHelper.checkPriorConditions(triggerMap, Trigger.New, Trigger.Old, Trigger.NewMap, Trigger.OldMap);
          RetailCheckinQueueTriggerHelper.sendEWTSMS(Trigger.New,Trigger.OldMap);
        RetailCheckinQueueTriggerHelper.performOperations(triggerMap, Trigger.New, Trigger.Old, Trigger.NewMap, Trigger.OldMap);

    }

    public override void beforeInsert() {
        RetailCheckinQueueTriggerHelper.populateMinutesUntilFree(Trigger.New, null);
        RetailCheckinQueueTriggerHelper.populateInitialQP(Trigger.New);
        RetailCheckinQueueTriggerHelper.populateInitialMaxEWT(Trigger.New, null);
    }
    
    public override void beforeUpdate() {
        RetailCheckinQueueTriggerHelper.populateMinutesUntilFree(Trigger.New, Trigger.oldMap);
        RetailCheckinQueueTriggerHelper.populateInitialQP(Trigger.New);
        RetailCheckinQueueTriggerHelper.populateLastModifiedTimeZone(Trigger.New,Trigger.oldMap);//6070
        RetailCheckinQueueTriggerHelper.populateInitialMaxEWT(Trigger.New, Trigger.oldMap);
    }
}
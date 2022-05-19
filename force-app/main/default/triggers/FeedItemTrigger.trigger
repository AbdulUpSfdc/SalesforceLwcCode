/*
 *Initial Version - 03/22/2021 - Story 1675 
*/
trigger FeedItemTrigger on FeedItem (before insert, before update, after insert, after update) {

    if(boolean.Valueof(System.Label.feedItemTriggerBypass)){ return;}
    
    if(Trigger.isInsert && Trigger.isAfter){
            BWC_EditFeedItemHelper.edit(trigger.new);
            BWC_FeedItemTriggerHelperClass.updateLastActivityonCase();
    }
    //CDEX 71551
    //BWC_FeedItemTriggerHandler.delegateProcessing();
}
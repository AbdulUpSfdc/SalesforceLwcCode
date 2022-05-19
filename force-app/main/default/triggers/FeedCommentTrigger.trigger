trigger FeedCommentTrigger on FeedComment (before insert, after insert, after update) {
    
  if(trigger.isAfter){
        if(trigger.isInsert){
            FeedItemTriggerHelper.afterInsert(trigger.new);
        }else if(trigger.isUpdate){
        }
    }else if(trigger.isBefore){
        if(trigger.isInsert){
        }
	}
}
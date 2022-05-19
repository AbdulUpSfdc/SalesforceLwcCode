trigger BWFeedbackThreadComment on BWFeedbackThreadComment__c (before insert, after insert) {
    if(trigger.isBefore){
    	if(trigger.isInsert){  
            BWPublicFeedbackThreadCommentTgrHelper.setDisplayNameValues(Trigger.new);          
        }
	}
    if(trigger.isAfter){
    	if(trigger.isInsert){  
            BWPublicFeedbackThreadCommentTgrHelper.updateParentThread(Trigger.new);          
        }
	}
}
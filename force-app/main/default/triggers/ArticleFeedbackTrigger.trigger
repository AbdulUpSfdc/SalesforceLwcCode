trigger ArticleFeedbackTrigger on KM_Article_Feedback__c (before insert,after insert, after update) {
    
    if(trigger.isbefore) {
        if(trigger.isinsert){
            //BWArticleFeedbackHelper.addPrimaryChnnl(trigger.new);
            BWArticleFeedbackHelper.handleBeforeInsert(Trigger.new);   
            
        }
    } 
    else if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            BWArticleFeedbackHelper.updateSponsorEmail(Trigger.newMap);
        }
        else if(Trigger.isUpdate) {
            //BWArticleFeedbackHelper.sendFeedbackNotifications(Trigger.oldMap, Trigger.newMap);
        }
    }
}
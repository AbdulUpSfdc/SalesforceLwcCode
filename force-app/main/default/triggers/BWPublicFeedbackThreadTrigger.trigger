trigger BWPublicFeedbackThreadTrigger on BWPublicFeedbackThread__c (before insert) {

    if(trigger.isAfter){
        if(trigger.isInsert){ 
          
        }else if(trigger.isUpdate){
            
        }
    } else if(trigger.isBefore){
    	if(trigger.isInsert){  
            BWPublicFeedbackThreadTriggerHelper.setFieldValues(Trigger.new);
            BWPublicFeedbackThreadTriggerHelper.setDisplayNameValues(Trigger.new);             
        }
        else if(trigger.isUpdate){
            
        }
    }    
    
}
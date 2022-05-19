trigger BWC_Adjustment_Trigger on Adjustment__c (before insert, before update, after insert, after update) {
    
    try{
        if(Trigger.isBefore){
            if(Trigger.isInsert){
                BWC_Adjustment_Trigger_Helper.handleBeforeInsert();
            }

            if(Trigger.isUpdate){
                BWC_Adjustment_Trigger_Helper.handleBeforeUpdate();
            }
        }

        if(Trigger.isAfter){

            if(Trigger.isInsert){
                BWC_Adjustment_Trigger_Helper.handleAfterInsert();
            }

            if(Trigger.isUpdate){
                BWC_Adjustment_Trigger_Helper.handleAfterUpdate();
            }
        }
    }catch(Exception e) {
        BWC_ExceptionUtils.handleException(e, true);
        throw e;
    }
}
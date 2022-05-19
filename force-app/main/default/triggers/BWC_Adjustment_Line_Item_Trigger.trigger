trigger BWC_Adjustment_Line_Item_Trigger on Adjustment_Line_Item__c (before insert, before update, after insert, after update) {
    
    try{
        if(Trigger.isBefore){
            if(Trigger.isInsert){
                BWC_AdjustmentLineItem_Trigger_Helper.handleBeforeInsert();
            }

            if(Trigger.isUpdate){
            }
        }

        if(Trigger.isAfter){

            if(Trigger.isInsert){

                BWC_AdjustmentLineItem_Trigger_Helper.handleAfterInsert();
            }

            if(Trigger.isUpdate){
            }
        }
    }catch(Exception e) {
        BWC_ExceptionUtils.handleException(e, true);
        throw e;
    }
}
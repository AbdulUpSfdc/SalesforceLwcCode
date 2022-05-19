trigger BWC_Case_Feedback_Trigger on Case_Feedback__c(before insert, before update) {
    try {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                BWC_Case_Feedback_Trigger_Helper.handleBeforeInsert();
            }
            if (Trigger.isUpdate) {
                BWC_Case_Feedback_Trigger_Helper.handleBeforeUpdate();
            }
        }
    } catch (Exception e) {
        BWC_ExceptionUtils.handleException(e, true);
        throw e;
    }
}
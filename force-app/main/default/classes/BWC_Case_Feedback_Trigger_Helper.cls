public with sharing class BWC_Case_Feedback_Trigger_Helper {
    private static List<Case_Feedback__c> feedbackList;

    // Before record is inserted
    public static void handleBeforeInsert() {
        initializeData();
        maskDescription();
    }

    // Before record is updated
    public static void handleBeforeUpdate() {
        initializeData();
        maskDescription();
    }

    // Initializing data
    public static void initializeData() {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                feedbackList = Trigger.new;
            }
            if (Trigger.isUpdate) {
                feedbackList = Trigger.new;
            }
        }
    }

    // Masking case issue description field using BWC_Utils
    public static void maskDescription() {
        for (Case_Feedback__c feedback : feedbackList) {
            if (String.isNotEmpty(feedback.Case_Issue_Description__c)) {
                feedback.Case_Issue_Description__c = BWC_Utils.maskSentence(feedback.Case_Issue_Description__c);
            }
        }
    }
}
public with sharing class KMFeatureAccessibilityHelper {

    //hasFeature = KMFeatureAccessibilityHelper.featureIsAccessible('Public Feedback', 'Primary Channel', 'userprimaryChannel');
    public static Boolean featureIsAccessible(String featureName, String filterType, String filterValue) {
        //query table if result is there return true else return false;
        System.debug('featureName=|'+featureName+'|filterType=|'+filterType+'|filterValue=|'+filterValue);
        if (featureName==null || filterType==null ||filterValue==null ){
            return false;
        }
        List<BWKMKnowledgeFeatureAccessibility__c>  knowledgeFeatureAccessibility = [Select Id,Public_Feedback_Visible__c from BWKMKnowledgeFeatureAccessibility__c where 
                                                                                     Accessibility_Filter_Type__c= :filterType and
                                                                                     Filter_Value__c= :filterValue and Feature_Name__c = :featureName ];
        if (knowledgeFeatureAccessibility.size()>0){
            if (knowledgeFeatureAccessibility[0].Public_Feedback_Visible__c){
                return true;
            }else{
                return false;
            }
        }
        return false;
    }
}
@isTest
public class KMFeatureAccessibilityHelperTest {
    @testsetup
    public static void testData(){
    BWKMKnowledgeFeatureAccessibility__c accessibility1 = KM_TestDataFactory.getFeatureAccessibility('Public Feedback', 'Primary Channel', 'KM ACC Sales',true);
        insert accessibility1;
        BWKMKnowledgeFeatureAccessibility__c accessibility2 = KM_TestDataFactory.getFeatureAccessibility('Public Feedback', 'Primary Channel', 'KM Agent Principal',false);
      insert accessibility2;
  
    }
    
    public static testMethod void testFeatureIsAccessible(){
        Boolean isVisible =KMFeatureAccessibilityHelper.featureIsAccessible('Public Feedback', 'Primary Channel', 'KM ACC Sales');
        System.assertEquals(isVisible,true);
        Boolean isVisible2 =KMFeatureAccessibilityHelper.featureIsAccessible('Public Feedback', 'Primary Channel', 'KM Agent Principal');
        System.assertEquals(isVisible2,false);
        Boolean isVisible3 =KMFeatureAccessibilityHelper.featureIsAccessible('Public Feedback', 'Primary Channel', 'KM Test');
        System.assertEquals(isVisible3,false);
         Boolean isVisible4 =KMFeatureAccessibilityHelper.featureIsAccessible(null, 'Primary Channel', 'KM Test');
        System.assertEquals(isVisible4,false);
    }
    
}
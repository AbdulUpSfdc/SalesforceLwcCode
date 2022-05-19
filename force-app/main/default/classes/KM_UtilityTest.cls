@isTest
public class KM_UtilityTest {
    @isTest
    static void testData(){
        KM_Utility.getFeatureSettings('Public_Feedback_Bell_Notifications');
        //To cover catch Block
        Test.StartTest();
        KM_Utility.getFeatureSettings(null);
        Test.stopTest();
      }

}
@isTest
public class DataClassificationReportControllerTST {
    
    @isTest
    public static void testCase00(){
        string res = DataClassificationReportController.getEntityData('Account');
        system.assertNotEquals(null, res);
    }
    @isTest
    public static void testCase01(){
        string res = DataClassificationReportController.getEntities();
        system.assertNotEquals(null, res);
    }
    @isTest
    public static void testCase02(){
        string res = DataClassificationReportController.getMetaDataForValues();
        system.assertNotEquals(null, res);
    }
    @isTest
    public static void testCase03(){
        string res = DataClassificationReportController.getEntitiesForInput();
        system.assertNotEquals(null, res);
    }
    @isTest
    public static void testCase04(){
        DataClassificationReportController controller = new DataClassificationReportController();
        string tempVar = '["lead","account","order"]';
        string res = DataClassificationReportController.saveMetaValues(tempVar,'reportable_entity_json__c');
        system.assertNotEquals(null, res);
    }
    @isTest
    public static void testCase05(){
        DataClassificationReportController controller = new DataClassificationReportController();
        string res = DataClassificationReportController.getMetaDataForOmittedValues();
        system.assertNotEquals(null, res);
    }
}
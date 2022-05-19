@istest
public class dciModFlexipageDisplayControllerTest {
    @TestSetup
    static void makeData(){
        TestDataFactory dataFactory = new TestDataFactory();
        dataFactory.createTestData(2,'Empl');
    }
    public static testMethod void testdisplayComponent(){
        Employee__c empRecord = [Select Id from Employee__c limit 1];
        empRecord.User__c = userinfo.getUserId();
        update empRecord;
        Test.StartTest();
        dciModFlexipageDisplayController.displayComponent();
        Test.stopTest();
        
    }
}
@isTest
public class StoreUpdateQueueableTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    
    @TestSetup
    static void makeData(){
        dataFactoryWrap = dataFactory.createTestData(2,'EmpStrRetail');
    }
    
    static testmethod void storeUpdatableQueueTest(){
        List<Store__c> lstStore = new List<Store__c>();
        Map<string,store__c> storeMap = new Map<string,store__c> ();
        List<Group> groupsList = new List<Group>();
        Group gp = new Group(Name = 'Test store group',DeveloperName = 'testDeveloperName');
        insert gp;
        groupsList.add(gp);
        
        List<Store__c> storeList = [select id,PublicGroupId__c,MarketId__c from Store__c];
        storeMap.put('testDeveloperName',storeList[0]);
        lstStore.add(storeList[1]);
        Test.startTest();
        StoreUpdateQueueable sQueue = new StoreUpdateQueueable(groupsList,storeMap,lstStore);
        system.enqueueJob(sQueue);
        Test.stopTest();
        
    }
    
}
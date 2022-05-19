@isTest
public without sharing class EmployeeStrategyTest {

    
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    
    @isTest
    static void employeeCreatedStrategy() {
        dataFactoryWrap = dataFactory.createTestData(1, 'EmpC');
        
        Map<Id,Map<String,List<Employee__c>>> mapStoreVsMapRoleEmployee = dataFactory.getHomeStoreEmployeesByRole(dataFactoryWrap.mapRoleVsUsers, dataFactoryWrap.lstStore);        
        Map<String,List<Employee__c>> mapRoleToEmps = mapStoreVsMapRoleEmployee.get(dataFactoryWrap.lstStore.get(0).Id);
        List<Employee__c> repEmpsList = mapRoleToEmps.get(TestDataFactory.mapProfileToSfProfile.get(TestDataFactory.REP_PROFILE));
        
        LeadRedistribution__c lrd = New LeadRedistribution__c(Employee__c=repEmpsList.get(0).Id, 
                                                              NewValue__c=repEmpsList.get(0).SFProfileId__c,
                                                              Status__c=RetailConstants.STATUS_NEW,
                                                              IsPrimary__c = true,
                                                              User__c = repEmpsList.get(0).User__c,
                                                              Reason__c = 'New Employee');
        insert lrd;
        
        List<LeadRedistribution__c> beforeStrategyRunLrdsList = [SELECT Id, STatus__c FROM LeadRedistribution__c WHERE Id =: lrd.Id];
        System.assert(beforeStrategyRunLrdsList.size() == 1);
        
        Test.startTest();
        EmployeeCreated ec = New EmployeeCreated(New Map<Id, LeadRedistribution__c>{lrd.Id => lrd});
        ec.runStrategy();
        Test.stopTest();
        
        List<LeadRedistribution__c> afterStrategyRunLrdsList = [SELECT Id, STatus__c FROM LeadRedistribution__c WHERE Id =: lrd.Id];
        System.assert(afterStrategyRunLrdsList.size() == 0);
    }
    
    @isTest
    static void employeeDemotionStrategy() {
        dataFactoryWrap = dataFactory.createTestData(1, 'EmpD');
        
        Map<Id,Map<String,List<Employee__c>>> mapStoreVsMapRoleEmployee = dataFactory.getHomeStoreEmployeesByRole(dataFactoryWrap.mapRoleVsUsers, dataFactoryWrap.lstStore);
        Map<String,List<Employee__c>> mapRoleToEmps = mapStoreVsMapRoleEmployee.get(dataFactoryWrap.lstStore.get(0).Id);
        List<Employee__c> repEmpsList = mapRoleToEmps.get(TestDataFactory.mapProfileToSfProfile.get(TestDataFactory.REP_PROFILE));
        List<Employee__c> mgrEmpsList = mapRoleToEmps.get(TestDataFactory.mapProfileToSfProfile.get(TestDataFactory.SM_PROFILE));
        
        LeadRedistribution__c lrd = New LeadRedistribution__c(Employee__c = repEmpsList.get(0).Id, 
                                                              OldValue__c = mgrEmpsList.get(0).SFProfileId__c,
                                                              NewValue__c = repEmpsList.get(0).SFProfileId__c,
                                                              Status__c = RetailConstants.STATUS_NEW,
                                                              IsPrimary__c = true,
                                                              User__c = repEmpsList.get(0).User__c,
                                                              Reason__c = 'Employee Demotion');
        insert lrd;
        
        List<LeadRedistribution__c> beforeStrategyRunLrdsList = [SELECT Id, STatus__c FROM LeadRedistribution__c WHERE Id =: lrd.Id];
        System.assert(beforeStrategyRunLrdsList.size() == 1);
        
        Test.startTest();
        EmployeeDemotion ec = New EmployeeDemotion(New Map<Id, LeadRedistribution__c>{lrd.Id => lrd});
        ec.runStrategy();
        Test.stopTest();
        
        List<LeadRedistribution__c> afterStrategyRunLrdsList = [SELECT Id, STatus__c FROM LeadRedistribution__c WHERE Id =: lrd.Id];
        System.assert(afterStrategyRunLrdsList.size() == 0);
    }
    
    @isTest
    static void employeePromotionStrategy() {
        dataFactoryWrap = dataFactory.createTestData(1, 'EmpP');
        
        Map<Id,Map<String,List<Employee__c>>> mapStoreVsMapRoleEmployee = dataFactory.getHomeStoreEmployeesByRole(dataFactoryWrap.mapRoleVsUsers, dataFactoryWrap.lstStore);
        Map<String,List<Employee__c>> mapRoleToEmps = mapStoreVsMapRoleEmployee.get(dataFactoryWrap.lstStore.get(0).Id);
        List<Employee__c> repEmpsList = mapRoleToEmps.get(TestDataFactory.mapProfileToSfProfile.get(TestDataFactory.REP_PROFILE));
        List<Employee__c> mgrEmpsList = mapRoleToEmps.get(TestDataFactory.mapProfileToSfProfile.get(TestDataFactory.SM_PROFILE));
        
        LeadRedistribution__c lrd = New LeadRedistribution__c(Employee__c = repEmpsList.get(0).Id, 
                                                              OldValue__c = repEmpsList.get(0).SFProfileId__c,
                                                              NewValue__c = mgrEmpsList.get(0).SFProfileId__c,
                                                              Status__c = RetailConstants.STATUS_NEW,
                                                              IsPrimary__c = false,
                                                              User__c = repEmpsList.get(0).User__c,
                                                              Reason__c = 'Employee Promotion',
                                                              Action__c='Redistribute',
                                                              AdditionalAttributes__c=dataFactoryWrap.lstStore.get(0).Id);
        insert lrd;
        
        List<LeadRedistribution__c> beforeStrategyRunLrdsList = [SELECT Id, STatus__c FROM LeadRedistribution__c WHERE Id =: lrd.Id];
        System.assert(beforeStrategyRunLrdsList.size() == 1);
        
		Test.startTest();        
        EmployeePromotion ec = New EmployeePromotion(New Map<Id, LeadRedistribution__c>{lrd.Id => lrd});
        ec.runStrategy();
        Test.stopTest();
        
        List<LeadRedistribution__c> afterStrategyRunLrdsList = [SELECT Id, STatus__c FROM LeadRedistribution__c WHERE Id =: lrd.Id];
        System.assert(afterStrategyRunLrdsList.size() == 0);
    }
    

}
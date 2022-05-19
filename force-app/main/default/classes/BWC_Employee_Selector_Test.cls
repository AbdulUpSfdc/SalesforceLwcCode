@IsTest
public with sharing class BWC_Employee_Selector_Test {

    @TestSetup
    static void makeData(){
        Employee__c emp = new Employee__c();
        emp.User__c = UserInfo.getUserId();
        emp.EmployeeId__c = 'tt1234';

        insert emp;
    }

    @IsTest
    static void getEmployeeTest(){

        Test.startTest();
        Employee__c response = BWC_Employee_Selector.getEmployee(UserInfo.getUserId());
        Test.stopTest();

    }

    @IsTest
    static void getEmployeeByUIDTest(){

        String UID = 'tt1234';

        Employee__c response = BWC_Employee_Selector.getEmployeeByUID(UID);

        System.assert(response.EmployeeId__c == UID, 'Employee with correct UID was not entered.');

    }

    @IsTest
    static void getUsersManagerEmployeeRecTest() {
        User e1 = BWC_TestDataFactory.createUser();
		User m1 = BWC_TestDataFactory.createUser();
        
        Update New User(Id=e1.Id, ManagerId=m1.Id);
		Employee__c manager = BWC_TestDataFactory.createEmployee();
        manager.User__c = m1.Id;
        Insert manager;
        
        Test.startTest();
        Employee__c e2 = BWC_Employee_Selector.getUsersManagerEmployeeRec(e1.Id);
        Test.stopTest();
        
        System.assert(e2.User__c == m1.Id);
    }
}
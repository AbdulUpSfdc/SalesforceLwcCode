@isTest
/*
* This class is used to test various test cases of proximity calculation on lead for prospects
* Author: Rashmi Thippeswamy
*/
private class UserLocationTraceTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    /* 
*This method is used to setup test data of employee,employee store retail,leads and stores
*/
    @TestSetup
    static void makeData(){
        //dataFactoryWrap = dataFactory.createTestData(3,'lead');
    }
    @isTest
    static void testProximity(){
        Store__c st ;
        Store__c st2 ;
        List<Employee__c> lstEmp =new List<Employee__c>();
        lstEmp = [Select id ,homeStoreLocation__c  FROM Employee__c where User__c=: Userinfo.getUserId()];
        if(lstEmp.isEmpty()){
            Employee__c emp =new Employee__c();
            st = new Store__c();
            st.Name='Test store';
            st.GeoLocation__latitude__s = 25.2;
            st.GeoLocation__longitude__s = 45.5;
            insert st;
            st2 = new Store__c();
            st2.Name='Test store1';
            st2.GeoLocation__latitude__s = 27.2;
            st2.GeoLocation__longitude__s = 47.5;
            insert st2;
            st = [select id from Store__c   limit 1];
            
            emp.homeStoreLocation__c = st.id;
            emp.User__c =UserInfo.getUserId();
            emp.SFProfileId__c = RetailConstants.RSC_REP;
            insert emp;
            
            EmployeeStoreRetail__c esr = new EmployeeStoreRetail__c();
            esr.Store__c = st.Id;
            esr.Employee__c = emp.Id;
            insert esr;
            
            EmployeeStoreRetail__c esr1 = new EmployeeStoreRetail__c();
            esr1.Store__c = st2.Id;
            esr1.Employee__c = emp.Id;
            esr1.IsLoginStore__c= true;
            insert esr1;
        }
        UserLocationTrace.putUserLocationInCustomSetting(new List<String>{ st.id});
        UserLocationTrace.putUserLocationInCustomSetting(new List<String>{ st.id});
    }   
}
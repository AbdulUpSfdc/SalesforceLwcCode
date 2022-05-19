@IsTest
public class LogOutTriggerHandlerTest {
    
    @IsTest
    private static void test(){
        
        Store__c  st = new Store__c();
        st.Name='Test store';
        st.GeoLocation__latitude__s = 25.2;
        st.GeoLocation__longitude__s = 45.5;
        insert st;
        
        Employee__c emp =new Employee__c();
        emp.homeStoreLocation__c = st.id;
        emp.User__c =UserInfo.getUserId();
        emp.SFProfileId__c = RetailConstants.RSC_REP;
        insert emp;
        
        EmployeeStoreRetail__c esr = new EmployeeStoreRetail__c();
        esr.Store__c = st.Id;
        esr.Employee__c = emp.Id;
        esr.DCIPresenceStatus__c = 'Online';
        esr.IsLoginStore__c = true;
        insert esr;
        
        Test.startTest();
        EventBus.publish(new LogoutEventStream(UserId=UserInfo.getUserId()));
        Test.stopTest();}
    
}
@isTest
public class DCIofflinebatchtest {
    @isTest
    static void TestBatchJob(){
        
        Store__c testStore = new Store__c();
        
        insert testStore;
        Employee__c emp = new Employee__c();
        emp.SFProfileId__c = 'RSC-REP';
        emp.User__c = UserInfo.getUserId();
        insert emp;
        
        List <EmployeeStoreRetail__c> Empoff = new List<EmployeeStoreRetail__c>();
        for(integer i = 0;i < 200 ; i++){
            EmployeeStoreRetail__c ER = new EmployeeStoreRetail__c();
            ER.IsLoginStore__c = true;
            ER.Store__c = teststore.id;
            ER.DCIPresenceStatus__c = 'Online';
            ER.Employee__c = emp.id;
            Empoff.add(ER);
        }
        insert Empoff;
        
        Test.startTest();
        
        DCIofflinebatch obj = new DCIofflinebatch();
        DataBase.executeBatch(obj); 
        
        Test.stopTest();
        
    }
    
   
    
}
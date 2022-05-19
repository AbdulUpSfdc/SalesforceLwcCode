@IsTest
public class BWC_EmployeeServices_Test {
    @testsetup static void setupEmployeeData(){
        SOA_Level__c soaLevel = BWC_TestDataFactory.createSOA('Centers','Collections','Collections','Level 1','Wireless',100);
        insert soaLevel;     

        Employee__c emp = BWC_TestDataFactory.createEmployeeWithSOA(soaLevel,'tt1234',UserInfo.getUserId());
        insert emp;     
    }
    @IsTest static void testmethod1(){
        Map<String,employee__c> employeeMap = new Map<String,Employee__c>();
        String userId = UserInfo.getUserId();
        employeeMap = BWC_EmployeeController.fetchEmployeeData(userId);
        system.assertEquals(100,employeeMap.get(userId).SOA_Level__r.Authorization_Amount__c);
    }
    @IsTest static void testmethod2(){

        Employee__c emp = [select Id,User__c from Employee__c limit 1];
        String userId = UserInfo.getUserId();
        string response = BWC_EmployeeController.saveDetails(userId,null,emp.Id);
        Employee__c emprec = [select Id,Delegate_1__c,delegate_2__c from Employee__c where id =:emp.Id limit 1];
        system.assertEquals(emprec.Delegate_1__c,userId);
    }
    // Method to catch the Exception while saving the data with invalid ID
    @isTest static void errorDuringSaveDeetailsTestMethod(){
        string response;
        Employee__c emp = [select Id,User__c from Employee__c limit 1];
        try{
            response = BWC_EmployeeController.saveDetails(emp.User__c,'null',emp.Id);
        }catch(exception ex){
            system.debug('ex'+ex);
        }
        // Response will be response will be null if the error is thrown
        system.assertEquals(response==null,true);
    }
}
public with sharing class BWC_EmployeeService {    
    // Method to fetch Employee Details along with SOA Authorization Amount of the selected user from the LWC Component
    public static Map<string,Employee__c> getEmployeeInfo(string delegateId) {
        Map<String,employee__c> employeeMap = new Map<String,Employee__c>();
        List<Employee__c> empRecord = [select id,User__c,SOA_Level__r.Authorization_Amount__c from Employee__c where user__c =: delegateId WITH SECURITY_ENFORCED];
        for (Employee__c emp : empRecord){
            employeeMap.put(emp.User__c,emp);
        }
        return employeeMap;
    }
    
    // Method to update Delegate details on Employee Record based on the users selected from LWC Component
    public static void updateDelegatesOnEmployee(String delegate1,String delegate2,String recordId) {
        BWC_EmployeeUpdate employeeUpdate = new BWC_EmployeeUpdate();
        Employee__c emprec = new Employee__c(Id=recordId, Delegate_1__c=delegate1,delegate_2__c=delegate2);
        // Update Employee Record
        employeeUpdate.execute(emprec);
    }

    // Employee Object is a public readonly and Deligate fields needs to be updated
    public without sharing class BWC_EmployeeUpdate { 
        public void execute(Employee__c emp) {
            update emp;
        }
    }
}
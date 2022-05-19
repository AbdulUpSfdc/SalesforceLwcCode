/* ================================================
* @class name: BWC_Employee_Selector
* @author: Salesforce Inc.
* @purpose: Selector layer apex class
* @created date (mm/dd/yyyy) :  03/20/2021
================================================*/ 
public with sharing class BWC_Employee_Selector {
    
    public static Employee__c getEmployee(string userId){
        // FLS Not needed, results not returned to user
        list<Employee__c> returnValue = [
            SELECT User__c , Work_Street__c,Work_State__c,Work_Zipcode__c,Work_Country__c,Work_City__c,Delegate_1__c,Delegate_2__c,Channel__c,Channel1__c,Manager__c,Sub_Channel__c, Call_Center_ID_with_Channel__c
                      FROM Employee__c
                      WHERE User__c =: userId
                      LIMIT 1];
        return (returnValue.IsEmpty())?null:returnValue[0];            
    }
    public static Employee__c getEmployeeByUID(string attUserId) {
        // FLS Not needed, results not returned to user
        List<Employee__c> employee = [
            SELECT
                id, User__c, EmployeeId__c,
                SFProfileId__c, SOA_Level__c
            FROM Employee__c
            WHERE EmployeeId__c = :attUserId
            lIMIT 1
        ];

        return (employee.isEmpty()) ? null : employee[0];
    }
    
    public static Employee__c getUsersManagerEmployeeRec(String userId) {
            // FLS Not needed, results not returned to user
			List<Employee__c> employee = [SELECT Id, User__c, Channel1__c, Sub_Channel__c, Delegate_1__c, Delegate_2__c 
                                          FROM Employee__c
                                          WHERE User__c IN (SELECT ManagerId FROM User WHERE Id =:userId)
                                          LIMIT 1];

        return (employee.isEmpty()) ? null : employee[0];
    }
    
}
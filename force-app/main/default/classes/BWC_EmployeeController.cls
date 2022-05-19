public with sharing class BWC_EmployeeController {
    
    @AuraEnabled(cacheable=true)
    public static Map<string,Employee__c> fetchEmployeeData(String delegateId)
    {
        // Method to fetch Employee Details along with SOA Authorization Amount of the selected user from the LWC Component
        return BWC_EmployeeService.getEmployeeInfo(delegateId);
    }
    
    @AuraEnabled
    public static String saveDetails(String delegate1,String delegate2, String recordId)
    {   
        EmployeeResponseWrapper responseWrapper = new EmployeeResponseWrapper();
        
        String del1= String.isNotEmpty(delegate1) ? delegate1 : null;
        String del2= String.isNotEmpty(delegate2) ? delegate2 : null;
        
        try{
            // Method to update Delegate details on Employee Record based on the users selected from LWC Component
            BWC_EmployeeService.updateDelegatesOnEmployee(del1,del2,recordId);
            responseWrapper.success = true;
        }catch(System.Exception e) {
            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            throw BWC_Controller.handleException(e);
        }
        return responseWrapper.serialize();
    }
    

    public class EmployeeResponseWrapper extends BWC_ResponseWrapper {
        public List<Employee__c> employees;
    }
  
    
    
}
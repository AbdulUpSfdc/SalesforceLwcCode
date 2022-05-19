public with sharing class BWC_RSATokenService {
    public static BWC_RSAToken.RSATokenResponse getRSAToken(){
        String params = getRequest();
        BWC_RSAToken.RSATokenResponse response = BWC_RSATokenCallout.getRSAToken(params);
        
        return response;
    }
    
    public static String getRequest(){
        String attuid = BWC_Utils.getCurrentUserAttId();
        String Params = '';
        if(attuid == null || attuid == ''){
            throw new BWC_Exception('ATTUID is empty on user record');
        }
        Employee__c employeeRecord = getEmployeeRecord(attuid);
        if(employeeRecord == null){
             throw new BWC_Exception('Employee Record Not Found for ' + attuid);
        }
        params += 'attuid='+attuid + '&';
        params += 'firstName='+UserInfo.getFirstName() + '&';
        params += 'lastName='+ UserInfo.getLastName() + '&';
        params += 'channel='+employeeRecord.BWDefaultKMChannel__c + '&';
        params += 'market='+employeeRecord.BWDefault_KM_Master__c + '&';
        params += 'role='+employeeRecord.User_Role__c + '&';
        params += 'employeeType='+employeeRecord.Employee_Type_Id__c;        
        return params;
    }
    
    private static Employee__c getEmployeeRecord(String attuid){
        
        List<Employee__c> employeeRecords = [Select Id,BWDefaultKMChannel__c,BWDefault_KM_Master__c,User_Role__c,Employee_Type_Id__c from Employee__c WHERE EmployeeId__c =:attuid];
        if(employeeRecords.size() > 0){
            return employeeRecords[0];
        }
        
        return null;
    }
}
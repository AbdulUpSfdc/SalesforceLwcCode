@IsTest
public with sharing class BWC_RSATokenServiceCallout_Test {
    @IsTest
    static void requestResend(){
        BWC_ApiMock.setTestApiMock('RSAToken', 'RSAToken');
        Test.startTest();
        BWC_RSAToken.RSATokenResponse resp = new BWC_RSAToken.RSATokenResponse();
        try{
            resp =  BWC_RSATokenCallout.getRSAToken('attuid=aa123&firstName=test&lastName=test&channel=99&market=4&role=13944&employeeType=373');
        } catch(BWC_Exception e){
            System.assert(e.getCause() instanceOf System.JSONException);
        }
            Test.stopTest();
    }
    
        @IsTest
    static void requestNegative(){
        BWC_Utils.setStaticResourceMock('BWC_Mock_NotJson', 200);
		 try {        
        BWC_RSAToken.RSATokenResponse resp = new BWC_RSAToken.RSATokenResponse();
 			resp =  BWC_RSATokenCallout.getRSAToken('attuid=aa123&firstName=test&lastName=test&channel=99&market=4&role=13944&employeeType=373');
        }
        catch (BWC_Exception e) {
            System.assert(e.getCause() instanceOf System.JSONException);
        }
    }
    
    @isTest
    static void getRSAToken(){
        BWC_ApiMock.setTestApiMock('RSAToken', 'RSAToken');
        User u = BWC_TestDataFactory.createUser();
        u.ATTUID__c = 'tt1234';
        update u;
        System.runAs(u) {
        Employee__c emp = new Employee__c();
        emp.User__c = UserInfo.getUserId();
        emp.EmployeeId__c = 'tt1234';
		insert emp;
        Test.startTest();
        BWC_RSAToken.RSATokenResponse resp = new BWC_RSAToken.RSATokenResponse();
        resp =  BWC_RSATokenService.getRSAToken();
        Test.stopTest();
        }
    }
    
    @IsTest
    static void getRequest(){
        User u = BWC_TestDataFactory.createUser();
        u.ATTUID__c = 'tt1234';
        update u;
        System.runAs(u) {
        Employee__c emp = new Employee__c();
        emp.User__c = UserInfo.getUserId();
        emp.EmployeeId__c = 'tt1234';
		insert emp;
        Test.startTest();
        BWC_RSAToken.RSATokenResponse resp = new BWC_RSAToken.RSATokenResponse();
        String paramValresp =  BWC_RSATokenService.getRequest();
        Test.stopTest();
        }
    }
}
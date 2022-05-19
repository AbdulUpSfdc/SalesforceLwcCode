@IsTest
public class BWC_IMEISearchServiceCallout_Test {
    @IsTest
    static void requestResend(){
        BWC_ApiMock.setTestApiMock('IMEI_Search', 'BWC_IMEI_Search');
        Test.startTest();
        BWC_IMEISearch.IMEISearchResponse resp = new BWC_IMEISearch.IMEISearchResponse();
        try{
            resp =  BWC_IMEISearchCallout.IMEISearch('');
        } catch(BWC_Exception e){
            System.assert(e.getCause() instanceOf System.JSONException);
        }
            Test.stopTest();
    }
    
            @IsTest
    static void requestNegative(){
        BWC_Utils.setStaticResourceMock('BWC_Mock_NotJson', 200);
		 try {        
			BWC_IMEISearch.IMEISearchResponse resp = new BWC_IMEISearch.IMEISearchResponse();
 			 resp =  BWC_IMEISearchCallout.IMEISearch('');
         }
        catch (BWC_Exception e) {
            System.assert(e.getCause() instanceOf System.JSONException);
        }
    }
    @isTest
    static void getIMEI(){
        BWC_ApiMock.setTestApiMock('IMEI_Search', 'BWC_IMEI_Search');
        User u = BWC_TestDataFactory.createUser();
        u.ATTUID__c = 'tt1234';
        update u;
        System.runAs(u) {
        Employee__c emp = new Employee__c();
        emp.User__c = UserInfo.getUserId();
        emp.EmployeeId__c = 'tt1234';
		insert emp;
        Test.startTest();
         BWC_IMEISearch.IMEISearchResponse resp = new  BWC_IMEISearch.IMEISearchResponse();
        resp =  BWC_IMEISearchService.IMEISearch('12345678901234');
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
        String paramValresp =  BWC_IMEISearchService.getRequest('12345678901234');
        Test.stopTest();
        }
    }
}
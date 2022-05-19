/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-20-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   10-19-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
@isTest(SeeAllData=false)
public with sharing class BWC_ExceptionUtilsTest {
    public BWC_ExceptionUtilsTest() {

    }

    public static Account accountFail;
    public static Account accountSuccess;
    
    
    public static Integer eListSize;
   	public static String eCause;
    public static Decimal eLineNumber;
    public static String eMessage;
    public static String eStackTraceString;
    public static String eTypeName;
    
    static{
        
        accountFail = new Account();
        accountSuccess = new Account(LastName = 'Account 2',recordTypeId=BWC_TestDataFactory.getRecordTypeIdByName(BWC_Constants.PERSON_ACCOUNT,'Account'));
        
    }

  
    static testMethod void testAccountInsertFailure() {
       Test.startTest(); 
        try {
            insert accountFail;
        } catch(Exception e) {
            BWC_ExceptionUtils.handleException(e, true);
            
            eCause = String.valueOf(e.getCause());
            eLineNumber = e.getLineNumber();
            eMessage = e.getMessage();
            eStackTraceString = e.getStackTraceString();
            eTypeName = e.getTypeName();
        }        
        Test.stopTest();
        List<Exception__c> exceptionCreated = [SELECT Id, Name, Cause__c, Line_Number__c, Message__c, Stack_Trace_String__c, Type_Name__c FROM Exception__c];
        
        eListSize = exceptionCreated.size();
        System.assertEquals(eListSize, 1);
        
        System.assertEquals(eCause, exceptionCreated[0].Cause__c);
        System.assertEquals(eLineNumber, exceptionCreated[0].Line_Number__c);
        System.assertEquals(eMessage, exceptionCreated[0].Message__c);
        System.assertEquals(eStackTraceString, exceptionCreated[0].Stack_Trace_String__c);
        System.assertEquals(eTypeName, exceptionCreated[0].Type_Name__c);
        
    }
    
    static testMethod void testAccountInsertSuccess() {
        Test.startTest(); 
        try {
            insert accountSuccess;
        } catch(Exception e) {
            BWC_ExceptionUtils.handleException(e, true);
            
            eCause = String.valueOf(e.getCause());
            eLineNumber = e.getLineNumber();
            eMessage = e.getMessage();
            eStackTraceString = e.getStackTraceString();
            eTypeName = e.getTypeName();
        }        
        Test.stopTest(); 
        List<Exception__c> exceptionCreated = [SELECT Id, Name, Cause__c, Line_Number__c, Message__c, Stack_Trace_String__c, Type_Name__c FROM Exception__c];
        
        eListSize = exceptionCreated.size();
        System.assertEquals(eListSize, 0);
        
    }

    static testMethod void miscTest() {
        BWC_Exception ex1 = new BWC_Exception('test', 'req', 'res');
        ex1.initCause(new JSONException());
        BWC_Exception ex2 = new BWC_Exception('test', 'req', 'res');
        ex2.initCause(ex1);
        BWC_ExceptionUtils.handleException(ex2, 'test', 'test');
    }
}
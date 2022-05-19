/*
* This class is used to test various test cases for SMSNotificationOptInOut.
* Author:Abdul Khan
* Change(s):
* 	6-28-2021 - ak313h - create class
*/
@isTest
public class SMSNotificationOptInOutTest {
    
     @IsTest
    static void testNotifation(){
      // disable notification
   
      Employee__c objEmployee = new Employee__c();
        objEmployee.SMSNotificationOptInOut__c = true;
        objEmployee.User__c = userinfo.getuserid();
      insert objEmployee;      
           SMSNotificationOptInOut.setUserData(false);
      Boolean isNotificationEnabled =   SMSNotificationOptInOut.getUserData();
      // check user optin status 
      System.assertEquals(isNotificationEnabled, false);
    }

}
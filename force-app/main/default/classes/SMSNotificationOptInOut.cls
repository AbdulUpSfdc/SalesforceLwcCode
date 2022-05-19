public without sharing class SMSNotificationOptInOut {
    
    @AuraEnabled
   public static Boolean getUserData() {
       Boolean isEnabled;
       List<Employee__c> lstUser = [select Id ,SMSNotificationOptInOut__c from Employee__c where User__c=: userinfo.getuserid() limit 1];
      if(lstUser.size() > 0){
           isEnabled = !lstUser[0].SMSNotificationOptInOut__c;
      }
      return isEnabled;
   }
   
     @AuraEnabled
   public static Boolean setUserData(Boolean isEnabled) {
       List<Employee__c> lstUser = [select Id ,SMSNotificationOptInOut__c from Employee__c where User__c=: userinfo.getuserid() LIMIT 1];
       System.debug('lstUser===>>>>'+lstUser);
       Boolean isSuccess;
       if(lstUser.size() > 0){
           lstUser[0].SMSNotificationOptInOut__c = !isEnabled;
           update lstUser;
           System.debug('lstUser===>>>>'+lstUser);
           isSuccess = true;
       }
       return isSuccess;
   }
   
}
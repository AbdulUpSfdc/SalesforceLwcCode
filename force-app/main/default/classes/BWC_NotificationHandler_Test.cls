@IsTest
public class BWC_NotificationHandler_Test {
    @IsTest
    static void callUpdateMessagingSessionEventTest(){
        Account acct = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount('Wireless', acct);
        Case caseRec = BWC_TestDataFactory.createEscalatedCase(acct, billingAccount, acct.PersonContactId);
        List<BWC_CaseNotificationRequest> notificationsList = new List<BWC_CaseNotificationRequest>();
        Test.startTest();
            BWC_CaseNotificationRequest notifications = BWC_NotificationsHandler.getSMSDeliveryFlowRequest(caseRec.Id,billingAccount.Contact_Number__c,'test', billingAccount.Id);
            notificationsList.add(notifications);
            BWC_NotificationsHandler.sendSMS(notificationsList);
        Test.stopTest(); 
    }
  
}
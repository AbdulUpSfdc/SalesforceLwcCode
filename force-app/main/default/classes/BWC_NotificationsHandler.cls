public with sharing class BWC_NotificationsHandler {
    
    //This method returns notification object to send SMS to contacts on cases.
    public static BWC_CaseNotificationRequest getSMSDeliveryFlowRequest(Id targetRecordId, String phone, string uniqueSMStemplate, Id billingAccount){
        BWC_CaseNotificationRequest notification = new BWC_CaseNotificationRequest();        
        notification.targetRecordId = targetRecordId;
        notification.phone = phone;
        notification.uniqueSMSTemplate = uniqueSMStemplate;
        notification.billingAccount = billingAccount;
        return notification;
    }
    
    //This method calls the  SMS Flow on creation / update of cases.
    public static void sendSMS(List<BWC_CaseNotificationRequest> smsList) {
        Map<String, Object> caseSMSDelivery = new Map<String, Object>();
        caseSMSDelivery.put('SMS_Message', (Object)smsList);
        //below debug statement is to check the data in higher orgs, If the there is failure in sending SMS  
        system.debug('NotificationRequest to Flow----->' + caseSMSDelivery);
        if (!Test.isRunningTest()) {
            callFlow('BWC_Case_SMS_Delivery', caseSMSDelivery);
        }
    }
    
    //This method creates flow interview dynamically.
    public static void callFlow(String flowName, Map <String, Object> inputs) {
        Flow.Interview notificationsFlow = Flow.Interview.createInterview(flowName, inputs);
        notificationsFlow.start();
    }

}
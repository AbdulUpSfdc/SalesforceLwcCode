//We cannot use create this as inner class as this class carries parameters to (BWC_Case_SMS_Delivery)flow in the object form 
public class BWC_CaseNotificationRequest {
    @AuraEnabled
    public Id targetRecordId;//Case Id
    @AuraEnabled
    public String phone;// Phone Number to Send SMS
    @AuraEnabled
    public String uniqueSMSTemplate; //Developer Name of SMS 
    @AuraEnabled
    public Id billingAccount;//BillingAccount Id
}
public with sharing class BWC_EscalationCaseServiceController {
   
    @AuraEnabled
    public static List<Case> getEscalationCasesByBillingAccount(String billingAccountNumber){
        try {
            return BWC_EscalationCaseService.getEscalationCasesByBillingAccount(
                billingAccountNumber
            );
        } catch (Exception e) {
            throw BWC_Controller.handleException(e, 'BAN=' + billingAccountNumber);
        }
    }
}
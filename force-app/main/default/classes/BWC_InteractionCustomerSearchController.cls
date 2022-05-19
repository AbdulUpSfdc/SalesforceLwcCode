public with sharing class BWC_InteractionCustomerSearchController {
    @AuraEnabled
    public static ResultWrapper linkInteractionAndPersonAccount(String interactionId, String personAccountId) {

        // update the Customer__c field of the Interaction__c record.
        // update the CTI_Call_Identifier__c field of the Person Account (Account) record.
        ResultWrapper result = new ResultWrapper();
        result.success = false;
        try {
            List<Interaction__c> listInteractions = [SELECT Id, CTI_Call_Identifier__c FROM Interaction__c WHERE Id = :interactionId];
            if (listInteractions.size() > 0) {

                Account acc = new Account(Id = personAccountId, CTI_Call_Identifier__c = listInteractions[0].CTI_Call_Identifier__c);
                Interaction__c intAction = new Interaction__c(Id = interactionId, Customer__c = personAccountId);

                update acc;
                update intAction;

                result.success = true;
            }
            else {
                result.message = 'Invalid Interaction Id: ' + interactionId;
            }
        }
        catch (Exception ex) {
             // Log the exception
             BWC_ExceptionUtils.handleException(ex, 'interactionId: ' + interactionId + '; personAccountId: ' + personAccountId, null);

             // Return error with message
             result.success = false;
             result.message = ex.getMessage();
        }

        return result;
    }

    public class ResultWrapper {
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String message;
    }

    
    @AuraEnabled
    public static Boolean resetInteraction(String interactionId) {
        return true;
    }
}
public inherited sharing class BWC_RAISRRedactionService {
    public static BWC_RAISRRegistrationData getRegistrationData (String interactionId) {
        BWC_RAISRRegistrationData obj_registrationData = new BWC_RAISRRegistrationData();
        obj_registrationData.attUID = BWC_Utils.getCurrentUserAttId();
        Interaction__c interaction = [
            SELECT 
                Id, 
                CTI_Call_Identifier__c,
                Call_Reference_Number__c, 
                Billing_Account_Number__c
            FROM 
                Interaction__c 
            WHERE 
            Id = :interactionId
        ];
        obj_registrationData.callReferenceNumber = interaction.Call_Reference_Number__c;
        obj_registrationData.ban = interaction.Billing_Account_Number__c;
  
        return obj_registrationData;
    }
}
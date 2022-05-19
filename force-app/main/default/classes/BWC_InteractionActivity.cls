public with sharing class BWC_InteractionActivity {

    @AuraEnabled
    public static void createInteractionActivity(Id interactionId, String actionName, String detailRecord) {
        if(String.isEmpty(actionName)) {
            return;
        }
        
        try {
            Interaction_Activity__c ia = new Interaction_Activity__c();

            // fetch customer from Interaction
            Interaction__c interaction = [SELECT Customer__c FROM Interaction__c WHERE Id = :interactionId LIMIT 1];
            if(interaction != null) {
                ia.Customer__c = interaction.Customer__c;
            }

            // Extract Ids from detail
            Map<String, Object> detailMap = (Map<String, Object>)JSON.deserializeUntyped(detailRecord);

            // Billing Account
            String ban = (String)detailMap.get('ban');
            Billing_Account__c billingAccount;
            if (!String.isEmpty(ban)) {

                List<Billing_Account__c> baList = (List<Billing_Account__c>)[
                    SELECT Id FROM Billing_Account__c WHERE Billing_Account_Number__c = :ban LIMIT 1
                ];

                if (!baList.isEmpty()) {
                    billingAccount = baList[0];
                }
                else {
                    system.debug('No Billing Account found for BAN: ' + ban);
                }
    
            }
            else {
                system.debug('No Ban found in detailRecord.');
            }

            // Plan and Asset IDs
            String planId = (Id)detailMap.get('planId');
            String assetId = (Id)detailMap.get('assetId');

            // fetch Type and LIC from metadata        
            list<BWC_Interaction_Metadata__mdt> md = [SELECT Type__c,LIC__c FROM BWC_Interaction_Metadata__mdt WHERE Action__c = :actionName LIMIT 1];
            if(!md.IsEmpty()) {

                ia.Interaction__c = interactionId;
                ia.Action__c = actionName;
                ia.Detail_Record__c = detailRecord;
                ia.Type__c = md[0].Type__c;
                ia.Billing_Account__c = billingAccount != null ? billingAccount.Id : null;
                ia.Plan__c = planId;
                ia.Equipment__c = assetId;

                insert ia;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
        Get all Interaction_Activity__c records for an interaction.
    */
    @AuraEnabled
    public static List<Interaction_Activity__c> getInteractionActivities(Id interactionId) {

        return [
            SELECT
                Id, Interaction__c, Type__c
            FROM
                Interaction_Activity__c
            WHERE
                Interaction__c = :interactionId
            ORDER BY
                Type__c
        ];

    }

    /*
        Returns values for Interaction_Activity__c.Type__c. Key is api name, value is label.
    */
    @AuraEnabled
    public static Map<String, String> getInteractionActivityTypes() {

        Map<String, String> returnValue = new Map<String, String>();
        for (Schema.PicklistEntry picklistEntry : Interaction_Activity__c.Type__c.getDescribe().getPicklistValues()) {
            returnValue.put(picklistEntry.getValue(), picklistEntry.getLabel());
        }
        return returnValue;

    }
    @AuraEnabled
    public static string getInteractionId(id recordId) {
        string returnValue = '';
        if (recordId != null) {
            system.debug(recordId.getSobjectType().getDescribe().getName());
            switch on recordId.getSobjectType().getDescribe().getName() {
                when 'Account' {
                 //   returnValue = BWC_Utils.getInteractionIdFromAccountId(recordId);
                }
                when 'Interaction__c' {
                    returnValue = recordId;
                }
            }
        }
        return returnValue;
    }

    // escalation case creation

    @AuraEnabled    
    public static Id createEscalationCase(Id interactionId, String ecType, String ecFeature, String detailRecord) {
        //System.debug('*** ecType: ' + ecType);
        //System.debug('*** ecFeature: ' + ecFeature);
        return BWC_CreateCase.createEscalationCase(interactionId, ecType, ecFeature, detailRecord);
    }

    @AuraEnabled
    public static Interaction__c getInteractionRecord(Id recordId){

        return [SELECT Id, CompletedDate__c, Call_Status__c  FROM Interaction__c WHERE Id=:recordId];

    }


 }
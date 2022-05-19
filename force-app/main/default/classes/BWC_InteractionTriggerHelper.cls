public with sharing class BWC_InteractionTriggerHelper {

    // Set the Customer__c field if it is null with the Account (Person Account) Id.
    // The Account (Person Account) is identified by matching the field CTI_Call_Identifier__c of Interaction__c with
    // field CTI_Call_Identifier__c of Account (Person Account)
    public static void setCustomerUsingCTICallIdentifier() {

        List<Interaction__c> listInteractions = (List<Interaction__c>)Trigger.new;

        // Collect the value in CTI_Call_Identifier__c in a Set
        Set<String> setCTICallIdentifier = new Set<String>();
        for(Interaction__c intAction : listInteractions) {
            // Collect only if CTI_Call_Identifier__c is not null and Customer__c is not already set
            if (intAction.CTI_Call_Identifier__c != null && intAction.Customer__c == null) {
                setCTICallIdentifier.add(intAction.CTI_Call_Identifier__c);
            }
        }

        // When there are CTICallIdentifiers
        if (setCTICallIdentifier.size() > 0) {
            // Create a Map of CTI_Call_Identifier__c to Account (Person Account)
            Map<String, Account> mapCTICallIdentifierToAccount = new Map<String, Account>();
            for (Account acc : [SELECT Id, CTI_Call_Identifier__c FROM Account WHERE CTI_Call_Identifier__c IN :setCTICallIdentifier]) {
                mapCTICallIdentifierToAccount.put(acc.CTI_Call_Identifier__c, acc);
            }

            // When there is data in the Map
            if (mapCTICallIdentifierToAccount.size() > 0) {
                // for each Interaction set the Customer__c field
                for(Interaction__c intAction : listInteractions) {
                    // Set Customer__c only if CTI_Call_Identifier__c is not null and Customer__c is not already set
                    if (intAction.CTI_Call_Identifier__c != null && intAction.Customer__c == null) {
                        Account acc = mapCTICallIdentifierToAccount.get(intAction.CTI_Call_Identifier__c);
                        if (acc != null) {
                            intAction.Customer__c = acc.Id;
                        }
                    }
                }
            }
        }
    }

    // Raise the Interaction Complete Platform Event if the Complete Date is set.
    // To be called only in after Update
    public static void raiseInteractionPlatformEventOnUpdate() {
        List<Interaction__c> listInteractions = (List<Interaction__c>)Trigger.new;
        Map<Id, Interaction__c> mapOldInteraction = (Map<Id, Interaction__c>)Trigger.oldMap;

        // Create the platform event data to be raised for completed Interctions
        List<Interaction_Complete__e> icEvents = new List<Interaction_Complete__e>();
        for(Interaction__c intAction : listInteractions) {

            Interaction__c oldInteraction = mapOldInteraction.get(intAction.Id);

            // If CompletedDate__c is set now, create Interaction Complete Platform Event
            if (intAction.CompletedDate__c != null && oldInteraction.CompletedDate__c != intAction.CompletedDate__c ) {

                icEvents.add(new Interaction_Complete__e(InteractionId__c = intAction.Id));
                System.debug('Transfer false');
            }

            //If interaction is transferred, fire event with isTransfer=true
            if (intAction.Transfer_Date__c != null && oldInteraction.Transfer_Date__c != intAction.Transfer_Date__c ) {

                icEvents.add(new Interaction_Complete__e(InteractionId__c = intAction.Id, isTransfer__c=true));
                System.debug('Transfer true');

            }
        }

        if (icEvents.size() > 0) {
            // Call method to publish events
            List<Database.SaveResult> results = EventBus.publish(icEvents);

            // Inspect publishing result for each event
            for (Integer index = 0; index < results.size(); index++) {
                Database.SaveResult sr = results[index];

                if (sr.isSuccess()) {
                    System.debug('Successfully published Interaction Complete Platform Event for Interaction Id: ' + icEvents[index].InteractionId__c);
                } else {
                    String errMesage = '';
                    for(Database.Error err : sr.getErrors()) {
                        errMesage += 'Status code: ' + err.getStatusCode() + ': Error Message: ' + err.getMessage();
                    }
                    System.debug('Error punlishing Interaction Complete Platform Event for Interaction Id: ' + icEvents[index].InteractionId__c + ' -- ' + errMesage);
                }
            }
        }
    }


    // Mask the notes, if it is being updated.
    // To be called only in before Update
    public static void maskNotes() {
        List<Interaction__c> listInteractions = (List<Interaction__c>)Trigger.new;
        Map<Id, Interaction__c> mapOldInteraction = (Map<Id, Interaction__c>)Trigger.oldMap;

        // Mask notes if it is changing
        for(Interaction__c intAction : listInteractions) {
            // If CompletedDate__c is set now, create Interaction Complete Platform Event
            if (intAction.Notes__c != null && intAction.Notes__c != mapOldInteraction.get(intAction.Id).Notes__c) {
                intAction.Notes__c = BWC_Utils.maskSentence(intAction.Notes__c);
            }
        }
    }

    // 12-14-2020
    // Populate Billing Account field of Interaction__c using BAN in field User_Account_Number__c
    // To be called only in before Insert/Update
    public static void populateBillingAccount() {
        List<Interaction__c> listInteractions = (List<Interaction__c>)Trigger.new;

        // Collect interactions needing billing account set
        List<Interaction__c> interactionsToProcess = new List<Interaction__c>();
        Set<Id> customerIds = new Set<Id>();
        for(Interaction__c intAction : listInteractions) {

            if (intAction.Customer__c != null && intAction.Billing_Account__c == null) {
                interactionsToProcess.add(intAction);
                customerIds.add(intAction.Customer__c);
            }

        }

        if (!interactionsToProcess.isEmpty()) {

            // Get accounts with their billing accounts
            Map<Id, Account> accountMap = new Map<Id, Account>([
                SELECT
                    Id, (
                        SELECT Id, Billing_Account__r.Billing_Account_Number__c, Billing_Account__r.Product_Name_360__c, Billing_Account__r.CTI_Call_Identifier__c
                        FROM Customer_Account_Relation__r
                        ORDER BY Billing_Account__r.Product_Name_360__c, Billing_Account__r.Billing_Account_Number__c)
                FROM
                    Account
                WHERE
                    Id IN :customerIds
            ]);

            for (Interaction__c interactionToProcess : interactionsToProcess) {

                Account customer = accountMap.get(interactionToProcess.Customer__c);
                Billing_Account__c foundBillingAccount = null;

                // Spin through billing accounts finding best match
                for (Customer_Account_Relation__c relation : customer.Customer_Account_Relation__r) {

                    Billing_Account__c billingAccount = relation.Billing_Account__r;

                    // Check that ids match
                    if (!String.isEmpty(interactionToProcess.CTI_Call_Identifier__c) && billingAccount.CTI_Call_Identifier__c != interactionToProcess.CTI_Call_Identifier__c) {
                        // If the interaction has CTI_Call_Identifier__c (normally it will) then it has to match the same value on the billing account, or we ignore
                        continue;
                    }

                    if (billingAccount.Billing_Account_Number__c == interactionToProcess.User_Account_Number__c) {

                        // Exact match to User_Account_Number__c -- done
                        foundBillingAccount = billingAccount;
                        break;

                    }

                    if (foundBillingAccount == null ||
                        (foundBillingAccount.Product_Name_360__c != BWC_Constants.ACCOUNT_TYPE_WIRELESS) &&
                        billingAccount.Product_Name_360__c == BWC_Constants.ACCOUNT_TYPE_WIRELESS) {

                        // Favor wireless
                        foundBillingAccount = billingAccount;

                    }

                    if (foundBillingAccount == null ||
                        (foundBillingAccount.Product_Name_360__c != BWC_Constants.ACCOUNT_TYPE_WIRELESS &&
                        foundBillingAccount.Product_Name_360__c != BWC_Constants.ACCOUNT_TYPE_UVERSE &&
                        billingAccount.Product_Name_360__c == BWC_Constants.ACCOUNT_TYPE_UVERSE)) {

                        // Favor uverse next
                        foundBillingAccount = billingAccount;

                    }

                    if (foundBillingAccount == null) {
                        // Use any other
                        foundBillingAccount = billingAccount;
                    }

                }

                if (foundBillingAccount != null) {
                    interactionToProcess.Billing_Account__c = foundBillingAccount.Id;

                    if(String.isBlank(interactionToProcess.User_Account_Number__c)){
                        interactionToProcess.User_Account_Number__c = foundBillingAccount.Billing_Account_Number__c;
                    }
                }

            }
        }
    }
}
public with sharing class BWC_PlanTriggerHelper {

    // Update the Billing Account field Has_Only_Direct_TV__c to true if there is only one 
    // Plan and it is a DIRECTTV
    public static void updateBillingAccountHasOnlyDirectTVOnly() {
        // Collect Billing Accounts
        Set<Id> setBillingAccountIds = new Set<Id>();
        
        // For Delete use Trigger.old else use Trigger.new
        List<Plan__c> listPlans = (List<Plan__c>)(Trigger.isDelete?Trigger.old:Trigger.new);

        // Collect Billing Account Ids
        for(Plan__c plan : listPlans) {
            if (plan.Billing_Account__c != null) {
                setBillingAccountIds.add(plan.Billing_Account__c);
            }
        }

        if (setBillingAccountIds.size() > 0) {

            // Get the Plans
            List<Plan__c> listBillingAccountPlans = BWC_Plan_Selector.getPlansForBillingAccounts(setBillingAccountIds);

            // Create a Map with Billing Account Id and their list of plans
            Map<Id, List<Plan__c>> mapBAToPlans = new Map<Id, List<Plan__c>>();
            for (Plan__c plan : listBillingAccountPlans) {
                List<Plan__c> listCurrPlans = mapBAToPlans.get(plan.Billing_Account__c);

                if (listCurrPlans == null) {
                    listCurrPlans = new List<Plan__c>();
                    mapBAToPlans.put(plan.Billing_Account__c, listCurrPlans);
                }
                listCurrPlans.add(plan);
            }

            // List of Billing Accounts to be updated
            List<Billing_Account__c> listBillingAccountsToUpdate = new List<Billing_Account__c>();

            // For each Billing Account check its Plans
            for (Id baId : mapBAToPlans.keySet()) {
                List<Plan__c> listCurrPlans = mapBAToPlans.get(baId);

                Boolean hasOnlyDirectTV = false;

                // If there is only one Plan and it is DirectTV, set hasOnlyDirectTV to true
                if (listCurrPlans.size() == 1) {
                    String product = listCurrPlans[0].Product__c;
                    if (product != null) {
                        product = product.replace(' ', '').toLowerCase();
                        if (product.contains('directv')) {
                            hasOnlyDirectTV = true;
                        }
                    }
                }

                // Collect Billing_Account__c to update only if the value of Has_Only_Direct_TV__c is not same as hasOnlyDirectTV 
                if (listCurrPlans[0].Billing_Account__r.Has_Only_Direct_TV__c != hasOnlyDirectTV) {
                    listBillingAccountsToUpdate.add(new Billing_Account__c(Id = baId, Has_Only_Direct_TV__c = hasOnlyDirectTV));
                }                
            }

            // If there are Billing_Account__c's to update
            if (listBillingAccountsToUpdate.size() > 0) {
                update listBillingAccountsToUpdate;
            }
        }
    }
}
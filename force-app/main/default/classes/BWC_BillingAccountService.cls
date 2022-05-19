global with sharing class BWC_BillingAccountService {


    public static Map<String, Decimal> serviceNameOrder;
    public static final String DEFAULT_SORT = 'Default';

    public static List<Billing_Account__c> getBillingAccountSummary(Id interactionId) {

        Interaction__c interaction = BWC_Interaction.getInteraction(interactionId);
        BWC_AuthorizationCallout.AuthorizationStatusContent authorizationData =
            (BWC_AuthorizationCallout.AuthorizationStatusContent) JSON.deserialize(interaction.Authorization_Json__c, BWC_AuthorizationCallout.AuthorizationStatusContent.class);

        Map<String, String> banAuthLevelMap = new Map<String, String>();
        for(BWC_AuthorizationCallout.AssociatedAccount acc : authorizationData.associatedAccounts){
            banAuthLevelMap.put(acc.accountBan, acc.authorizationLevel);
        }

        List<Billing_Account__c> allBillingAccounts = BWC_BillingAccount.getBillingAccounts(interaction);
        List<Billing_Account__c> billingAccounts = new List<Billing_Account__c>();

        for(Billing_Account__c billingAccount : allBillingAccounts){

            if (BWC_BillingAccount.agentHasAccess(billingAccount) != true) {
                continue;
            }
            billingAccounts.add(billingAccount);

            String authLevel = banAuthLevelMap.get(billingAccount.Billing_Account_Number__c);
            if(!BWC_Authorization.AUTHORIZATION_LEVELS_L1_PRIVILEGED.contains(authLevel)){
                BWC_BillingAccount.maskBillingAccountBans(billingAccount);
            }

        }

        return sortAccountsByServiceName(billingAccounts, 'Broadband_Agent');
    }

    /**
     * @description Self-explain. Should we need new sorting, new entries will need to be added to BWC_Billing_Account_Sort__mdt
     * @param  billingAccounts List of Billing Accounts to be sorted
     * @param agentType Name of the custom permission assigned to the agent. If no custom permission is assigned, send null.
     * @return list of billing accounts sorted by Service Name using the specified agent type.
     */
    public static List<Billing_Account__c> sortAccountsByServiceName(List<Billing_Account__c> billingAccounts, String agentType){

        if(agentType == null){
            agentType = DEFAULT_SORT;
        }else{
            agentType = FeatureManagement.checkPermission(agentType) ? agentType : DEFAULT_SORT;
        }

        // Populate map used for sorting billing accounts
        List<BWC_Billing_Account_Sort__mdt> accountSortList = [SELECT Id, Service_Name__c, Sort_Order__c FROM BWC_Billing_Account_Sort__mdt WHERE Agent_Type__c =:agentType ORDER BY Sort_Order__c ASC];
        serviceNameOrder = new Map<String, Decimal>();
        for(BWC_Billing_Account_Sort__mdt accountSort : accountSortList){
            serviceNameOrder.put(accountSort.Service_Name__c, accountSort.Sort_Order__c);
        }

        // Populate list to sort
        List<BillingAccountSortWrapper> billingAccountsWrapper = new List<BillingAccountSortWrapper>();
        for(Billing_Account__c billingAccount : billingAccounts){
            billingAccountsWrapper.add(new BillingAccountSortWrapper(billingAccount));
        }

        billingAccountsWrapper.sort();

        // Extract billing accounts from wrapper
        List<Billing_Account__c> sortedAccounts = new List<Billing_Account__c>();
        for(BillingAccountSortWrapper accountWrapper : billingAccountsWrapper){
            sortedAccounts.add(accountWrapper.billingAccount);
        }

        return sortedAccounts;

    }


    global class BillingAccountSortWrapper implements Comparable {

        public Billing_Account__c billingAccount;

        public BillingAccountSortWrapper(Billing_Account__c billingAccount){
            this.billingAccount = billingAccount;
        }

        global Integer compareTo(Object compareTo) {

            BillingAccountSortWrapper compareToAcc = (BillingAccountSortWrapper)compareTo;

            Decimal currentAccountOrder = BWC_BillingAccountService.serviceNameOrder.get(billingAccount.Service_Type_Name__c);
            Decimal compareToAccountOrder = BWC_BillingAccountService.serviceNameOrder.get(compareToAcc.billingAccount.Service_Type_Name__c);

            // If null, send to the end
            currentAccountOrder = currentAccountOrder == null ? 999 : currentAccountOrder;
            compareToAccountOrder = compareToAccountOrder == null ? 999 : compareToAccountOrder;

            Integer returnValue = 0;

            if (currentAccountOrder < compareToAccountOrder) {
                returnValue = -1;
            } else if (currentAccountOrder > compareToAccountOrder) {
                returnValue = 1;
            }

            return returnValue;
        }
    }
    
}
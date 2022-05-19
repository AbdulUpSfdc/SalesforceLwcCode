/*
    Base class for service that acts on an interaction and one or more billing accounts.
*/
public inherited sharing abstract class BWC_InteractionServiceBase extends BWC_AsyncServiceBase {

    public Id recordId;
    public Id interactionId;
    public Id billingAccountId;
    public Interaction__c interaction;
    public Id caseId;
    public Case caseRecord;
    public Id personAccountId;
    public List<Billing_Account__c> billingAccounts;
    public Map<Id, Billing_Account__c> billingAccountMap;
    public Map<String, Billing_Account__c> billingAccountsByBan;
    public Map<String, String> authLevelByBan;
    public Billing_Account__c billingAccount;
    protected BWC_AuthorizationCallout.AuthorizationStatusContent authorizationContent;

    /*
        Constructs the service class, including retrieving interaction and billing account data associated with the interaction.
    */
    public BWC_InteractionServiceBase(Id recordId, Id billingAccountId) {

        this.recordId = recordId;
        this.billingAccountId = billingAccountId;

        if (recordId.getSobjectType() == Interaction__c.getSObjectType()) {

            // Record is interaction
            this.interactionId = recordId;
            this.interaction = BWC_Interaction.getInteraction(interactionId);
            this.personAccountId = this.interaction.Customer__c;

            if (String.isNotEmpty(this.interaction.Authorization_Json__c)) {
                this.authorizationContent = (BWC_AuthorizationCallout.AuthorizationStatusContent)JSON.deserialize(this.interaction.Authorization_Json__c, BWC_AuthorizationCallout.AuthorizationStatusContent.class);
            }
            else {
                this.authorizationContent = new BWC_AuthorizationCallout.AuthorizationStatusContent();
            }

            if (this.interaction.Customer__c != null) {

                // Interaction has customer set, get billing accounts
                this.billingAccounts = BWC_BillingAccount.getBillingAccounts(this.interaction);

                // All billing accounts for the interaction
                mapBillingAccounts();

                // Billing Account number with Authorization level
                mapAuthorizationLevel();

                if (this.billingAccountId != null) {
                    this.billingAccount = this.billingAccountMap.get(this.billingAccountId);
                    if (this.billingAccount == null) {
                        throw new BWC_Exception('No valid Billing Account record found for Id: ' + this.billingAccountId + ' on Interaction: ' + this.interaction.Id);
                    }
                }
                else {
                    // Use interaction's default billing account
                    if (this.interaction.Billing_Account__c == null) {
                        throw new BWC_Exception('No Billing_Account__c set on Interaction.');
                    }
                    this.billingAccount = this.billingAccountMap.get(this.interaction.Billing_Account__c);
                }

            }

        }
        else if (recordId.getSobjectType() == Case.getSObjectType()) {

            this.caseId = recordId;
            this.caseRecord = [SELECT Id, AccountId FROM Case WHERE Id = :recordId];
            
            if (this.caseRecord.AccountId != null) {

                // Case has a customer set, get billing accounts
                this.billingAccounts = BWC_BillingAccount.getBillingAccounts(this.caseRecord);
                this.personAccountId = this.caseRecord.AccountId;
                mapBillingAccounts();

            }

        }
        else {
            throw new BWC_Exception('Unrecognized recordId: ' + recordId);
        }

    }

    /*
        Return interaction authorization level for specified ban.
    */
    public String getAuthorizationLevel(String ban) {

        if (this.authorizationContent == null || this.authorizationContent.associatedAccounts == null) {
            return null;
        }

        return this.authLevelByBan.get(ban);

    }

    /*
        Map all billing accounts by ID and by Ban.
    */
    private void mapBillingAccounts() {
        this.billingAccountMap = new Map<Id, Billing_Account__c>(this.billingAccounts);
        this.billingAccountsByBan = new Map<String, Billing_Account__c>();
        for (Billing_Account__c billingAccount : this.billingAccounts) {
            this.billingAccountsByBan.put(billingAccount.Billing_Account_Number__c, billingAccount);
        }
    }

    /*
        Lookup Billing_Account__c mapped by ban, return Id if found or null otherwise.
    */
    protected Id getBillingAccountIdForBan(String ban) {

        Billing_Account__c billingAccount = this.billingAccountsByBan.get(ban);
        return billingAccount?.Id;

    }

    protected String getMaskedBan(String ban) {

        // TODO Mask when everything supports
        return ban;

    }

    private void mapAuthorizationLevel(){

        this.authLevelByBan = new Map<String, String>();

        if(this.authorizationContent == null || this.authorizationContent.associatedAccounts == null){
            return;
        }

        for (BWC_AuthorizationCallout.AssociatedAccount associatedAccount : this.authorizationContent.associatedAccounts) {
            this.authLevelByBan.put(associatedAccount.accountBan, associatedAccount.authorizationLevel);
        }

    }

    protected List<Billing_Account__c> getL1BillingAccounts(){

        List<Billing_Account__c> l1Accoutns = new List<Billing_Account__c>();

        for(Billing_Account__c billingAccount : billingAccounts){

            String authorizationLevel = getAuthorizationLevel(billingAccount.Billing_Account_Number__c);

            if(BWC_Authorization.AUTHORIZATION_LEVELS_L1_PRIVILEGED.contains(authorizationLevel)){
                l1Accoutns.add(billingAccount);
            }

        }

        return l1Accoutns;
    }

}
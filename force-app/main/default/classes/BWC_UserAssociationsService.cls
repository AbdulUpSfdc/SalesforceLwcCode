/*
    Service API for getting User Associations for a billing account.
*/
public with sharing class BWC_UserAssociationsService {

    /*
        Service API to get all user associations for one account/interaction.
        Parameter recordId passed can be Person Account Id or Interaction__c Id

    */
    public static List<BWC_UserAssociations.UserAssociationsResponse> getUserAssociations(Id recordId) {

        if (recordId == null) {
            throw new BWC_Exception('Argument required: recordId');
        }

        // Get associated users for any wireless billing accounts
        List<Billing_Account__c> billingAccounts = BWC_AccountService.getBillingAccounts(recordId, new Set<String>{BWC_Constants.ACCOUNT_TYPE_WIRELESS}, null, false, false);

        if (billingAccounts.isEmpty()) {

            // No billing accounts, just return empty response
            return new List<BWC_UserAssociations.UserAssociationsResponse>();

        }

        // Build request list
        List<BWC_UserAssociations.UserAssociationsRequest> requests = new List<BWC_UserAssociations.UserAssociationsRequest>();
        for (Billing_Account__c billingAccount : billingAccounts) {

            requests.add(new BWC_UserAssociations.UserAssociationsRequest(billingAccount.Billing_Account_Number__c, billingAccount.Account_Type__c));

        }

        // Callout
        List<BWC_UserAssociations.UserAssociationsResponse> responses = BWC_UserAssociationsCallout.getUserAssociations(requests);

        return responses;

    }

    public class GetUserAssociationsService extends BWC_InteractionServiceBase{

        public List<BWC_UserAssociations.UserAssociationsRequest> request;
        public BWC_UserAssociations.UserAssociationsResponse response;

         /*
            Construct the service object from caller arguments.
        */
        public GetUserAssociationsService(Id recordId,Id InteractionId) {

            super(InteractionId,recordId);
            this.buildRequest();

        }

        public void buildRequest() {
        
            // Build request list
            List<BWC_UserAssociations.UserAssociationsRequest> requests = new List<BWC_UserAssociations.UserAssociationsRequest>();
            for (Billing_Account__c billingAccount : this.billingAccounts) {
                if (billingAccount.Account_Type__c != BWC_Constants.BillingAccount_AccountType_Wireless) {
                    continue;
                }
                requests.add(new BWC_UserAssociations.UserAssociationsRequest(billingAccount.Billing_Account_Number__c, billingAccount.Account_Type__c));
    
            }
            this.callout = new BWC_UserAssociationsCallout.GetUserAssociationsCallout(requests);
           
            
        }

        /*
            Builds and returns final response.
        */
         public override Object buildResponse() {

            this.response = (BWC_UserAssociations.UserAssociationsResponse)this.callout.getResponse();
            return this.response;

        }
       
     }

    /*
        Service API to get user associations for one billing account.
    */
    public static List<BWC_UserAssociations.UserAssociationsResponse> getUserAssociationsForBillingAccount(Id billingAccountId) {

        if (billingAccountId == null) {
            throw new BWC_Exception('Argument required: billingAccountId');
        }

        // Lookup record to get BAN and account type
        List<Billing_Account__c> billingAccounts = [
            SELECT
                Id, Billing_Account_Number__c, Account_Type__c
            FROM
                Billing_Account__c
            WHERE
                Id = :billingAccountId
        ];

        if (billingAccounts.isEmpty()) {
            throw new BWC_Exception('Billing Account not found: ' + billingAccountId);
        }

        Billing_Account__c billingAccount = billingAccounts[0];

        if (String.isEmpty(billingAccount.Billing_Account_Number__c)) {
            throw new BWC_Exception('Billing Account Number is blank.');
        }
        if (String.isEmpty(billingAccount.Account_Type__c)) {
            throw new BWC_Exception('Account Type is blank.');
        }

        return getUserAssociationsForBan(billingAccount.Billing_Account_Number__c, billingAccount.Account_Type__c);

    }

    /*
        Service API to get user associations for one ban.
    */
    public static List<BWC_UserAssociations.UserAssociationsResponse> getUserAssociationsForBan(String ban, String accountType) {

        if (ban == null) {
            throw new BWC_Exception('Argument required: ban');
        }

        if (accountType == null) {
            throw new BWC_Exception('Argument required: accountType');
        }

        // Build request list
        List<BWC_UserAssociations.UserAssociationsRequest> requests = new List<BWC_UserAssociations.UserAssociationsRequest>{
            new BWC_UserAssociations.UserAssociationsRequest(ban, accountType)
        }; 

        // Callout
        List<BWC_UserAssociations.UserAssociationsResponse> responses = BWC_UserAssociationsCallout.getUserAssociations(requests);

        return responses;

    }

    /*
        Service API to add authorized users to billing account.
    */
    public static List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> addUserAssociations(List<BWC_UserAssociations.UserAssociation> userAssociations) {

        if (userAssociations == null) {
            throw new BWC_Exception('Argument required: userAssociations');
        }

        // Fix missing values
        for (BWC_UserAssociations.UserAssociation userAssociation : userAssociations) {
            if (userAssociation.middleName == null) {
                userAssociation.middleName = '';
            }
            if (userAssociation.suffix == null) {
                userAssociation.suffix = '';
            }
        }

        // Callout
        List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> responses = BWC_UserAssociationsCallout.addUserAssociations(userAssociations);

        return responses;

    }

    /*
        Service API to remove authorized users from billing account.
    */
    public static List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> deleteUserAssociations(List<BWC_UserAssociations.UserAssociation> userAssociations) {

        if (userAssociations == null) {
            throw new BWC_Exception('Argument required: userAssociations');
        }

        // Fix missing values
        for (BWC_UserAssociations.UserAssociation userAssociation : userAssociations) {
            if (userAssociation.middleName == null) {
                userAssociation.middleName = '';
            }
            if (userAssociation.suffix == null) {
                userAssociation.suffix = '';
            }
        }

        // Callout
        List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> responses = BWC_UserAssociationsCallout.deleteUserAssociations(userAssociations);

        return responses;

    }

}
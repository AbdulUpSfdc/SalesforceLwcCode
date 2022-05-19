public inherited sharing class BWC_PaymentDetailsService {

    public static List<BWC_PaymentDetails.PaymentDetailsResponse> getPaymentDetails(String recordId, List<String> bans, List<String> topics) {
        return getPaymentDetails( recordId, bans, null, null, topics );    
    }

    /*
        Call service synchronously.
    */
    public static List<BWC_PaymentDetails.PaymentDetailsResponse> getPaymentDetails(
        String recordId, List<String> bans, String attUID, String temporaryProfileKey,  List<String> topics
    ) {

        BWC_PaymentDetails.PaymentDetailsResponses responses = getPaymentDetailsSync(recordId, bans, attUID, temporaryProfileKey, topics);
        return responses.responses;

    } 

    public static BWC_PaymentDetails.PaymentDetailsResponses getPaymentDetailsSync(
        String recordId, List<String> bans, String attUID, String temporaryProfileKey,  List<String> topics) {

            GetPaymentDetailsService service = new GetPaymentDetailsService(recordId, bans, attUID, temporaryProfileKey, topics);
            BWC_PaymentDetails.PaymentDetailsResponses responses = (BWC_PaymentDetails.PaymentDetailsResponses)service.call();
            return responses;
    }

    /*
        Implements getPaymentDetails, can be called synchronously or async.
    */
    public class GetPaymentDetailsService extends BWC_InteractionServiceBase {

        // Request and Response state
        public List<String> bans;
        public List<String> topics;
        public String attUID;
        public String temporaryProfileKey;
        public List<BWC_PaymentDetails.PaymentDetailsRequest> request;
        public BWC_PaymentDetails.PaymentDetailsResponses response;

        /*
            Construct the service object from caller arguments.
        */
        public GetPaymentDetailsService(Id interactionId, List<String> bans, String attUID, String temporaryProfileKey, List<String> topics) {

            super(interactionId, null);

            // Store inputs
            this.bans = bans;
            this.topics = topics;
            this.attUID = attUID;
            this.temporaryProfileKey = temporaryProfileKey;

            this.buildRequest();

        }

        public void buildRequest() {

            String individualId = '';
            Boolean isDigitalCustomer = false;
            Interaction__c interaction = [SELECT Id, CTI_Call_Identifier__c, Customer__r.Individual_ID__c, Customer__r.Is_Digital_Customer__c 
                                                FROM Interaction__c 
                                                WHERE Id = :interactionId];
            if (String.isEmpty(this.temporaryProfileKey)) {
                this.temporaryProfileKey = interaction.CTI_Call_Identifier__c;
            }
            individualId = interaction.Customer__r.Individual_ID__c;
            isDigitalCustomer = interaction.Customer__r.Is_Digital_Customer__c;

            // Get all billing accounts that are in the requested list, authorized, and not unified
            List<Billing_Account__c> billingAccounts = BWC_AccountService.getBillingAccounts(
                this.interactionId, BWC_Constants.VALID_BILLING_ACCOUNT_TYPES, this.bans  == null || this.bans.isEmpty() ? null : new Set<String>(this.bans), true, true);

            this.request = new List<BWC_PaymentDetails.PaymentDetailsRequest>();
            String userId = (String.isBlank( this.attUID )) ? BWC_Utils.getCurrentUserAttId() : this.attUID;

            for (Billing_Account__c billingAccount : billingAccounts) {

                BWC_PaymentDetails.PaymentDetailsRequest requestItem = new BWC_PaymentDetails.PaymentDetailsRequest();
                requestItem.firstName = billingAccount.First_Name__c;
                requestItem.lastName = billingAccount.Last_Name__c;
                requestItem.accountId = billingAccount.Billing_Account_Number__c;
                requestItem.accountType = billingAccount.Account_Type__c;
                requestItem.appName = BWC_Constants.APP_NAME;
                requestItem.sourceUser = userId;
                requestItem.sourceSystem = BWC_Constants.SOURCE_SYSTEM;
                requestItem.sourceLocation = BWC_Constants.SOURCE_LOCATION;
                requestItem.productCode = BWC_Constants.CONFEEELIG_PRODUCT_CODE;
                requestItem.paymentDate = DateTime.now().format('YYYY-MM-dd');
                requestItem.temporaryProfileKey = this.temporaryProfileKey;
                requestItem.topics = this.topics;

                this.request.add(requestItem);
            }

            // Payment Profiles for BSSe Customers
            if (isDigitalCustomer) {
                BWC_PaymentDetails.PaymentDetailsRequest requestItem = new BWC_PaymentDetails.PaymentDetailsRequest();
                requestItem.individualId = individualId;
                requestItem.appName = BWC_Constants.APP_NAME;
                requestItem.sourceUser = userId;
                requestItem.sourceSystem = BWC_Constants.SOURCE_SYSTEM;
                requestItem.sourceLocation = BWC_Constants.SOURCE_LOCATION;
                requestItem.productCode = BWC_Constants.CONFEEELIG_PRODUCT_CODE;
                requestItem.paymentDate = DateTime.now().format('YYYY-MM-dd');
                requestItem.temporaryProfileKey = this.temporaryProfileKey;
                requestItem.topics = new List<String>{'paymentProfiles'};
                this.request.add(requestItem);
            }

            this.callout = new BWC_PaymentDetailsCallout.GetPaymentDetailsCallout(this.request);

        }

        /*
            Builds and returns final response.
        */
        public override Object buildResponse() {

            this.response = (BWC_PaymentDetails.PaymentDetailsResponses)this.callout.getResponse();

            for (Integer i = 0; i < this.response.responses.size(); i++) {

                BWC_PaymentDetails.PaymentDetailsResponse banResponse = this.response.responses[i];

                String account = '';
                if (banResponse.individualId != null) {
                    account = banResponse.individualId;
                } else {
                    account = banResponse.ban;
                }

                // Set record ID of corresponding billing account
                banResponse.billingAccountId = this.billingAccountsByBan.get(account)?.Id;

                // Set first and last name back into responses:
                // They're needed for some subsequent APIs and this way they're available as they're not otherwise in the response.
                banResponse.lastName = this.request[i].lastName;
                banResponse.firstName = this.request[i].firstName;

            }

            return this.response;

        }

    }

}
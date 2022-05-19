public with sharing class BWC_InteractionService {

    private static final String CPNI_NO_VOICE_ON_ACCOUNT = 'No voice on account';

    /*
        Used by client to poll to find customer and billing account which have been prefetched by external process.
    */
    public static PrefetchStatusResult checkPrefetchStatus(String ctiCallIdentifier) {

        if (String.isEmpty(ctiCallIdentifier)) {
            throw new BWC_Exception('Argument required: ctiCallIdentifier');
        }

        PrefetchStatusResult result = new PrefetchStatusResult();
        result.message = '';

        // Get status from cache
        String status = BWC_PrefetchCacheManager.getStatus(ctiCallIdentifier, BWC_PrefetchCacheManager.TYPE_CUSTOMER_SEARCH);

        if (status == BWC_PrefetchCacheManager.STATUS_IN_PROCESS) {

            // Still in process -- this will be result of most polls, so we are only hitting platform cache
            result.message = 'Prefetch in process.';
            result.prefetchStatus = BWC_PrefetchCacheManager.STATUS_IN_PROCESS;
            return result;

        }

        // For any other status, we'll need to take a look at the interaction record
        List<Interaction__c> interactions = 
            [SELECT Id, Customer__c, CTI_Call_Identifier__c, Is_Customer_Polling_Completed__c FROM Interaction__c WHERE CTI_Call_Identifier__c = :ctiCallIdentifier];

        if (interactions.isEmpty()) {
            throw new BWC_Exception('No interaction record found for CTI_Call_Identifier__c: ' + ctiCallIdentifier);
        }
        Interaction__c interaction = interactions[0];

        // Customer already set?
        if (interaction.Customer__c != null) {

            result.message = 'Interaction Customer already set.';
            result.prefetchStatus = BWC_PrefetchCacheManager.STATUS_SUCCEEDED;

        }
        else if (interaction.Is_Customer_Polling_Completed__c == true) {

            // Should not be polling
            result.message = 'Polling already completed.';
            result.prefetchStatus = BWC_PrefetchCacheManager.STATUS_FAILED;
            return result;

        }
        else if (status == BWC_PrefetchCacheManager.STATUS_SUCCEEDED) {

            // We can set customer now
            List<Account> accountRecords = [SELECT Id FROM Account WHERE CTI_Call_Identifier__c = :ctiCallIdentifier];
            if (accountRecords.isEmpty()) {

                result.message = 'Prefetch reports success but Account not found for CTI_Call_Identifier__c: ' + ctiCallIdentifier;
                result.prefetchStatus = BWC_PrefetchCacheManager.STATUS_FAILED;

            }
            else {

                result.message = 'Prefetch successful, setting Customer: ' + accountRecords[0].Id;
                interaction.Customer__c = accountRecords[0].Id;
                result.prefetchStatus = BWC_PrefetchCacheManager.STATUS_SUCCEEDED;

            }

            interaction.Is_Customer_Polling_Completed__c = true;

        }
        else if (status == BWC_PrefetchCacheManager.STATUS_FAILED) {

            result.prefetchStatus = BWC_PrefetchCacheManager.STATUS_FAILED;
            interaction.Is_Customer_Polling_Completed__c = true;
            result.message = 'Prefetch failed.';

        }
        else {

            interaction.Is_Customer_Polling_Completed__c = true;
            result.message = 'No prefetch status could be found.';

        }

        // Billing Account will be set by trigger
        update interaction;

        return result;

    }

    public with sharing class PrefetchStatusResult {

        public String prefetchStatus;   // "In Process", "Succeeded", "Failed"
        public String message = '';

        public String serialize() {
            return JSON.serialize(this, true);
        }

    }

    /**************************************************************************
        AutoSearchInteractionForCustomer service
    **************************************************************************/

    public with sharing class AutoSearchInteractionForCustomerService extends BWC_InteractionServiceBase {
     
        public AutosearchResponse response;

        public BWC_UnifiedSearchService.CustomerSearch customerSearchService;
        public BWC_UnifiedSearch.UnifiedSearchRequest customerSearchRequest;
        public BWC_UnifiedSearch.UnifiedSearchResponse customerSearchResponse;

        public AutoSearchInteractionForCustomerService(Id interactionId) {
            super(interactionId, null);
            this.buildRequest();
        }

        public void buildRequest() {
        
            this.response = new AutosearchResponse();
    
            String ban = this.interaction.User_Account_Number__c;
            String accountType;
    
            if (String.isNotEmpty(ban)) {

                this.customerSearchRequest = new BWC_UnifiedSearch.UnifiedSearchRequest();
                this.customerSearchRequest.accountNumber = ban;
            }
            else {
    
                this.response.message = 'No BAN provided on Interaction Record.';
    
            }
    
            if (this.customerSearchRequest == null) {

                // Can't search by Ban and Account Type
                if (String.isNotEmpty(interaction.User_Order_Num__c)) {
    
                    // We will search by Order ID
                    this.response.message += ' Searching with Order ID: ' + interaction.User_Order_Num__c + '.';
                    this.customerSearchRequest = new BWC_UnifiedSearch.UnifiedSearchRequest();
                    this.customerSearchRequest.orderId = interaction.User_Order_Num__c;
    
                }
                else {
    
                    this.response.message += ' No Order ID provided on Interaction record.';
        
                }

            }

            if (this.customerSearchRequest == null) {
    
                // Can't search by Ban and Account Type or by Order ID
                if (String.isNotEmpty(interaction.User_Telephone_Number__c)) {
    
                    // We will search by CTN
                    this.response.message += ' Searching with CTN: ' + interaction.User_Telephone_Number__c + '.';
                    this.customerSearchRequest = new BWC_UnifiedSearch.UnifiedSearchRequest();
                    this.customerSearchRequest.phoneNumber = interaction.User_Telephone_Number__c;
    
                }
                else {
    
                    this.response.message += ' No CTN provided on Interaction record.';
        
                }
    
            }
    
            if (this.customerSearchRequest != null) {

                // We can try to search
                // This will link it to interaction if found
                this.customerSearchService = new BWC_UnifiedSearchService.CustomerSearch(this.interactionId, this.customerSearchRequest);
    
            }
            else {
    
                this.response.message += ' Insufficent data to attempt search.';
                this.response.success = false;
    
            }
    
        }

        /*
            Override because we're chaining to another service (CustomerSearchService) and not just making a callout.
        */
        public override Object callWithContinuation() {

            if (this.customerSearchService != null) {

                // Make the async call to do customer search
                Object response = this.customerSearchService.callWithContinuation(this);
                if (response instanceof Continuation) {
                    // It's a continuation, just return
                    return response;
                }

                // Async was not necessary, build response now
                this.customerSearchResponse = (BWC_UnifiedSearch.UnifiedSearchResponse)response;

            }

            // Now can get our response
            return this.getResponse();

        }

        /*
            Override because we're chaining to another service (CustomerSearchService) and not just making a callout.
        */
        public override Object processContinuationResponse() {

            try {
                // Get the payment details.
                this.customerSearchResponse = (BWC_UnifiedSearch.UnifiedSearchResponse)this.customerSearchService.processContinuationResponse();
            }
            catch (System.Exception e) {
                // Error during search
                this.response.success = false;
                this.response.message += ' Error during account search: ' + e.getMessage();
            }

            // Now can get our response.
            return this.getResponse();

        }

        /*
            Customer search results are available, build final response.
        */
        protected override Object buildResponse() {

            if (this.customerSearchResponse != null) {

                if (this.customerSearchResponse.individualsFound != null) {

                    // Evaluate result
                    if (this.customerSearchResponse.accountResponseCount == 1) {
                        this.response.success = true;
                        this.response.message += ' Search returned one account.';
                    }
                    else if (this.customerSearchResponse.accountResponseCount == 0) {
                        this.response.success = false;
                        this.response.message += ' Search returned no accounts.';
                    }
                    else {
                        this.response.success = false;
                        this.response.message += ' Search returned multiple accounts.';
                    }

                }

            }

            this.interaction.Is_Customer_Polling_Completed__c = true;
            update this.interaction;

            return this.response;

        }

    }

    public with sharing class AutosearchResponse extends BWC_Service.ServiceResponse {

        public Boolean success;
        public String message;

    }

    /**************************************************************************
     GetInteractionNotificationsService
    **************************************************************************/

    /*
        Retrieves all current notifications associated with the interaction, for display on the interaction page.
    */
    public with sharing class GetInteractionNotificationsService extends BWC_InteractionServiceBase {

        public BWC_PaymentDetailsService.GetPaymentDetailsService getPaymentDetailsService;
        public BWC_PaymentDetails.PaymentDetailsResponses paymentDetailsResponse;
        public GetInteractionNotificationsResponse response;

        public GetInteractionNotificationsService(Id interactionId) {
            super(interactionId, null);
            this.buildRequest();
        }

        public void buildRequest() {

            // Don't waste time with API call for payment details if it's non-serviceable
            if (this.interaction.Is_Nonserviceable_Customer__c != true) {
                // Prepare call to payment details -- that is the aysnc part of this service
                this.getPaymentDetailsService = new BWC_PaymentDetailsService.GetPaymentDetailsService(this.interactionId, null, null, null,
                    new List<String>{BWC_PaymentDetails.TOPIC_PAYMENT_RECOMMENDATIONS, BWC_PaymentDetails.TOPIC_EXTENDED_PA});
            }

        }

        /*
            Override because we're chaining to another service (GetPaymentDetailsService) and not just making a callout.
        */
        public override Object callWithContinuation() {

            if (this.getPaymentDetailsService != null) {

                // Make the async call to get payment details
                Object response = this.getPaymentDetailsService.callWithContinuation(this);
                if (response instanceof Continuation) {
                    // It's a continuation, just return
                    return response;
                }

                // Async was not necessary, build response now
                this.paymentDetailsResponse = (BWC_PaymentDetails.PaymentDetailsResponses)response;

            }

            // Now can get our response
            return this.getResponse();

        }

        /*
            Override because we're chaining to another service (GetPaymentDetailsService) and not just making a callout.
        */
        public override Object processContinuationResponse() {

            // Get the payment details.
            this.paymentDetailsResponse = (BWC_PaymentDetails.PaymentDetailsResponses)this.getPaymentDetailsService.processContinuationResponse();

            // Now can get our response.
            return this.getResponse();

        }

        /*
            Payment details are available, build final response.
        */
        protected override Object buildResponse() {

            Boolean isRetailEmployee = false;
            Employee__c employee = BWC_Employee_Selector.getEmployee(UserInfo.getUserId());
            if(employee!=null){
                isRetailEmployee = employee.Channel1__c == BWC_Employee.CHANNEL_RETAIL && BWC_Employee.AUTHORIZED_RETAIL_SUB_CHANNELS.contains(employee.Sub_Channel__c);
            }

            GetInteractionNotificationsResponse response = new GetInteractionNotificationsResponse();
            response.notifications = new List<BWC_Notification.Notification>();

            // Prepaid only?
            if (this.interaction.Customer__r.Is_Prepaid_Only__c == true) {
                BWC_Notification.Notification notification = new BWC_Notification.Notification();
                notification.message = Label.BWC_PrepaidAccountNotice;
                notification.texture = 'alert';
                notification.action = new BWC_Notification.Action('kiccare', Label.BWC_Login);
                notification.action.href = Label.BWC_PrepaidAccountNotice;
                notification.action.icon = new BWC_Notification.Icon();
                notification.action.icon.name = 'utility:new_window';
                response.notifications.add(notification);
            }

            // Any FirstNet?
            Boolean hasFirstNet = false;
            for (Billing_Account__c billingAccount : this.billingAccounts) {

                if (billingAccount.Is_FirstNet__c == true) {
                    hasFirstNet = true;
                }

                if(isRetailEmployee
                    && billingAccount.Customer_Liability__c == BWC_BillingAccount.CUSTOMER_LIABILITY_IRU
                    && billingAccount.firstNet_Type__c == BWC_BillingAccount.FIRST_NET_LEGACY) {

                    BWC_Notification.Notification notification = new BWC_Notification.Notification();
                    notification.message = Label.BWC_Legacy_IRU_Account;
                    notification.texture = 'alert';
                    notification.closeButton = true;
                    response.notifications.add(notification);
                }

                if(isRetailEmployee
                    && billingAccount.Customer_Liability__c == BWC_BillingAccount.CUSTOMER_LIABILITY_IRU
                    && billingAccount.firstNet_Type__c == BWC_BillingAccount.FIRST_NET_UTF) {

                    BWC_Notification.Notification notification = new BWC_Notification.Notification();
                    notification.message = Label.BWC_UTF_IRU_Account;
                    notification.texture = 'alert';
                    notification.closeButton = true;
                    response.notifications.add(notification);
                }

                if(isRetailEmployee
                    && billingAccount.Customer_Liability__c == BWC_BillingAccount.CUSTOMER_LIABILITY_CRU
                    && this.interaction.Customer__r.Is_Business_Customer__c) {

                    BWC_Notification.Notification notification = new BWC_Notification.Notification();
                    notification.message = Label.BWC_BusinessAccountCRU;
                    notification.texture = 'alert';
                    notification.closeButton = true;
                    response.notifications.add(notification);
                }
            }

            if (hasFirstNet && !isRetailEmployee) {

                // Have to determine whether agent is international or not because we show different notification message
                Boolean isUsa = employee?.Work_Country__c == BWC_Constants.COUNTRY_USA;

                BWC_Notification.Notification notification = new BWC_Notification.Notification();
                notification.message = isUsa ? Label.BWC_FirstNet_Message : Label.BWC_FirstNet_Intl_Message;
                notification.texture = 'alert';
                response.notifications.add(notification);

            }

            // Business Account?
            if (this.interaction.Customer__r.Is_Business_Customer__c == true && !isRetailEmployee) {
                BWC_Notification.Notification notification = new BWC_Notification.Notification();
                notification.message = Label.BWC_BusinessCustomer_Message;
                notification.texture = 'alert';
                response.notifications.add(notification);
            }

            // If non-serviceable, no other notifications matter
            if (this.interaction.Is_Nonserviceable_Customer__c == true) {
                return response;
            }

            // Implied CPNI Consent?
            if (this.interaction.Cpni_Consent__c == 'Implied') {
                BWC_Notification.Notification notification = new BWC_Notification.Notification();
                notification.message = Label.BWC_CpniImpliedNotification;
                notification.texture = 'alert';
                notification.closeButton = true;
                response.notifications.add(notification);
            }

            // If agent doesn't have Payment Permission
            if (FeatureManagement.checkPermission('Payment_Permission') != true) {
                return response;
            }

            //
            // EPA enrollment
            //

            // Find all BANs which are eligible for EPA or already enrolled in EPA
            List<BWC_PaymentDetails.PaymentDetailsResponse> epaEligibleBillingAccounts = new List<BWC_PaymentDetails.PaymentDetailsResponse>();
            List<BWC_PaymentDetails.PaymentDetailsResponse> epaEnrolledBillingAccounts = new List<BWC_PaymentDetails.PaymentDetailsResponse>();
            for (BWC_PaymentDetails.PaymentDetailsResponse paymentDetailsResponse : this.paymentDetailsResponse.responses) {
                if (paymentDetailsResponse.isEpaEnrolled == true) {
                    epaEnrolledBillingAccounts.add(paymentDetailsResponse);
                }
                else if (paymentDetailsResponse.isEpaEligible == true) {
                    epaEligibleBillingAccounts.add(paymentDetailsResponse);
                }
            }

            if (!epaEnrolledBillingAccounts.isEmpty()) {

                // Add notification for all enrolled bans

                BWC_Notification.Notification notification = new BWC_Notification.Notification();
                notification.closeButton = true;
                notification.items = new List<BWC_Notification.NotificationItem>{
                    new BWC_Notification.NotificationItem('This customer <b>has enrolled</b> in an Extended Payment Arrangement on:')
                };

                for (Integer i = 0; i < epaEnrolledBillingAccounts.size(); i++) {

                    BWC_PaymentDetails.PaymentDetailsResponse enrolledBillingAccount = epaEnrolledBillingAccounts[i];
                    Boolean isLastItem = i == epaEnrolledBillingAccounts.size() - 1;

                    String label = '<b>Account ' + enrolledBillingAccount.ban + ' (' + BWC_BillingAccount.getBillingAccountTypeLabel(enrolledBillingAccount.accountType) + ')</b>.';
                    BWC_Notification.NotificationItem item = new BWC_Notification.NotificationItem(label);

                    // Add the View action
                    InteractionNotificationAction action = new InteractionNotificationAction();
                    action.name = 'epaViewDetails';
                    action.message = 'View Details' + (isLastItem ? '.' : ', ');
                    action.interactionId = this.interactionId;
                    action.billingAccountId = enrolledBillingAccount.billingAccountId;
                    action.ban = enrolledBillingAccount.ban;
                    action.accountType = enrolledBillingAccount.accountType;
                    item.action = action;

                    notification.items.add(item);

                }

                response.notifications.add(notification);

            }

            if (!epaEligibleBillingAccounts.isEmpty()) {

                // Add notification for all eligible bans
                BWC_Notification.Notification notification = new BWC_Notification.Notification();
                notification.closeButton = true;
                notification.items = new List<BWC_Notification.NotificationItem>{
                    new BWC_Notification.NotificationItem('This customer <b>is eligible</b> to setup an Extended Payment Arrangement on:')
                };

                for (Integer i = 0; i < epaEligibleBillingAccounts.size(); i++) {

                    BWC_PaymentDetails.PaymentDetailsResponse eligibleBillingAccount = epaEligibleBillingAccounts[i];
                    Boolean isLastItem = i == epaEligibleBillingAccounts.size() - 1;

                    String label = '<b>Account ' + eligibleBillingAccount.ban + ' (' + BWC_BillingAccount.getBillingAccountTypeLabel(eligibleBillingAccount.accountType) + ')</b>.';
                    BWC_Notification.NotificationItem item = new BWC_Notification.NotificationItem(label);

                    if (FeatureManagement.checkPermission('Collections_Agent') || Test.isRunningTest()) {
                        // Add the Enroll action
                        InteractionNotificationAction action = new InteractionNotificationAction();
                        action.name = 'epaEnroll';
                        action.message = 'Enroll' + (isLastItem ? '.' : ', ');
                        action.interactionId = this.interactionId;
                        action.billingAccountId = eligibleBillingAccount.billingAccountId;
                        action.ban = eligibleBillingAccount.ban;
                        action.accountType = eligibleBillingAccount.accountType;
                        item.action = action;
                    }
                    else {
                        item.message += isLastItem ? '.' : ', ';
                    }

                    notification.items.add(item);

                }

                response.notifications.add(notification);

            }

            return response;            

        }

    }

    /*
        Response wrapper for returned notifications.
    */
    public with sharing class GetInteractionNotificationsResponse extends BWC_Service.ServiceResponse {
        public List<BWC_Notification.Notification> notifications;
    }

    /*
        Notification action specific to Interaction, includes IDs of Interaction and Billing Account.
    */
    public with sharing class InteractionNotificationAction extends BWC_Notification.Action {
        public Id interactionId;
        public Id billingAccountId;
        public String ban;
        public String accountType;
    }

    /**************************************************************************
        CPNI Preference service
    **************************************************************************/

    /*
        Set cpni value on interaction
    */
    public static void setCpniConsent(Id interactionId, String cpniConsent, Id billingAccountId) {

        if (cpniConsent == NULL || cpniConsent == '') {
            Billing_Account__c billingAccount = BWC_AccountService.getBillingAccountForId(billingAccountId);
            if (billingAccount.CPNI_Preference__c != NULL && billingAccount.CPNI_Preference__c != '') {
                cpniConsent = billingAccount.CPNI_Preference__c;
            } else {
                cpniConsent = CPNI_NO_VOICE_ON_ACCOUNT;
            }
        }
        update (new Interaction__c(Id = interactionId, Cpni_Consent__c = cpniConsent));

    }
    

}
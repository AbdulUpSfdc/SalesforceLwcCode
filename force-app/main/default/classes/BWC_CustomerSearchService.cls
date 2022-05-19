public with sharing class BWC_CustomerSearchService {

    public static BWC_CustomerSearch.CustomerSearchResponse accountSearch(Id recordId, BWC_CustomerSearch.CustomerSearchRequest searchRequest) {

        CustomerSearchService service = new CustomerSearchService(recordId, searchRequest);
        return (BWC_CustomerSearch.CustomerSearchResponse)service.call();

    }

    public with sharing class CustomerSearchService extends BWC_InteractionServiceBase {

        // Request and Response state
        public BWC_CustomerSearch.CustomerSearchRequest request;
        public BWC_CustomerSearch.CustomerSearchResponse response;

        /*
            Construct the service object from caller arguments.
        */
        public CustomerSearchService(Id recordId, BWC_CustomerSearch.CustomerSearchRequest request) {

            // Can be Interaction or Case
            super(recordId, null);

            // Store inputs
            this.request = request;

            this.buildRequest();

        }

        public void buildRequest() {

            this.callout = new BWC_CustomerSearchCallout.CustomerSearchCallout(this.request);

        }

        /*
            Builds and returns final response.
        */
        public override Object buildResponse() {

            // Get the response
            this.response = (BWC_CustomerSearch.CustomerSearchResponse)this.callout.getResponse();
            this.response.accountResponseCount = this.response.accountResponses == null ? 0 : this.response.accountResponses.size();

            if (this.response.accountResponses != null) {

                // Response has zero or more customers (not addresses)
    
                if (this.response.accountResponses.isEmpty()) {
                    // No results -- just return the empty
                    return response;
                }
    
                if (this.response.accountResponseCount == 1) {
    
                    // There's a single customer found
                    BWC_CustomerSearch.AccountResponse accountResponse = this.response.accountResponses[0];
    
                    // Check to make sure it's sufficient to create the person account
                    if (String.isEmpty(accountResponse.accountHeader.lastName)) {
                        throw new BWC_Exception('Partial header received from service, cannot save person account.', JSON.serialize(this.request), JSON.serialize(this.response));
                    }
    
                    Account acct = upsertRecordsForCustomer(accountResponse, this.interaction != null ? this.interaction.CTI_Call_Identifier__c : null);
                    accountResponse.accountId = acct.Id;
                    accountResponse.personAccountId = acct.Id;
    
                    if (this.interaction != null) {                    
    
                        // Update interaction fields
                        Interaction__c intAction = new Interaction__c(Id = this.interaction.Id, Customer__c = acct.Id);
                        
                        if (!String.isEmpty(this.request.ban)) {
                            intAction.User_Account_Number__c = this.request.ban;
                        } 
                        else if (!String.isEmpty(accountResponse.accountHeader.ban)){
                            intAction.User_Account_Number__c = accountResponse.accountHeader.ban;
                        }
                        else {
                            throw new BWC_Exception('Cannot set billing account because accountHeader ban is not provided in search results.');
                        }

                        Boolean atLeastOneUverseAccount = false;
                        for(BWC_CustomerSearch.BillingAccount billingAccount : accountResponse.accounts) {

                            atLeastOneUverseAccount = atLeastOneUverseAccount ||  billingAccount.accountTypeLob == BWC_Constants.ACCOUNT_TYPE_UVERSE;
                        }

                        intAction.has_Uverse_BAN__c = atLeastOneUverseAccount;
                        
                        update intAction;

                        // Start product search for the interaction
                        BWC_ProductSearchService.queueProductSearch(this.interaction);

                    }
    
                }
                else {
    
                    // Multiple customers found -- just return the response and no further action
    
                }
    
            }
            else if (response.addressesResponse != null) {
    
                // Multiple addresses found -- just return the response and no further action
    
            }
            else {
                throw new BWC_Exception('Neither singleResponse or mduResponse was returned.');
            }    

            // If single account was found for interaction, remove the details so they are not available on browser to unauthorizeduser
            if (this.interaction != null && this.response.accountResponseCount == 1) {
                response.accountResponses.clear();
            }

            // Return response
            return this.response;

        }

    }

    /*
        Upsert Account, Billing Accounts, and Customer Account Relations for the search results
    */
    public static Account upsertRecordsForCustomer(BWC_CustomerSearch.AccountResponse accountResponse, String ctiCallIdentifier) {

        BWC_CustomerSearch.AccountHeader accountHeader = accountResponse.accountHeader;
        BWC_CustomerSearch.AccountDetails accountDetails = accountResponse.accountDetails;

        // Map data into Account
        String primaryBan = accountResponse.accountHeader.ban != null ? accountResponse.accountHeader.ban : '';
        String primaryProduct = accountResponse.accountHeader.primaryProduct;
        Account acct = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BWC_Constants.ACCOUNT_RECORD_TYPE_PERSON_ACCOUNT).getRecordTypeId(),
            FirstName = accountHeader.firstName,
            LastName = accountHeader.lastName,
            Phone = accountHeader.contactNumber,
            PersonEmail = accountHeader.email,
            Primary_BAN__c = primaryBan,
            Primary_Product__c = primaryProduct,
            External_Id__c = primaryBan + primaryProduct,
            Global_ID__c = accountDetails.globalId,
            Is_Business_Customer__c = accountDetails.accountType == BWC_Constants.CUSTOMER_TYPE_BUSINESS || accountDetails.accountType == BWC_Constants.CUSTOMER_TYPE_GOVERNMENT,
            Employee__c = accountHeader.isEmployee != null ? Boolean.valueOf(accountHeader.isEmployee) : false,
            CTI_Call_Identifier__c = ctiCallIdentifier
        );

        // Populate Billing Accounts
        Map<String, BWC_CustomerSearch.BillingAccount> billingAccountsByBan = new Map<String, BWC_CustomerSearch.BillingAccount>();
        Map<String, Billing_Account__c> billacctMap = new Map<String, Billing_Account__c>();
        Boolean isAtLeastOneNonPrepaidBan = false;
        Boolean isOnlyFirstNet = true;
        for(BWC_CustomerSearch.BillingAccount billingAccount : accountResponse.accounts) {

            if (billingAccount.error != null) {
                // [TODO] Log
                System.debug(LoggingLevel.ERROR, 'Account has error: ' + JSON.serialize(billingAccount, true));
            }

            if (String.isEmpty(billingAccount.ban) || String.isEmpty(billingAccount.accountTypeLob)) {
                // We don't have minimal fields to continue, will not upsert for this billing account
                continue;
            }

            if (billingAccount.accountTypeLob.equalsIgnoreCase('hbomax')) {
                // Ignore HBOMAX
                continue;
            }

            // Map by BAN to allow search for existing person account relationships
            billingAccountsByBan.put(billingAccount.ban, billingAccount);

            Boolean isPrimary = billingAccount.ban == primaryBan;

            // Map data into Billing Account
            Billing_Account__c billacct = new Billing_Account__c(
                CTI_Call_Identifier__c = ctiCallIdentifier,
                Billing_Account_Number__c = billingAccount.ban,
                Account_Type__c = billingAccount.accountTypeLob,
                Unified_BAN__c = billingAccount.accountTypeLob == BWC_Constants.ACCOUNT_TYPE_WIRELESS ? billingAccount.unifiedBan : null,
                Is_Unified__c = billingAccount.isUnified != null ? billingAccount.isUnified : false,
                Wireless_BAN__c = billingAccount.accountTypeLob == BWC_Constants.ACCOUNT_TYPE_UVERSE ? billingAccount.wirelessBan : null,
                Customer_Type__c = billingAccount.accountType,
                Product_Name_360__c = billingAccount.productName360,
                Account_Status__c = billingAccount.accountStatus,
                Bundle_Discount__c = billingAccount.accountTypeLob == BWC_Constants.ACCOUNT_TYPE_WIRELESS && billingAccount.isBundleDiscount != null
                    ? (billingAccount.isBundleDiscount ? 'Yes' : 'No')
                    : null,
                Service_Start_Date__c = billingAccount.serviceStartDate != null ? Date.parse(billingAccount.serviceStartDate) : null,
                Customer_Since__c = billingAccount.serviceStartDate != null ? Date.parse(billingAccount.serviceStartDate) : null,
                First_Name__c = String.isNotEmpty(billingAccount.firstName) ? billingAccount.firstName : acct.FirstName,
                Last_Name__c = String.isNotEmpty(billingAccount.lastName) ? billingAccount.lastName : acct.LastName,
                Contact_Number__c = billingAccount.contactNumber,
                Alternate_Phone_Number__c = billingAccount.secondaryPhoneNumber,
                Email__c = String.isNotEmpty(billingAccount.email) && billingAccount.email.contains('@') ? billingAccount.email : null,
                Is_Employee__c = billingAccount.isEmployee != null ? billingAccount.isEmployee : false,
                CustomerID__c = billingAccount.customerId,
                Customer_Liability__c = billingAccount.customerLiabilityType,
                SubDiscount__c = billingAccount.subDiscount,
                Passcode__c = billingAccount.passcode,
                DigitalLife__c = billingAccount.isDigitalLife != null ? billingAccount.isDigitalLife : false,
                Prepaid_Customer__c = billingAccount.isPrepaidCustomer != null ? billingAccount.isPrepaidCustomer : false,
                Service_Discount__c = billingAccount.serviceDiscount,
                BMG_Contract_Type__c = billingAccount.bmgContractType,
                Security_Level__c = billingAccount.securityLevel,
                Billing_Market__c = billingAccount.billingMarket,
                CPNI_Preference__c = billingAccount.cpni != null ? billingAccount.cpni.cpniIndicator : null,
                Language_Preference__c = billingAccount.languagePreference != null ? billingAccount.languagePreference : (isPrimary ? accountDetails.languagePreference : null),
                Visually_Impaired__c = isPrimary && accountDetails.visuallyImpaired != null ? Boolean.valueOf(accountDetails.visuallyImpaired) : false,
                Enrolled_in_Large_Print__c = isPrimary && accountDetails.enrolledInLargePrint != null ? Boolean.valueOf(accountDetails.enrolledInLargePrint) : false,
                Credit_Class__c = isPrimary ? accountDetails.creditClass : null,
                Fan_Name__c = billingAccount.fan?.fanName,
                Fan_Id__c = billingAccount.fan?.fanId,
                Fan_Number__c = billingAccount.fan?.fanId,
                FAN_Category__c = billingAccount.fan?.fanCategory,
                FAN_Sub_Category_1__c = billingAccount.fan?.fanSubCategory1,
                FAN_Sub_Category_2__c = billingAccount.fan?.fanSubCategory2,
                FAN_Sub_Category_3__c = billingAccount.fan?.fanSubCategory3,
                FAN_Sub_Category_4__c = billingAccount.fan?.fanSubCategory4,
                Has_Only_Direct_TV__c = isPrimary
                    ? (accountDetails.isMigratedDTV != null ? Boolean.valueOf(accountDetails.isMigratedDTV) : false)
                    : (billingAccount.isMigratedDTV != null ? Boolean.valueOf(billingAccount.isMigratedDTV) : false),
                Eligible_for_Restoral_Picklist__c = billingAccount.restoreEligible != null ? (billingAccount.restoreEligible ? 'Yes' : 'No') : null,
                POTS_Voice_Phone_Number__c = billingAccount.serviceNumber != null ? BWC_Utils.formatPhone(billingAccount.serviceNumber) : '',
                HBO_Max_Entitlement__c = billingAccount.hboMaxEntitlementIndicator != null ? billingAccount.hboMaxEntitlementIndicator : false,
                Suspension_status__c = billingAccount.suspensionStatus,
                PAH_Contact_Phone__c = billingAccount.primaryAccountHolder,
                Is_FirstNet__c = billingAccount.fnType != null ? BWC_BillingAccount.FIRST_NET_TYPES.contains(billingAccount.fnType) : false,
                firstNet_Type__c = billingAccount.fnType
            );

            // Keep track so we can set flag on account if all bans are prepaid
            if (billacct.Prepaid_Customer__c != true) {
                isAtLeastOneNonPrepaidBan = true;
            }

            if (billacct.Is_FirstNet__c != true) {
                isOnlyFirstNet = false;
            }

            // Need to set Billing address and Service Address based on the order sequence checking of 
            // If no Service address, then look for ServiceUSPS, if no ServiceUSPS, then look for ServiceSAG, 
            // if no ServiceSAG, then look for ServiceFSP.

            // For Billing Address and Service Address assignment, create a map
            Map<String, BWC_CustomerSearch.Address> mapAddrTypeToAddress = new Map<String, BWC_CustomerSearch.Address>();
            if (billingAccount.address != null) {
                for(BWC_CustomerSearch.Address address : billingAccount.address) {
                    mapAddrTypeToAddress.put(address.type, address);
                }
            }

            // Set the Billing Address
            BWC_CustomerSearch.Address billingAddress = mapAddrTypeToAddress.get(BWC_Constants.ADDRESS_TYPE_BILLING);

            // First Search for Billing Address
            if (billingAddress != null) {
                billacct.Billing_Address_Line_1__c = billingAddress.streetName1;
                billacct.Billing_City__c = billingAddress.locality;
                billacct.Billing_State__c  = billingAddress.stateOrProvince;
                billacct.Billing_Zipcode__c  = billingAddress.postcode;
            }

            // Then Search for Service Address in this order
            List<String> listServiceAddressTypes = new List<String> {
                BWC_Constants.ADDRESS_TYPE_SERVICE, 
                BWC_Constants.ADDRESS_TYPE_SERVICE_USPS,
                BWC_Constants.ADDRESS_TYPE_SERVICE_SAG,
                BWC_Constants.ADDRESS_TYPE_SERVICE_FSP};

            // Check if Service address is available in the order added to the List listServiceAddressTypes
            BWC_CustomerSearch.Address serviceAddress = null;
            for (Integer idx = 0; idx < listServiceAddressTypes.size(); idx++) {
                // get the address with the type at listServiceAddressTypes[idx]
                serviceAddress = mapAddrTypeToAddress.get(listServiceAddressTypes[idx]);
                if (serviceAddress != null) {
                    billacct.Service_Address_Line_1__c = serviceAddress.streetName1;
                    billacct.Service_City__c = serviceAddress.locality;
                    billacct.Service_State__c  = serviceAddress.stateOrProvince;
                    billacct.Service_Zipcode__c  = serviceAddress.postcode;
                    // Service Address is found, so break the loop
                    break;
                }
            }

            billacctMap.put(billacct.Billing_Account_Number__c, billacct);

        }

        // Set flag indicating all bans are prepaid
        acct.Is_Prepaid_Only__c = !isAtLeastOneNonPrepaidBan;

        // Set firstnet flag
        acct.isFirstNet__c = isOnlyFirstNet;

        // Upsert billing account records by BAN
        upsert billacctMap.values() Billing_Account_Number__c;
        
        // Discover existing person account linked to any of the bans
        List<Customer_Account_Relation__c> existingBanRelations = [
            SELECT
                Id, Billing_Account__r.Billing_Account_Number__c, Billing_Account__r.Account_Type__c, Customer__c, Customer__r.Primary_BAN__c,Customer__r.Primary_Product__c,Customer__r.External_Id__c
            FROM
                Customer_Account_Relation__c
            WHERE
                Billing_Account__r.Billing_Account_Number__c IN :billingAccountsByBan.keyset()
        ];

        for (Customer_Account_Relation__c existingBanRelation : existingBanRelations) {

            // Make sure account type also matches
            if (billingAccountsByBan.get(existingBanRelation.Billing_Account__r.Billing_Account_Number__c).accountTypeLob == existingBanRelation.Billing_Account__r.Account_Type__c
            
            && acct.Primary_BAN__c == existingBanRelation.Customer__r.Primary_BAN__c) {

                // Found existing person account, set the ID and we will update the existing account
                acct.Id = existingBanRelation.Customer__c;
                acct.External_Id__c = existingBanRelation.Customer__r.External_Id__c;
                break;

            }

        }
        
        // Insert or update account
        if (acct.Id != null) {
            // An existing account was found for one of the bans: update it
            update acct;
        }
        else {
            // No existing person account was found for any of the bans: insert a new one
            insert acct;
        }

        // Upsert Customer_Account_Relation__c records to link the Billing Accounts to Person Account.
        List<Customer_Account_Relation__c> custacctRelLst = new List<Customer_Account_Relation__c>();
        for (Billing_Account__c billingAccount : billacctMap.values()) {
            custacctRelLst.add(new Customer_Account_Relation__c(
                Billing_Account__c = billingAccount.Id,
                Customer__c = acct.Id,
                External_Id__c = acct.Id + '' + billingAccount.Id,
                Role__c = BWC_Constants.ACCOUNT_RELATIONSHIP
            ));
        }

        upsert custacctRelLst External_Id__c;

        return acct;

    }

    public with sharing class CBRSearchService extends BWC_InteractionServiceBase{

        public BWC_CustomerSearch.CBRResponse response;
        public String phoneNumber;

        public CBRSearchService(Id recordId, String phoneNumber){
            super(recordId, null);
            this.phoneNumber = phoneNumber;

            this.buildRequest();
        }

        public void buildRequest(){
            this.callout = new BWC_CustomerSearchCallout.CBRSearchCallout(this.phoneNumber);
        }

        public override Object buildResponse(){

            this.response = (BWC_CustomerSearch.CBRResponse) this.callout.getResponse();
            List<BWC_CustomerSearch.Customer> customers = this.response.customers;

            if(customers == null){
                return this.response;
            }

            if(customers.isEmpty()){
                return this.response;
            }

             // If only one person with at least one account, perform search
            if(customers.size() == 1 && customers[0].accounts!= null && !customers[0].accounts.isEmpty()){
                this.response.performSearch = true;
            }

            List<BWC_CustomerSearch.Accounts> accounts = new List<BWC_CustomerSearch.Accounts>();
            // If more than one person, or one person with more than account, show selection panel
            for(BWC_CustomerSearch.Customer customer : customers){

                if(customer.accounts == null){
                    continue;
                }

                accounts.addAll(customer.accounts);
            }

            List<BWC_CustomerSearch.CBRSelection> accountSelection = new List<BWC_CustomerSearch.CBRSelection>();
            for(BWC_CustomerSearch.Accounts account : accounts){

                BWC_CustomerSearch.CBRSelection acct = new BWC_CustomerSearch.CBRSelection();
                acct.accountNumber = BWC_BillingAccount.maskBan(account.ban);
                acct.ban = account.ban;
                acct.lob = BWC_BillingAccount.ACCOUNT_TYPE_LABEL_MAP.get(account.accountType);
                acct.accountType = account.accountType;
                acct.status = account.accountStatus;
                acct.name = BWC_Utils.toProperCase(account.profile?.firstName) +' '+ BWC_Utils.toProperCase(account.profile?.lastName);
                acct.email = BWC_Utils.maskEmailAddress(account.profile?.emailAddress);
                acct.phoneNumber = BWC_Utils.maskPhoneNumber(account.profile?.phoneNumber);

                if(account.addresses!=null){

                    String zipCode;
                    for(BWC_CustomerSearch.AddressCBR address : account.addresses){
                        if(address.addressType == BWC_CustomerSearch.BILLING_ADDRESS_TYPE){
                            zipCode = address.zip;
                            break;
                        }
                    }
                    acct.zipCode = zipCode;
                }

                accountSelection.add(acct);
            }

            this.response.customers.clear();
            this.response.accounts = accountSelection;

            return this.response;
        }
    }

}
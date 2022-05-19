public inherited sharing class BWC_UnifiedSearchService {


    public class CustomerSearch extends BWC_InteractionServiceBase {

        public BWC_UnifiedSearch.UnifiedSearchRequest request;
        public BWC_UnifiedSearch.UnifiedSearchResponse response;

        public CustomerSearch(Id interactionId, BWC_UnifiedSearch.UnifiedSearchRequest request){
            super(interactionId, null);

            this.request = request;

            this.buildRequest();
        }

        public void buildRequest(){
            this.callout = new BWC_UnifiedSearchCallout.CustomerSearchCallout(this.request);
        }

        public override Object buildResponse(){
            this.response = (BWC_UnifiedSearch.UnifiedSearchResponse) this.callout.getResponse();
            this.response.accountResponseCount = this.response.individuals?.size();

            if(this.response.individuals.isEmpty()){
                return this.response;
            }

            //If more than one individual, process and mask data to be shown on the UI
            if(this.response.accountResponseCount >= 1){
                processRecordsForUI(this.response);
            }

            //If a single individual is found, upsert records and link the interaction
            if (this.response.accountResponseCount == 1) {

                this.response = upsertRecordsForCustomer(this.response, this.interaction != null ? this.interaction.CTI_Call_Identifier__c : null);
                if(this.interaction!=null){
                    // There's a single customer found
                    BWC_UnifiedSearch.IndividualFound individual = this.response.individualsFound[0];
                    List<BWC_UnifiedSearch.Accounts> accounts = this.response.individuals[0].accounts;
                    String accountId = individual.accountId;

                    Boolean atLeastOneUverseAccount = false;
                    Boolean hasSameUserAccountNumber = false; // Validates there's an account that matches the current User_Account_Number__c value.
                    for(BWC_UnifiedSearch.Accounts billingAccount : accounts){
                        atLeastOneUverseAccount = atLeastOneUverseAccount || billingAccount.serviceType == BWC_Constants.ACCOUNT_TYPE_UVERSE;
                        hasSameUserAccountNumber = hasSameUserAccountNumber || this.interaction.User_Account_Number__c == billingAccount.id;
                    }

                    /**
                     * User Account Number could have already been set by CTI.
                     * if User_Account_Number__c is either empty or different from any of the accounts from the response, we need populate it.
                     *
                     * The User_Account_Number__c field could not match any of the existing accounts if the API fails and the agent
                     * searches for another Billing Account Number
                     *
                    */
                    if(String.isBlank(this.interaction.User_Account_Number__c) || !hasSameUserAccountNumber){
                        // Setting search ban. If searching by other term, use the first account number we get
                        if(!String.isEmpty(this.request.accountNumber)){
                            this.interaction.User_Account_Number__c = this.request.accountNumber;
                        } else{
                            this.interaction.User_Account_Number__c = this.response.individuals?.get(0)?.accounts?.get(0)?.id;
                        }

                    }

                    this.interaction.Has_Uverse_BAN__c = atLeastOneUverseAccount;

                    linkInteractionWithAccount(this.interaction, accountId);
                }
            }

            this.response.individuals.clear();

            return this.response;
        }

    }

    public static BWC_UnifiedSearch.UnifiedSearchResponse upsertRecordsForCustomer(BWC_UnifiedSearch.UnifiedSearchResponse response, String ctiCallIdentifier){

        // FOR UI
        List<BWC_UnifiedSearch.IndividualFound> individuals = new List<BWC_UnifiedSearch.IndividualFound>();

        Map<String, Account> accountsByIndividualId = new Map<String, Account>();
        Map<String, Billing_Account__c> billingAccountsByBan = new Map<String, Billing_Account__c>();
        Map<String, List<Billing_Account__c>> billingAccountsByIndividualId = new Map<String, List<Billing_Account__c>>();

        // Loop to create Account and Billing Account records. Also creates the response returned to the UI.
        for(BWC_UnifiedSearch.IndividualResponse individual : response.individuals){

            BWC_UnifiedSearch.Characteristic shippingAddress = BWC_UnifiedSearch.getAddress(individual.contactMedium, new Set<String>{BWC_UnifiedSearch.SHIPPING_ADDRESS_TYPE});

            // TODO: do we need to set the ctiCallIdentifier for all the accounts?
            Account acct = new Account(
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BWC_Constants.ACCOUNT_RECORD_TYPE_PERSON_ACCOUNT).getRecordTypeId(),
                FirstName = individual.givenName,
                LastName = individual.familyName,
                Phone = BWC_UnifiedSearch.getPhoneNumberIndividual(individual.contactMedium, BWC_UnifiedSearch.WORK_CONTACT_TYPE),
                PersonHomePhone = BWC_UnifiedSearch.getPhoneNumberIndividual(individual.contactMedium, BWC_UnifiedSearch.HOME_CONTACT_TYPE),
                PersonOtherPhone = BWC_UnifiedSearch.getPhoneNumberIndividual(individual.contactMedium, BWC_UnifiedSearch.OTHER_CONTACT_TYPE),
                PersonEmail = BWC_UnifiedSearch.getContactMedium(individual.contactMedium, BWC_UnifiedSearch.CONTACT_MEDIUM_EMAIL, BWC_UnifiedSearch.CONTACT_TYPE_OTHER),
                Individual_Id__c = individual.id,
                Is_Digital_Customer__c =  BWC_Utils.getBoolean(individual.digitalCustomer),
                ShippingCity = shippingAddress?.city,
                ShippingCountry = shippingAddress?.country,
                ShippingState = shippingAddress?.stateOrProvince,
                ShippingStreet = shippingAddress?.street1,
                ShippingPostalCode = shippingAddress?.postCode,
                Shipping_Address_Id__c = shippingAddress?.place?.id,
                Language_Code__c = individual.languageAbility?.get(0).languageCode,
                Language_Name__c = individual.languageAbility?.get(0).languageName,
                CTI_Call_Identifier__c = ctiCallIdentifier,
                Employee__c = individual.isEmployee != null ? individual.isEmployee : false
            );

            BWC_UnifiedSearch.IndividualFound individualFound = processIndividual(individual, acct);

            accountsByIndividualId.put(acct.Individual_Id__c, acct);
            billingAccountsByIndividualId.put(acct.Individual_Id__c, new List<Billing_Account__c>());

            Boolean atLeastOneBusinessGoverment = false;
            Boolean atLeastOneFirstNet = false;


            if(individual.accounts != null){

                for(BWC_UnifiedSearch.Accounts billingAccount : individual.accounts){

                    if(String.isEmpty(billingAccount.id) || String.isEmpty(billingAccount.serviceType)){
                        continue;
                    }

                    if(billingAccount.serviceType.equalsIgnoreCase('hbomax')){
                        continue;
                    }

                    String contactNumber = BWC_UnifiedSearch.getPhoneNumber(billingAccount.contact?.get(0)?.contactMedium, BWC_UnifiedSearch.PRIMARY_SUBCONTACT_TYPE);
                    String alternatePhoneNumber = BWC_UnifiedSearch.getPhoneNumber(billingAccount.contact?.get(0)?.contactMedium, BWC_UnifiedSearch.SECONDARY_SUBCONTACT_TYPE);
                    String email = BWC_UnifiedSearch.getContactMedium(billingAccount.contact?.get(0)?.contactMedium, BWC_UnifiedSearch.CONTACT_MEDIUM_EMAIL, BWC_UnifiedSearch.CONTACT_TYPE_OTHER);
                    BWC_UnifiedSearch.Characteristic billingAddress = BWC_UnifiedSearch.getAddress(billingAccount.contact?.get(0)?.contactMedium, new Set<String>{BWC_UnifiedSearch.BILLING_ADDRESS_TYPE});
                    BWC_UnifiedSearch.Characteristic serviceAddress = BWC_UnifiedSearch.getAddress(billingAccount.contact?.get(0)?.contactMedium, BWC_UnifiedSearch.SERVICE_ADDRESS_TYPES_SET);
                    BWC_UnifiedSearch.ConsentPreferences cpniPreference = BWC_UnifiedSearch.getPreferenceByNotificationType(billingAccount.consentPreferences, BWC_UnifiedSearch.CPNI_NOTIFICATION_TYPE);

                    Billing_Account__c billacct = new Billing_Account__c(
                        Billing_Account_Number__c = billingAccount.id,
                        Account_Type__c = billingAccount.serviceType,
                        Customer_Type__c = billingAccount.accountType,
                        Product_Name_360__c = billingAccount.details?.productName360,
                        Account_Status__c = billingAccount.state,
                        Wireless_BAN__c = billingAccount.wirelessBan,
                        Unified_BAN__c = billingAccount.unifiedBan,
                        Is_Unified__c = billingAccount.isUnifiedBan != null ? billingAccount.isUnifiedBan : false,
                        Is_FirstNet__c = billingAccount.details?.isFirstNet != null ? billingAccount.details?.isFirstNet : false,
                        Service_Start_Date__c = BWC_Utils.parseDate(billingAccount.createdOn),
                        Customer_Since__c = BWC_Utils.parseDate(billingAccount.createdOn),
                        First_Name__c = String.isNotEmpty(billingAccount.givenName) ? billingAccount.givenName : acct.FirstName,
                        Last_Name__c = String.isNotEmpty(billingAccount.familyName) ? billingAccount.familyName : acct.LastName,
                        Contact_Number__c = contactNumber,
                        Alternate_Phone_Number__c = alternatePhoneNumber,
                        Email__c = String.isNotEmpty(email)
                            && email.contains('@')
                            ? email : null,
                        Billing_Market__c = billingAccount.billingMarket,
                        CPNI_Preference__c = cpniPreference?.electionCode,
                        Fan_Name__c = billingAccount.fanDetails?.fanName,
                        Fan_Id__c = billingAccount.fanDetails?.fanId,
                        Fan_Number__c = billingAccount.fanDetails?.fanId,
                        FAN_Category__c = billingAccount.fanDetails?.fanCategory,
                        FAN_Sub_Category_1__c = billingAccount.fanDetails?.fanSubCategory1,
                        FAN_Sub_Category_2__c = billingAccount.fanDetails?.fanSubCategory2,
                        FAN_Sub_Category_3__c = billingAccount.fanDetails?.fanSubCategory3,
                        FAN_Sub_Category_4__c = billingAccount.fanDetails?.fanSubCategory4,
                        SubDiscount__c = billingAccount.fanDetails?.fanDiscountEnabled,
                        Billing_Address_Line_1__c = billingAddress?.street1,
                        Billing_City__c = billingAddress?.city,
                        Billing_State__c = billingAddress?.stateOrProvince,
                        Billing_Zipcode__c = billingAddress?.postCode,
                        Billing_Country__c = billingAddress?.country,
                        Billing_Address_Id__c = billingAddress?.place?.id,
                        Service_Address_Line_1__c = serviceAddress?.street1,
                        Service_City__c = serviceAddress?.city,
                        Service_State__c = serviceAddress?.stateOrProvince,
                        Service_Zipcode__c = serviceAddress?.postCode,
                        Service_Country__c = serviceAddress?.country,
                        Service_Address_Id__c = serviceAddress?.place?.id,
                        FirstNet_Type__c = billingAccount.details?.firstNetType,
                        VOC_Number__c = billingAccount.oldestCTN,
                        CTI_Call_Identifier__c = ctiCallIdentifier,
                        HBO_Max_Entitlement__c = billingAccount.details?.hbomaxEntitlementIndicator != null ? billingAccount.details?.hbomaxEntitlementIndicator : false,
                        Prepaid_Customer__c = billingAccount.details?.isPrepaid != null ? billingAccount.details?.isPrepaid : false
                    );

                    billingAccountsByBan.put(billacct.Billing_Account_Number__c, billacct);
                    billingAccountsByIndividualId.get(acct.Individual_Id__c).add(billAcct);

                    individualFound.accounts.add(processAccount(billingAccount, billacct));

                    atLeastOneBusinessGoverment = billacct.Customer_Type__c == BWC_Constants.CUSTOMER_TYPE_BUSINESS
                        || billacct.Customer_Type__c == BWC_Constants.CUSTOMER_TYPE_GOVERNMENT
                        || atLeastOneBusinessGoverment;
                    atLeastOneFirstNet = billacct.Is_FirstNet__c && atLeastOneFirstNet;

                }
            }

            acct.Is_Business_Customer__c = atLeastOneBusinessGoverment;
            acct.isFirstNet__c = atLeastOneFirstNet;

            individuals.add(individualFound);

        }

        upsert billingAccountsByBan.values() Billing_Account_Number__c;

        upsert accountsByIndividualId.values() Individual_id__c;

        // Setting AccountId on response returned to the UI
        for(BWC_UnifiedSearch.IndividualFound individual : individuals){

            System.debug(individual);
            Account acc = accountsByIndividualId.get(individual.globalId);
            individual.accountId = acc.Id;

            for(BWC_UnifiedSearch.AccountFound account : individual.accounts){
                account.billingAccountId = billingAccountsByBan.get(account.accountNumber).Id;
                account.accountNumber = BWC_BillingAccount.maskBan(account.accountNumber);
            }
        }

        response.individualsFound = individuals;

        System.debug('accountsByIndividualId: '+accountsByIndividualId);
        System.debug('billingAccountsByIndividualId: '+ billingAccountsByIndividualId);

        // Upsert Customer_Account_Relation__c records to link the Billing Accounts to Person Account.
        Map<String,Customer_Account_Relation__c> custacctRelMap = new Map<String,Customer_Account_Relation__c>();
        for (String individualId : billingAccountsByIndividualId.keySet()) {

            Account acct = accountsByIndividualId.get(individualId);

            for(Billing_Account__c billingAccount : billingAccountsByIndividualId.get(individualId)){

                Billing_Account__c billAcc = billingAccountsByBan.get(billingAccount.Billing_Account_Number__c);
                String externalId = acct.Id + '' + billAcc.Id;
                System.debug('Account:'+acct );
                System.debug('billingAccount:'+billingAccount );

                custacctRelMap.put(externalId,new Customer_Account_Relation__c(
                    Billing_Account__c = billAcc.Id,
                    Customer__c = acct.Id,
                    External_Id__c = externalId,
                    Role__c = BWC_Constants.ACCOUNT_RELATIONSHIP
                ));
            }
        }

        upsert custacctRelMap.values() External_Id__c;

        return response;
    }

    public static void processRecordsForUI(BWC_UnifiedSearch.UnifiedSearchResponse response){

        // FOR UI
        List<BWC_UnifiedSearch.IndividualFound> individuals = new List<BWC_UnifiedSearch.IndividualFound>();

        for(BWC_UnifiedSearch.IndividualResponse individual : response.individuals){

            BWC_UnifiedSearch.IndividualFound individualFound = processIndividual(individual, null);

            if(individual.accounts == null){
                continue;
            }

            for(BWC_UnifiedSearch.Accounts billingAccount : individual.accounts){
                individualFound.accounts.add(processAccount(billingAccount, null));
            }

            individuals.add(individualFound);
        }

        response.individualsFound = individuals;

    }

    public static BWC_UnifiedSearch.IndividualFound processIndividual(BWC_UnifiedSearch.IndividualResponse ind, Account acct){

        String phoneNumber;
        String email;

        if(acct!=null){
            phoneNumber = acct.Phone;
            email = acct.PersonEmail;
        }else{
            phoneNumber = BWC_UnifiedSearch.getPhoneNumberIndividual(ind.contactMedium, BWC_UnifiedSearch.WORK_CONTACT_TYPE);
            email = BWC_UnifiedSearch.getContactMedium(ind.contactMedium, BWC_UnifiedSearch.CONTACT_MEDIUM_EMAIL, BWC_UnifiedSearch.CONTACT_TYPE_OTHER);
        }

        BWC_UnifiedSearch.IndividualFound individual = new BWC_UnifiedSearch.IndividualFound();
        individual.fullName = BWC_Utils.toProperCase(ind.givenName)+' '+BWC_Utils.toProperCase(ind.familyName);
        individual.globalId = ind.id;
        individual.contactNumber = BWC_Utils.maskPhoneNumber(phoneNumber);
        individual.email =  BWC_Utils.maskEmailAddress(email);
        individual.accounts = new List<BWC_UnifiedSearch.AccountFound>();

        return individual;
    }

    public static BWC_UnifiedSearch.AccountFound processAccount(BWC_UnifiedSearch.Accounts acct, Billing_Account__c billAcc){

        String zipCode;
        String ban;

        if(billAcc!=null){
            zipCode = billAcc.Billing_Zipcode__c;
            ban = billAcc.Billing_Account_Number__c;
        }else{
            BWC_UnifiedSearch.Characteristic billingAddress = BWC_UnifiedSearch.getAddress(acct.contact?.get(0)?.contactMedium, new Set<String>{BWC_UnifiedSearch.BILLING_ADDRESS_TYPE});
            zipCode = billingAddress?.postCode?.left(5);
            ban=BWC_BillingAccount.maskBan(acct.id);
        }

        BWC_UnifiedSearch.AccountFound acc = new BWC_UnifiedSearch.AccountFound();
        acc.accountNumber = ban;
        acc.lineOfBusiness =  BWC_BillingAccount.ACCOUNT_TYPE_LABEL_MAP.get(acct.serviceType);
        acc.zipCode = zipCode;
        acc.status = acct.state;

        return acc;
    }

    public static void linkInteractionWithAccount(Interaction__c interaction, Id accountId){

        Account acc = new Account(Id=accountId);
        acc.CTI_Call_Identifier__c = interaction.CTI_Call_Identifier__c;
        update acc;

        interaction.Customer__c = accountId;
        update interaction;

        BWC_ProductSearchService.queueProductSearch(interaction);
    }

    public static void linkInteractionWithAccount(Id interactionId, Id accountId, Boolean hasUverseAccount){

        Interaction__c interaction = BWC_Interaction.getInteraction(interactionId);
        interaction.Has_Uverse_BAN__c = hasUverseAccount;
        linkInteractionWithAccount(interaction, accountId);
    }

}
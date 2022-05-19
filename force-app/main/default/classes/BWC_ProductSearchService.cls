public without sharing class BWC_ProductSearchService {

    private static final Set<String> INVALID_PRODUCT_TYPES = new Set<String>{'potsvoice'};

    /*
        Call service synchronously for a person account, used by SyncCaseWith products.
    */
    public static List<ServiceModel> getProductsGroupedByService(String personAccountId) {

        GetProductsService service = new GetProductsService(personAccountId, null, true);
        ServiceModelWrapper response = (ServiceModelWrapper)service.call();
        return response.results;
    }

    /*
        Retrieve products and save into Plan__c and Asset records for all or some bans associated with an Interaction or a Case.
    */
    public inherited sharing class GetProductsService extends BWC_InteractionServiceBase {

        public List<Id> billingAccountIds;
        public Set<Id> validBillingAccountIds = new Set<Id>();
        public Set<Id> invalidBillingAccountIds = new Set<Id>();
        public Boolean forceRefresh;
        public BWC_ProductSearch.ProductSearchResponse calloutResponse;
        public ServiceModelWrapper response;

        public GetProductsService(Id recordId, List<Id> billingAccountIds, Boolean forceRefresh) {

            // Get interaction and billing accounts
            super(recordId, null);

            this.billingAccountIds = billingAccountIds;
            this.forceRefresh = forceRefresh;

            // Check billing accounts if specific ones are requested
            if (billingAccountIds != null && !billingAccountIds.isEmpty()) {
                for (Id billingAccountId : billingAccountIds) {
                    Billing_Account__c billingAccount = this.billingAccountMap.get(billingAccountId);
                    if (billingAccount != null) {
                        if (!INVALID_PRODUCT_TYPES.contains(billingAccount.Product_Name_360__c)) {
                            this.validBillingAccountIds.add(billingAccountId);
                        }
                        else {
                            this.invalidBillingAccountIds.add(billingAccountId);
                        }
                    }
                    else {
                        throw new BWC_Exception('Billing Account not associated with personAccount: ' + billingAccountId);
                    }
                }
            }
            else {
                // Take all valid billing accounts
                this.billingAccountIds = new List<Id>(this.billingAccountMap.keyset());
                for (Id billingAccountId : new List<Id>(this.billingAccountMap.keyset())) {
                    Billing_Account__c billingAccount = this.billingAccountMap.get(billingAccountId);
                    if (!INVALID_PRODUCT_TYPES.contains(billingAccount.Product_Name_360__c)) {
                        this.validBillingAccountIds.add(billingAccountId);
                    }
                    else {
                        this.invalidBillingAccountIds.add(billingAccountId);
                    }
                }
            }

            // Determine if callout is needed
            Boolean needsReload = true;
            if (forceRefresh != true && this.interaction != null) {

                // Not forcing refresh, so check locally before making any API callout
                // Check if Plans and Equipments already exist and have same CTI_Call_Identifier__c as in Billing Account.
                List<ServiceModel> existingServices = readPlansAndEquipments();
                if (existingServices != null && existingServices.size() > 0) {

                    needsReload = false;
                    Boolean hasEquipments = false;
                    Boolean hasPlans = false;

                    for(ServiceModel service : existingServices) {
                
                        if (service.equipments != null) {
                            for (Asset asset : service.equipments) {
                                hasEquipments = true;
                                // The CTI_Call_Identifier__c of this Asset doesnt match the CTI_Call_Identifier__c of Billing Account.
                                // So call to mulesoft is needed.
                                if (asset.CTI_Call_Identifier__c != service.ctiCallIdentifier) {
                                    needsReload = true;
                                    break;
                                }
                            }          
                        }

                        // If it is not already determined that call to mulesoft is needed.
                        if (!needsReload && service.plans != null) {
                            for (Plan__c plan : service.plans) {
                                hasPlans = true;                    
                                // The CTI_Call_Identifier__c of this Plan doesnt match the CTI_Call_Identifier__c of Billing Account.
                                // So call to mulesoft is needed.
                                if (plan.CTI_Call_Identifier__c != service.ctiCallIdentifier) {
                                    needsReload = true;
                                    break;
                                }
                            }
                        }

                        if (needsReload) {
                            break;
                        }
                    }

                    // No need to make Mulesoft API call if there are atleast one equipment or one plan and 
                    // the CTI_Call_Identifier__c matches on all plans and equipments
                    if (!needsReload && (hasEquipments || hasPlans)) {
                        this.response = new ServiceModelWrapper();
                        this.response.results = existingServices;
                    }
                    else {

                        if (needsReload) {

                            // Check to see if search is already ongoing due to prefetch
                            String status = BWC_PrefetchCacheManager.getStatus(this.interaction.CTI_Call_Identifier__c, BWC_PrefetchCacheManager.TYPE_PRODUCT_SEARCH);
            
                            if (status == BWC_PrefetchCacheManager.STATUS_IN_PROCESS) {
                                // Still in process -- this will be result of most polls, so we are only hitting platform cache
                                this.response = new ServiceModelWrapper();
                                this.response.message = 'Prefetch in process.';
                                this.response.prefetchStatus = BWC_PrefetchCacheManager.STATUS_IN_PROCESS;
                                needsReload = false;
                            }
                    
                        }
                        else {
                            needsReload = true;
                        }

                    }

                }

            }

            if (needsReload) {
                this.buildRequest();
            }

        }

        private void buildRequest() {

            // Create the payload to get Product Details from Mulesoft.
            List<BWC_ProductSearch.ProductSearchRequest> productSearchRequests = new List<BWC_ProductSearch.ProductSearchRequest>();
            for (Id billingAccountId : this.billingAccountIds) {

                if (!this.validBillingAccountIds.contains(billingAccountId)) {
                    // Skip invalid
                    continue;
                }
                
                Billing_Account__c billingAccount = this.billingAccountMap.get(billingAccountId);
                if (billingAccount.Account_Type__c.equalsIgnoreCase('hbomax')) {
                    // 10-09 Anshul handling HBO max..eeveentually mule should fix it rt
                    continue;
                }

                BWC_ProductSearch.ProductSearchRequest request = new BWC_ProductSearch.ProductSearchRequest();
                request.topics = 'plans,equipments';
                request.customerId = billingAccount.Billing_Account_Number__c;
                request.accountId = billingAccount.Billing_Account_Number__c;
                request.accountType = billingAccount.Account_Type__c;
                request.isDigitalLife = billingAccount.DigitalLife__c;
                productSearchRequests.add(request);

            }

            if (!productSearchRequests.isEmpty()) {
                // Create the callout instance
                this.callout = new BWC_ProductSearchCallout.ProductSearchCallout(productSearchRequests);
            }

        }

        public override Object buildResponse() {

            if (this.callout != null) {
                
                // Callout was needed, first upsert all the Plan__c and Asset records
                this.calloutResponse = (BWC_ProductSearch.ProductSearchResponse)this.callout.getResponse();

                if (this.calloutResponse.accounts != null) {
                    upsertPlans(this.billingAccountsByBan, this.calloutResponse);
                    upsertEquipments(this.personAccountId, this.billingAccountsByBan, this.calloutResponse);
                }

            }

            if (!this.invalidBillingAccountIds.isEmpty()) {

                // There are invalid product types which we need to create dummy records for
                // Currently only invalid type is POTS Voice
                List<Plan__c> plans = new List<Plan__c>();
                for (Id billingAccountId : new List<Id>(this.invalidBillingAccountIds)) {
                    Billing_Account__c billingAccount = this.billingAccountMap.get(billingAccountId);
                    plans.add(generatePlanForInvalid(billingAccount));
                }

                upsert plans Plan_Unique_Name__c;

            }

            // Check if prefetching
            if (this.response != null && this.response.prefetchStatus == BWC_PrefetchCacheManager.STATUS_IN_PROCESS) {
                return this.response;
            }

            // Read the records back
            List<ServiceModel> services = readPlansAndEquipments();

            // Add errors to results:

            if (this.callout != null) {

                // Map callout response by ban
                Map<String, BWC_ProductSearch.AccountResponse> accountsByBan = new Map<String, BWC_ProductSearch.AccountResponse>();

                if (this.calloutResponse.accounts != null) {
                    for (BWC_ProductSearch.AccountResponse psAccount : this.calloutResponse.accounts) {
                        accountsByBan.put(psAccount.ban, psAccount);
                    }
                }

                // Check for errors
                Boolean hasErrors = false;
                Set<String> bansWithResults = new Set<String>();
                for (ServiceModel service : services) {

                    bansWithResults.add(service.ban);

                    BWC_ProductSearch.AccountResponse psAccount = accountsByBan.get(service.ban);
                    if (psAccount != null) {
                        // Pass through any errors to return payload
                        service.planserror = psAccount.planserror;
                        service.equipmentserror = psAccount.equipmentserror;
                    }

                    if (service.planserror != null || service.equipmentserror != null) {
                        hasErrors = true;
                    }

                }

                if (hasErrors) {

                    BWC_Exception plansException = new BWC_Exception('API returned error(s) for plans and/or equipment.');
                    BWC_ExceptionUtils.handleException(plansException, true, 'personAccountId: ' + this.personAccountId, null);

                }

            }

            this.response = new ServiceModelWrapper();
            this.response.results = services;
            return this.response;

        }

        private List<ServiceModel> readPlansAndEquipments() {
            Map<String, ServiceModel> serviceModelMap = new Map<String, ServiceModel>();
    
            // Get field set name to query for specific fields later for plan and assets
            Set<String> planFieldSetNames = new Set<String>();
            Set<String> assetFieldSetNames = new Set<String>();

            Set<Id> accessibleBillingAccountIds = new Set<Id>();
            for (Id billingAccountId : this.billingAccountIds) {

                Billing_Account__c billingAccount = this.billingAccountMap.get(billingAccountId);
        
                if (BWC_BillingAccount.agentHasAccess(billingAccount) != true) {
                    // Agent shouldn't see this ban
                    continue;
                }

                accessibleBillingAccountIds.add(billingAccountId);

                // Add service
                ServiceModel serviceModel = new ServiceModel();
                serviceModel.ban = billingAccount.Billing_Account_Number__c;
                serviceModel.accountType = billingAccount.Account_Type__c;
                serviceModel.unifiedBan = billingAccount.Unified_BAN__c;    
                serviceModel.ctiCallIdentifier = billingAccount.CTI_Call_Identifier__c;
                serviceModel.serviceTypeName =  billingAccount.Service_Type_Name__c;
                serviceModel.serviceName = billingAccount.Service_Name__c;
                serviceModel.serviceLabel = billingAccount.Service_Label__c;
                serviceModel.sequence = billingAccount.Display_Sequence__c;
                serviceModel.hboMaxflag = billingAccount.HBO_Max_Entitlement__c;
                serviceModelMap.put(billingAccount.Service_Name__c, serviceModel);

                // Add field set for plan depending on billing account type
                switch on billingAccount.Account_Type__c.toLowerCase() {
                    when 'dtv' { planFieldSetNames.add('DIRECTV'); }
                    when 'directv' { planFieldSetNames.add('DIRECTV'); }
                    when 'dtvs' { planFieldSetNames.add('DIRECTV'); }
                    when 'uverse' { planFieldSetNames.add('Internet'); }
                    when 'dtvnow' { planFieldSetNames.add('AT_T_TV'); }
                    when 'pots' { planFieldSetNames.add('POTS'); }
                    when else { planFieldSetNames.add('Wireless'); }
                }

                // Add field set for asset depending on billing account field set name
                assetFieldSetNames.add(billingAccount.Field_Set_Name__c);
            }
    
            // Build query for plans based on field sets from billing accounts
            List<Schema.FieldSetMember> planFieldSetMemberList = new List<Schema.FieldSetMember>();
            for (String fs : planFieldSetNames) {
                if (Schema.SObjectType.Plan__c.fieldSets.getMap().get(fs) != null) {
                    List<Schema.FieldSetMember> fields = Schema.SObjectType.Plan__c.fieldSets.getMap().get(fs).getFields();
                    planFieldSetMemberList.addAll(fields);
                }
                if (Schema.SObjectType.Plan__c.fieldSets.getMap().get(fs + '_View') != null) {
                    List<Schema.FieldSetMember> fields = Schema.SObjectType.Plan__c.fieldSets.getMap().get(fs + '_View').getFields();
                    planFieldSetMemberList.addAll(fields);
                }
            }
            Set<String> fieldsToQueryPlan = new Set<String>();
            for(Schema.FieldSetMember f : planFieldSetMemberList) {
                fieldsToQueryPlan.add(f.getFieldPath().toLowerCase());
            }
            // The following fields are needed regardless the fieldset so we add them to the set because they might already be part of a fieldset
            // and we don't want to duplicate them
            fieldsToQueryPlan.addAll(new Set<String>{'service_name__c', 'service_label__c', 'display_sequence__c', 'field_set_name__c', 
                                'cti_call_identifier__c'});
            String planQuery = 'SELECT ';    
            for(String f : fieldsToQueryPlan) {
                planQuery += f + ', ';
            }
            planQuery += 'Id, Billing_Account__r.Billing_Account_Number__c, Billing_Account__r.Account_Type__c, Billing_Account__r.Product_Name_360__c, Billing_Account__r.CTI_Call_Identifier__c, Billing_Account__r.HBO_Max_Entitlement__c FROM Plan__c WHERE Billing_Account__c IN :accessibleBillingAccountIds AND Is_Deleted__c <> true WITH SECURITY_ENFORCED';
    
            // Build query for assets based on field sets from billing accounts
            List<Schema.FieldSetMember> assetFieldSetMemberList = new List<Schema.FieldSetMember>();
            for (String fs : assetFieldSetNames) {
                if (Schema.SObjectType.Asset.fieldSets.getMap().get(fs) != null) {
                    List<Schema.FieldSetMember> fields = Schema.SObjectType.Asset.fieldSets.getMap().get(fs).getFields();
                    assetFieldSetMemberList.addAll(fields);
                }
                if (Schema.SObjectType.Asset.fieldSets.getMap().get(fs + '_View') != null) {
                    List<Schema.FieldSetMember> fields = Schema.SObjectType.Asset.fieldSets.getMap().get(fs + '_View').getFields();
                    assetFieldSetMemberList.addAll(fields);
                }
            }
            Set<String> fieldsToQueryAsset = new Set<String>();
            for(Schema.FieldSetMember f : assetFieldSetMemberList) {
                fieldsToQueryAsset.add(f.getFieldPath().toLowerCase());
            }
            // The following fields are needed regardless the fieldset so we add them to the set because they might already be part of a fieldset
            // and we don't want to duplicate them
            fieldsToQueryAsset.addAll(new Set<String>{'service_name__c', 'service_label__c', 'display_sequence__c', 'field_set_name__c', 'status',
                                'cti_call_identifier__c', 'group_id__c', 'is_primary__c', 'manufacturer__c', 'make_and_model__c'});
            String assetQuery = 'SELECT ';
            for(String f : fieldsToQueryAsset) {
                assetQuery += f + ', ';
            }
            List<String> statusLst = BWC_Constants.EQUIPMENT_STATUSES;
            assetQuery += 'Id, Billing_Account__r.Billing_Account_Number__c, Billing_Account__r.Account_Type__c, Billing_Account__r.CTI_Call_Identifier__c, Billing_Account__r.HBO_Max_Entitlement__c, Billing_Account__r.PAH_Contact_Phone__c FROM Asset WHERE Billing_Account__c IN :accessibleBillingAccountIds AND Status in :statusLst AND Is_Deleted__c <> true WITH SECURITY_ENFORCED';

            List<Plan__c> sfPlans = Database.query(String.escapeSingleQuotes(planQuery));
            List<Asset> sfAssets = Database.query(String.escapeSingleQuotes(assetQuery));

            // Get the plan records and group by Service_Name__c formula field
            for (Plan__c plan : sfPlans) {

                // Ignore incorrect potsvoice records
                if (plan.Billing_Account__r.Product_Name_360__c == 'potsvoice' && String.isEmpty(plan.Plan_Name__c)) {
                    continue;
                }

                ServiceModel serviceModel = serviceModelMap.get(plan.Service_Name__c);
    
                // This group of Service doesnt exist. so create one.
                if (serviceModel == null) {
                    serviceModel = new ServiceModel();
                    serviceModel.ban = plan.Billing_Account__r.Billing_Account_Number__c;
                    serviceModel.accountType = plan.Billing_Account__r.Account_Type__c;                    
                    serviceModel.ctiCallIdentifier = plan.Billing_Account__r.CTI_Call_Identifier__c;
                    serviceModel.serviceName = plan.Service_Name__c;
                    serviceModel.serviceLabel = plan.Service_Label__c;
                    serviceModel.sequence = plan.Display_Sequence__c;
                    serviceModel.hboMaxFlag = plan.Billing_Account__r.HBO_Max_Entitlement__c;
                    serviceModelMap.put(plan.Service_Name__c, serviceModel);
                }
                serviceModel.planFieldSet = plan.Field_Set_Name__c;
                serviceModel.plans.add(plan);
            }

            // Get the equipments from Asset Object and group by Service_Name__c  formula field
            for (Asset asset : sfAssets) {
                ServiceModel serviceModel = serviceModelMap.get(asset.Service_Name__c);
                
                // This group of Service doesnt exist. so create one.
                if (serviceModel == null) {
                    serviceModel = new ServiceModel();
                    serviceModel.ban = asset.Billing_Account__r.Billing_Account_Number__c;
                    serviceModel.accountType = asset.Billing_Account__r.Account_Type__c;
                    serviceModel.ctiCallIdentifier = asset.Billing_Account__r.CTI_Call_Identifier__c;    
                    serviceModel.serviceName = asset.Service_Name__c;
                    serviceModel.serviceLabel = asset.Service_Label__c;
                    serviceModel.sequence = asset.Display_Sequence__c;
                    serviceModel.hboMaxFlag = asset.Billing_Account__r.HBO_Max_Entitlement__c;
                    serviceModelMap.put(asset.Service_Name__c, serviceModel);
                }
                serviceModel.equipmentFieldSet = asset.Field_Set_Name__c;
                serviceModel.equipments.add(asset);
            }
            
            // Get all the Services
            List<ServiceModel> serviceModels = serviceModelMap.values();

            // sort the services.
            serviceModels.sort();
    
            return serviceModels;
        }

    }

    /*
        Upsert Plan__c and Asset records based upon product search response.
    */
    public static void upsertPlansAndEquipments(
        String personAccountId,
        BWC_ProductSearch.ProductSearchResponse productResponse) {

        if (productResponse.accounts == null) {
            return;
        }

        // Collect the BAN's from the accounts
        Set<String> setBANs = new Set<String>();
        for (BWC_ProductSearch.AccountResponse acct : productResponse.accounts) {
            setBANs.add(acct.ban);
        }

        // Create the Map of BAN to Billing Accounts
        Map<String, Billing_Account__c> mapBANToBillingAccount = new Map<String, Billing_Account__c>();

        // 11-12-2020 Read CTI_Call_Identifier__c FROM Billing_Account
        for(Billing_Account__c billingAccount : [SELECT Id, Billing_Account_Number__c, CTI_Call_Identifier__c FROM Billing_Account__c WHERE Billing_Account_Number__c IN :setBANs]) {
            mapBANToBillingAccount.put(billingAccount.Billing_Account_Number__c, billingAccount);
        }

        upsertPlans(mapBANToBillingAccount, productResponse);
        upsertEquipments(personAccountId, mapBANToBillingAccount, productResponse);

        // Upsert plans for types that don't return service details
        List<Billing_Account__c> allBillingAccounts = BWC_BillingAccount.getBillingAccounts(personAccountId);
        List<Plan__c> plans = new List<Plan__c>();
        for (Billing_Account__c billingAccount : allBillingAccounts) {
            if (INVALID_PRODUCT_TYPES.contains(billingAccount.Product_Name_360__c)) {
                plans.add(generatePlanForInvalid(billingAccount));
            }
        }

    }
    
    // upsert the plans to SF Object Plan__c
    // 09-22-2020 Also Pass serviceResult so that we get to know if it was successful.
    private static void upsertPlans(
        Map<String, Billing_Account__c> mapBANToBillingAccount, 
        BWC_ProductSearch.ProductSearchResponse productResponse) {
        
        // The plans to upsert.
        List<Plan__c> listSFPlans = new List<Plan__c>();

        Set<String> setUniquePlans = new Set<String>();
        // Loop through the accounts
        for (BWC_ProductSearch.AccountResponse acct : productResponse.accounts) {

            // Get the Billing Account of this Plan
            Billing_Account__c billingAccount = mapBANToBillingAccount.get(acct.ban);
            BWC_ProductSearch.Details details = acct.details;

            if (billingAccount != null && acct.plans != null) {
                // Loop through the plans in the Account
                for (BWC_ProductSearch.Plan plan : acct.plans) {

                    // Create the Plan__c object
                    Plan__c sfPlan = new Plan__c();

                    // Set Billing Account lookup
                    sfPlan.Billing_Account__c = billingAccount.Id;

                    sfPlan.CTI_Call_Identifier__c = billingAccount.CTI_Call_Identifier__c;

                    // External Id is combination of Billing Account Id and Plan Name
                    sfPlan.Plan_Unique_Name__c = acct.ban + (plan.planName != null?plan.planName.trim():'');

                    // Reset any soft delete, because record is here even if previously soft-deleted
                    sfPlan.Is_Deleted__c = false;

                    sfPlan.Account_Status__c = plan.accountStatus;
                    //sfPlan.Account_Type__c = acct.accountType;
                    sfPlan.Contract_End_Date__c = BWC_Utils.parseDate(plan.contractEnd);

                    if(String.isNotBlank(plan.contractStartDate)){
                        sfPlan.Contract_Start_Date__c = BWC_Utils.parseDate(plan.contractStartDate);
                    }
                    if(String.isNotBlank(plan.contractEndDate)){
                        sfPlan.Contract_End_Date__c = BWC_Utils.parseDate(plan.contractEndDate);
                    }

                    if(String.isNotBlank(plan.policyId)){
                        sfPlan.Policy_ID__c = plan.policyId;
                    }

                    if(plan.subscribers != null){

                        String ctns = '';
                        for(BWC_ProductSearch.PlanSubscriber subscriber : plan.subscribers){

                            ctns+=subscriber.subscriberId;

                            if(subscriber.subscriberPlanName!=null){
                                ctns += ' - '+subscriber.subscriberPlanName + ' - MRC $'+subscriber.subscriberMonthlyCost;
                            }

                            ctns+='\n';
                        }
                        sfPlan.CTNs_on_Plan__c = ctns;
                    }
                
                    sfPlan.Highest_Available_Speed__c = plan.maxLimit;
                    sfPlan.Limit__c = plan.maxLimit;
                    sfPlan.Transport_Type__c = plan.transportType;
                    if(plan.monthlyCost!=null){
                        sfPlan.Monthly_Cost__c = Decimal.valueOf(plan.monthlyCost);
                    } else{
                        sfPlan.Monthly_Cost__c = 0.00;
                    }

                    sfPlan.Number_Of_Add_Ons__c = plan.numberOfAddOns;

                    sfPlan.Number_Of_Lines__c = plan.numberOfLines;
                    
                    sfPlan.Number_Of_Receivers__c = plan.numberOfReceivers;

                    sfPlan.Phone__c = plan.phone;
                    sfPlan.Plan_Name__c = plan.planName;
                    sfPlan.Product__c = plan.productName;
                    if(plan.productDescription!=null){
                        sfPlan.Product_Description__c = plan.productDescription.left(255);
                    }
                    sfPlan.Product_Type__c = plan.productType;
    
                    // 10-01-2020 if product is null use Account Type
                    if (sfPlan.Product__c == null) {
                        sfPlan.Product__c = sfPlan.AccountType__c;
                    }

                    sfPlan.Usage__c = plan.usage;
                    if(plan.baseAllowanceInformation!=null) sfPlan.Base_Allowance__c = plan.baseAllowanceInformation;
                    if(plan.buyerRemorseDate!=null) sfPlan.Buyer_Remorse_Date__c = Date.valueOf(plan.buyerRemorseDate);
                    if(plan.featureCodePrice!=null) sfPlan.Plan_Price_Code__c = plan.featureCodePrice;
                    if(plan.featureCode!=null) sfPlan.Plan_Code__c = plan.featureCode;
                    if(plan.featureEffectiveDate!=null) sfPlan.Plan_Effective_Date__c = BWC_Utils.parseDate(plan.featureEffectiveDate);
                    if(String.isNotBlank(plan.protectionPlanName)) sfPlan.Protection_Plan__c = plan.protectionPlanName;
                    if(plan.deviceProtection!=null) sfPlan.Device_Protection__c = plan.deviceProtection;

                    if(plan.productType == BWC_Constants.PLAN_PRODUCT_TYPE_VBP && details.TVReceiverWithDVRQty!=null){
                        sfPlan.Number_Of_Receivers__c = Integer.valueOf(details.TVReceiverWithDVRQty);
                    }

                    if(plan.productType==BWC_Constants.PLAN_PRODUCT_TYPE_IPTV){

                        if(details.freeReceiverQty!=null) sfPlan.Number_of_Free_Receivers__c = Integer.valueOf(details.freeReceiverQty);
                        if(details.TVReceiverQty!=null){
                            sfPlan.Number_Of_Receivers__c  = Decimal.valueOf(details.TVReceiverQty);
                            sfPlan.Number_of_TV_Receivers__c = Integer.valueOf(details.TVReceiverQty);
                        } 
                        if(details.TVReceiverWithDVRQty!=null) sfPlan.Number_of_TV_Receivers_With_DVR__c = Integer.valueOf(details.TVReceiverWithDVRQty);

                    }

                    //It means there's third party internet information
                    if(String.isNotBlank(plan.thirdPartyInternetName)){
                        sfPlan.Plan_Name__c = plan.thirdPartyInternetName;
                        sfPlan.Product__c = BWC_Constants.THIRD_PARTY_INTERNET;
                    }

                    // Add to list only if not already added to avoid duplicates while upserting.
                    if (!setUniquePlans.contains(sfPlan.Plan_Unique_Name__c)) {
                        listSFPlans.add(sfPlan);
                        setUniquePlans.add(sfPlan.Plan_Unique_Name__c);
                    }
                }
            }
            else {
                // The Billing Account is not found.
                // Log error.
            }
        }

        // Upsert the plans.
        if (listSFPlans.size() > 0) {
            upsert listSFPlans Plan_Unique_Name__c;
        } 

        // Soft delete any that are no longer present in service results
        List<Plan__c> plansToSoftDelete = BWC_Plan_Selector.getPlansToSoftDelete(mapBANToBillingAccount.values(), setUniquePlans);
        if (!plansToSoftDelete.isEmpty()) {
            for (Plan__c planToSoftDelete : plansToSoftDelete) {
                planToSoftDelete.Is_Deleted__c = true;
            }
            update plansToSoftDelete;
        }

    }

    /*
        Generate a dummy Plan__c object for a billing account whose type does not return service info.
    */
    private static Plan__c generatePlanForInvalid(Billing_Account__c billingAccount) {

        Plan__c sfPlan = new Plan__c();
        sfPlan.Billing_Account__c = billingAccount.Id;
        sfPlan.CTI_Call_Identifier__c = billingAccount.CTI_Call_Identifier__c;
        sfPlan.Plan_Unique_Name__c = billingAccount.Billing_Account_Number__c + 'Not Available';
        sfPlan.Plan_Name__c = 'Not Available';
        sfPlan.Product__c = 'POTS Voice';
        sfPlan.Monthly_Cost__c = null;
        return sfPlan;

    }

    private static void upsertEquipments(
        String personAccountId,
        Map<String, Billing_Account__c> mapBANToBillingAccount, 
        BWC_ProductSearch.ProductSearchResponse productResponse) {

        // The assets to upsert.
        List<Asset> listSFAssets = new List<Asset>();

        Map<String,BWC_ProductSearch.Subscriber> subsMap = new Map<String,BWC_ProductSearch.Subscriber>();
        Set<String> setUniqueAssets = new Set<String>();
        for (BWC_ProductSearch.AccountResponse acct : productResponse.accounts) {

            // Get the Billing Account of this asset
            Billing_Account__c billingAccount = mapBANToBillingAccount.get(acct.ban);
            /////////////////////
            ///Subscriber code start //10-29-2020
            if(acct.subscribers != null && acct.subscribers.size()>0) {
            for (BWC_ProductSearch.Subscriber subscriber : acct.subscribers) {

                subsMap.put(subscriber.subscriberId,subscriber);
                System.debug('*****'+subscriber.subscriberStatus);
                if(subscriber.subscriberStatus == 'Cancelled' || subscriber.subscriberStatus == 'Reserved'){
                    // Create the Asset object
                    Asset sfAsset = new Asset();
                    System.debug('inside cancelled or reserved');
                    // 11-12-2020 Set CTI_Call_Identifier__c on Asset
                    sfAsset.CTI_Call_Identifier__c = billingAccount.CTI_Call_Identifier__c;

                    sfAsset.Name = subscriber.subscriberId;
                    sfAsset.AccountId = personAccountId;

                    // Set Billing Account lookup
                    sfAsset.Billing_Account__c = billingAccount.Id;

                    sfAsset.Phone_Number__c = subscriber.subscriberId;
                    sfAsset.Mobile_Created_Date__c = BWC_Utils.parseDate(subscriber.subscriberSince);
                    sfAsset.Status = subscriber.subscriberStatus;
                    sfAsset.User__c = subscriber.subscriberName;

                    // External Id is combination of Billing Account Id and Phone
                    sfAsset.Equipment_Unique_Identifier__c = acct.ban + subscriber.subscriberId;
                    // Add to list only if not already added to avoid duplicates while upserting.
                    if (!setUniqueAssets.contains(sfAsset.Equipment_Unique_Identifier__c)) {
                        listSFAssets.add(sfAsset);
                        setUniqueAssets.add(sfAsset.Equipment_Unique_Identifier__c);
                    }
                }
            } //end of for loop
            }
            //subscriber code end //10-29-2020
        // Loop through the accounts

            ////////////////////
            if (billingAccount != null && acct.equipments != null) {

                // Loop through the equipments in the Account
                for (BWC_ProductSearch.Equipment equipment : acct.equipments) {

                    // Create the Asset object
                    Asset sfAsset = new Asset();

                    // 11-12-2020 Set CTI_Call_Identifier__c on Asset
                    sfAsset.CTI_Call_Identifier__c = billingAccount.CTI_Call_Identifier__c;

                    //11-4-2020 added equipmentId feature
                    if(equipment.phone != null && equipment.phone != '') {
                        sfAsset.Name = equipment.phone;
                        // External Id is combination of Billing Account Id and Phone
                         sfAsset.Equipment_Unique_Identifier__c = acct.ban + equipment.phone;
                         sfAsset.Phone_Number__c = equipment.phone;
                         sfAsset.Status = equipment.subStatus;
                    } else if(equipment.equipmentId != null && equipment.equipmentId != '') {
                        sfAsset.Name = equipment.equipmentId;
                        // External Id is combination of Billing Account Id and Phone
                        sfAsset.Equipment_Unique_Identifier__c = acct.ban + equipment.equipmentId;
                        sfAsset.Status = equipment.status;
                        sfAsset.Phone_Number__c = equipment.equipmentId;
                        sfAsset.Free_Receivers__c = BWC_Utils.getBoolean(equipment.isFreeReceiver);
                        sfAsset.Home_DVR__c = BWC_Utils.getBoolean(equipment.iswholeHomeDVR);
                        sfAsset.High_Definition__c = BWC_Utils.getBoolean(equipment.isHD);
                        sfAsset.TV_Receiver__c = BWC_Utils.getBoolean(equipment.isReceiver);
                        sfAsset.TV_Receiver_with_DVR__c  = BWC_Utils.getBoolean(equipment.isDVR);
                        sfAsset.Purchase_Terms__c = equipment.purchaseTerms;
                        sfAsset.Description = equipment.equipmentAttrDesc;
                    }
                    sfAsset.AccountId = personAccountId;

                    // Reset any soft delete, because record is here even if previously soft-deleted
                    sfAsset.Is_Deleted__c = false;

                    // Set Billing Account lookup
                    sfAsset.Billing_Account__c = billingAccount.Id;

                    // External Id is combination of Billing Account Id and Phone
                    //sfAsset.Equipment_Unique_Identifier__c = acct.ban + equipment.phone;

                   // set device type to Connected car else it is device. In future Mule will fix it
                    if (equipment.equipmentType == BWC_Constants.EQUIPMENT_TYPE_CONNECTED_CAR) {

                        sfAsset.Device_Type__c = 'Connected Car';

                        // Device is make and model
                        sfAsset.Device__c = BWC_Utils.appendString(equipment.vMake, equipment.vModel, ' ');
                        sfAsset.Vehicle_Trim__c =equipment.vTrim;
                        sfAsset.Vehicle_VIN__c = equipment.vin;
                        sfAsset.Vehicle_Year__c = equipment.vYear;
                        // sfAsset.Make_And_Model__c = BWC_Utils.appendString(equipment.vMake, equipment.vModel, ' ');
                        if(!String.isBlank(equipment.model)) sfAsset.Make_And_Model__c =  equipment.model;

                    }
                    else {
                        
                        if(equipment.equipmentType!=null){
                            sfAsset.Device_Type__c = equipment.equipmentType;
                        }

                        // Use device from response
                        if(equipment.equipmentId != null && equipment.manufacturer != null && equipment.modelNumber != null) {
                            sfAsset.Device__c = BWC_Utils.appendString(equipment.manufacturer, equipment.modelNumber, ' ');
                        } else {
                            sfAsset.Device__c = equipment.device;
                        }

                        if(!String.isBlank(equipment.manfName)) sfAsset.Manufacturer__c = equipment.manfName;
                        if(!String.isBlank(equipment.model)) sfAsset.Make_And_Model__c =  equipment.model;
                        

                    }
                    
                    if (equipment.deviceProtection != null) {
                        sfAsset.Device_Protection__c = equipment.deviceProtection;
                    }

                    sfAsset.Group_ID__c = equipment.groupId;
                    sfAsset.Installment__c = equipment.installments;
                    if(equipment.installmentAmount!=null) sfAsset.Installments_Amount__c = Decimal.valueOf(equipment.installmentAmount);
                    sfAsset.SIM__c = equipment.sim;
                    sfAsset.IMEI__c = equipment.imei;
                    
                    if(subsMap.containsKey(equipment.phone)){
                        BWC_ProductSearch.Subscriber subscriber = subsMap.get(equipment.phone);
                        sfAsset.ContractStart__c = BWC_Utils.parseDate(subscriber.contractStart);
                        sfAsset.ContractEnd__c = BWC_Utils.parseDate(subscriber.contractEnd);
                        sfAsset.ContractLength__c = subscriber.contractLength;
                        sfAsset.Mobile_Created_Date__c = BWC_Utils.parseDate(subscriber.subscriberSince);
                    } else {
                        sfAsset.ContractStart__c = BWC_Utils.parseDate(equipment.contractStart);
                        sfAsset.ContractEnd__c = BWC_Utils.parseDate(equipment.contractEnd);
                        sfAsset.ContractLength__c = equipment.contractLength;
                    }

                    // Set the Is_Primary__c field of Asset
                    if (equipment.isPrimary != null) {
                        sfAsset.Is_Primary__c = equipment.isPrimary;
                    }
                    
                    sfAsset.Receiver_Model__c = equipment.receiverModel;
                    sfAsset.Receiver_Type__c = equipment.receiverType;
                    sfAsset.Room__c = equipment.room;
                    sfAsset.SerialNumber = equipment.serialNumber;
                    sfAsset.Technology__c = equipment.technology;
                    sfAsset.Type__c = equipment.type_Z;
                    sfAsset.Upgrade__c = equipment.upgrade != null ? equipment.upgrade : false ;
                    sfAsset.User__c = equipment.user;
                    sfAsset.Warranty__c = equipment.warranty;
                    sfAsset.Subscriber_Plan_Name__c = equipment.subscriberPlanName;

                    if(equipment.parkInd != null) sfAsset.Parked_Equipment__c =  equipment.parkInd;
                    if(equipment.tradeInInd!=null) sfAsset.Trade_In_Devices__c = BWC_Utils.getBoolean(equipment.tradeInInd);
                    if(equipment.totalEarlyPayOfInstAmt!=null) sfAsset.Device_Pay_Off_Amount__c = DEcimal.valueOf(equipment.totalEarlyPayOfInstAmt);
                    if(equipment.etfAmount != null) sfAsset.Early_Termination_Fee__c = Decimal.valueOf(equipment.etfAmount);
                    if(equipment.payUpAmount!=null){
                        Decimal payupAmount = Decimal.valueOf(equipment.payUpAmount);
                        sfAsset.Pay_Up_Amount__c = payupAmount > 0 ? payupAmount : null;
                    }

                    if(!String.isBlank(equipment.billingProductCode)) sfAsset.Billing_Product_Code__c = equipment.billingProductCode;
                    if(!String.isBlank(equipment.contractType)) sfAsset.Contract_Type__c = equipment.contractType;

                    if(equipment.planIdentifier!=null){
                        Plan__c planReference = new Plan__c(Plan_Unique_Name__c=equipment.planIdentifier);
                        sfAsset.Plan__r = planReference;
                    } 

                    if(equipment.equipmentStatus!=null){
                        sfAsset.Equipment_Status__c = equipment.equipmentStatus;
                    }

                    //US-240
                    if(acct.accountType.equals(BWC_Constants.ACCOUNT_TYPE_DIRECTV)){
                        if(String.isNotBlank(sfAsset.Purchase_Terms__c)) sfAsset.Type__c = sfAsset.Purchase_Terms__c;
                        sfAsset.Receiver_Type__c = equipment.equipmentAttrDesc;
                        sfAsset.Receiver_Model__c = equipment.modelNumber;
                    }

                    if(!String.isBlank(equipment.subMarket)) sfAsset.Submarket__c = equipment.subMarket;
                    if(String.isNotBlank(equipment.modelNumber)) sfAsset.Model__c = equipment.modelNumber;

                    if(String.isNotBlank(equipment.location)){
                        sfAsset.Location__c = equipment.location;
                    }
                    

                    // Add to list only if not already added to avoid duplicates while upserting.
                    if (!setUniqueAssets.contains(sfAsset.Equipment_Unique_Identifier__c)  && sfAsset.Name != null) {
                        listSFAssets.add(sfAsset);
                        setUniqueAssets.add(sfAsset.Equipment_Unique_Identifier__c);
                    }
                } //end of for loop
                
            }
            else {
                // The Billing Account is not found.
                // Log error.
            }
        }

        // Upsert the assets.
        if (listSFAssets.size() > 0) {
            upsert listSFAssets Equipment_Unique_Identifier__c;
        }

        // Soft delete any that are no longer present in service results
        List<Asset> assetsToSoftDelete = BWC_Asset_Selector.getAssetsToSoftDelete(mapBANToBillingAccount.values(), setUniqueAssets);
        if (!assetsToSoftDelete.isEmpty()) {
            for (Asset assetToSoftDelete : assetsToSoftDelete) {
                assetToSoftDelete.Is_Deleted__c = true;
            }
            update assetsToSoftDelete;
        }

    }

    public inherited sharing class GetSOCCodeService extends BWC_InteractionServiceBase {

        public BWC_ProductSearch.ProductSearchResponse response;

        public GetSOCCodeService(Id interactionId, Id billingAccountId) {

            super(interactionId, billingAccountId);            
            this.buildRequest();

        }

        private void buildRequest() {

            // Create the payload to get Product Details from Mulesoft.
            List<BWC_ProductSearch.ProductSearchRequest> productSearchRequests = new List<BWC_ProductSearch.ProductSearchRequest>();

            BWC_ProductSearch.ProductSearchRequest request = new BWC_ProductSearch.ProductSearchRequest();
            request.topics = 'plans,equipments';
            request.customerId = this.billingAccount.Billing_Account_Number__c;
            request.accountId = this.billingAccount.Billing_Account_Number__c;
            request.accountType = this.billingAccount.Account_Type__c;
            productSearchRequests.add(request);

            // Create the callout instance
            this.callout = new BWC_ProductSearchCallout.ProductSearchCallout(productSearchRequests);

        }

        public override Object buildResponse() {

            if (this.callout == null) {
                // No callout was needed, just return the response that's already built
                return this.response;
            }

            this.response = (BWC_ProductSearch.ProductSearchResponse)this.callout.getResponse();
            return this.response;

        }

    }

    public inherited sharing class ServiceModelWrapper extends BWC_Service.ServiceResponse {
        public List<ServiceModel> results;
        public String prefetchStatus;   // "In Process", "Succeeded", "Failed"
        public String message = '';
    }

    public inherited sharing class ServiceModel implements Comparable {

        public String ban;
        public String accountType;
        public String unifiedBan;

        // 11-12-2020 CTI_Call_Identifier__c from Billing Account
        public String ctiCallIdentifier;

        // The unique name of this Service
        public String serviceName;

        // The label of this Service
        public String serviceLabel;

        // THe name of te field set for the Plan records
        public String planFieldSet;

        // THe name of te field set for the Asset records
        public String equipmentFieldSet;

        // The display seaquence for this Service
        public Decimal sequence;
        
        // List of Asset records
        public List<Asset> equipments;

        // List of Plan records
        public List<Plan__c> plans;

        // Error associated with getting plans
        public BWC_MuleServiceError planserror;

        // Error associated with getting equipment
        public BWC_MuleServiceError equipmentserror;

        public String serviceTypeName;

        public Boolean hboMaxFlag;

        public ServiceModel() {
            equipments = new List<Asset>();
            plans = new List<Plan__c>();
        }

        // Implement the compareTo() method
        // The Display Seuence field from Asset or Plan is used to sort the Services in a List.
        // The following method is used to compare, when the sort method on the list is called.
        public Integer compareTo(Object compareTo) {
            // Use sequence field to sort the Services
            ServiceModel compareToServiceModel = (ServiceModel)compareTo;
            if (sequence == compareToServiceModel.sequence) return 0;
            if (sequence > compareToServiceModel.sequence) return 1;
            return -1;        
        }
    }

    /*
        Start async prefetch search to reduce agent wait.
    */
    public static void queueProductSearch(Interaction__c interaction) {

        // Make sure prefetch is not already ongoing
        String status = BWC_PrefetchCacheManager.getStatus(interaction.CTI_Call_Identifier__c, BWC_PrefetchCacheManager.TYPE_PRODUCT_SEARCH);
        if (status == BWC_PrefetchCacheManager.STATUS_IN_PROCESS && status == BWC_PrefetchCacheManager.STATUS_SUCCEEDED) {
            // Not needed, prefetch in process or done
            return;
        }

        // Now set prefetch status to In Progress so any other caller does not try to do duplicate search
        BWC_PrefetchCacheManager.putStatus(interaction.CTI_Call_Identifier__c, BWC_PrefetchCacheManager.TYPE_PRODUCT_SEARCH, BWC_PrefetchCacheManager.STATUS_IN_PROCESS);

        // Queue the search
        System.enqueueJob(new ProductSearchQueable(interaction.Id));

    }

    /*
        Queueable to support background product search. 
    */
    public inherited sharing class ProductSearchQueable implements Queueable, Database.AllowsCallouts {

        public Id interactionId;
        public Interaction__c interaction;

        public ProductSearchQueable(Id interactionId) {
            this.interactionId = interactionId;
        }

        public void execute(QueueableContext context) {

            try {

                // Do product search, force refresh so caching is not checked
                GetProductsService service = new GetProductsService(this.interactionId, null, true);
                this.interaction = service.interaction;
                ServiceModelWrapper response = (ServiceModelWrapper)service.call();

                // Success, update cache
                BWC_PrefetchCacheManager.putStatus(
                    this.interaction.CTI_Call_Identifier__c, BWC_PrefetchCacheManager.TYPE_PRODUCT_SEARCH, BWC_PrefetchCacheManager.STATUS_SUCCEEDED);

            }
            catch (System.Exception e) {

                // Failure
                BWC_PrefetchCacheManager.putStatus(
                    this.interaction.CTI_Call_Identifier__c, BWC_PrefetchCacheManager.TYPE_PRODUCT_SEARCH, BWC_PrefetchCacheManager.STATUS_FAILED);

                // Log
                BWC_Log.logException(e, BWC_Log.CATEGORY_QUEUEABLE, new BWC_Log.Context('interactionId', this.interactionId), this.interactionId);

            }

        }

    }

}
public with sharing class BWC_ProductSearchController {

    @AuraEnabled(continuation = true)
    public static Object getProductsGroupedByServiceCont(String recordId, List<Id> billingAccountIds, Boolean forceRefresh) {

        Map<String, String> authorizationsByBan = new Map<String, String>();

        try {

            BWC_ProductSearchService.GetProductsService service = new BWC_ProductSearchService.GetProductsService(recordId, billingAccountIds, forceRefresh);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'getProductsGroupedByServiceResp';
                return response;
            }

            // Continuation wasn't needed
            BWC_ProductSearchService.ServiceModelWrapper serviceWrapper = (BWC_ProductSearchService.ServiceModelWrapper)response;
            if (serviceWrapper.prefetchStatus == BWC_PrefetchCacheManager.STATUS_IN_PROCESS) {
                // Prefetch is in progress, just return that status
                BWC_ProductSearchResultWrapper wrapper = new BWC_ProductSearchResultWrapper();
                wrapper.prefetchStatus = BWC_PrefetchCacheManager.STATUS_IN_PROCESS;
                wrapper.message = serviceWrapper.message;
                return wrapper;
            }
            else {
                // No ongoing prefetch, return the results
                List<BWC_ProductSearchService.ServiceModel> serviceModels = serviceWrapper.results;
                return getProductsGroupedByServiceBuildResponse(service, serviceModels);
            }

        }
        catch (System.Exception e) {

            // Log the exception
            BWC_ExceptionUtils.handleException(e, 'recordId: ' + recordId, null);

            // Return error with message
            BWC_ProductSearchResultWrapper searchResult = new BWC_ProductSearchResultWrapper();
            searchResult.success = false;
            searchResult.message = e.getMessage();
            return searchResult;

        }

    }

    @AuraEnabled
    public static BWC_ProductSearchResultWrapper getProductsGroupedByServiceResp(List<String> labels, Object state) {

        BWC_ProductSearchService.GetProductsService service = (BWC_ProductSearchService.GetProductsService)state;

        try {

            BWC_ProductSearchService.ServiceModelWrapper serviceWrapper = (BWC_ProductSearchService.ServiceModelWrapper)service.processContinuationResponse();
            List<BWC_ProductSearchService.ServiceModel> serviceModels = serviceWrapper.results;
            return getProductsGroupedByServiceBuildResponse(service, serviceModels);

        }
        catch (System.Exception e) {
            // Log the exception
            BWC_ExceptionUtils.handleException(e, 'recordId: ' + service.interactionId, null);

            // Return error with message
            BWC_ProductSearchResultWrapper searchResult = new BWC_ProductSearchResultWrapper();
            searchResult.success = false;
            searchResult.message = e.getMessage();
            return searchResult;
        }

    }

    /*
        This builds the final controller response based upon the response from the service call.
    */
    private static BWC_ProductSearchResultWrapper getProductsGroupedByServiceBuildResponse(
        BWC_ProductSearchService.GetProductsService searchService, List<BWC_ProductSearchService.ServiceModel> serviceModels) {

        BWC_ProductSearchResultWrapper searchResult = new BWC_ProductSearchResultWrapper();
        
        // Get Map of all the field sets of Plan__c and Asset
        Map<String, Schema.FieldSet> planFieldSetMap = Schema.SObjectType.Plan__c.fieldSets.getMap();
        Map<String, Schema.FieldSet> equipmentFieldSetMap = Schema.SObjectType.Asset.fieldSets.getMap();

        // Loop through each service
        for(BWC_ProductSearchService.ServiceModel serviceModel : serviceModels) {

            // Attempt to determine authorization level
            String authorizationLevel;
            String unifiedAuthorizationLevel;
            if (FeatureManagement.checkPermission('Bypass_Interaction_Authorization')) {

                // User has permission override and gets L1
                authorizationLevel = BWC_Constants.AUTHORIZATION_LEVEL_L1;
                unifiedAuthorizationLevel = BWC_Constants.AUTHORIZATION_LEVEL_L1;

            }
            else if (searchService.interaction != null) {

                authorizationLevel = searchService.getAuthorizationLevel(serviceModel.ban);

                if (authorizationLevel == null) {
                    // If we're on an interaction and for some reason auth level is unknown, assume L0 for minimal access
                    authorizationLevel = BWC_Constants.AUTHORIZATION_LEVEL_L0;
                }

                if (String.isNotBlank(serviceModel.unifiedBan)) {

                    unifiedAuthorizationLevel = searchService.getAuthorizationLevel(serviceModel.ban);
                    if (unifiedAuthorizationLevel == null) {
                        unifiedAuthorizationLevel = BWC_Constants.AUTHORIZATION_LEVEL_L0;
                    }

                }

            }
            else {

                // We're on person account, we don't really use auth level in that context so just set to L1
                authorizationLevel = BWC_Constants.AUTHORIZATION_LEVEL_L1;
                unifiedAuthorizationLevel = BWC_Constants.AUTHORIZATION_LEVEL_L1;

            }

            BWC_ProductSearchResultWrapper.Service service = new BWC_ProductSearchResultWrapper.Service();
            service.ban = serviceModel.ban;
            service.accountType = serviceModel.accountType;
            service.unifiedBan = serviceModel.unifiedBan;
            service.serviceName = serviceModel.serviceName;
            service.authorizationLevel = authorizationLevel;
            service.serviceTypeName = serviceModel.serviceTypeName;
            service.authorizationLevelUnifiedBan = unifiedAuthorizationLevel;
            service.serviceLabel = service.serviceLabel();
            service.hboMaxFlag = serviceModel.hboMaxFlag;
            service.maskedBan = service.getMaskedBan();
            // Get the plans in the current service.
            // Only the fields specified in the field set is returned
            // THe name of the fieldset to use is specified in serviceModel.planFieldSet
            if (serviceModel.plans != null && !serviceModel.plans.isEmpty()) {
                service.plans = getRecordsUsingFieldSet(serviceModel.plans, serviceModel.planFieldSet, planFieldSetMap);
                service.hasPlanPackages = true;
            }
            else {
                service.hasPlanPackages = false;
            }

            // Sort the equipments based on Group Id and Phone Number with Primary Group at the Top.
            // Show Devices only for wireless
            service.hasEquipment = false;
            if (serviceModel.accountType != null && serviceModel.accountType.equalsIgnoreCase('wireless')) {
                if (serviceModel.equipments != null && !serviceModel.equipments.isEmpty()) {

                    serviceModel.equipments = BWC_EquipmentGroupSortUtil.groupSort(serviceModel.equipments);
                    service.hasEquipment = true;

                    // Get the equipments in the current service.
                    // Only the fields specified in the field set is returned
                    // THe name of the fieldset to use is specified in serviceModel.equipmentFieldSet
                    if(serviceModel.equipmentFieldSet == 'Wireless') {
                        populateBANMap(serviceModel.equipments);
                        service.equipments = getRecordsUsingFieldSet(serviceModel.equipments, serviceModel.equipmentFieldSet, equipmentFieldSetMap);
                    }

                }
            }

            service.planserror = serviceModel.planserror;
            service.equipmentserror = serviceModel.equipmentserror;

            // Hide anything based on L0 authorization
            applyAuthorizationRules(service);

            searchResult.services.add(service);
        }

        searchResult.success = true;

        return searchResult;

    }

    private static Map<Id, Billing_Account__c> billingAccountMap = new Map<Id, Billing_Account__c>();

    /*
        Hide / remove data based upon authorization.
    */
    private static final Set<String> UVERSE_ALLOWED_FIELDS = new Set<String> {
        'Billing_Account__c', 'BAN__c', 'Product__c'
    };
    private static void applyAuthorizationRules(BWC_ProductSearchResultWrapper.Service service) {

        if (BWC_Constants.AUTHORIZATION_LEVELS_L1_PRIVILEGED.contains(service.authorizationLevel)) {

            // Nothing hidden for L1 OR Bypass
            return;

        }
        else if (service.authorizationLevel == BWC_Constants.AUTHORIZATION_LEVEL_L0) {

            service.isHidden = true;

        }
        else {
            throw new BWC_Exception('Unexpected authorizationLevel: ' + service.authorizationLevel);
        }

        if (service.isHidden == true) {

            service.plans = null;
            service.hasPlanPackages = null;
            service.equipments = null;
            service.hasEquipment = false;

        }

    }

    /*
    Returns the records of the SObject records in parameter sObjects.
    Only the fields specified in the fieldset name in parameter fieldSetName are returned for each record.
    */
    private static List<BWC_ProductSearchResultWrapper.Record> getRecordsUsingFieldSet(List<SObject> sObjects, String fieldSetName, Map<String, Schema.FieldSet> fieldSetMap) {

        List<BWC_ProductSearchResultWrapper.Record> records = new List<BWC_ProductSearchResultWrapper.Record>();

        if (sObjects.size() > 0) {
            // Get the fieldset to use from the map fieldSetMap
            Schema.FieldSet fieldSet = fieldSetMap.get(fieldSetName);

            // Get the fields in the fieldset
            List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();

            for(SObject row : sObjects) {
                BWC_ProductSearchResultWrapper.Record record = new BWC_ProductSearchResultWrapper.Record();

                BWC_ProductSearchResultWrapper.Field field;

                // Add field to the record.
                // Only add the fields specified in the field set
                for (Schema.FieldSetMember fsm : fieldSetMembers) {
                    field = new BWC_ProductSearchResultWrapper.Field();
                    field.fieldName = fsm.getFieldPath();
                    field.fieldLabel = fsm.getLabel();
                    field.fieldValue = row.get(field.fieldName);

                    record.fields.add(field);
                }

                // 01-08-2021
                // Add Id field
                field = new BWC_ProductSearchResultWrapper.Field();
                field.fieldName = 'Id';
                field.fieldLabel = 'Id';
                field.fieldValue = row.get('Id');
                record.fields.add(field);

                // If this is Equipment Object,
                // Add field Is_Primary and Status (without __c)
                // These two fields are used for UI settings.
                // Value of Is_Primary will be true if phoneNumber is equals to PAH Contact phone on billing account
                // Value of Status will be same as Status
                if (row.getsObjectType() == Asset.sObjectType) {

                    Billing_Account__c billingAccount = (Billing_Account__c) row.getSObject('Billing_Account__r');

                    if(billingAccount != null){

                        String phoneNumber = (String) row.get('Phone_Number__c');
                        field = new BWC_ProductSearchResultWrapper.Field();
                        field.fieldName = 'Is_Primary';
                        field.fieldLabel = 'Is_Primary';
                        field.fieldValue = phoneNumber == billingAccount.PAH_Contact_Phone__c;
                        record.fields.add(field);

                    }

                    field = new BWC_ProductSearchResultWrapper.Field();
                    field.fieldName = 'Status';
                    field.fieldLabel = 'Status';
                    field.fieldValue = row.get('Status');
                    record.fields.add(field);

                    record.fields.addAll(addAdditionalFields(row));
                }
                records.add(record);
            }
        }

        return records;
    }

    @AuraEnabled(continuation = true)
    public static Object getSOCCodeCont(Id interactionId, Id billingAccountId) {

        SOCCodeResultWrapper searchResult = new SOCCodeResultWrapper();
        searchResult.success = false;

        try {
            BWC_ProductSearchService.GetSOCCodeService service = new BWC_ProductSearchService.GetSOCCodeService(interactionId, billingAccountId);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'getSOCCodeResp';
                return response;
            }

            // Continuation wasn't needed
            BWC_ProductSearch.ProductSearchResponse productSearchResponse = (BWC_ProductSearch.ProductSearchResponse)response;
            searchResult.resultJSON = JSON.serialize(productSearchResponse);
            searchResult.success = true;

        }
        catch (System.Exception e) {
            // Log the exception
            BWC_ExceptionUtils.handleException(e, 'interactionId: ' + interactionId + ' billingAccountId: ' + billingAccountId, null);

            // Return error with message
            searchResult.success = false;
            searchResult.message = e.getMessage();
        }

        return searchResult;
    }

    @AuraEnabled
    public static SOCCodeResultWrapper getSOCCodeResp(List<String> labels, Object state) {

        SOCCodeResultWrapper searchResult = new SOCCodeResultWrapper();
        searchResult.success = false;
        BWC_ProductSearchService.GetSOCCodeService service = (BWC_ProductSearchService.GetSOCCodeService)state;

        try {

            BWC_ProductSearch.ProductSearchResponse productSearchResponse = (BWC_ProductSearch.ProductSearchResponse)service.processContinuationResponse();
            searchResult.resultJSON = JSON.serialize(productSearchResponse);
            searchResult.success = true;

        }
        catch (System.Exception e) {
            // Log the exception
            BWC_ExceptionUtils.handleException(e, 'interactionId: ' + service.interactionId + ' billingAccountId: ' + service.billingAccountId, null);

            // Return error with message
            searchResult.success = false;
            searchResult.message = e.getMessage();        
        }

        return searchResult;

    }

    private static List<BWC_ProductSearchResultWrapper.Field> addAdditionalFields(SObject row){
        List<BWC_ProductSearchResultWrapper.Field> fields = new List<BWC_ProductSearchResultWrapper.Field>();

        BWC_ProductSearchResultWrapper.Field field;

        field = new BWC_ProductSearchResultWrapper.Field();
        field.fieldName = 'Manufacturer__c';
        field.fieldLabel = 'Manufacturer';
        field.fieldValue = row.get('Manufacturer__c');
        fields.add(field);

        field = new BWC_ProductSearchResultWrapper.Field();
        field.fieldName = 'Make_And_Model__c';
        field.fieldLabel = 'Make And Model';
        field.fieldValue = row.get('Make_And_Model__c');
        fields.add(field);

        String banId = (String) row.get('Billing_Account__c');
        if(!String.isBlank(banId) && billingAccountMap.containsKey(banId)){
            Billing_Account__c ban = billingAccountMap.get(banId);
            field = new BWC_ProductSearchResultWrapper.Field();
            field.fieldName = 'Product_Name_360__c';
            field.fieldLabel = 'Product Name 360';
            field.fieldValue = ban.Product_Name_360__c;
            fields.add(field);
        }

        return fields;
    }

    /**
     *Populate Billing Account map used to add additional information to Asset fields
    */
    private static void populateBANMap(List<SObject> Assets){
        Set<Id> banIdSet = new Set<Id>();
        for(SObject asst : Assets){
            String banId = (String)asst.get('Billing_Account__c');
            if(!String.isBlank(banId)){
                banIdSet.add(banId);
            }
        }

        billingAccountMap = new Map<Id, Billing_Account__c>([SELECT
            Id,
            Product_Name_360__c
            FROM Billing_Account__c
            WHERE Id=:banIdSet
            WITH SECURITY_ENFORCED
        ]);
    }

    public class SOCCodeResultWrapper {

           @AuraEnabled
           public String resultJSON {get; set;}
           @AuraEnabled
           public Boolean success {get; set;}
           @AuraEnabled
           public String message {get; set;}
   }

}
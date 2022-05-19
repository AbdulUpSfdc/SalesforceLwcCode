/* ================================================
* @author : Shoukat Khan
* @date :   09/14/2020   
* @group : Product Search 
* @description : Wrapper class to return result to bwcProductList lwc compoenent
================================================*/
public with sharing class BWC_ProductSearchResultWrapper {
    
    // boolean to specify if the search is successful
    @AuraEnabled
    public Boolean success {get; set;}

    // error message
    @AuraEnabled
    public String message {get; set;}

    // The products grouped by services
    @AuraEnabled
    public List<Service> services {get; set;}

    // Prefetch status
    @AuraEnabled
    public String prefetchStatus {get; set;}   // "In Process", "Succeeded", "Failed"

    public BWC_ProductSearchResultWrapper() {
        this.success = false;
        this.services = new List<Service>();
    }

    /*
    This class represents one Service (such as Wireless, Internet, DTV etc.) of a Person Account.
    The service has plans and equipments.
    */
    public class Service {
        public Service() {
            this.plans = new List<Record>();
            this.equipments = new List<Record>();
        }

        // Billing account number
        @AuraEnabled
        public String ban {get; set;}

        @AuraEnabled
        public String accountType {get; set;}

        @AuraEnabled
        public String unifiedBan {get; set;}

        // The unique name of the service
        @AuraEnabled
        public String serviceName {get; set;}

        // The label of the service to show on the UI
        @AuraEnabled
        public String serviceLabel {get; set;}

        // Boolean to specify if this service has plans
        @AuraEnabled
        public Boolean hasPlanPackages {get; set;}

        // Boolean to specify if this service has equipments
        @AuraEnabled
        public Boolean hasEquipment {get; set;}

        // The list of plans (only the fileds specified in fieldset for this plans is returned)
        @AuraEnabled
        public List<Record> plans {get; set;}

        // The list of equipments (only the fileds specified in fieldset for this equipments is returned)
        @AuraEnabled
        public List<Record> equipments {get; set;}

        // L0 or L1 authorization level for the BAN
        @AuraEnabled
        public String authorizationLevel {get; set;}

        // Indicates whether whole service is hidden based upon authorization
        @AuraEnabled
        public Boolean isHidden {get; set;}

        // Error regarding getting plans
        @AuraEnabled
        public BWC_MuleServiceError planserror {get; set;}

        // Error regarding getting equipment
        @AuraEnabled
        public BWC_MuleServiceError equipmentserror {get; set;}

        @AuraEnabled
        public String serviceTypeName;

        @AuraEnabled
        public String authorizationLevelUnifiedBan;

        @AuraEnabled
        public Boolean hboMaxFlag;

        @AuraEnabled
        public String maskedBan;

        public String serviceLabel(){

            String currentBan = BWC_Constants.AUTHORIZATION_LEVELS_L1_PRIVILEGED.contains(authorizationLevel) ? ban : BWC_BillingAccount.maskBan(ban);
            String currentUnified = BWC_Constants.AUTHORIZATION_LEVELS_L1_PRIVILEGED.contains(authorizationLevelUnifiedBan) ? unifiedBan : BWC_BillingAccount.maskBan(unifiedBan);

            if(String.isNotBlank(currentUnified) && serviceTypeName.toLowerCase().equals(BWC_Constants.ACCOUNT_TYPE_WIRELESS)){
                String template = 'Wireless - {0} (Unified - {1})';
                List<Object> params = new List<Object>{currentBan, currentUnified};
                return String.format(template, params);
            }

            String template = '{0} - {1}';
            List<Object> params = new List<Object>{serviceTypeName, currentBan};

            return String.format(template,params);
        }

        public String getMaskedBan(){
            return BWC_Constants.AUTHORIZATION_LEVELS_L1_PRIVILEGED.contains(authorizationLevel) ? ban : BWC_BillingAccount.maskBan(ban);
        }

    }

    /*
    This class represents one record of an object.
    It has list of fields in it.
    */
    public class Record {
        public Record() {
            this.fields = new List<Field>();
        }
        @AuraEnabled
        public List<Field> fields {get; set;}
    }

    /*
    This class represents one field in a record.
    It has field name, label and value.
    */
    public class Field {

        @AuraEnabled
        public String fieldName {get; set;}

        @AuraEnabled
        public String fieldLabel {get; set;}

        @AuraEnabled
        public Object fieldValue {get; set;}

        @AuraEnabled
        public Boolean isHidden {get; set;}

    }
}
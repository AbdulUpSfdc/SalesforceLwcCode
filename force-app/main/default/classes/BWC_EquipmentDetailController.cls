public with sharing class BWC_EquipmentDetailController {

    @AuraEnabled
    public static String getEquipmentDetails(String recordId){
        RecordDetailsWrapper result = new RecordDetailsWrapper();
        List<RecordDetails> rdList = new List<RecordDetails>();

        // equipments are stored in Asset object
        List<Asset> equipLst;
        try{

            if(recordId!=null){
                equipLst = getEquipmentList(recordId);
            }

            if(equipLst!=null && equipLst.size()>0){

                // 10-05-2020 Moved from above inside this if after checking for equipLst
                Map<String, Schema.FieldSet> fieldSetMap =
                            Schema.SObjectType.Asset.fieldSets.getMap();
                String fieldSetName = equipLst[0].Field_Set_Name_View__c;
                Schema.FieldSet fieldSet = fieldSetMap.get(fieldSetName);
                List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
                List<String> fields = new List<String>();
                for (Schema.FieldSetMember fsm : fieldSetMembers) {
                    fields.add(fsm.getFieldPath());
                }


                for(Asset e:equipLst){
                    if(e.Status=='Active'){
                        RecordDetails rd = new RecordDetails();
                        rd.recordId = e.Id;
                        rd.phone = e.Phone_Number__c;
                        rd.device = e.Device__c;
                        rd.fields  = fields;

                        // 11-16-2020
                        rd.ban = e.Billing_Account__r.Billing_Account_Number__c;
                        rd.accountType = e.Billing_Account__r.Account_Type__c;
                        rd.receiverModel = e.Receiver_Model__c;
                        rd.deviceType = e.Device_Type__c;
                        rd.description = e.Description;
                        rd.status = e.Status;
                        rdList.add(rd);
                    }
                }
            }
            result.success = true;
            result.recordDetails = rdList;
        } catch (Exception e){
            System.debug('Exception :'+e);
            BWC_ExceptionUtils.handleException(e, 'billingAccountId: ' + recordId, null);
            result.message = e.getMessage();
            result.success = false;
        }
        return JSON.serialize(result);
    }

    @AuraEnabled(cacheable=true)
    public static List<Asset> getEquipmentSummaryDetails(String recordId){
        List<Asset> equipLst = getEquipmentList(recordId);
        system.debug('Anshul see result'+equipLst);
        return equipLst;
    }

    public class RecordDetails{
        public String recordId;
        public String phone;
        public String device;
        public List<String> fields;

        // 11-16-2020
        public String ban;
        public String accountType;
        public String receiverModel;
        public String deviceType;
        public String description;
        public String status;
        public RecordDetails(){}
    }

    public class RecordDetailsWrapper {

        public Boolean success {get; set;}
        public String message {get; set;}

        public List<RecordDetails> recordDetails;

    }

    // Get equpments stored in Asset record.
    private static List<Asset> getEquipmentList(Id billingAccountId){
        if(billingAccountId!=null){
            // 11-16-2020
            List<Asset> equipLst = BWC_Asset_Selector.getAssetsForBillingAccounts(new Set<Id>{billingAccountId});

            if(!equipLst.isEmpty()){
                return  equipLst;
            } else {
                return null;
            }
        } else {
            return null;
        }
    }

}
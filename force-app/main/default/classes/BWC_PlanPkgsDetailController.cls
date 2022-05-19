public with sharing class BWC_PlanPkgsDetailController {
    
    @AuraEnabled
    public static String getPlanPkgsDetail(String recordId){

        RecordDetailsWrapper result = new RecordDetailsWrapper();

        try {

            List<Plan__c> planLst = getPlanList(recordId);
            Map<String, Schema.FieldSet> fieldSetMap = Schema.SObjectType.Plan__c.fieldSets.getMap();
            Schema.FieldSet fieldSet;
            List<String> fields = new List<String>();
            if(planLst != null && planLst.size() > 0) {
                String recType = planLst[0].Field_Set_Name_View__c;
                if(recType != null && recType != ''){
                    fieldSet = fieldSetMap.get(recType);
                }else {
                    fieldSet = fieldSetMap.get(BWC_Constants.BillingAccount_AccountType_Wireless);
                } 
                List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields(); 
                for (Schema.FieldSetMember fsm : fieldSetMembers) {
                    fields.add(fsm.getFieldPath());
                }        
            } 
            
            List<RecordDetails> rdList = new List<RecordDetails>();
            for(Plan__c e:planLst){
                RecordDetails rd = new RecordDetails();
                rd.recordId = e.Id;
                rd.planName = e.Plan_Name__c;
                rd.fields  = fields;
                rdList.add(rd);
            }

            result.success = true;
            result.recordDetails = rdList;

        }
        catch(System.Exception e) {

            // Return error message in wrapper
            BWC_ExceptionUtils.handleException(e, 'billingAccountId: ' + recordId, null);
            result.message = e.getMessage();
            result.success = false;

        }

        // Return serialized wrapper with result and/or error
        return JSON.serialize(result);

    }

    public class RecordDetailsWrapper {

        public Boolean success {get; set;}
        public String message {get; set;}

        public List<RecordDetails> recordDetails;

    }

    public class RecordDetails{
        public String recordId;
        public String planName;
        //String device;
        public List<String> fields;
        public RecordDetails(){}
    }

    private static List<Plan__c> getPlanList(String billingAccountId){
        if(billingAccountId != null){
            List<Plan__c> planLst = BWC_Plan_Selector.getPlansForBillingAccounts(new Set<Id>{billingAccountId});
            if(!planLst.isEmpty()){                            
                return planLst;  
            } else {
                return null;
            }     
        } else {
            return null;
        }         
    }
}
public with sharing class BWC_PlanDetailController {

    @AuraEnabled
    public static String getBillingAccount(String recordId){
        Billing_Account__c plan;
        RecordDetails rd = new RecordDetails();
        
        try {       
            if(recordId!=null) {
                plan = [SELECT Field_Set_Name__c   
                    FROM Billing_Account__c
                    WHERE Id=:recordId];
            }
            
            List<Schema.FieldSetMember> fieldSetMembers;
            if(plan!=null && plan.Field_Set_Name__c != null && plan.Field_Set_Name__c != ''){
                Map<String, Schema.FieldSet> fieldSetMap = Schema.SObjectType.Billing_Account__c.fieldSets.getMap();
                Schema.FieldSet fieldSet = fieldSetMap.get(plan.Field_Set_Name__c);
                fieldSetMembers = fieldSet.getFields();
            }
            
            rd.recordId = recordId;
            rd.fields = new List<String>();
            if(fieldSetMembers != null && fieldSetMembers.size() > 0) {
                for (Schema.FieldSetMember fsm : fieldSetMembers) {
                    rd.fields.add(fsm.getFieldPath());
                }
            }
            rd.success = true;  
        } catch (Exception e) {
            BWC_ExceptionUtils.handleException(e, 'billingAccountId: ' + recordId, null);
            rd.message = e.getMessage();
            rd.success = false;    
        }
        
        return JSON.serialize(rd);
    }

    public class RecordDetails{
        public String recordId;
        List<String> fields;
        public Boolean success {get; set;}
        public String message {get; set;}
    }
}
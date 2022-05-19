public with sharing class BWC_CaseEscalationDetailController {

    private static String CASE_API_NAME = 'Case';
    private static String CTN_FIELD_SET_NAME = 'CaseCTNFields';
    private static Schema.DescribeSObjectResult caseDescribeResult;
    private static Map<String, String> caseActionFieldsetMap = new Map<String, String>();

    @AuraEnabled
    public static String getCaseActionFieldSet(String caseId, String caseAction){

        caseActionFieldsetMap = getEscalationMetadataMap();
        if(!caseActionFieldsetMap.containsKey(caseAction)){
            throw new AuraHandledException('No FieldSet was found for the provided Case Action');
        }

        String fieldSetName = caseActionFieldsetMap.get(caseAction);

        caseDescribeResult = getCaseDescribeResult();
        Schema.FieldSet fieldSet = caseDescribeResult.fieldsets.getMap().get(fieldSetName);
        Schema.FieldSet ctnFieldSet = caseDescribeResult.fieldsets.getMap().get(CTN_FIELD_SET_NAME);

        if(fieldSet==null){
            throw new AuraHandledException('No FieldSet was found for the provided Case Action');
        }

        CaseFieldSets caseFieldSets = new CaseFieldSets();

        caseFieldSets.caseActionfieldSet = getFieldsFromFieldset(fieldSet);
        caseFieldSets.ctnFieldset = getFieldsFromFieldset(ctnFieldSet);
        caseFieldSets.ctnDynamicFields = CaseEscalationFieldsController.getCaseActionDynamicFields('', caseAction, caseId);

        return JSON.serialize(caseFieldSets);
    }

    public static Map<String, String> getEscalationMetadataMap(){

        Map<String, String> tempMap = new Map<String, String>();
        List<Escalate_Case_Action_Fieldset_Mapping__mdt> escalateCaseActionfieldset =[SELECT
                                                                                        Id,
                                                                                        MasterLabel,
                                                                                        QualifiedApiName,
                                                                                        Case_Action__c,
                                                                                        Field_Set_API_Name__c
                                                                                        FROM Escalate_Case_Action_Fieldset_Mapping__mdt
                                                                                        ORDER BY MasterLabel ASC
                                                                                    ];

        for(Escalate_Case_Action_Fieldset_Mapping__mdt record : escalateCaseActionfieldset){
            tempMap.put(record.Case_Action__c, record.Field_Set_API_Name__c);
        }

        return tempMap;
    }

    public static Schema.DescribeSObjectResult getCaseDescribeResult(){

        if(caseDescribeResult!=null){
            return caseDescribeResult;
        }

        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(CASE_API_NAME);

        return SObjectTypeObj.getDescribe();
    }

    public static List<CaseField> getFieldsFromFieldset(Schema.FieldSet fieldset){

        List<CaseField> casefields = new List<CaseField>();
        for(Schema.FieldSetMember field : fieldset.getFields()){
            casefields.add(new CaseField(field.getFieldPath(), field.getRequired()));
        }

        return casefields;
    }

    @AuraEnabled(cacheable = true)
    public static Boolean getUserAccessToCase(String recordId){
        try {
            Id userId = UserInfo.getUserId();
            List<UserRecordAccess> userRecordAccessList = [SELECT RecordId FROM UserRecordAccess WHERE UserId=:userId AND RecordId=:recordId AND HasEditAccess=true];

            return !userRecordAccessList.isEmpty();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //Wrapper class. We need separate field sets
    public class CaseFieldSets{
        //Used on both readOnly and edit form
        public List<CaseField> caseActionfieldSet;
        //Used on readonly form
        public List<CaseField> ctnFieldset;
        //Used on edit form
        public Map<Id,Map<String,List<CaseEscalationFieldsController.CaseDynamicFieldsInfo>>> ctnDynamicFields;
    }

    public class CaseField{
        public String apiName;
        public Boolean isRequired;

        public CaseField(String apiName, Boolean isRequired){
            this.apiName = apiName;
            this.isRequired = isRequired;
        }
    }
}
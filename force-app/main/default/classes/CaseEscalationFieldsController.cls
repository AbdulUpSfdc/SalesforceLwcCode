/* ================================================
* @author : MANOJ KOLLI
* @date :   11/30/2020
* @group : Case
* @description : class to display fields for escalation case
================================================*/


public with sharing class CaseEscalationFieldsController{

    public final static String URGENT_BILLING_PERMISSION = 'Urgent_Billing_Inquiries';
    public final static String CASE_TYPE_BILLING_INQUIRY = 'Billing | Inquiry';
    public final static String ACCOUNT_TYPE_WIRELESS = 'wireless';
    public final static String CASE_OBJECT_NAME = 'Case';
    public final static String CASE_ACTION_FIELD = 'CaseAction__c';
    public final static String CASE_TYPE_FIELD = 'Type';
    public final static String PAYMENT_TYPE_FIELD = 'PaymentType__c';
    public final static String REFUND_TYPE_FIELD = 'RefundType__c';

    @AuraEnabled
    public static ModelDynamicFieldInfo getCaseDetails(String selAction,String caseType, String caseRecId){

        List<ModelCaseDetails> lstOfModelCase=new List<ModelCaseDetails>();

        Map<String,String> mapOfFieldSetApiNames = new Map<String,String>();
        Map<Id, Escalate_Case_Action_Fieldset_Mapping__mdt> caseEscalationFSMap = new Map<Id, Escalate_Case_Action_Fieldset_Mapping__mdt>([SELECT id, 
					MasterLabel, 
					QualifiedApiName,
                    Case_Action__c,
					Field_Set_API_Name__c 
					from Escalate_Case_Action_Fieldset_Mapping__mdt WITH SECURITY_ENFORCED
					order by MasterLabel ASC]);

        if(caseEscalationFSMap!=Null){

            for(Escalate_Case_Action_Fieldset_Mapping__mdt caseActionFieldSet : caseEscalationFSMap.values()){
                //System.debug('MK ########'+caseActionFieldSet.Case_Action__c+'------>'+caseActionFieldSet.Field_Set_API_Name__c);
                mapOfFieldSetApiNames.put(caseActionFieldSet.Case_Action__c,caseActionFieldSet.Field_Set_API_Name__c);
            }
        }


        if(selAction!=null && selAction!='' && mapOfFieldSetApiNames != Null && mapOfFieldSetApiNames.containsKey(selAction)){

            Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
            Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('Case');
            Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
            Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(mapOfFieldSetApiNames.get(selAction));

			System.debug('### mapOfFieldSetApiNames '+mapOfFieldSetApiNames);
			//System.debug('### mapOfFieldSetApiNames.get(selAction) '+mapOfFieldSetApiNames.get(selAction));
			//System.debug('### selAction '+selAction);
			//System.debug('### fieldSetObj '+fieldSetObj);

            for(Schema.FieldSetMember fieldSetMember : fieldSetObj.getFields()){
				Boolean isDisabled = fieldSetMember.getFieldPath() == PAYMENT_TYPE_FIELD || fieldSetMember.getFieldPath() == REFUND_TYPE_FIELD ? true : false;
                lstOfModelCase.add(new ModelCaseDetails(fieldSetMember.getFieldPath(),fieldSetMember.getRequired(), isDisabled));
            }


        }
        //System.debug('### lstOfModelCase '+lstOfModelCase);
        //System.debug('### getCaseActionDynamicFields(caseType,selAction,caseRecId) '+getCaseActionDynamicFields(caseType,selAction,caseRecId));
        return new ModelDynamicFieldInfo(lstOfModelCase,getCaseActionDynamicFields(caseType,selAction,caseRecId));
    }

    @AuraEnabled
    public static String getCaseActionValues(String caseType){
        Map<String, List<BWC_Bitset.TPicklistEntry>> response = BWC_DependentPicklist.GetDependentOptions(CASE_OBJECT_NAME, CASE_TYPE_FIELD, CASE_ACTION_FIELD);
        List<BWC_Bitset.TPicklistEntry> caseActions = response.get(caseType);

        List<BWC_Case_Action_Permissions__mdt> permissions = getActiveCaseActionPermissions();
        List<BWC_Bitset.TPicklistEntry> filteredCaseActions = caseActions;

        for(BWC_Case_Action_Permissions__mdt permission : permissions){

            if(!FeatureManagement.checkPermission(permission.Custom_Permission_Name__c)){

                List<BWC_Bitset.TPicklistEntry> temp = new List<BWC_Bitset.TPicklistEntry>();
                for(BWC_Bitset.TPicklistEntry entry : filteredCaseActions){

                    if(entry.label.startsWithIgnoreCase(permission.Case_Action_Prefix__c)){
                        continue;
                    }

                    temp.add(entry);
                }
                filteredCaseActions = temp;
            }

        }

        caseActions = filteredCaseActions;

        //Remove Urgent Case Actions if user has no permission
        // if(!FeatureManagement.checkPermission(URGENT_BILLING_PERMISSION)){
        //     List<BWC_Bitset.TPicklistEntry> filteredCaseActions = new List<BWC_Bitset.TPicklistEntry>();
        //     for(BWC_Bitset.TPicklistEntry entry : caseActions){

        //         if(entry.label.startsWithIgnoreCase('urgent')) continue;

        //         filteredCaseActions.add(entry);
        //     }
        //     caseActions = filteredCaseActions;
        // }

        return JSON.serialize(caseActions);
    }

    public class ModelDynamicFieldInfo{
        @AuraEnabled  public List<ModelCaseDetails> lstOfModelCase{get;set;}
        @AuraEnabled public  Map<Id,Map<String,List<CaseDynamicFieldsInfo>>> caseDynamicFieldInfo{get;set;}

        public ModelDynamicFieldInfo(List<ModelCaseDetails> lstOfModelCase,Map<Id,Map<String,List<CaseDynamicFieldsInfo>>> caseDynamicFieldInfo){
            this.lstOfModelCase=lstOfModelCase;
            this.caseDynamicFieldInfo=caseDynamicFieldInfo;
        }
    }

    public class ModelCaseDetails{
        @AuraEnabled  public String apiName{get;set;}
        @AuraEnabled public Boolean isRequired{get;set;}
        @AuraEnabled public Boolean isDisabled{get;set;}

        public ModelCaseDetails(String apiName,Boolean isRequired,Boolean isDisabled){
            this.apiName=apiName;
            this.isRequired=isRequired;
            this.isDisabled=isDisabled;
        }
    }


    public class CaseDynamicFieldsInfo{
        @AuraEnabled  public String fieldLabel{get;set;}
        @AuraEnabled  public String fieldVal{get;set;}
        @AuraEnabled  public String type{get;set;}
        @AuraEnabled public Boolean isRequired{get;set;}

        public CaseDynamicFieldsInfo(String fieldLabel,String fieldVal,String type,Boolean isRequired){
            this.fieldLabel=fieldLabel;
            this.fieldVal=fieldVal;
            this.type=type;
            this.isRequired=isRequired;
        }

    }


    //get dynamic fields for Type/CaseAction
    public static Map<Id,Map<String,List<CaseDynamicFieldsInfo>>> getCaseActionDynamicFields(String caseType , String selAction, String caseRecId){

        System.debug('###caseType'+caseType+'###selAction'+selAction+'###caseRecId'+caseRecId);

        Map<Id,Map<String,List<CaseDynamicFieldsInfo>>> subscriberInfoMap = new Map<Id,Map<String,List<CaseDynamicFieldsInfo>>>();

        //retrieve case info
        Case c = [Select Id, Billing_Account__c from Case Where Id = :caseRecId];

        if(String.isNotBlank(c.Billing_account__c)){

            List<Asset> assetlst = getAssets(c.Billing_Account__c);

            for(Asset asst : assetlst){
                List<CaseDynamicFieldsInfo> fieldInfoList = new List<CaseDynamicFieldsInfo>();
                Map<String,List<CaseDynamicFieldsInfo>> subscriberfieldsMap = new Map<String,List<CaseDynamicFieldsInfo>>();

                //Metadata to build caseDynamicFieldsinfo to avoid hardcoding the fields we want to display
                fieldInfoList.add(new CaseDynamicFieldsInfo(CaseConstants.CASE_PRODUCT_SRV_SUBSCRIBER_STATUS,asst.status,'Text',false));
                fieldInfoList.add(new CaseDynamicFieldsInfo(CaseConstants.CASE_PRODUCT_SRV_SUBSCRIBER_NAME,asst.User__c,'Text',false));
                fieldInfoList.add(new CaseDynamicFieldsInfo(CaseConstants.CASE_PRODUCT_SRV_RATE_PLAN_NAME,(asst.Plan__r.Billing_Account__c == c.Billing_Account__c)?asst.Plan__r.Product__c:'','Text',false));
                fieldInfoList.add(new CaseDynamicFieldsInfo(CaseConstants.CASE_PRODUCT_SRV_RATE_PLAN_CODE,(asst.Plan__r.Billing_Account__c == c.Billing_Account__c)?asst.Plan__r.Plan_Code__c:'','Text',false));
                fieldInfoList.add(new CaseDynamicFieldsInfo(CaseConstants.CASE_PRODUCT_SRV_DEVICE_TYPE,asst.Device_Type__c,'Text',false));
                fieldInfoList.add(new CaseDynamicFieldsInfo(CaseConstants.CASE_PRODUCT_SRV_DEVICE_MAKEMODEL,asst.Make_And_Model__c,'Text',false));
                fieldInfoList.add(new CaseDynamicFieldsInfo(CaseConstants.CASE_PRODUCT_SRV_DEVICE_PRODUCTCODE,asst.Plan__r?.Plan_Code__c,'Text',false));
                fieldInfoList.add(new CaseDynamicFieldsInfo(CaseConstants.CASE_PRODUCT_SRV_DEVICE_MANUFACTURER ,asst.Manufacturer__c,'Text',false));
                fieldInfoList.add(new CaseDynamicFieldsInfo(CaseConstants.CASE_PRODUCT_SRV_DEVICE_IMEI ,asst.IMEI__c,'Text',false));
                fieldInfoList.add(new CaseDynamicFieldsInfo(CaseConstants.CASE_PRODUCT_SRV_DEVICE_SIM ,asst.SIM__c,'Text',false));

                fieldInfoList.add(new CaseDynamicFieldsInfo(CaseConstants.CASE_PRODUCT_SUBMARKET ,asst.Submarket__c,'Text',false));

                subscriberfieldsMap.put(asst.Phone_Number__c,fieldInfoList);
                subscriberInfoMap.put(asst.Id,subscriberfieldsMap);
            }

        }
        System.debug('************************subscriberInfoMap'+subscriberInfoMap);
        return subscriberInfoMap;
    }


    //get Equipments related to billing account
    public static List<Asset> getAssets(Id billAcctId){
        Set<Id> billingAccountIds = new Set<Id>{billAcctId};
        List<Asset> assets = BWC_Asset_Selector.getAssetsForBillingAccounts(billingAccountIds);
        List<Asset> filteredAssets = new List<Asset>();
        for(Asset asst : assets){
            if(asst.Billing_Account__r.Account_Type__c.equals(BWC_Constants.ACCOUNT_TYPE_WIRELESS)){
                filteredAssets.add(asst);
            }
        }

        return filteredAssets;
    }

    public static List<BWC_Case_Action_Permissions__mdt> getActiveCaseActionPermissions(){
        return [SELECT Id, Case_Action_Prefix__c, Custom_Permission_Name__c FROM BWC_Case_Action_Permissions__mdt WHERE Is_Active__c=true];
    }

}
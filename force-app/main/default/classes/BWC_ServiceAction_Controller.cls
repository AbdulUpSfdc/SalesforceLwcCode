/* ================================================
* @class name: BWC_ServiceAction_Controller
* @author: Salesforce Inc.
* @purpose: supports Billing Account Actions
* @created date (mm/dd/yyyy) :  03/20/2021
================================================*/
public with sharing class BWC_ServiceAction_Controller {

    //passes combobo options to the client
    @AuraEnabled(cacheable=true)
    public static string getComboboxOptions(string controlValue){

        Map<Object,List<String>> optionsMap = BWC_ServiceAction_Controller.getDependentPicklistValues(Interaction_Activity__c.Action__c);
        list<string> returnValue;
       try{
       returnValue = optionsMap.get(controlValue);

       }catch(Exception e){

       }

        return  JSON.serialize(returnValue);

    }
    //intial payload for lwc to process
    @AuraEnabled(cacheable=true)
    public static string getData(string billingAccountId){
        payLoadWrapper returnValue = new payLoadWrapper();

        Customer_Account_Relation__c car = BWC_ServiceAction_Controller.getCARInfo(billingAccountId);
        Billing_Account__c ba = BWC_ServiceAction_Controller.getBillingAccountInfo(billingAccountId);
        returnValue.interactId = BWC_ServiceAction_Controller.getInteractionId(car);
        returnValue.ban = ba?.Billing_Account_Number__c;
        returnValue.metadataListForEscalations = MetadataSelector.getInteractionMetadata();
        return  JSON.serialize(returnValue);
    }
    class payLoadWrapper {
        string ban;
        string interactId;
        List<BWC_Interaction_Metadata__mdt> metadataListForEscalations;
    }
    //support query to link records
    public static Billing_Account__c getBillingAccountInfo(string billingAccountId ){
        Billing_Account__c ba = [SELECT id , Billing_Account_Number__c FROM Billing_Account__c WHERE id=:billingAccountId
        LIMIT 1];
        return ba;
    }
    //support query to link records
    @AuraEnabled(cacheable=true)
    public static string getInteractionId(Customer_Account_Relation__c car ){
       string returnValue;
        list<Interaction__c> interactions = [SELECT id, Customer__c FROM Interaction__c  WHERE Customer__c =: car.Customer__c
        order by CreatedDate desc
        LIMIT 1];
        for(Interaction__c i : interactions){
        returnValue = i.id;
        }
        return returnValue;
    }
    //support query to link records
    public static Customer_Account_Relation__c getCARInfo(string billingAccountId ){
        Customer_Account_Relation__c car = [ SELECT id , Customer__c, Billing_Account__c FROM Customer_Account_Relation__c WHERE Billing_Account__c =: billingAccountId
        LIMIT 1];

        return car;
    }
    //passes device data to the client for processing
    @AuraEnabled(cacheable=true)
    public static string getDeviceData (string baId ){
        List<Asset> returnValue;
        returnValue = CaseEscalationFieldsController.getAssets(baId);
    return JSON.serialize(returnValue);
    }
    /*
     *  Super sweet open source that gets dependent picklist values
     *  IF YOU CAN'T READ THE CODE DON"T MESS WITH IT!!!
     */
    public static Map<Object,List<String>> getDependentPicklistValues(Schema.sObjectField dependToken ){
    Schema.DescribeFieldResult depend = dependToken.getDescribe();
    Schema.sObjectField controlToken = depend.getController();
    if ( controlToken == null ) return null;
    Schema.DescribeFieldResult control = controlToken.getDescribe();
    List<Schema.PicklistEntry> controlEntries =
    (   control.getType() == Schema.DisplayType.Boolean
    ?   null
    :   control.getPicklistValues()
    );

    String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    Map<Object,List<String>> dependentPicklistValues = new Map<Object,List<String>>();
    for ( Schema.PicklistEntry entry : depend.getPicklistValues() ) if ( entry.isActive() )
    {
        List<String> base64chars =
            String.valueOf
            (   ((Map<String,Object>) JSON.deserializeUntyped( JSON.serialize( entry ) )).get( 'validFor' )
            ).split( '' );
        if (base64Chars == null || base64Chars.isEmpty() || base64Chars[0] == '')
        continue;
        for ( Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++ )
        {
            Object controlValue =
            (   controlEntries == null
            ?   (Object) (index == 1)
            :   (Object) (controlEntries[ index ].isActive() ? controlEntries[ index ].getLabel() : null)
            );
            Integer bitIndex = index / 6, bitShift = 5 - Math.mod( index, 6 );
            if  (   controlValue == null
                ||  (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0
                ) continue;
            if ( !dependentPicklistValues.containsKey( controlValue ) )
            {
                dependentPicklistValues.put( controlValue, new List<String>() );
            }
            dependentPicklistValues.get( controlValue ).add( entry.getLabel() );
        }
    }
    return dependentPicklistValues;
}
}
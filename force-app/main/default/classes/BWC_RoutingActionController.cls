public without sharing class BWC_RoutingActionController {

    public static final String CASE_OBJECT_NAME = 'Case';
    public static final String SERVICE_INQUIRY_TYPE = 'Services | Inquiry';
    public static final String TIER_2_FIELD = 'Tier2__c';
    public static final String TIER_3_FIELD = 'Tier3__c';
    public static final String LNP_PREFIX = 'LNP';
    public static final String IT_TLG_PREFIX = 'IT-TLG';

    // TODO: remove caseType as we'll only use caseAction for field dependency
    @AuraEnabled
    public static String getRoutingActionValues(String caseAction ){
        try {
            Boolean includeTier2 = checkAvailableQueues(TIER_2_FIELD, caseAction);
            Boolean includeTier3 = checkAvailableQueues(TIER_3_FIELD, caseAction);
            Boolean isLNPAction = caseAction.contains(LNP_PREFIX);

            Map<String, List<RoutingAction>> routingActionMap = new Map<String, List<RoutingAction>>();
            List<Case_Escalation_Routing_Actions__mdt> metadataLst = [SELECT Label, Base_Routing_Action__c, Available_Routing_Action__c  FROM Case_Escalation_Routing_Actions__mdt ORDER BY Label];
            for(Case_Escalation_Routing_Actions__mdt record : metadataLst){
                if(!routingActionMap.containsKey(record.Base_Routing_Action__c)){
                    routingActionMap.put(record.Base_Routing_Action__c, new List<RoutingAction>());
                }
                RoutingAction action = new RoutingAction();
                action.label = record.Available_Routing_Action__c;
                action.value = record.Available_Routing_Action__c;

                if(action.label.contains('Tier 2') && !includeTier2) continue;
                if(action.label.contains('Tier 3') && !includeTier3){
                    continue;
                }

                if(!isLNPAction && action.label.startsWith(IT_TLG_PREFIX)){
                    continue;
                }

                routingActionMap.get(record.Base_Routing_Action__c).add(action);
            }

            return JSON.serialize(routingActionMap);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getQueueId(String queueName){
        try {
            return [Select Id, Type, Name FROM Group WHERE Type = 'Queue' AND Name =:queueName].Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getQueueIdByDevName(String queueName){
        try {
            return [Select Id, Type, Name FROM Group WHERE Type = 'Queue' AND DeveloperName =:queueName LIMIT 1].Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getTierValues(String dependentField, String selectedValue){
        Map<String, List<BWC_Bitset.TPicklistEntry>> response = getDependentValues(dependentField);
        List<BWC_Bitset.TPicklistEntry> picklistValues = new List<BWC_Bitset.TPicklistEntry>();

        if(response.containsKey(selectedValue)){
            picklistValues = response.get(selectedValue);
        }
        return JSON.serialize(picklistValues);
    }

    public static Map<String, List<BWC_Bitset.TPicklistEntry>> getDependentValues(String dependentField){

        Schema.DescribeFieldResult depend = Schema.getGlobalDescribe().get( 'Case' ).getDescribe().fields.getMap().get( dependentField ).getDescribe();
        Schema.sObjectField controlToken = depend.getController();

        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries =
        (   control.getType() == Schema.DisplayType.Boolean
        ?   null
        :   control.getPicklistValues()
        );

        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/-';
        Map<String,List<BWC_Bitset.TPicklistEntry>> dependentPicklistValues = new Map<String,List<BWC_Bitset.TPicklistEntry>>();
        for ( Schema.PicklistEntry entry : depend.getPicklistValues() ) if ( entry.isActive() )
        {
            List<String> base64chars =
                String.valueOf
                (   ((Map<String,Object>) JSON.deserializeUntyped( JSON.serialize( entry ) )).get( 'validFor' )
                ).split( '' );
            for ( Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++ )
            {
                Object controlValue =
                (   controlEntries == null
                ?   (Object) (index == 1)
                :   (Object) (controlEntries[ index ].isActive() ? controlEntries[ index ].getLabel() : null)
                );
                Integer bitIndex = index / 6, bitShift = 5 - Math.mod( index, 6 );

                if(bitIndex >= base64chars.size()) continue;

                if  (   controlValue == null
                    ||  (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0
                    ) continue;
                if ( !dependentPicklistValues.containsKey( (String)controlValue ) )
                {
                    dependentPicklistValues.put( (String) controlValue, new List<BWC_Bitset.TPicklistEntry>() );
                }
                BWC_Bitset.TPicklistEntry ple = new BWC_Bitset.TPicklistEntry();
                ple.value = entry.getValue();
                ple.label = entry.getLabel();
                dependentPicklistValues.get( (String) controlValue ).add( ple);
            }
        }
        return dependentPicklistValues;
    }

    public static Boolean checkAvailableQueues(String fieldName, String selectedValue){
        Map<String, List<BWC_Bitset.TPicklistEntry>> response = getDependentValues(fieldName);
        return response.containsKey(selectedValue);
    }

    @AuraEnabled
    public static String getOutboundQueueName(String caseAction){
        try {
            List<Escalate_Case_Action_Fieldset_Mapping__mdt> caseActionMetadataLst = [SELECT Outbound_Queue_Name__c FROM Escalate_Case_Action_Fieldset_Mapping__mdt WHERE Case_Action__c=:caseAction];

            if(caseActionMetadataLst.isEmpty()){
                throw new BWC_RoutingException('No mapping was found for the case action: '+caseAction);
            }

            return caseActionMetadataLst[0].Outbound_Queue_Name__c;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class BWC_RoutingException extends Exception{}

    public class RoutingAction{
        public String label;
        public String value;
    }
}
public with sharing class BWC_BillingAccountAction {
    public BWC_BillingAccountAction() {
    }
    @AuraEnabled(cacheable=true)
    public static String getAllowedActions() {

        list<BWC_Interaction_Metadata__mdt> mdList = getMetaDataRecords();
        List<string> returnList = new List<string>();
        if(!mdList.isEmpty()){
            for(BWC_Interaction_Metadata__mdt metaRecord: mdList){

                returnList.add(metaRecord.Action__c);

            }
        }

    return JSON.serialize(returnList);
    
    }
    public static list<BWC_Interaction_Metadata__mdt> getMetaDataRecords(){
       
        list<BWC_Interaction_Metadata__mdt> mdList = [SELECT Type__c, Action__c, Allow_LIC_Escalation__c 
                                                      FROM BWC_Interaction_Metadata__mdt 
                                                      WHERE Allow_LIC_Escalation__c = true 
                                                      ];
        
        return mdList;
    }



}
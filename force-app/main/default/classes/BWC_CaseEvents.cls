public with sharing class BWC_CaseEvents {
    
    public static void publishEvents(List<Case> cases){
        
        List<SObject> plateformEvents = new List<sObject>();
        Set<Id> billingAccountIdsSet = New Set<Id>();
        
        for(Case c: cases) {
            billingAccountIdsSet.add(c.Billing_Account__c);
        }
        
        Map<Id,Billing_Account__c> billingAccountsMap = BWC_BillingAccount_Selector.getBillingAccounts(billingAccountIdsSet);
        
        for (Case c: cases) {
            Billing_Account__c ba = billingAccountsMap.get(c.Billing_Account__c);
            if(c.Status == 'Closed') {
                plateformEvents.add(buildPlatformEvent('Escalation Case Closed', 
                                                       c.Id, 
                                                       ba.Billing_Account_Number__c, 
                                                       ba.Billing_Market__c));
            } else {
                plateformEvents.add(buildPlatformEvent('Escalation Case Created', 
                                                       c.Id, 
                                                       ba.Billing_Account_Number__c, 
                                                       ba.Billing_Market__c, 
                                                       Integer.valueOf(c.Bill_Seq_Number__c), 
                                                       c.Bill_Date__c, 
                                                       c.Amount_in_Dispute__c));
            }
        }
        
        system.debug('##plateformEvents:'+plateformEvents);
        
        if(!plateformEvents.isEmpty()){
            
            try {
                // Call method to publish events
                List<Database.SaveResult> results = EventBus.publish(plateformEvents);
                system.debug('##results:'+results);
                // Inspect publishing result for each event
                for (Integer index = 0; index < results.size(); index++) {
                    Database.SaveResult sr = results[index];
                    if (sr.isSuccess()) {
                        System.debug('Successfully published Escalation Platform Event');
                    } else {
                        System.debug(sr.getErrors());
                    }
                }
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
            
        }
    }
    
    public static sObject buildPlatformEvent(String plateforceEvent, Id caseId, String banId, String banMarket, Integer billSeqNo, Date billDate, Decimal billAmount ){
        if(plateforceEvent == 'Escalation Case Created'){
            Escalation_Case_Created__e escalation = new Escalation_Case_Created__e(CaseId__c = caseId, 
                                                                                   BAN__c = banId, 
                                                                                   BAN_Market__c = banMarket, 
                                                                                   Bill_Seq_Number__c  = billSeqNo, 
                                                                                   Bill_Date__c = billDate,
                                                                                   Bill_Amount__c = billAmount);
            return escalation;
        }
        return null;
    }
    
    public static sObject buildPlatformEvent(String plateforceEvent, Id caseId, String banId, String banMarket){
        if(plateforceEvent == 'Escalation Case Created'){
            Escalation_Case_Created__e escalation = new Escalation_Case_Created__e(CaseId__c = caseId, 
                                                                                   BAN__c = banId, 
                                                                                   BAN_Market__c = banMarket);
            return escalation;
        }            
        if(plateforceEvent == 'Escalation Case Closed'){
            Escalation_Case_Closed__e escalation = new Escalation_Case_Closed__e(CaseId__c = caseId, 
                                                                                 BAN__c = banId, 
                                                                                 BAN_Market__c = banMarket);
            return escalation;
        }
        return null;
    }
}
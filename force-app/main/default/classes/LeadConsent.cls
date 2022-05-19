public without sharing class LeadConsent {
     
    /**
     * This method is to get Lead Consent Custom Object for Touchless to check Accepted = True
    */
    @AuraEnabled
    public static LeadConsent__c getLeadConsent(String idHash){
        LeadConsent__c objLeadConsent;
        LeadConsentService.verifyHashID(idHash);
        if(idHash != null){
            objLeadConsent = LeadConsentService.getConsentDetails(idHash);
        }
        return objLeadConsent;
    }

    /**
     * This method is to update record into Lead Consent Custom Object for Touchless
    */
    @AuraEnabled
    public static void updateLeadConsent(String idHash){  
        LeadConsentService.verifyHashID(idHash);   
        if(idHash!= null){
            LeadConsentService.updateConsentDetails(idHash);
        }
    }
    /**
     * This method is to update cancelled records into Lead Consent Custom Object for Touchless
    */
    @AuraEnabled
    public static void updateLeadConsentCancelled(String idHash){ 
        LeadConsentService.verifyHashID(idHash);      
        if(idHash!= null){
            LeadConsentService.updateConsentCancelledDetails(idHash);
        }
    }
}
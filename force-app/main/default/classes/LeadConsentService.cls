public inherited sharing class LeadConsentService {
    /**
    * This method is to verify the oneway hash ID sent in the Consent URL
    */
    public static void verifyHashID(String oneWayHash){
        if(String.isBlank(oneWayHash)) {
            System.debug('Hash is empty');
            throw new AuraHandledException('This link is Invalid.');
          }
        
        if (oneWayHash.length() < 40 ) {
            System.debug('Hash is too short');
            throw new AuraHandledException('This link is Invalid.');
        }
    }
    /**
    * This method is to retrieve the oneway hash ID  sent in the Consent URL and expire it if exceeded TTL
    */
    public static LeadConsent__c getConsentDetails(String oneWayHash){
        LeadConsent__c objLeadConsent;
        List<LeadConsent__c> leadConsents = new List<LeadConsent__c>(); 
        String hash = String.escapeSingleQuotes(oneWayHash) + '%';    
        leadConsents = [SELECT Id,CreatedDate, FirstName__c,LastName__c,Email__c,RequestID__c,MobilePhone__c, Accepted__c FROM LeadConsent__c WHERE RequestId__c like :hash]; 
        Map<String, RetailCustomSetting__c> settingsMap= LeadForm.getRetailCustomSettings();
        if(leadConsents.size()>0){
            objLeadConsent = leadConsents[0];

            // Last case sensetive hash check, since SOQL is not case sensetive
            if (!oneWayHash.equals(objLeadConsent.RequestID__c)) {
                throw new AuraHandledException('This link is Invalid.');
            }

            Long created = objLeadConsent.CreatedDate.getTime() / 1000;
            Long now = System.now().getTime() / 1000;
            String ttlStr = settingsMap.get('ConsentTTL').KeyValue__c;
            Long ttl = Long.valueOf(ttlStr);
            if (ttl < (now - created)) {
                throw new AuraHandledException('This link is Expired.');
            }
        }else{
            throw new AuraHandledException('This link is Invalid.');
        }
        return objLeadConsent;
    }

    /**
    * This method is to update consent record using the oneway hash ID sent in the Consent URL
    */
    public static void updateConsentDetails(String oneWayHash){
        LeadConsent__c objLeadConsent = getConsentDetails(oneWayHash);
        objLeadConsent.Accepted__c = true;
        update objLeadConsent;
        system.debug('LeadConsent__c update ' + objLeadConsent);
    }

    /**
    * This method is to update cancelled consent record using the oneway hash ID sent in the Consent URL
    */
    public static void updateConsentCancelledDetails(String oneWayHash){
        LeadConsent__c objLeadConsent = getConsentDetails(oneWayHash);
        objLeadConsent.Accepted__c = false;
        objLeadConsent.ConsentCancelled__c = true;
        update objLeadConsent;
        system.debug('LeadConsent__c update ' + objLeadConsent);
    }
}
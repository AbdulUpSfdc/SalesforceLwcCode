public with sharing class BWC_CpniConsent {

    public virtual class UpdateCpniConsentRequest {
        public List<ConsentPreference> consentPreferences;
    }

    public class ConsentPreference {
        public String consentType;
        public String preference;
        public String market;
    }

    public virtual class UpdateCpniConsentResponse {
        public String status;
    }

}
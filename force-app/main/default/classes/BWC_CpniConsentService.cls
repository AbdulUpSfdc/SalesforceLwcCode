public with sharing class BWC_CpniConsentService {

    public static BWC_CpniConsent.UpdateCpniConsentResponse updateCpniConsent(BWC_CpniConsent.UpdateCpniConsentRequest request, String ban, String accountType) {
        return BWC_CpniConsentCallout.updateCpniConsent(request, ban, accountType);
    }

}
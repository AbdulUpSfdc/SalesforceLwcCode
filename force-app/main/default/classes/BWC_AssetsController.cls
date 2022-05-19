/*
    Aura Enabled Methods for Assets
*/
public with sharing class BWC_AssetsController {
    
    @AuraEnabled
    public static List<Asset> getAssetsForBillingAccounts(String requestJson){
        try {
            Set<Id> request = (Set<Id>) 
                JSON.deserialize(requestJson, Set<Id>.class);
            return BWC_Asset_Selector.getAssetsForBillingAccounts(request);
        } catch (Exception e) {
            throw BWC_Controller.handleException(e, 'request=' + requestJson);
        }
    }
}
/* ================================================
* @author : Anshul Gupta
* @date :   09/05/2020
* @group : Customer Search
* @description : Controller class to be used by LWC Account search
================================================*/
public with sharing class BWC_CustomerSearchController {

    /*
        Do account search async using Continuation.
    */
    @AuraEnabled(continuation = true)
    public static Object accountSearchCont(Id recordId, String requestJson) {

        try {

            BWC_CustomerSearch.CustomerSearchRequest request =
                (BWC_CustomerSearch.CustomerSearchRequest)JSON.deserialize(requestJson, BWC_CustomerSearch.CustomerSearchRequest.class);
            BWC_CustomerSearchService.CustomerSearchService service = new BWC_CustomerSearchService.CustomerSearchService(recordId, request);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'accountSearchResp';
                return response;
            }

            // No continuation needed, so return it directly
            BWC_CustomerSearch.CustomerSearchResponse customerSearchResponse = (BWC_CustomerSearch.CustomerSearchResponse)response;
            return customerSearchResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e, 'Record Id:' + recordId + '; requestJson:' + requestJson );
        }

    }

    /*
        Handle continuation response for account search.
    */
    @AuraEnabled
    public static String accountSearchResp(List<String> labels, Object state) {

        try {

            BWC_CustomerSearchService.CustomerSearchService service = (BWC_CustomerSearchService.CustomerSearchService)state;
            BWC_CustomerSearch.CustomerSearchResponse customerSearchResponse = (BWC_CustomerSearch.CustomerSearchResponse)service.processContinuationResponse();
            return customerSearchResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }

   @AuraEnabled
   public static Boolean resetInteraction(String interactionId) {

       Interaction__c intAction = [SELECT Id, Customer__c FROM Interaction__c WHERE Id = :interactionId];

       Id accountId = intAction.Customer__c;

       // update interaction fields
       intAction.Customer__c = null;
       intAction.Is_Authorized__c = false;

       intAction.User_CPNI_Code__c = false;
        intAction.User_Unified_Bill_Indicator__c = false;
        intAction.User_VHT__c = false;

        intAction.Activity_Summary__c = null;
        intAction.ANI__c = null;

        intAction.Authorization_Json__c = null;
        intAction.Authorized_User_First_Name__c = null;
        intAction.Authorized_User_Id__c = null;
        intAction.Authorized_User_Last_Name__c = null;
        intAction.Manual_Authentication_Method__c = null;
        intAction.Notes__c = null;

        intAction.DNIS__c = null;
        intAction.trackingIdent__c = null;

        intAction.User_Account_Number__c = null;
        intAction.User_Action_Object__c = null;
        intAction.User_Authentication__c = null;
        intAction.User_Bill_Src__c = null;

        intAction.User_Department_Code__c = null;
        intAction.User_DTV_Account_Number__c = null;
        intAction.User_Language__c = null;
        intAction.User_Order_Num__c = null;
        intAction.User_OTT_Account_Num__c = null;
        intAction.User_Specific_Object__c = null;
        intAction.User_Specific_Problem_Type__c = null;

        intAction.User_TIG_Acct_Num__c = null;
        intAction.User_TN_Type__c = null;
        intAction.User_Uverse_Account_Number__c = null;

        intAction.User_Telephone_Number__c = null;
        intAction.User_TFN__c = null;

        // clear out picklists
        intAction.Authentication__c = null;
        intAction.Call_Status__c = null;

        // clear out Lookups
        intAction.Billing_Account__c = null;

        // Clear out dates
        intAction.CompletedDate__c = null;

       update intAction;


       if (accountId != null) {

            // reset CTI_Call_Identifier__c in Account
           Account acc = new Account(Id = accountId, CTI_Call_Identifier__c = null);
           update acc;

           List<Customer_Account_Relation__c> customerAccountRelations;


            // All bans
            customerAccountRelations = [SELECT
                                        Id, Customer__c, Billing_Account__c
                                        FROM Customer_Account_Relation__c
                                        WHERE Customer__c = :accountId];

            Set<Id> setBillingAccounts = new Set<Id>();
            List<Billing_Account__c> listBillingAccounts = new List<Billing_Account__c>();
            for (Customer_Account_Relation__c car : customerAccountRelations) {

                setBillingAccounts.add(car.Billing_Account__c);

                // reset CTI_Call_Identifier__c in Billing_Account__c
                listBillingAccounts.add(new Billing_Account__c(Id = car.Billing_Account__c, CTI_Call_Identifier__c = null));
            }

            if (listBillingAccounts.size() > 0) {
                update listBillingAccounts;

                List<Plan__c> listPlans = BWC_Plan_Selector.getPlansForBillingAccounts(setBillingAccounts);
                for (Plan__c plan : listPlans) {
                    plan.CTI_Call_Identifier__c = null;
                }
                if (listPlans.size() > 0) {
                    // reset CTI_Call_Identifier__c in Plan__c
                    update listPlans;
                }

                List<Asset> listAssets = BWC_Asset_Selector.getAssetsForBillingAccounts(setBillingAccounts);
                for (Asset ast : listAssets) {
                    ast.CTI_Call_Identifier__c = null;
                }
                if (listAssets.size() > 0) {
                    // reset CTI_Call_Identifier__c in Asset
                    update listAssets;
                }
            }
       }

       return true;
   }

    @AuraEnabled(continuation = true)
    public static Object cbrSearchCont(Id recordId, String phoneNumber){

        BWC_Log.setRelatedRecordId(recordId);

        try {
            BWC_CustomerSearchService.CBRSearchService service = new BWC_CustomerSearchService.CBRSearchService(recordId, phoneNumber);
            Object response = service.callWithContinuation();

            if(response instanceof Continuation){
                ((Continuation)response).ContinuationMethod = 'cbrSearchResp';
                return response;
            }

            BWC_CustomerSearch.CBRResponse cbrResponse = (BWC_CustomerSearch.CBRResponse) response;
            return cbrResponse.serialize();

        } catch (Exception e) {
            throw BWC_Controller.handleException(e, 'request phoneNumber='+phoneNumber);
        }

    }

    @AuraEnabled
    public static String cbrSearchResp(List<String> labels, Object state){

        try {
            BWC_CustomerSearchService.CBRSearchService service = (BWC_CustomerSearchService.CBRSearchService)state;
            BWC_CustomerSearch.CBRResponse response = (BWC_CustomerSearch.CBRResponse) service.processContinuationResponse();

            return response.serialize();

        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

}
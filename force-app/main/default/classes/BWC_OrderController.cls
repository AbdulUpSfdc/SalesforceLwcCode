/**
 * Apex class used by bwcOrderServices LWC
*/
public with sharing class BWC_OrderController {


    /**************************************************************************
      OrderHistory
    **************************************************************************/
    @AuraEnabled(continuation = true)
    public static Object getOrderHistoryCont(Id interactionId){

        BWC_Log.setRelatedRecordId(interactionId);

        try {

            BWC_OrderService.GetOrderHistory service = new BWC_OrderService.GetOrderHistory(interactionId);

            Object response = service.callWithContinuation();

            if(response instanceof Continuation){
                ((Continuation)response).continuationMethod = 'getOrderHistoryResp';
                return response;
            }

            BWC_Order.OrderHistoryResponse orderHistoryResponse = (BWC_Order.OrderHistoryResponse) response;

            return orderHistoryResponse.serialize();

        } catch (Exception e) {

            throw BWC_Controller.handleException(e);

        }

    }

    @AuraEnabled
    public static String getOrderHistoryResp(List<String> labels, Object state){

        try {

            BWC_OrderService.GetOrderHistory service = (BWC_OrderService.GetOrderHistory)state;

            BWC_Order.OrderHistoryResponse orderHistoryResponse =
                (BWC_Order.OrderHistoryResponse) service.processContinuationResponse();

            return orderHistoryResponse.serialize();

        } catch (Exception e) {

            throw BWC_Controller.handleException(e);

        }

    }


    /**************************************************************************
      OrderDetails
    **************************************************************************/
    @AuraEnabled(continuation = true)
    public static Object getOrderDetailsCont(Id interactionId, String orderId){

        BWC_Log.setRelatedRecordId(interactionId);

        try {

            BWC_OrderService.GetOrderDetails service = new BWC_OrderService.GetOrderDetails(interactionId, orderId);

            Object response = service.callWithContinuation();

            if(response instanceof Continuation){
                ((Continuation)response).continuationMethod = 'getOrderDetailsResp';
                return response;
            }

            BWC_Order.OrderDetailsResponse orderDetailsResponse = (BWC_Order.OrderDetailsResponse) response;

            return orderDetailsResponse.serialize();

        } catch (Exception e) {

            throw BWC_Controller.handleException(e);

        }

    }

    @AuraEnabled
    public static String getOrderDetailsResp(List<String> labels, Object state){

        try {

            BWC_OrderService.GetOrderDetails service = (BWC_OrderService.GetOrderDetails)state;

            BWC_Order.OrderDetailsResponse orderDetailsResponse =
                (BWC_Order.OrderDetailsResponse) service.processContinuationResponse();

            return orderDetailsResponse.serialize();

        } catch (Exception e) {

            throw BWC_Controller.handleException(e);

        }

    }

    @AuraEnabled
    public static String getBillingAccountsId(List<String> bans){
        Map<String, String> result = new Map<String, String>();
        List<Billing_Account__c> billingAccounts = [SELECT Id, Billing_Account_Number__c FROM Billing_Account__c WHERE Billing_Account_Number__c IN :bans WITH SECURITY_ENFORCED];
        for(Billing_Account__c billingAccount : billingAccounts){
            result.put(billingAccount.Billing_Account_Number__c, billingAccount.Id);
        }
        return JSON.serialize(result);
    }

}
public inherited sharing class BWC_OrderService {

    public static final Integer NUMBER_OF_ORDERS = 50;

    public class GetOrderHistory extends BWC_InteractionServiceBase {

        BWC_Order.OrderHistoryRequest request;
        BWC_Order.OrderHistoryResponse response;

        public GetOrderHistory(Id interactionId){

            super(interactionId, null);
            this.buildRequest();

        }

        public void buildRequest(){

            this.request = new BWC_Order.OrderHistoryRequest();

            if(this.interactionId == null){
                throw new BWC_Exception('Argument interactionId is required');
            }

            // Only get authorized accounts
            List<Billing_Account__c> billingAccounts = BWC_AccountService.getBillingAccounts(recordId,null,null,true ,false);

            List<Long> banList = new List<Long>();
            for(Billing_Account__c billingAccount : billingAccounts) {
                Long banLong = Long.valueOf(billingAccount.Billing_Account_Number__c);
                banList.add(banLong);
            }

            this.request.ban = banList; //bans;
            this.request.numberOfOrders = NUMBER_OF_ORDERS;
            this.request.endDate = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            this.request.startDate = Datetime.now().addDays(-60).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');

            this.callout = new BWC_OrderCallout.GetOrderHistoryCallout(this.request);
        }

        public override Object buildResponse(){
            this.response = (BWC_Order.OrderHistoryResponse) this.callout.getResponse();
            return this.response;
        }

    }

    public class GetOrderDetails extends BWC_InteractionServiceBase{

        BWC_Order.OrderDetailsResponse response;
        String orderId;

        public GetOrderDetails(Id interactionId, String orderId){

            super(interactionId, null);
            this.orderId = orderId;

            this.buildRequest();

        }

        public void buildRequest(){

            if(String.isBlank(this.interactionId)){
                throw new BWC_Exception('Argument interactionId is required');
            }

            if(String.isBlank(this.orderId)){
                throw new BWC_Exception('Argument orderId is required');
            }

            this.callout = new BWC_OrderCallout.GetOrderDetailsCallout(this.orderId);

        }

        public override Object buildResponse(){

            this.response  = (BWC_Order.OrderDetailsResponse) this.callout.getResponse();

            String ban = this.response.details.accounts[0].accountNumber;
            String authorizationLevel = this.getAuthorizationLevel(ban);

            if(authorizationLevel==null){
                throw new BWC_Exception('Billing Account from order is not associated with this interaction record');
            }

            if(!BWC_Authorization.AUTHORIZATION_LEVELS_L1_PRIVILEGED.contains(authorizationLevel)){
                throw new BWC_Exception('User does not have access to view details for this order');
            }

            return this.response;

        }

    }
}
public with sharing class BWC_OrderCallout {

    public static final String API_ORDER_HISTORY = 'Order_History';
    public static final String API_ORDER_DETAILS = 'Order_Details';

    public class GetOrderHistoryCallout extends BWC_Callout {

        BWC_Order.OrderHistoryRequest request;
        BWC_Order.OrderHistoryResponse response;

        public GetOrderHistoryCallout(BWC_Order.OrderHistoryRequest request){
            this.setCallout(API_ORDER_HISTORY, request, null, null, null);
        }

        public override Object buildResponse(){
            this.response = new BWC_Order.OrderHistoryResponse();
            this.response.orders = (List<BWC_Order.OrderDetail>) this.deserialize(List<BWC_Order.OrderDetail>.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);

            return this.response;
        }

    }

    public class GetOrderDetailsCallout extends BWC_Callout {

        BWC_Order.OrderDetailsResponse response;

        public GetOrderDetailsCallout(String orderId){
            this.setCallout(API_ORDER_DETAILS, null, orderId, null, null);
        }

        public override Object buildResponse(){
            this.response = new BWC_Order.OrderDetailsResponse();
            this.response.details = (BWC_Order.OrderDetail) this.deserialize(BWC_Order.OrderDetail.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);

            return this.response;
        }

    }
}
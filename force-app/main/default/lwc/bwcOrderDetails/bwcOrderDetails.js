import { LightningElement, api, track, wire } from 'lwc';
import HideLightningHeader from '@salesforce/resourceUrl/HideAppPageHeader';
import { loadStyle } from 'lightning/platformResourceLoader';
import {CurrentPageReference} from "lightning/navigation";
import { bwcPubSubFireEvent} from 'c/bwcPubSub';

//Custom permissions
import hasViewDeviceEquipmentReturnsPermission from '@salesforce/customPermission/View_Device_Equipment_Returns';

//Other components
import * as BwcUtils from 'c/bwcUtils';
import * as BwcOrderServices from 'c/bwcOrderServices';
import Order, {isFalloutOrder} from 'c/bwcOrder';
import { createActivity, InteractionActivityValueMapping } from 'c/bwcInteractionActivityService'

export default class BwcOrderDetails extends LightningElement {

    _interactionId;
    _ban;
    _orderId;
    _recordId;
    showOrder=false;
    isFallout = false;

    @api accountId;
    @api tabTitle;

    @track products=[];
    @track productPromotion = {};
    @track paymentTenders = [];
    @track promotions=[];
    @track fulfillments = [];
    @track addresses = [];
    @track returns = [];
    @track hasReturnItems = false;
    @track currentOrder;
    @track productDetails;
    orderPrice;

    @wire(CurrentPageReference)
    pageRef;

    connectedCallback(){

        //To get rid of the header from an lightning app page
        loadStyle(this, HideLightningHeader)
        .then(()=>{
            BwcUtils.log('Header should be removed')
        })
        .catch(()=>{
            BwcUtils.log('there was an error loading the external css')
        });

        this._orderId = this.pageRef.state.c__orderId;
        this._recordId = this.pageRef.state.c__recordId;

        this.callGetOrderDetail();
    }

    /**
     * Calls API to retrieve order-specific details
     */
    async callGetOrderDetail(){

        try {

            const orderDetail = await BwcOrderServices.getOrderDetail(this._recordId, this._orderId)
            

            const order = orderDetail.details;
            const newOrder = Order.fromResponse(order);

            this.showOrder=true;
            this.products = newOrder.products;
            this.productDetails= newOrder.products;
            this.paymentTenders = newOrder.paymentTenders;
            this.promotions = newOrder.promotions;
            this.fulfillments = newOrder.fulfillments;
            this.addresses = newOrder.addresses;
            this.hasReturnItems = newOrder.hasReturnItems;
            this.returns = newOrder.returns;
            this.isFallout = isFalloutOrder(order);
            this.orderPrice = newOrder.orderPrice?.total || 0.00;
            this.currentOrder = order;

            bwcPubSubFireEvent(this.pageRef, 'pubsubproductdetails',this.productDetails);


        } catch (error) {
            const toastArgs = {
                title:'Error',
                message:error.message,
                variant:'error',
            }
            BwcUtils.showToast(this, toastArgs);
            BwcUtils.error(error);
        }
    }

    handleReturnTabOpen(){

        this.createInteractionActivity(InteractionActivityValueMapping.OrderDetailsReturns);
    }

    createInteractionActivity(action){

        let interactionId = BwcUtils.getInteractionIdFromUrl();

        let intActPayload = {
            recordId: interactionId,
            service: 'TBD',
            serviceName: 'TBD',
            ban: this.currentOrder.billingAccountNumber,
            orderDetails:{
                orderNumber: this.currentOrder.orderId,
                orderDate: this.currentOrder.orderDate,
                orderType: this.currentOrder.orderType,
                returnType: this.currentOrder.returnType
            }
        }

        createActivity(interactionId, action, intActPayload);

        BwcUtils.log('interaction activity event fired');
    }

    get showReturnsTab(){
        return hasViewDeviceEquipmentReturnsPermission && this.hasReturnItems;
    }
}
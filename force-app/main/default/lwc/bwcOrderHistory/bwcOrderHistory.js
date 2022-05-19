import {  api, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';

// LWC
import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcOrder from 'c/bwcOrder';
import BwcPageElementBase from 'c/bwcPageElementBase';
import * as BwcLabelServices from 'c/bwcLabelServices';
import * as BwcOrderServices from 'c/bwcOrderServices';
import * as BwcInteractionServices from 'c/bwcInteractionServices';
import { createActivity, InteractionActivityValueMapping } from 'c/bwcInteractionActivityService';

// Apex
import getBillingAccountsId from '@salesforce/apex/BWC_OrderController.getBillingAccountsId';

//Interaction fields
import AUTH_JSON from '@salesforce/schema/Interaction__c.Authorization_Json__c';

//Fields to display in the modal
const FULFILLMENT_MODAL_FIELDS = [
    {field: 'fulfillmentType', label: 'Fulfillment Type'},
    {field: 'fulfillmentStatus', label: 'Fulfillment Status'},
];

const TRADE_IN = 'Trade-in';
const WARNING_ICON = 'utility:warning';
const ERROR_VARIANT_ICON = 'error';
const RIGHT_POSITION = 'right';

const INTERACTION_FIELDS = [
    AUTH_JSON
];

export default class BwcOrderHistory extends BwcPageElementBase {

    // Labels
    labels = BwcLabelServices.labels;

    // The Salesforce Person Account Record Id
    @api recordId;

    error = '';

    orderHistoryColumns = [
        { label: 'Order Number', fieldName: 'orderId', type: 'button', sortable: true, typeAttributes: {label: {fieldName: 'orderId'}, name:'orderDetails', variant: 'base'},initialWidth:160},
        { label: 'Order Date', fieldName: 'orderDate', type: 'text', hideDefaultActions: true, initialWidth:146},
        { label: this.labels.account, fieldName: 'billingAccountNumber', type: 'text', hideDefaultActions: true ,initialWidth:146},
        { label: 'Order/Fulfillment Type', fieldName: 'orderType', type: 'text', sortable: true, hideDefaultActions: true, cellAttributes: {wrapText: true}, initialWidth:180},
        { label: 'LOB', fieldName: 'lineBusiness', type: 'text', sortable: true, hideDefaultActions: true, cellAttributes: {wrapText: true}, initialWidth:146 },
        { label: 'Install Date', fieldName: 'installationDate', type: 'date-local', typeAttributes: {month: '2-digit', day: '2-digit'}, hideDefaultActions: true, initialWidth:146 },
        { label: 'Return Type', fieldName: 'returnType', type: 'text', hideDefaultActions: true, cellAttributes: {wrapText: true}, initialWidth:146  },
        { label: 'Order Status', fieldName: 'status', type: 'iconText', sortable: true, hideDefaultActions: true, initialWidth:150,
            typeAttributes: {
                iconName: {fieldName: 'statusIcon'},
                iconVariant: {fieldName : 'iconVariant'},
                iconAlternativeText: {fieldName: 'iconAlternativeText'},
                iconPosition: {fieldName: 'iconPosition'}
            },
        },
    ];

    authBANMap;

    //Get information from current interaction
    @wire(getRecord, {recordId: '$recordId', fields: INTERACTION_FIELDS})
    wiredInteraction({error, data}){

        if(data){
            this.processAuthJson(getFieldValue(data, AUTH_JSON));
        }

        if(error){
            BwcUtils.log(error);
        }
    }

    orderHistoryData;
    localOrderHistory;
    currentRow;
    interaction;
    //Used to get the fulfillment information when an user clicks the orderId
    orderMap = new Map();

    //Used to store all the  billing account numbers from the order history response
    banSet = new Set();

    //Used to store all the billingAccountIds
    banMap = {}

    // Used to show spinner as the billing are being loaded.
    isLoading = false;

    // Used to do operation once upon first render
    isRendered = false;

    showOrderHistoryTable = false;
    showOrderHistoryEmpty = true;
    showOrderDetailView = false;
    isDetailsModalOpen = false;

    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field] || '';
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.localOrderHistory];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.localOrderHistory = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    // refresh the order history data
    handleOrderHistoryRefresh() {
        // this.openOrderDetailsSubtab();
        this.callOrderHistoryData();
    }

    //Show order fulfillment details
    openOrderDetailsModal(){
        this.isDetailsModalOpen = true;
    }

    //hide order fulfillment details
    closeOrderDetailsModal(){
        this.isDetailsModalOpen = false;
    }

    // The LWC framework calls this method when the LWC is loaded.
    async renderedCallback() {
        if (this.isRendered) {
            return;
        }
        this.isRendered = true;

        // call order api
        this.callOrderHistoryData();
        this.interaction = await BwcInteractionServices.getInteraction(this.recordId);
    }

    // get order data
    async callOrderHistoryData() {
        // hide table and empty message, show spinner
        this.showOrderHistoryTable = false;
        this.showOrderHistoryEmpty = false;
        this.isLoading = true;
        
        
        try{
            const responseWrapper = await BwcOrderServices.getOrderHistory(this.recordId)

            this.orderHistoryData = responseWrapper.orders;
            this.buildLocalOrderHistory();

            if(this.orderHistoryData.length > 0) {
                this.showOrderHistoryTable = true;
                this.showOrderHistoryEmpty = false;
            } else {
                this.showOrderHistoryEmpty = true;
            }

            // Stop spinner.
            this.isLoading = false;
    }
        catch(error) {
            this.error = (error);
            this.isLoading = false;
            BwcUtils.log('Error calling getOrderHistoryData. Error: ' , error);
        };
    }

    // fill out the object used to populate the table
    buildLocalOrderHistory() {

        let newHistory = [];
        this.localOrderHistory = [];
        this.accountNumbersSet = [];

        let orderedItemsFilter = item=>!item.isReturnItem && !item.isTradeInDevice;


        for(let order of this.orderHistoryData) {

            // API sometimes sends empty objects
            if(order.orderId === null || order.orderId === undefined){
                continue;
            }

            let newOrder = {};
            newOrder.orderId = order.orderId;
            newOrder.orderDate = order.orderDate;
            newOrder.lineBusiness = order?.products?.[0]?.lineOfBusiness || '';
            newOrder.orderType = order?.fulfillments?.[0]?.fulfillmentType;
            newOrder.billingAccountNumber = order?.accounts?.[0]?.accountNumber;
            newOrder.status = order?.orderStatus?.code;
            newOrder.orderStatus = order.orderStatus;
            newOrder.products = order.products;
            newOrder.returnType = this.getReturnType(order);
            newOrder.interactionId = this.recordId;
            newOrder.statusIcon = BwcOrder.isFalloutOrder(order) ? WARNING_ICON : '';
            newOrder.iconVariant = newOrder.statusIcon === WARNING_ICON ? ERROR_VARIANT_ICON :'';
            newOrder.iconPosition = RIGHT_POSITION;
            newOrder.fulfillments = order.fulfillments;

            this.banSet.add(newOrder.billingAccountNumber);

            //Populating map, so we can get this information later in constant time
            this.orderMap.set(newOrder.orderId, newOrder);

            newHistory.push(newOrder);
        }

        this.localOrderHistory = newHistory;
        this.callGetBillingAccountsId();
        BwcUtils.log(this.localOrderHistory);
    }

    getReturnType(order){

        let hasTradeIn = order.products?.some(product=> product.items?.some(item=>item.isTradeInDevice));

        return hasTradeIn ? TRADE_IN : '';
    }
    /**
     * @param  {} products array of products returned by the API
     * @param  {} filter arrow function applied to the items attribute of the product
     * @returns products with items that meet the criteria of the filter
     */
    getFilteredProducts(products, filterFunction){
        return products.map(product=>{

            let updatedProduct = {...product};

            let filteredItems = updatedProduct.items?.filter(filterFunction);

            if(filteredItems){
                updatedProduct.items = filteredItems;
            }

            return updatedProduct;

        });
    }

    // hide the order detail modal
    closeOrderDetailsView() {
        this.showOrderDetailView = false;
    }

    // handle row action
    handleRowAction(event) {
        switch (event.detail.action.name) {
            case 'orderDetails':
                this.currentRow = event.detail.row;
                this.logInteractionActivity(event.detail.row);
                this.openOrderDetailsSubtab();
                break;

            default:
                BwcUtils.error('Unknown action: ' + event.detail.action.name);
                break;
        }
    }

    async logInteractionActivity(row){
        
        let individualId;
        let interactionId = this.interaction;

        if(interactionId!=null){
            individualId = interactionId.Customer__r.Individual_ID__c;
        }

        const shipmentStatusSummary = row.fulfillments.map( fulfillment => {
            return fulfillment.shipments?.map(shipment => shipment.shipmentStatus);
         }).flat(1).filter(status => status).join(', ');

        const lineLevelStatusSummary = row.products.map(product => {
             return product.lines.map(line => line.lineStatus?.code);
         }).flat(1).filter(status => status).join(', ');
        
        const detailRecord = { 
            "recordId": this.recordId,
            "individualId": individualId, 
            "ban": row.billingAccountNumber, 
            "orderDetails": { 
                "orderNumber":row.orderId, 
                "orderDate":row.orderDate, 
                "orderType": row.orderType, 
                "orderTypeBroadband":"UVerse",
                "orderStatus": row.status,
                "lineLevelStatus": lineLevelStatusSummary,
                "shipmentStatus": shipmentStatusSummary
            }
        }
        createActivity(this.recordId, InteractionActivityValueMapping.ViewOrders, detailRecord);
    }

    /**
     * Method that opens a subtab on the console.
     * It sends the order information as params
     * User must be L1 authenticated in order to access order detail information
     */
    openOrderDetailsSubtab(){

        //get Order from Map
        let order = this.orderMap.get(this.currentRow.orderId);
        BwcUtils.log('***billingAccountNumber', order.billingAccountNumber);


        let authBan = this.authBANMap.get(order.billingAccountNumber);

        if(!authBan || !BwcConstants.AuthenticationLevel.isL1Privileged(authBan)){
            return;
        }

        let banId = this.banMap[order.billingAccountNumber];

        const message = {
            label: `Order ${this.currentRow.orderId}`,
            icon: 'custom:custom93',
            pageReference: {
                type: 'standard__component',
                attributes: {
                    componentName: 'c__BWCOrderDetailsPage'
                },
                state:{
                    c__ban:banId,
                    c__orderId: this.currentRow.orderId,
                    c__recordId: this.recordId
                }
            },
        };

        BwcUtils.openSubTab(message);
    }

    callGetBillingAccountsId(){
        // Sometimes we get empty orders, which leads to empty billing accounts. Here we remove undefined values form the array85732096
        let banlist = Array.from(this.banSet).filter(ban=>ban);
        getBillingAccountsId({bans: banlist})
        .then((result)=>{
            BwcUtils.log('getBillingAccountsId');
            BwcUtils.log({result})
            this.banMap = JSON.parse(result);
        })
        .catch((error)=>{
            BwcUtils.error(error);
        })
    }

    /**
     * Method that populates authBANMap, used to decide whether the user can access additional order information or not
     * @param  {} authJson json from interaction record which specifies the authentication and authorization level for each associated account
     */
    processAuthJson(authJson){
        let parsedJson = JSON.parse(authJson);
        let { associatedAccounts } = parsedJson;

        this.authBANMap = new Map();

        associatedAccounts.forEach(account=>{
            this.authBANMap.set(account.accountBan, account.authorizationLevel);
        });

    }

    handleLmsRefresh(scope, recordId){
        if(!scope && recordId === this.recordId){
            this.callOrderHistoryData();
        }
    }

    //List of fields we show in the order fulfillment details modal
    get orderDetails(){

        let details = [];
        for(let field of FULFILLMENT_MODAL_FIELDS){
            let newDetail = {};
            let currentRow = this.orderMap.get(this.currentRow.orderId);
            newDetail.label = field.label;
            newDetail.value = currentRow[field.field];

            details.push(newDetail);
        }

        return details;
    }

}
import * as BwcPageHelpers from 'c/bwcPageHelpers';

const TRADE_IN = 'Trade-in';
const PENDING_STATUS = 'Pending';
const IN_QUEUE_STATUS = 'In Queue';
const OPEN_STATUS = 'OPEN';

export const isFalloutOrder = order=>{

    if(order?.orderStatus?.code !== OPEN_STATUS){
        return false;
    }

    return order.products?.some(product=>
        product.lines?.some(line=> line.lineStatus?.clientStatus === PENDING_STATUS || line.lineStatus?.clientStatus === IN_QUEUE_STATUS)
    );
}

/*
    Open order details in a subtab.
*/
export const openOrderDetails = (recordId, orderId) => {

    const pageReference = {
        type: 'standard__component',
        attributes: {
            componentName: 'c__BWCOrderDetailsPage'
        },
        state:{
            c__orderId: orderId,
            c__recordId: recordId
        }
    };

    BwcPageHelpers.openSubtab(pageReference, `Order ${orderId}`, 'custom:custom93');

}

export default class Order {

    orderId;
    originChannel;
    products;
    paymentTenders;
    promotions;
    fulfillments;
    addresses;
    hasReturnItems;
    returns;

    static fromResponse(order){

        let returnsTradeInItemsFilter = item=>item.isReturnItem || item.isTradeInDevice;
        let orderedItemsFilter = item=>!item.isReturnItem && !item.isTradeInDevice;

        const sortMap = {
            uverse: 1,
            wireless: 2    
        }

        const orderFunction = (a, b) => {
            // Anything other LOB comes last
            if (!b.lineOfBusiness || !sortMap[b.lineOfBusiness.toLowerCase()] || sortMap[a.lineOfBusiness.toLowerCase()] < sortMap[b.lineOfBusiness.toLowerCase()]) {
                return -1;
            }
            else if (!a.lineOfBusiness || !sortMap[a.lineOfBusiness.toLowerCase()] || sortMap[b.lineOfBusiness.toLowerCase()] > sortMap[a.lineOfBusiness.toLowerCase()]) {
                return 1;
            }
            return 0;
        };

        const newOrder = new Order();

        for(let property in order){
            if (Object.prototype.hasOwnProperty.call(order, property)) {
                newOrder[property] = order[property];
            }
        }
        
        newOrder.products = Order.getFilteredProducts(order.products, orderedItemsFilter);
        newOrder.returns =  Order.getReturnItems(order.products, returnsTradeInItemsFilter);
        newOrder.hasReturnItems = Order.hasTradeInOrReturn(order);
        newOrder.returnType = Order.getReturnType(order);
        newOrder.paymentTenders = Order.getPaymentTenders(order);
        newOrder.products.sort(orderFunction);
        return newOrder;
    }

    /**
    * @param  {} order returned by the Order Detail API
    * @returns true if the order has tradeIn or return Items
    */
    static hasTradeInOrReturn(order){
        return order.products?.some(product=> product.items?.some(item=>item.isTradeInDevice || item.isReturnItem));
    }

    static getFilteredProducts(products, filterFunction){
        return products.map(product=>{

            let updatedProduct = {...product};

            let filteredItems = updatedProduct?.items?.filter(filterFunction);

            if(filteredItems!==undefined){
                updatedProduct.items = filteredItems;
            }


            return updatedProduct;

        });
    }

    /**
     * @param  {} products array of products returned by the API
     * @returns an array of items with productSequenceNumber which isReturnItem or isTradeInDevice are true
     */
    static getReturnItems(products, filterFunction){

        if(!products){
            return [];
        }

        return products
                .map( (product) => (!product.items) ? [] :
                    product.items
                    .map((tempItem)=>{
                        let item = {...tempItem};
                        item.productSequenceNumber = product.productSequenceNumber;
                        return item;
                    }) 
                )
                .flat(1)
                .filter(filterFunction);
    }

    static getReturnType(order){

        let hasTradeIn = order.products?.some(product=> product.items?.some(item=>item.isTradeInDevice));

        return hasTradeIn ? TRADE_IN : '';
    }

       /**
     * @param  {} order
     * @returns an array of payment tenders with additional information (CTN, itemDescription)
     */
    static getPaymentTenders(order){

        const items = order.products.map(product=>product.items).flat(1);
        const lines = order.products.map(product=>product.lines).flat(1);
        if(!order.paymentTenders){
            return [];
        }
        const paymentTenders = order.paymentTenders.map( payment =>{

            const paymentTender = {...payment};

            const matchingItem = items.find(item=>{
                return item.payments?.find(itemPayment => itemPayment.paymentTenderSequence === payment.tenderSequence);
            });

            const lineSequence = matchingItem?.lineSequence;

            paymentTender.ctn = lines.find(line => line.lineSequence === lineSequence)?.customerTelephoneNumber;
            paymentTender.device = matchingItem?.itemDescription;

            return paymentTender;
        });

        return paymentTenders;
    }

}
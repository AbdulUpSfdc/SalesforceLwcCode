import * as BwcUtils from 'c/bwcUtils';
import getOrderHistoryCont from '@salesforce/apexContinuation/BWC_OrderController.getOrderHistoryCont';
import getOrderDetailsCont from '@salesforce/apexContinuation/BWC_OrderController.getOrderDetailsCont';

export const getOrderDetail = async (recordId, orderId) => {

    BwcUtils.log(`call getOrderDetail: recordId = ${recordId} orderId = ${orderId}`);

    const orderDetailResultJson = await getOrderDetailsCont({interactionId: recordId, orderId: orderId});

    BwcUtils.log('result getOrderDetail: ' + orderDetailResultJson);

    const orderDetailResult = JSON.parse(orderDetailResultJson);


    return orderDetailResult;

};

export const getOrderHistory =  async interactionId => {
   
    BwcUtils.log(`call getOrderHistory, interactionId: ${interactionId}`);

    const responseWrapperJson = await getOrderHistoryCont({interactionId: interactionId});

    BwcUtils.log('response getOrderHistory: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);

    return responseWrapper;

    
};
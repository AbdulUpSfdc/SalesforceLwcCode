import * as BwcUtils from 'c/bwcUtils';
import getChargeCodesByMarketApex from '@salesforce/apex/BWC_ChargeCodeServiceController.getChargeCodesByMarket';
import getReasonForChargeCodeApex from '@salesforce/apex/BWC_ChargeCodeServiceController.getReasonForChargeCode';
import getGoodwillAdjustmentReasonsApex from '@salesforce/apex/BWC_ChargeCodeServiceController.getGoodwillAdjustmentReasons';
import getLineItemAdjustmentReasonsApex from '@salesforce/apex/BWC_ChargeCodeServiceController.getLineItemAdjustmentReasons';

export const getChargeCodesByMarket = async (billingMarket) => {

    BwcUtils.log('call getChargeCodesByMarket', billingMarket);

    const response = await getChargeCodesByMarketApex({ billingMarket });
   
    BwcUtils.log('response getChargeCodesByMarket', response);

    return response;
};

export const getReasonForChargeCode = async (chargeCode, chargeType) => {

    BwcUtils.log('call getReasonForChargeCode', chargeCode, chargeType);

    const response = await getReasonForChargeCodeApex({ chargeCode, chargeType });
   
    BwcUtils.log('response getReasonForChargeCode', response);

    return response;
}

export const getGoodwillAdjustmentReasons = async () => {

    BwcUtils.log('call getGoodwillAdjustmentReasons');

    const response = await getGoodwillAdjustmentReasonsApex();
   
    BwcUtils.log('response getGoodwillAdjustmentReasons', response);

    return response;
}

export const getLineItemAdjustmentReasons = async () => {

    BwcUtils.log('call getLineItemAdjustmentReasons');

    const response = await getLineItemAdjustmentReasonsApex();
   
    BwcUtils.log('response getLineItemAdjustmentReasons', response);

    return response;
}
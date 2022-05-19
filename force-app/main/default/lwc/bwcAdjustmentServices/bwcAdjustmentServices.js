import * as BwcUtils from 'c/bwcUtils';
import getPostedAdjustmentsCont from '@salesforce/apexContinuation/BWC_AdjustmentsController.getPostedAdjustmentsCont';
import getPendingAdjustmentsCont from '@salesforce/apexContinuation/BWC_AdjustmentsController.getPendingAdjustmentsCont';
import getCdeRecommendationsCont from '@salesforce/apexContinuation/BWC_AdjustmentsController.getCdeRecommendationsCont';
import postAdjustmentsApex from '@salesforce/apex/BWC_AdjustmentsController.postAdjustments';
import reverseAdjustmentApex from '@salesforce/apex/BWC_AdjustmentsController.reverseAdjustment';

export const getPostedAdjustments = async (recordId, requests) => {

    BwcUtils.log( 'call getPostedAdjustments', recordId, requests );

    const requestsJson = JSON.stringify(requests);

    const responseJson = await getPostedAdjustmentsCont({ recordId, requestsJson });

    const response = JSON.parse(responseJson);

    BwcUtils.log('response getPostedAdjustments', response);

    return response.response;

}

export const getPendingAdjustments = async (recordId, requests) => {

    BwcUtils.log( 'call getPendingAdjustments', recordId, requests );

    const requestsJson = JSON.stringify(requests);

    const responseJson = await getPendingAdjustmentsCont({ recordId, requestsJson });

    const response = JSON.parse(responseJson);

    BwcUtils.log('response getPendingAdjustments', response);

    return response.response;

}

export const getCdeRecommendations = async (recordId, request) => {

    BwcUtils.log( 'call getCdeRecommendations', recordId, request );

    const requestJson = JSON.stringify(request);

    const responseJson = await getCdeRecommendationsCont({ recordId, requestJson });

    const response = JSON.parse(responseJson);

    BwcUtils.log('response getCdeRecommendations', response);

    return response;

}

export const postAdjustments = async (recordId, request) => {

    BwcUtils.log( 'call postAdjustments', recordId, request );

    const requestJson = JSON.stringify(request);

    const responseJson = await postAdjustmentsApex({ recordId, requestJson });

    const response = JSON.parse(responseJson);

    BwcUtils.log('response postAdjustments', response);

    return response;

}

export const reverseAdjustment = async (recordId, request) => {

    BwcUtils.log('call reverseAdjustment', request);

    const requestJson = JSON.stringify(request);
    
    const responseJson = await reverseAdjustmentApex({ recordId, requestJson });
    
    const response = JSON.parse(responseJson);

    BwcUtils.log(`response reverseAdjustment`, response);

    return response;
}
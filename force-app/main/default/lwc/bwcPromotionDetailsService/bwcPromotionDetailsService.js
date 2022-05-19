import * as BwcUtils from 'c/bwcUtils';
import getPromotionDetailsCont from '@salesforce/apexContinuation/BWC_PromotionDetailsController.getPromotionDetailsForBillingAccountCont';


export const getPromotionDetailsForBillingAccount = async (recordId, interactionId) => {

    BwcUtils.log(`call Get Promotopn Details, recordId: ${recordId}, interactionId: ${interactionId}`);

    const responseWrapperJson = await getPromotionDetailsCont({recordId: recordId, InteractionId: interactionId});

    const responseWrapper = JSON.parse(responseWrapperJson);

    BwcUtils.log('result getPromotionDetails: ' , responseWrapperJson);

    return responseWrapper.responses;

};
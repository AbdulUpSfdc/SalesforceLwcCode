import getAddOnsForBillingAccountCont from '@salesforce/apexContinuation/BWC_AddOnsController.getAddOnsForBillingAccountCont';
import * as BwcUtils from 'c/bwcUtils';
export const getAddOnsForBillingAccount =  async (recordId,interactionId) => {
  

     BwcUtils.log(`call getAddOnsForBillingAccount, recordId: ${recordId}, interactionId: ${interactionId}`);
 
     const responseWrapperJson = await getAddOnsForBillingAccountCont({recordId: recordId,InteractionId: interactionId});
 
     BwcUtils.log('response getAddOnsForBillingAccount: ' + responseWrapperJson);
 
     const responseWrapper = JSON.parse(responseWrapperJson);
 
     return responseWrapper;
 
     
 }
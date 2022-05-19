import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import checkAuthorizationStatusCont from '@salesforce/apexContinuation/BWC_AuthorizationController.checkAuthorizationStatusCont';
import isAuthenticatedWithOtpApex from '@salesforce/apex/BWC_AuthorizationController.isAuthenticatedWithOtp';
import setNoAuthenticationApex from '@salesforce/apex/BWC_AuthorizationController.setNoAuthentication';

export const checkAuthorizationStatus = async (interactionId, billingAccountId) => {

    const request = {
        interactionId: interactionId,
        billingAccountId: billingAccountId
    };

    BwcUtils.log('call checkAuthorizationStatus: ' + JSON.stringify(request));

    const responseJson = await checkAuthorizationStatusCont(request);

    BwcUtils.log('result checkAuthorizationStatus: ' + responseJson);
    
    return JSON.parse(responseJson);

};

export const isAuthenticatedWithOtp = async (interactionId, billingAccountId) => {

    const request = {
        interactionId: interactionId,
        billingAccountId: billingAccountId
    };

    BwcUtils.log('call isAuthenticatedWithOtp: ' + JSON.stringify(request));

    const response = await isAuthenticatedWithOtpApex(request);

    BwcUtils.log('result isAuthenticatedWithOtp: ' + response);
    
    return response;

};

export const setNoAuthentication = async interactionId => {

    BwcUtils.log('call setNoAuthentication: ' + interactionId);

    await setNoAuthenticationApex({interactionId});

    BwcUtils.log('result checkAuthorizationStatus');

};

/*
    Determine if the content indicates that at least one BAN is not L1.
*/
export const hasL0Bans = (authorizationStatusContent) => {

    if (!authorizationStatusContent || !authorizationStatusContent.associatedAccounts) {
        // Nothing is L1
        return true;
    }

    const associatedL0 = authorizationStatusContent.associatedAccounts.find(account => account.authorizationLevel === BwcConstants.AuthenticationLevel.L0.value);
    if (associatedL0) {
        // There is at least one explicitly L0 account
        return true;
    }

    // Now see if there is recommended step up that is not represented in associatedAccounts
    if (authorizationStatusContent.recommendedStepUps) {

        let found = false;
        authorizationStatusContent.recommendedStepUps.forEach(stepUp => {

            if (!authorizationStatusContent.associatedAccounts.find(account => account.accountBan === stepUp.accountBan)) {
                // There is BAN with step up information and not L1 in associated Accounts -- so it's L0
                found = true;
            }

        });

        if (found) {
            return true;
        }

    }

    // All are L1
    return false;

}
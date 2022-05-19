/*
    Apex services for API_CUSTOMER_PROFILE.
*/
public with sharing class BWC_CustomerProfileService {

    /*
        Reset MyAT&T password and/or security question.
    */
    public static BWC_CustomerProfile.PasswordResetResponse resetPassword(BWC_CustomerProfile.PasswordResetRequest request) {

        // Fill in request fields
        if (request != null && String.isEmpty(request.domain)) {
            request.domain = 'slid.dum';
        }

        return BWC_CustomerProfileCallout.resetPassword(request);

    }

}
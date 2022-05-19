public with sharing class BWC_MakePaymentService {

    private static final STRING FIELDS_ROOT_PATH_ADD = 'makePaymentAccountRequest[0].makePaymentItemRequest[{i}]';
    private static final STRING FIELDS_ROOT_PATH_EDIT = 'modifyFuturePaymentRequest[{i}]';
    private static final STRING FIELDS_ROOT_PATH_ADD_EPA = 'makePaymentItemRequest';
    private static final STRING FIELDS_ROOT_PATH_BANKACCOUNT = '.paymentMethod.bankAccount.';
    private static final STRING FIELDS_ROOT_PATH_CARD = '.paymentMethod.card.';
    private static final STRING FIEDLS_ROOT_PATH_PROFILE_CVV = '.paymentMethod.paymentProfile.securityCode';
    private static final STRING[] BANKACCOUNT_FIELDS_LIST = new STRING[] { 'routingNumber', 'bankAccountNumber' };
    private static final STRING[] CARD_FIELDS_LIST = new STRING[] { 'cardNumber', 'expirationDate', 'securityCode', 'zipCode' };
    private static final STRING BSSE_SOURCE_SYSTEM = 'RTB';
    private static final STRING BSSE_SOURCE_LOCATION = 'XX';

    public static BWC_MakePayment.MakePaymentResponse makePayment(BWC_MakePayment.MakePaymentRequest request) {
        return makePayment(request, null);
    }

    public static BWC_MakePayment.MakePaymentResponse makePayment(BWC_MakePayment.MakePaymentRequest request, List<BWC_MakePayment.SpiData> paymentSPIData) {

        // Get tokenized fields
        List<String> tokenizedFields = new List<String>();
        if (paymentSPIData != null && paymentSPIData.size() > 0) {
            for (Integer i = 0; i < paymentSPIData.size(); i++) {
                tokenizedFields.addAll(getTokenizedFields(paymentSPIData[i], FIELDS_ROOT_PATH_ADD.replace('{i}', String.valueOf(i))));
            }
        }

        // Set fixed values
        if (String.isEmpty(request.locationId)) {
            request.locationId = BWC_Constants.LOCATION_ID;
        }
        if (String.isEmpty(request.sourceBusinessUnit)) {
            request.sourceBusinessUnit = BWC_Constants.SOURCE_BUSINESS_UNIT;
        }
        if (String.isEmpty(request.appName)) {
            request.appName = BWC_Constants.APP_NAME;
        }
        if (String.isEmpty(request.sourceSystem)) {
            request.sourceSystem = BWC_Constants.SOURCE_SYSTEM;
        }
        if (String.isEmpty(request.sourceLocation)) {
            request.sourceLocation = BWC_Constants.SOURCE_LOCATION;
        }

        // User ID gets user's ATT User ID
        if (String.isEmpty(request.sourceUser)) {
            request.sourceUser = BWC_Utils.getCurrentUserAttId();
        }

        // Set Merchant ID for cards or profiles
        if (request.makePaymentAccountRequest != null) {

            for (BWC_MakePayment.MakePaymentAccountRequest makePaymentAccountRequest : request.makePaymentAccountRequest) {

                if (makePaymentAccountRequest.makePaymentItemRequest != null) {

                    Integer i = 0; // Counter for tokenized fields
                    for (BWC_MakePayment.PaymentItemRequest makePaymentItemRequest : makePaymentAccountRequest.makePaymentItemRequest) {

                        if (makePaymentItemRequest.paymentMethod != null) {

                            if (makePaymentItemRequest.paymentMethod.card != null &&
                                String.isEmpty(makePaymentItemRequest.paymentMethod.card.merchantId)) {

                                makePaymentItemRequest.paymentMethod.card.merchantId = BWC_Constants.MERCHANT_ID;

                            }

                            if (makePaymentItemRequest.paymentMethod.paymentProfile != null &&
                                String.isEmpty(makePaymentItemRequest.paymentMethod.paymentProfile.merchantId)) {

                                    makePaymentItemRequest.paymentMethod.paymentProfile.merchantId = BWC_Constants.MERCHANT_ID;

                            }

                            // If there is a security code and it's more than 4 characters (tokenized), 
                            // get profile security code tokenized field
                            if (makePaymentItemRequest.paymentMethod.paymentProfile != null &&
                                makePaymentItemRequest.paymentMethod.paymentProfile.securityCode != null &&
                                makePaymentItemRequest.paymentMethod.paymentProfile.securityCode.length() > 4) {
                                    //Add path of profile security code tokenized field
                                    tokenizedFields.add(FIELDS_ROOT_PATH_ADD.replace('{i}', String.valueOf(i))+FIEDLS_ROOT_PATH_PROFILE_CVV);
                            }
                        }

                        i++;

                    }

                }

            }

        }

        // Tokenized fields
        if (!tokenizedFields.isEmpty()) {
            request.tokenizedFields = tokenizedFields;
        }

        BWC_MakePayment.MakePaymentResponse response = BWC_MakePaymentCallout.makePayment(request);

        return response;
    } 

    public static BWC_MakePayment.UpdatePaymentResponse updatePayment(BWC_MakePayment.UpdatePaymentRequest request) {
        return updatePayment(request, null);
    }

    public static BWC_MakePayment.UpdatePaymentResponse updatePayment(BWC_MakePayment.UpdatePaymentRequest request, List<BWC_MakePayment.SpiData> paymentSPIData) {

        // Get tokenized fields
        List<String> tokenizedFields = new List<String>();
        if (paymentSPIData != null && paymentSPIData.size() > 0) {
            for (Integer i = 0; i < paymentSPIData.size(); i++) {
                tokenizedFields.addAll(getTokenizedFields(paymentSPIData[i], FIELDS_ROOT_PATH_EDIT.replace('{i}', String.valueOf(i))));
            }
        }

        // Set fixed values
        if (String.isEmpty(request.locationId)) {
            request.locationId = BWC_Constants.LOCATION_ID;
        }
        if (String.isEmpty(request.sourceBusinessUnit)) {
            request.sourceBusinessUnit = BWC_Constants.SOURCE_BUSINESS_UNIT;
        }
        if (String.isEmpty(request.appName)) {
            request.appName = BWC_Constants.APP_NAME;
        }
        if (String.isEmpty(request.sourceSystem)) {
            request.sourceSystem = BWC_Constants.SOURCE_SYSTEM;
        }
        if (String.isEmpty(request.sourceLocation)) {
            request.sourceLocation = BWC_Constants.SOURCE_LOCATION;
        }

        // User ID gets user's ATT User ID
        if (String.isEmpty(request.sourceUser)) {
            request.sourceUser = BWC_Utils.getCurrentUserAttId();
        }

        // Set Merchant ID for cards or profiles
        if (request.modifyFuturePaymentRequest != null) {

            Integer i = 0;
            for (BWC_MakePayment.PaymentItemRequest paymentItemRequest : request.modifyFuturePaymentRequest) {

                if (paymentItemRequest.paymentMethod != null) {

                    if (paymentItemRequest.paymentMethod.card != null &&
                        String.isEmpty(paymentItemRequest.paymentMethod.card.merchantId)) {

                            paymentItemRequest.paymentMethod.card.merchantId = BWC_Constants.MERCHANT_ID;

                    }

                    if (paymentItemRequest.paymentMethod.paymentProfile != null &&
                        String.isEmpty(paymentItemRequest.paymentMethod.paymentProfile.merchantId)) {

                            paymentItemRequest.paymentMethod.paymentProfile.merchantId = BWC_Constants.MERCHANT_ID;

                    }

                    // If there is a security code and it's more than 4 characters (tokenized), 
                    // get profile security code tokenized field
                    if (paymentItemRequest.paymentMethod.paymentProfile != null &&
                        paymentItemRequest.paymentMethod.paymentProfile.securityCode != null &&
                        paymentItemRequest.paymentMethod.paymentProfile.securityCode.length() > 4) {
                            //Add path of profile security code tokenized field
                            tokenizedFields.add(FIELDS_ROOT_PATH_EDIT.replace('{i}', String.valueOf(i))+FIEDLS_ROOT_PATH_PROFILE_CVV);
                    }

                }

                i++;

            }

        }

        // Tokenized fields
        if (!tokenizedFields.isEmpty()) {
            System.debug('tokenizedFields: ' + tokenizedFields);
            request.tokenizedFields = tokenizedFields;
        }

        BWC_MakePayment.UpdatePaymentResponse response = BWC_MakePaymentCallout.updatePayment(request);

        return response;
    } 

    public static BWC_MakePayment.DeletePaymentResponse deletePayment(BWC_MakePayment.DeletePaymentRequest request) {

        // Set fixed values        
        if (request.commonData == null) {
            request.commonData = new BWC_MakePayment.CommonData();
        }

        if (String.isEmpty(request.commonData.appName)) {
            request.commonData.appName = BWC_Constants.APP_NAME;
        }
        BWC_MakePayment.DeletePaymentResponse response = BWC_MakePaymentCallout.deletePayment(request);

        return response;
    } 

    public static BWC_MakePayment.EpaEnrollResponse epaEnroll(BWC_MakePayment.EpaEnrollRequest request) {
        return epaEnroll(request, null);
    }

    public static BWC_MakePayment.EpaEnrollResponse epaEnroll(BWC_MakePayment.EpaEnrollRequest request, BWC_MakePayment.SpiData spiData) {

        // Get tokenized fields
        List<String> tokenizedFields = getTokenizedFields(spiData, FIELDS_ROOT_PATH_ADD_EPA);

        // Set fixed values
        if (String.isEmpty(request.appName)) {
            request.appName = BWC_Constants.APP_NAME;
        }
        if (String.isEmpty(request.sourceSystem)) {
            request.sourceSystem = BWC_Constants.SOURCE_SYSTEM;
        }
        if (String.isEmpty(request.sourceLocation)) {
            request.sourceLocation = BWC_Constants.SOURCE_LOCATION;
        }

        // User ID gets user's ATT User ID
        if (String.isEmpty(request.sourceUser)) {
            request.sourceUser = BWC_Utils.getCurrentUserAttId();
        }

        // Tokenized fields
        if (!tokenizedFields.isEmpty()) {
            request.tokenizedFields = tokenizedFields;
        }

        // Set Merchant ID for cards or profiles
        if (request?.makePaymentItemRequest?.paymentMethod?.card != null && String.isEmpty(request?.makePaymentItemRequest?.paymentMethod?.card?.merchantId)) {
            request.makePaymentItemRequest.paymentMethod.card.merchantId = BWC_Constants.MERCHANT_ID;
        }

        if (request?.makePaymentItemRequest?.paymentMethod?.paymentProfile != null &&
            String.isEmpty(request.makePaymentItemRequest.paymentMethod.paymentProfile.merchantId)) {
            request.makePaymentItemRequest.paymentMethod.paymentProfile.merchantId = BWC_Constants.MERCHANT_ID;
        }

        // If there is a security code and it's more than 4 characters (tokenized), 
        // get profile security code tokenized field
        if (request?.makePaymentItemRequest?.paymentMethod?.paymentProfile != null &&
            request?.makePaymentItemRequest?.paymentMethod?.paymentProfile?.securityCode != null &&
            request?.makePaymentItemRequest?.paymentMethod?.paymentProfile?.securityCode?.length() > 4) {
                //Add path of profile security code tokenized field
                tokenizedFields.add(FIELDS_ROOT_PATH_ADD_EPA+FIEDLS_ROOT_PATH_PROFILE_CVV);
        }

        BWC_MakePayment.EpaEnrollResponse response = BWC_MakePaymentCallout.epaEnroll(request);

        return response;
    }

    private static Boolean listContains(Object[] source, Object target) {
        return (new Set<Object>(source)).contains(target);
    }

    private static List<String> getTokenizedFields(BWC_MakePayment.SpiData paymentSPIData, String rootPath) {
        List<String> tokenizedFields = new List<String>();
        if (paymentSPIData != null && paymentSPIData.spiDataList != null) {
            for(BWC_MakePayment.SpiDataValues eachSPIField : paymentSPIData.spiDataList){
                if(!String.isBlank(eachSPIField.token)){
                    if (listContains(BANKACCOUNT_FIELDS_LIST, eachSPIField.name)) {
                        tokenizedFields.add(rootPath+FIELDS_ROOT_PATH_BANKACCOUNT+eachSPIField.name); //Add path of tokenized Field
                    } else if (listContains(CARD_FIELDS_LIST, eachSPIField.name)) {
                        tokenizedFields.add(rootPath+FIELDS_ROOT_PATH_CARD+eachSPIField.name); //Add path of tokenized Field
                    }
                }
            }
        }
        return tokenizedFields;
    }

}
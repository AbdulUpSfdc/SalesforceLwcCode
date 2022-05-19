/*
    Service API for adding, updating, or deleting a payment profile.
*/
public with sharing class BWC_PaymentProfileService {

    private static final STRING FIELDS_ROOT_PATH_BANKACCOUNT = 'Request.paymentMethod.bankAccount.';
    private static final STRING FIELDS_ROOT_PATH_CARD = 'Request.paymentMethod.card.';
    private static final STRING[] BANKACCOUNT_FIELDS_LIST = new STRING[] { 'routingNumber', 'bankAccountNumber' };
    private static final STRING[] CARD_FIELDS_LIST = new STRING[] { 'cardNumber', 'expirationDate', 'securityCode', 'zipCode' };
    private static final STRING BSSE_SOURCE_SYSTEM = 'RTB';
    private static final STRING BSSE_SOURCE_LOCATION = 'XX';

    public static BWC_PaymentProfile.PaymentProfileResponse postPaymentProfile(BWC_PaymentProfile.PaymentProfile paymentProfile, String mode) {
        return postPaymentProfile( paymentProfile, mode, false, null );
    }

    public static BWC_PaymentProfile.PaymentProfileResponse postPaymentProfile(BWC_PaymentProfile.PaymentProfile paymentProfile, String mode, Boolean isTempProfile) {
        return postPaymentProfile( paymentProfile, mode, isTempProfile, null );
    }

    public static BWC_PaymentProfile.PaymentProfileResponse postPaymentProfile(BWC_PaymentProfile.PaymentProfile paymentProfile, String mode, BWC_PaymentProfile.SpiData paymentSPIData) {
        return postPaymentProfile( paymentProfile, mode, false, paymentSPIData );
    }

    public static BWC_PaymentProfile.PaymentProfileResponse postPaymentProfile(
        BWC_PaymentProfile.PaymentProfile paymentProfile, String mode, Boolean isTempProfile, BWC_PaymentProfile.SpiData paymentSPIData) {

        System.debug('paymentSPIData: ' + paymentSPIData);
        List<String> tokenizedFields = new List<String>();
        if (paymentSPIData != null && paymentSPIData.spiDataList != null) {
            for(BWC_PaymentProfile.SpiDataValues eachSPIField : paymentSPIData.spiDataList){
                if(!String.isBlank(eachSPIField.token)){
                    if (listContains(BANKACCOUNT_FIELDS_LIST, eachSPIField.name)) {
                        tokenizedFields.add(mode+FIELDS_ROOT_PATH_BANKACCOUNT+eachSPIField.name); //Add path of tokenized Field
                    } else if (listContains(CARD_FIELDS_LIST, eachSPIField.name)) {
                        tokenizedFields.add(mode+FIELDS_ROOT_PATH_CARD+eachSPIField.name); //Add path of tokenized Field
                    }
                }
            }
        }

        // Set fixed values
        if (paymentProfile.commonData == null) {
            paymentProfile.commonData = new BWC_PaymentProfile.CommonData();
        }
        if (String.isEmpty(paymentProfile.commonData.appName)) {
            paymentProfile.commonData.appName = BWC_Constants.APP_NAME;
        }

        if (paymentProfile.paySource == null) {
            paymentProfile.paySource = new BWC_PaymentProfile.PaySource();
        }
        if (String.isEmpty(paymentProfile.paySource.sourceSystem)) {
            paymentProfile.paySource.sourceSystem = BWC_Constants.SOURCE_SYSTEM;
        }
        if (String.isEmpty(paymentProfile.paySource.sourceLocation)) {
            paymentProfile.paySource.sourceLocation = BWC_Constants.SOURCE_LOCATION;
        }
        if (String.isEmpty(paymentProfile.paySource.sourceUser)) {
            // User's ATT User ID
            paymentProfile.paySource.sourceUser = BWC_Utils.getCurrentUserAttId();
        }
        if (paymentProfile.paymentMethod != null && paymentProfile.paymentMethod.card != null) {
            paymentProfile.paymentMethod.card.verifyCardIndicator = true;
        }

        // Merchant ID for card -- may be re-introduced
        if (paymentProfile.paymentMethod != null && paymentProfile.paymentMethod.card != null &&
            String.isEmpty(paymentProfile.paymentMethod.card.merchantId)) {
                        
            paymentProfile.paymentMethod.card.merchantId = BWC_Constants.MERCHANT_ID;

        }

        // Tokenized fields
        if (!tokenizedFields.isEmpty()) {
            System.debug('tokenizedFields: ' + tokenizedFields);
            paymentProfile.tokenizedFields = tokenizedFields;
        }

        // Request
        BWC_PaymentProfile.PaymentProfileResponse response = BWC_PaymentProfileCallout.postPaymentProfile(paymentProfile, mode, isTempProfile);

        return response;

    }

    private static Boolean listContains(Object[] source, Object target) {
        return (new Set<Object>(source)).contains(target);
    }

}
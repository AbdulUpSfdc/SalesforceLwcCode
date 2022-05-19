/* ================================================
* @author : Emmanuel Hernandez
* @date :   01/06/2021   
* @group : Auto Pay Profiles
* @description : Service class for BWC_AutoPayProfilesController
================================================*/
public with sharing class BWC_AutoPayProfilesService {

    private static final STRING FIELDS_ROOT_PATH_BANKACCOUNT = 'Request.paymentMethod.bankAccount.';
    private static final STRING FIELDS_ROOT_PATH_CARD = 'Request.paymentMethod.card.';
    private static final STRING[] BANKACCOUNT_FIELDS_LIST = new STRING[] { 'routingNumber', 'bankAccountNumber' };
    private static final STRING[] CARD_FIELDS_LIST = new STRING[] { 'cardNumber', 'expirationDate', 'securityCode', 'zipCode' };

    public static BWC_AutoPayProfiles.AutoPayProfilesPostResponse postAutoPayProfile(BWC_AutoPayProfiles.AutoPayProfile autoPayProfile, String mode){
        return postAutoPayProfile(autoPayProfile, mode, null);
    }

    public static BWC_AutoPayProfiles.AutoPayProfilesPostResponse postAutoPayProfile(BWC_AutoPayProfiles.AutoPayProfile autoPayProfile, String mode, BWC_MakePayment.SpiData paymentSPIData){
        
        // Get tokenized fields
        List<String> tokenizedFields = getTokenizedFields(paymentSPIData, mode);

        if(!BWC_AutoPayProfiles.MODES.contains(mode)){
            throw new BWC_Exception('Specified mode is not supported: '+mode);
        }

        // Set fixed values
        if (String.isEmpty(autoPayProfile.appName)) {
            autoPayProfile.appName = BWC_Constants.APP_NAME;
        }
        if (String.isEmpty(autoPayProfile.sourceLocation)) {
            autoPayProfile.sourceLocation = BWC_Constants.SOURCE_LOCATION;
        }
        if (String.isEmpty(autoPayProfile.sourceSystem)) {
            autoPayProfile.sourceSystem = BWC_Constants.SOURCE_SYSTEM;
        }

        // User ID gets user's ATT User ID
        if (String.isEmpty(autoPayProfile.sourceUser)) {
            autoPayProfile.sourceUser = BWC_Utils.getCurrentUserAttId();
        }

        // Tokenized fields
        if (!tokenizedFields.isEmpty()) {
            autoPayProfile.tokenizedFields = tokenizedFields;
        }

        BWC_AutoPayProfiles.AutoPayProfilesPostRequest request = new BWC_AutoPayProfiles.AutoPayProfilesPostRequest();
        switch on mode {
            when 'add' {
                request.addRequest = autoPayProfile;
            }
            when 'delete' {
                request.deleteRequest = autoPayProfile;
            }
            when 'update' {
                request.updateRequest = autoPayProfile;
            }
            when 'pause' {
                request.pauseRequest = autoPayProfile;
            }
            when else {
                throw new BWC_Exception('Unknow mode for AutoPayProfiles: '+mode);
            }
        } 

        BWC_AutoPayProfiles.AutoPayProfilesPostResponse response = BWC_AutoPayProfilesCallout.postAutoPayProfile(request, mode);

        return response;
    }

    private static Boolean listContains(Object[] source, Object target) {
        return (new Set<Object>(source)).contains(target);
    }

    private static List<String> getTokenizedFields(BWC_MakePayment.SpiData paymentSPIData, String mode) {
        List<String> tokenizedFields = new List<String>();
        if (paymentSPIData != null && paymentSPIData.spiDataList != null) {
            for(BWC_MakePayment.SpiDataValues eachSPIField : paymentSPIData.spiDataList){
                if(!String.isBlank(eachSPIField.token)){
                    if (listContains(BANKACCOUNT_FIELDS_LIST, eachSPIField.name)) {
                        tokenizedFields.add(mode+FIELDS_ROOT_PATH_BANKACCOUNT+eachSPIField.name); //Add path of tokenized Field
                    } else if (listContains(CARD_FIELDS_LIST, eachSPIField.name)) {
                        tokenizedFields.add(mode+FIELDS_ROOT_PATH_CARD+eachSPIField.name); //Add path of tokenized Field
                    }
                }
            }
        }
        return tokenizedFields;
    }
}
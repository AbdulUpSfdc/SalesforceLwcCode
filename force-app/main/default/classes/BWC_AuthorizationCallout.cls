public inherited sharing class BWC_AuthorizationCallout {

    public static final String API_AUTHORIZATION_STATUS = 'Authorization_Status';
    public static final String API_AUTHORIZATION_STATUS_V2 = 'Authorization_Status_v2';

    public class GetAuthorizationStatusCallout extends BWC_Callout {

        // Request and Response state
        AuthorizationStatusRequest request;
        AuthorizationStatusResponse response;

        /*
            Construct the callout object from request.
        */
        public GetAuthorizationStatusCallout(AuthorizationStatusRequest request) {

            this.setCallout(API_AUTHORIZATION_STATUS_V2, request, null, null, null);

        }

        /*
            Build final response.
        */
        public override Object buildResponse() {

            this.response = (AuthorizationStatusResponse)this.deserialize(AuthorizationStatusResponse.class);

            // Verify basic expected response
            if (this.response.content == null) {
                throw new BWC_Exception('Expected API response for type AuthorizationStatusResponse has null content node.');
            }

            return this.response;

        }

    }

    /**************************************************************************
      API Schema
    **************************************************************************/

    public class AuthorizationStatusRequest {
        public String clientId;
        public String ivrSessionId;
        public String authenticationMethod;         // NONE, ANI, PASSCODE, OTP, AUTHENTIC_ID, VOICE_BIO, ZENKEY, CUSTOMER_GRAPH_ID
        public String authenticatedAccountType;     // WIRELESS, UVERSE, DTVNOW
        public String authenticatedAccountBan;
        public String unifiedBan;
        public String aniTelephoneNumber;
        public String commonConversationId;
        public String individualId;
        public String authenticatedEmailAddress;
        public String authenticatedPhoneNumber;
        public String authenticatedIdType;
        public String authenticatedId;
    }

    public class AuthorizationStatusResponse extends BWC_Callout.CalloutResponse {
        public AuthorizationStatusContent content;
    }

    public class AuthorizationStatusContent {

        public List<AssociatedAccount> associatedAccounts;
        public List<RecommendedStepUp> recommendedStepUps;

        /*
            Merge sourceContent into existing object, without removing any other entries from the existing object.
        */
        public List<AssociatedAccount> mergeFrom(AuthorizationStatusContent sourceContent, String authenticationMethod) {

            // Track which bans are getting updated authorization
            List<AssociatedAccount> updatedAssociatedAccounts = new List<AssociatedAccount>();

            if (sourceContent.associatedAccounts != null) {

                Map<Id, AssociatedAccount> associatedAccountMap = new Map<Id, AssociatedAccount>();
                if (this.associatedAccounts != null) {
                    // Add existing associated accounts into target map
                    for (AssociatedAccount associatedAccount : this.associatedAccounts) {
                        associatedAccountMap.put(associatedAccount.billingAccountId, associatedAccount);
                    }
                }

                // Add or update associated accounts from source
                for (AssociatedAccount associatedAccount : sourceContent.associatedAccounts) {
                    AssociatedAccount existingAssociatedAccount = associatedAccountMap.get(associatedAccount.billingAccountId);

                    if (existingAssociatedAccount == null) {
 
                        // It doesn't exist, just add
                        if (associatedAccount.authorizationLevel == BWC_Authorization.AUTHORIZATION_LEVEL_L1) {
                            // It went to L1 so record authentication method
                            associatedAccount.authenticationMethod = authenticationMethod;
                        }
                        updatedAssociatedAccounts.add(associatedAccount);
                        associatedAccountMap.put(associatedAccount.billingAccountId, associatedAccount);
 
                    }
                    else {

                        // It exists already

                        // If the BAN is not already privileged, then update, otherwise leave it
                        if (associatedAccount.authorizationLevel == BWC_Authorization.AUTHORIZATION_LEVEL_L1 &&
                            !BWC_Authorization.AUTHORIZATION_LEVELS_L1_PRIVILEGED.contains(existingAssociatedAccount.authorizationLevel)) {

                            // It's not yet privileged, overwrite it with whatever is incoming
                            existingAssociatedAccount.authorizationLevel = associatedAccount.authorizationLevel;
                            existingAssociatedAccount.authenticationMethod = authenticationMethod;
                            updatedAssociatedAccounts.add(associatedAccount);

                }

                        associatedAccountMap.put(existingAssociatedAccount.billingAccountId, existingAssociatedAccount);

                    }
                }

                // Generate associated account list from final values of map
                this.associatedAccounts = new List<AssociatedAccount>(associatedAccountMap.values());

            }

            if (sourceContent.recommendedStepUps != null) {

                Map<String, RecommendedStepUp> recommendedStepUpMap = new Map<String, RecommendedStepUp>();
                if (this.recommendedStepUps != null) {
                    for (RecommendedStepUp recommendedStepUp : this.recommendedStepUps) {
                        recommendedStepUpMap.put(recommendedStepUp.billingAccountId + recommendedStepUp.stepUpType, recommendedStepUp);
                    }
                }
                for (RecommendedStepUp recommendedStepUp : sourceContent.recommendedStepUps) {
                    recommendedStepUpMap.put(recommendedStepUp.billingAccountId + recommendedStepUp.stepUpType, recommendedStepUp);
                }

                // Generate new stepup list from final values of map
                this.recommendedStepUps = new List<RecommendedStepUp>(recommendedStepUpMap.values());

            }

            // Return the list of affected associated accounts
            return updatedAssociatedAccounts;

        }

        /*
            Find matching associated account.
        */
        public AssociatedAccount getAssociatedAccount(Id billingAccountId) {

            if (this.associatedAccounts != null) {
                for (AssociatedAccount associatedAccount : this.associatedAccounts) {
                    if (associatedAccount.billingAccountId == billingAccountId) {
                        return associatedAccount;
                    }
                }
            }
            return null;

        }

        /*
            Find all matching step-ups.
        */
        public List<RecommendedStepUp> getRecommendedStepUps(Id billingAccountId) {

            List<RecommendedStepUp> results = new List<RecommendedStepUp>();
            if (this.recommendedStepUps != null) {
                for (RecommendedStepUp recommendedStepUp : this.recommendedStepUps) {
                    if (recommendedStepUp.billingAccountId == billingAccountId) {
                        results.add(recommendedStepUp);
                    }
                }
            }
            return results;

        }

        /*
            Mask phone numbers and emails in communication methods.
        */
        public void maskCommunicationMethods() {

            if (this.recommendedStepUps != null) {
                for (RecommendedStepUp stepUp : this.recommendedStepUps) {
                    AssociatedAccount associatedAccount = getAssociatedAccount(stepUp.billingAccountId);
                    // Mask phone numbers
                    if (stepUp.otpPhoneNumber != null) {
                        List<StepUpOtpHashValues> optHashedPhoneNumbers = new List<StepUpOtpHashValues>();
                        for (Integer i = 0; i < stepUp.otpPhoneNumber.size(); i++) {

                            StepUpOtpHashValues hashedPhoneNumber = new StepUpOtpHashValues();
                            if (associatedAccount != NULL && (associatedAccount.authorizationLevel == BWC_Constants.AUTHORIZATION_LEVEL_L1 
                                || associatedAccount.authorizationLevel == BWC_Constants.AUTHORIZATION_LEVEL_BYPASS)) {
                                hashedPhoneNumber.label = BWC_Utils.formatPhone(stepUp.otpPhoneNumber[i]);
                                hashedPhoneNumber.value = BWC_Utils.formatPhone(stepUp.otpPhoneNumber[i]);
                            } else {
                                hashedPhoneNumber.label = BWC_Utils.maskPhoneNumber(stepUp.otpPhoneNumber[i]);
                                hashedPhoneNumber.value = BWC_Utils.hashContactMethod(stepUp.otpPhoneNumber[i]);
                            }
                            optHashedPhoneNumbers.add(hashedPhoneNumber);
                            stepUp.otpPhoneNumber[i] = BWC_Utils.maskPhoneNumber(stepUp.otpPhoneNumber[i]);
                        }
                        stepUp.otpHashedPhoneNumber = optHashedPhoneNumbers;
                    }
                    // Mask email addresses
                    if (stepUp.otpEmail != null) {
                        List<StepUpOtpHashValues> optHashedEmails = new List<StepUpOtpHashValues>();
                        for (Integer i = 0; i < stepUp.otpEmail.size(); i++) {
                            StepUpOtpHashValues hashedEmail = new StepUpOtpHashValues();
                            if (associatedAccount != NULL && (associatedAccount.authorizationLevel == BWC_Constants.AUTHORIZATION_LEVEL_L1 
                                || associatedAccount.authorizationLevel == BWC_Constants.AUTHORIZATION_LEVEL_BYPASS)) {
                                hashedEmail.label = stepUp.otpEmail[i];
                                hashedEmail.value = stepUp.otpEmail[i];
                            } else {
                                hashedEmail.label = BWC_Utils.maskEmailAddress(stepUp.otpEmail[i]);
                                hashedEmail.value = BWC_Utils.hashContactMethod(stepUp.otpEmail[i]);
                            }
                            optHashedEmails.add(hashedEmail);
                            stepUp.otpEmail[i] = BWC_Utils.maskEmailAddress(stepUp.otpEmail[i]);
                        }
                        stepUp.otpHashedEmail = optHashedEmails;
                    }
                }
            }

        }

        /*
            Find the matching otp phone number from masked version.
        */
        public String getValidOtpPhoneNumber(Id billingAccountId, String maskedPhoneNumber) {
            AssociatedAccount associatedAccount = getAssociatedAccount(billingAccountId);
            for (RecommendedStepUp stepUp : this.getRecommendedStepUps(billingAccountId)) {
                if (stepUp.otpPhoneNumber != null) {
                    for (String phoneNumber : stepUp.otpPhoneNumber) {
                        String phoneToCompare = '';
                        if (associatedAccount != NULL && (associatedAccount.authorizationLevel == BWC_Constants.AUTHORIZATION_LEVEL_L1 
                                || associatedAccount.authorizationLevel == BWC_Constants.AUTHORIZATION_LEVEL_BYPASS)) {
                            phoneToCompare = BWC_Utils.formatPhone(phoneNumber);
                        } else {
                            phoneToCompare = BWC_Utils.hashContactMethod(phoneNumber);
                        }
                        if (phoneToCompare == maskedPhoneNumber) {
                            return phoneNumber;
                        }
                    }
                }
            }
            return null;
        }

        /*
            Find the matching otp email address from masked version.
        */
        public String getValidOtpEmailAddress(Id billingAccountId, String hashedEmailAddress) {
            AssociatedAccount associatedAccount = getAssociatedAccount(billingAccountId);
            for (RecommendedStepUp stepUp : this.getRecommendedStepUps(billingAccountId)) {
                if (stepUp.otpEmail != null) {
                    for (String emailAddress : stepUp.otpEmail) {
                        String emailToCompare = '';
                        if (associatedAccount != NULL && (associatedAccount.authorizationLevel == BWC_Constants.AUTHORIZATION_LEVEL_L1 
                                || associatedAccount.authorizationLevel == BWC_Constants.AUTHORIZATION_LEVEL_BYPASS)) {
                            emailToCompare = emailAddress;
                        } else {
                            emailToCompare = BWC_Utils.hashContactMethod(emailAddress);
                        }
                        if (emailToCompare == hashedEmailAddress) {
                            return emailAddress;
                        }
                    }
                }
            }
            return null;
        }

        /*
            Tell if the specified billing account is authorized to L1 or BYPASS level.
        */
        public Boolean isL1Authorized(Id billingAccountId) {

            AssociatedAccount associatedAccount = getAssociatedAccount(billingAccountId);
            if (associatedAccount == null) {
                return false;
            }
            return BWC_Authorization.AUTHORIZATION_LEVELS_L1_PRIVILEGED.contains(associatedAccount.authorizationLevel);

        }

    }

    public class AssociatedAccount {
        public String accountType;
        public String accountBan;
        public String authorizationLevel;   //L0 or L1

        // Not returned by the API, but set by BWC_AuthorizationService
        public String authenticationMethod;
        public Id billingAccountId;

        public AssociatedAccount() {}

        public AssociatedAccount(Billing_Account__c billingAccount, String authorizationLevel, String authenticationMethod) {
            this.billingAccountId = billingAccount.Id;
            this.accountType = billingAccount.Account_Type__c;
            this.accountBan = billingAccount.Billing_Account_Number__c;
            this.authorizationLevel = authorizationLevel;
            this.authenticationMethod = authenticationMethod;
        }

    }

    public class RecommendedStepUp {
        public String stepUpType;
        public String accountType;
        public String accountBan;
        public List<String> otpPhoneNumber;
        public List<StepUpOtpHashValues> otpHashedPhoneNumber;
        public List<String> otpEmail;
        public List<StepUpOtpHashValues> otpHashedEmail;

        // Not returned by the API, but set by BWC_AuthorizationService
        public Id billingAccountId;

        public RecommendedStepUp() {}

        public RecommendedStepUp(String stepUpType, Billing_Account__c billingAccount, List<String> otpPhoneNumber, List<String> otpEmail) {
            this.stepUpType = stepUpType;
            this.billingAccountId = billingAccount.Id;
            this.accountType = billingAccount.Account_Type__c;
            this.accountBan = billingAccount.Billing_Account_Number__c;
            this.otpPhoneNumber = otpPhoneNumber;
            this.otpEmail = otpEmail;
        }

    }

    public class StepUpOtpHashValues {
        public String label;
        public String value;
    }

}
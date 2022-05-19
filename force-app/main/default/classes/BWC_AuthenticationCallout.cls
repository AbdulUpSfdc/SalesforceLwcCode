public with sharing class BWC_AuthenticationCallout {

    public static final String API_AUTHENTICATION_GENERATE_PIN = 'Authentication_Generate_Pin';
    public static final String API_AUTHENTICATION_VALIDATE_PIN = 'Authentication_Validate_Pin';
    public static final String API_AUTHENTICATION_VALIATE_CREDENTIALS = 'Authentication_Validate_Credentials';

    public class GeneratePinCallout extends BWC_Callout {

        // Request and Response state
        GeneratePinRequest request;
        GeneratePinResponse response;

        // Construct the service from caller arguments.
        public GeneratePinCallout(GeneratePinRequest request) {
            this.setCallout(API_AUTHENTICATION_GENERATE_PIN, JSON.serialize(request, true), null, null, null);
        }

        /*
            Build final response.
        */
        public override Object buildResponse() {
            this.response = (GeneratePinResponse)this.deserialize(GeneratePinResponse.class);
            return this.response;
        }

    }

    public class ValidatePinCallout extends BWC_Callout {

        // Request and Response state
        ValidatePinRequest request;
        ValidatePinResponse response;

        // Construct the service from caller arguments.
        public ValidatePinCallout(ValidatePinRequest request) {
            this.setCallout(API_AUTHENTICATION_VALIDATE_PIN, JSON.serialize(request, true), null, null, null);
        }

        protected override Boolean throwOnError() {
            // Don't throw on 400 -- response body has specific structured error
            return (this.httpResponse.getStatusCode() != 400);
        }

        /*
            Build final response.
        */
        public override Object buildResponse() {
            this.response = (ValidatePinResponse)this.deserialize(ValidatePinResponse.class);
            return this.response;
        }

    }

    public class ValidateCredentialsCallout extends BWC_Callout {

        // Request and Response state
        ValidateCredentialsRequest request;
        ValidateCredentialsResponse response;

        // Construct the service from caller arguments.
        public ValidateCredentialsCallout(ValidateCredentialsRequest request) {
            this.setCallout(API_AUTHENTICATION_VALIATE_CREDENTIALS, JSON.serialize(request, true), null, null, null);
        }

        protected override Boolean throwOnError() {
            // Don't throw on 400 -- response body has specific structured error
            return (this.httpResponse.getStatusCode() != 400);
        }

        /*
            Build final response.
        */
        public override Object buildResponse() {
            this.response = (ValidateCredentialsResponse)this.deserialize(ValidateCredentialsResponse.class);
            return this.response;
        }

    }

    /**************************************************************************
      API Schema
    **************************************************************************/

    public virtual class AuthenticationRequest {
        public String transactionName;
        public String callingSystemId;
        public String accountId;
        public String identificationType;
        public String agentId;
        public String browserLanguage;
    }

    public virtual class AuthenticationResponse extends BWC_Callout.CalloutResponse {
        public String transactionName;
        public String appStatusMsg;
        public String appStatusCode;
        public String appInfo;
    }

    public class GeneratePinRequest extends AuthenticationRequest {
        public String returnSecurityCode;
        public DeliveryMethods deliveryMethods; 
    }

    public class DeliveryMethods {
        public SmsDeliveryMethod sms;
        public EmailDeliveryMethod email;
        public AoDeliveryMethod ao;
    }

    public class SmsDeliveryMethod {
        public String smsPhoneNumber;
        public String deviceType;
    }

    public class EmailDeliveryMethod {
        public String emailAddress;
    }

    public class AoDeliveryMethod {
        public String phoneNumber;
    }

    public class GeneratePinResponse extends AuthenticationResponse {
        public String securityCode;
        public String securityCodeExpires;
    }

    public class ValidatePinRequest extends AuthenticationRequest {
        public String accountType;
        public String securityCode;
        public String deletePINOnSuccess;
        public String ivrSessionId;
        public String commonConversationId;
        public String ctn;
    }

    public class ValidatePinResponse extends AuthenticationResponse {
    }

    public class ValidateCredentialsRequest extends AuthenticationRequest {
        public String accountType;
        public String accountInvariantId;
        public AccountCredentials accountCredentials;
        public String ivrSessionId;
        public String commonConversationId;
        public String ctn;
    }

    public class AccountCredentials {
        public String billingZip;
        public String passcode;
        public String custcode;
        public String lastFourSSN;
        public String contactEmail;
        public String IMEI;
    }

    public class ValidateCredentialsResponse extends AuthenticationResponse {
        public String accountLocked;
        public String accountLockedReasonCode;
        public List<LockInfo> lockList;
    }

    public class LockInfo {
        public String lockName;
        public String setNumber;
        public String failedAuthCount;
        public String lastFailedAuthDateTime;
        public String lockExpirationDateTime;
        public String authAttemptsRemaining;
    }

}
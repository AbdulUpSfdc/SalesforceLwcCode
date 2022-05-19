/*
    Shared code for add/update/delete Payment Profile API.
*/
public with sharing class BWC_PaymentProfile {

    public static final String MODE_ADD = 'add';
    public static final String MODE_UPDATE = 'update';
    public static final String MODE_DELETE = 'delete';

    public class PaymentProfileRequest {

        public PaymentProfile addRequest;
        public PaymentProfile updateRequest;
        public PaymentProfile deleteRequest;

    }

    public class PaymentProfile {

        public CommonData commonData;
        public PaySource paySource; 
        public String accountId;
        public String accountType;
        public String firstName;
        public String lastName;
        public String profileName;
        public String profileOwnerId;
        public String merchantId;
        public String securityCode;
        public String customerAgreement;                        // Only for add and update
        public Integer tncId;                                   // Only for add and update
        public Boolean storeTermsAndConditionsConsent;          // Only for add and update
        public PaymentMethod paymentMethod;                     // Only for add and update
        public String temporaryProfileKey;  // used to add temp profiles so far 
        public String[] tokenizedFields;
        public String individualId;

    }

    public class CommonData {
        public String appName;
    }

    public class PaySource {
        public String sourceSystem;
        public String sourceLocation;
        public String sourceUser;
    }

    public class PaymentMethod {

        public String type; // 'CARD', 'BANKACCOUNT', 'PAYMENT_PROFILE'
        public Card card;
        public BankAccount bankAccount;
        public PaymentProfile paymentProfile;

        // Synonym for type
        public String paymentMethodType {get {return this.type;} set {this.type = value;}}

    }

    public class Card {

        public String securityCode;
        public String cardNumber;
        public String cardHolderName;
        public String expireYear;
        public String expireMonth;
        public BillingAddress billingAddress;
        public String merchantId;
        public Boolean verifyCardIndicator;

        // Automate zipCode if set on class instead of billingAddress
        public String zipCode {
            get {
                if (this.billingAddress != null) {
                    return this.billingaddress.zipCode;
                }
                else {
                    return null;
                }
            }
            set {
                if (this.billingAddress == null) {
                    this.billingAddress = new BillingAddress();
                }
                this.billingAddress.zipCode = value;
            }
        }

    }

    public class BillingAddress {

        public String zipCode;

    }

    // SpiData: list of payment input smart-fields with values/tokens
    public class SpiData {
        public List<SpiDataValues> spiDataList;
    }

    public class SpiDataValues {
        public String name;
        public String value;
        public String token;
    }
    // SpiData

    public class BankAccount {

        public String bankAccountNumber;
        public String accountHolderName;
        public String routingNumber;
        public String accountType;          //'CHECKING' or 'SAVINGS'
        public String checkNumber;
        
    }

    public class PaymentProfileResponse {

        public ResponseContent content;
        public Error error;

    }

    public class ResponseContent {
        public String responseCode;
        public String message;
        public String token;
        public String applePaytoken;
        public String cardToken;
    }

    public class Error {

        public String errorId;
        public String message;
        public ErrorDetails details;

    }

    public class ErrorDetails {

        public String code;
        public String message;

    }

}
public with sharing class BWC_AutoPayProfiles {

    public static String ADD_MODE = 'add';
    public static String UPDATE_MODE = 'update';
    public static String DELETE_MODE = 'delete';
    public static String PAUSE_MODE = 'pause';
    public static Set<String> MODES = new Set<String>{ADD_MODE, UPDATE_MODE, DELETE_MODE, PAUSE_MODE};

    public class AutoPayProfilesPostRequest {
        public AutoPayProfile addRequest;
        public AutoPayProfile updateRequest;
        public AutoPayProfile deleteRequest;
        public AutoPayProfile pauseRequest;
        
    }

    //for add, update, delete, pause modes
    public class AutoPayProfile {
        public String appName;
        public String sourceUser;
        public String sourceSystem;
        public String sourceLocation;
        public String systemId;
        public String divisionId;
        public String accountNumber; //for all modes
        public String accountType; //for all modes
        public String paymentPlanType; //for add and update
        public String customerAgreement; //for add and update
        public Integer tncId;//for add and update
        public Boolean storeTermsConditionConsent;//for add and update
        public PaymentMethod paymentMethod;//for add and update
        public String autopayPaymentDate; //for pause only
        public String[] tokenizedFields;
    }

    //for add, update, delete, pause modes
    public class AutoPayProfilesPostResponse {
        public Content content;
    }

    public class Content{
        public String responseCode;
        public String message;
    }

    public class Autopay{
        public String paymentPlan;
        public String paymentPlanType;
        public List<PaymentPlanInfo> paymentPlanInfo;
        public Boolean cancelNextAutopayPaymentAllowed;
        public String autoPayTrackingStatus;
        public PaymentPlanEligibility paymentPlanEligibility;
        public String responseCode;
        public String message;
    }

    public class ErrorAutoPay{
        public Integer code;
        public String description;
        public String idpTraceId;
        public String message;
        public String node;
        public String transactionId;

    }

    public class PaymentPlanInfo{
        public String paymentPlanStatus;
        public String effectiveDate;
        public String entryDate;
        public Card card;
        public BankAccount bankAccount;
    }

    public class PaymentMethod {
        public String type;
        public BankAccount bankAccount;
        public Card card;
        public PaymentProfile paymentProfile;
    }

    public class BankAccount {
        public String bankAccountNumber;
        public String routingNumber;
        public String accountType;
        public String accountHolderName;
    }

    public class Card {
        public String cardNumber;
        public String expireMonth;
        public String expireYear;
        public String securityCode;
        public String cardHolderName;
        public BillingAddress billingAddress;
        public String merchantId;
        public String cardMethodType;
        public String cardType;
    }

    public class BillingAddress {
        public String zipCode;
    }    

    public class PaymentProfile {
        public PaySource paySource;
        public String profileOwnerId;
        public String profileName;
        public String merchantId;
        public String securityCode;
    }

    public class PaySource {
        public String sourceSystem;
        public String sourceLocation;
        public String sourceUser;
    }

    public class PaymentPlanEligibility{
        public PaymentMethodAllowed paymentMethodAllowed;
        public Text2Pay text2Pay;
        public AutoPayDraftDayOptions autoPayDraftDayOptions;
    }

    public class PaymentMethodAllowed{
        public Boolean bank;
        public Boolean card;
    }

    public class Text2Pay{
        public Boolean elegibleFlag;
    }

    public class AutoPayDraftDayOptions{
        public String creditCardMethod;
        public String nonCreditCardMethod;
    }

}
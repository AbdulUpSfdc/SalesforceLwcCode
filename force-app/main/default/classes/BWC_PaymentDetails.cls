public with sharing class BWC_PaymentDetails {
    
    public static final String TOPIC_PAYMENT_HISTORY = 'paymentHistory';
    public static final String TOPIC_FUTURE_PAYMENTS = 'futurePayments';
    public static final String TOPIC_PAYMENT_PROFILES = 'paymentProfiles';
    public static final String TOPIC_CONVENIENCE_FEE_ELIGIBILITY = 'convenienceFeeEligibility';
    public static final String TOPIC_LAST_PAYMENT_METHOD = 'lastPaymentMethod';
    public static final String TOPIC_ACCOUNT_BALANCE_SUMMARY = 'accountBalanceSummary';
    public static final String TOPIC_BAN_BILLING_IDS = 'banBillingIds';
    public static final String TOPIC_PAYMENT_RECOMMENDATIONS = 'paymentRecommendations';
    public static final String TOPIC_AUTOPAY = 'autopay';
    public static final String TOPIC_TEMPORARY_PAYMENT_PROFILES = 'temporaryPaymentProfiles';
    public static final String TOPIC_EXTENDED_PA = 'extendedPA';

    public class PaymentDetailsRequest {
        public String firstName;
        public String lastName;
        public String accountId;
        public String accountType;
        public String productCode; 
        public String paymentDate;
        public String appName;
        public String sourceUser;
        public String sourceSystem;
        public String sourceLocation;
        public String temporaryProfileKey;
        public List<String> topics;
        public String individualId;
    }

    public class PaymentDetailsResponses extends BWC_Callout.CalloutResponse {
        public List<PaymentDetailsResponse> responses;
    }

    public class PaymentDetailsResponse extends BWC_Callout.ResponseNode {
        public String accountType;
        public String ban;
        public String firstName;
        public String lastName;
        public String individualId;
        public List<Payment> payments;
        public PaymentProfiles paymentProfiles;
        public ConveniencefeeEligibility conveniencefeeEligibility;
        public LastPaymentMethods lastPaymentMethod;
        public AccountBalanceSummary accountBalanceSummary;
        public BanBillingIds banBillingIds;
        public PaymentRecommendations futurePayments;
        public PaymentRecommendations paymentRecommendations;
        public PaymentProfiles temporaryPaymentProfiles;
        public Autopay autopay;
        public ExtendedPa extendedPA;
        public BWC_MuleServiceError errorpaymentHistory;
        public BWC_MuleServiceError errorfuturePayments;
        public BWC_MuleServiceError errorpaymentProfiles;
        public BWC_MuleServiceError errorconveniencefeeEligibility;
        public BWC_MuleServiceError errorlastPaymentMethod;
        public BWC_MuleServiceError erroraccountBalanceSummary;
        public BWC_MuleServiceError errorbanBillingIds;
        public BWC_MuleServiceError errorPaymentRecommendations;
        public BWC_MuleServiceError errortemporaryPaymentProfiles;
        public BWC_MuleServiceError errorautopay;
        public BWC_MuleServiceError errorextendedPA;

        // Not part of callout API
        public Id billingAccountId;

        public Boolean isEpaEligible {

            get {
                BWC_PaymentDetails.ExtendedPaDetails extendedPaDetails = this.paymentRecommendations?.paymentRecommendationDetails?.extendedPa;
                if (extendedPaDetails != null && extendedPaDetails.eligible == true && !BWC_PaymentDetails.EXTENDED_PA_DETAILS_ENROLLED_STATUSES.contains(extendedPaDetails.status)) {
                    return true;
                }
                return false;
            }

        }

        /*
            Returns true if account is enrolled or active in EPA.
        */
        public Boolean isEpaEnrolled {

            get {
                BWC_PaymentDetails.ExtendedPa extendedPa = this.extendedPa;
                if (this.extendedPa != null && BWC_PaymentDetails.EXTENDED_PA_ENROLLED_STATUSES.contains(this.extendedPa.status)) {
                    return true;
                }
                return false;
            }

        }

        /*
            Returns true if account is enrolled in EPA and active.
        */
        public Boolean isEpaActive {

            get {
                BWC_PaymentDetails.ExtendedPa extendedPa = this.extendedPa;
                if (this.extendedPa != null && BWC_PaymentDetails.EXTENDED_PA_ACTIVE_STATUSES.contains(this.extendedPa.status)) {
                    return true;
                }
                return false;
            }

        }

    }

    // Topic: paymentHistory

    public class PaymentProfiles {
        public List<PaymentProfile> paymentProfileList;
    }

    public class Payment {
        public String accountType;
        public String ban;
        public String pendingPaymentId;
        public String paymentAmount;
        public String paymentDate;
        public String paymentMethod;
        public Boolean autopay;
        public String paymentDetailMethodType;
        public String paymentDetailMethodLastFour;
        public Boolean lastSuccessfulPayment;
        public String confirmationNumber;
        public String paymentCategoryType;
        public String paymentType;
        public String paymentStatus;
        public String paymentSourceCode;
        public String paymentSourceDescription;
        public BankAccount bankAccount;
        public Card card;
        public PromiseToPay promiseToPay;
        public EligibleFlag editEligible;
        public EligibleFlag deleteEligible;
        public Boolean paymentArrangement;
        public Boolean unsecuredPayment;
    }

    public class EligibleFlag {
        public Boolean eligibleFlag;
        public String ineligibleReasonCode;
        public String ineligibleDescription;
    }

    // Topics: paymentRecommendations, futurePayments

    public class PaymentRecommendations {
        public EligibleFlag allowPaymentOnline;
        public EligibleFlag schedulePaymentAllowed;
        public EligibleFlag paymentArrangementAllowed;
        public PaymentOption paymentOptionOne;
        public PaymentOption paymentOptionTwo;
        public EligibilityAmounts eligibilityAmounts;
        public PaymentRecommendationDetails paymentRecommendationDetails;
        public BillingCollectionDetails billingCollectionDetails;
    }

    public class PaymentOption {
        public Boolean futurePaymentAllowed;
        public PaymentMethod paymentMethod;
        public PaymentDate paymentDate;
    }

    public class PaymentMethod {
        public Boolean bank;
        public Boolean card;
        public Boolean mail;
        public Boolean agency;
        public Boolean other;
    }
    
    public class PaymentDate {
        public String bank;
        public String card;
        public String mail;
        public String agency;
        public String other;
    }

    public class EligibilityAmounts {
        public String minAmountAllowed;
        public String maxAmountAllowed;
    }

    public class PaymentRecommendationDetails {
        public String experienceCode;
        public String experienceCodeDescription;
        public String minimumImmediatePayment;
        public String minimumTotalAmountByDueDate;
        public String minimumTotalAmountAfterDueDate;
        public String collectibleTotalAmountDue;
        public String collectibleTotalAmountPastDue;
        public ExtendedPaDetails extendedPa;
    }

    public static final String EXTENDED_PA_DETAILS_STATUS_ACTIVE = 'A';
    public static final String EXTENDED_PA_DETAILS_STATUS_BROKEN = 'B';
    public static final String EXTENDED_PA_DETAILS_STATUS_COMPLETED = 'C';
    public static final String EXTENDED_PA_DETAILS_STATUS_DELETED = 'D';   
    public static final String EXTENDED_PA_DETAILS_STATUS_NONE = 'N';
    public static final Set<String> EXTENDED_PA_DETAILS_ENROLLED_STATUSES = new Set<String> {
        EXTENDED_PA_DETAILS_STATUS_ACTIVE,
        EXTENDED_PA_DETAILS_STATUS_BROKEN
    };
    public class ExtendedPaDetails {
        public Boolean eligible;
        public String minInstallment;
        public String maxInstallment;
        public String status; // A = Active, B = Broken, C = Completed, D = Deleted, N = No extended payment arrangement, <blank> = Not enrolled
        public String financeTotalAmount;
        public List<ExtendedPaymentOptions> paymentOptions;
    }

    public class ExtendedPaymentOptions {
        public String installment;
        public String financeDownPayment;
        public String financePaymentAmount;
    }

    public class BillingCollectionDetails {
        public String accountMessageStatusGroup;
        public Boolean consequenceMessageAlert;
        public String ocaName;
        public String ocaPhone;
    }

    // Topic: paymentProfiles

    public class PaymentProfile {
        public String profileName;
        public String profileOwnerId;
        public String profileCreatedTime;
        public String profileProcessTime;
        public PaySource paySource;
        public String paymentMethodType;
        public BankAccount bankAccount;
        public Card card;
    }

    public class PaySource {
        public String sourceSystem;
        public String sourceLocation;
        public String sourceUser;
    }

    public class BankAccount {
        public String bankAccountNumber;
        public String accountHolderName;
        public String routingNumber;
        public String accountType;
        public String bankName;
    }

    public class Card {
        public String cardNumber;
        public String expireMonth;
        public String expireYear;
        public String cardHolderName;
        public String zipCode;
        public String cardType;
        public String cardMethodType;
        public Boolean trueCreditCardIndicator;
        public Boolean verified;
        public Boolean aboutToExpire;
        public Boolean expired;
    }

    public class PromiseToPay {
        public String method;
    }
    
    // Topic: convenienceFeeEligibility

    public class ConveniencefeeEligibility {
        public FeeEligibilityInfo feeEligibilityInfo;
    }

    public class FeeEligibilityInfo {
        public String accountId;
        public String productCode;
        public String eligibilityIndicator;
        public String rate;
        public String stateUSFIndicator;
        public String accountCode;
        public String currentBalance;
        public String paymentDate;
        public String serviceProviderId;
        public String serviceState;
        public String billingState;
        public String billPeriod;
        public String divisionCode;
        public String revenueInformationCode;
        public String journalIndicator;
        public String zipCode;
        public String serviceClass;
        public String accountStatus;
        public String accounttype;
        public String rao;
        public String occcode;
        public String usocid;
        public List<WaiveReasonList> waiveReasonList;
    }

    public class WaiveReasonList {
        public String waiveCode;
        public String waiveDescription;
    }

    // Topic: lastPaymentMethod

    public class LastPaymentMethods {
        public LastPaymentMethod lastPaymentMethodCard;
        public LastPaymentMethod lastPaymentMethodBank;
    }

    public class LastPaymentMethod {
        public BankAccount bankAccount;
        public Card card;
        public String lastPaymentMethodId;
        public String paymentDate;
    }

    // Topic: accountBalanceSummary
    public class AccountBalanceSummary {
        public String amountDue;
        public String amountPastDue;
        public String billDueDate;
        public String billCycleEndDate;
        public String billTotalAmount;
        public AutoPayInfo autoPayInfo;
        public List<ScheduledPaymentInfo> scheduledPayments;
        public LastPaymentInfo lastSuccesfulPayment;
        public String accountStatus;
        public Boolean treatmentIndicator;
    }

    public class AutoPayInfo {
        public Boolean enrolled;
    }

    public class LastPaymentInfo {
        public String paymentAmount;
        public String paymentDate;
    }

    public class ScheduledPaymentInfo {
        public String amount;
        public String paymentDate;
        public String paymentMethod;
    }

    // Topic: banBillingIds

    public class BanBillingIds {
        public String systemId;
        public String divisionId;
    }

    // Topic: autopay
    public class Autopay {
        public String paymentPlan;
        public String paymentPlanType;
        public List<PaymentPlanInfo> paymentPlanInfo;
        public Boolean cancelNextAutopayPaymentAllowed;
        public String autoPayPaymentDate;
        public Boolean autoPayPaymentCancelled;
        public String autoPayTrackingStatus;
        public PaymentPlanEligibility paymentPlanEligibility;
        public String responseCode;
        public String message;
    }

    public class PaymentPlanInfo{
        public String paymentPlanStatus;
        public String effectiveDate;
        public String entryDate;
        public Card card;
        public BankAccount bankAccount;
    }

    public class PaymentPlanEligibility {
        public PaymentMethodAllowed paymentMethodAllowed;
        public Text2Pay text2Pay;
        public AutoPayDraftDayOptions autoPayDraftDayOptions;
    }

    public class PaymentMethodAllowed {
        public Boolean bank;
        public Boolean card;
    }

    public class Text2Pay {
        public Boolean elegibleFlag;
    }

    public class AutoPayDraftDayOptions {
        public String creditCardMethod;
        public String nonCreditCardMethod;
    }

    // Topic: extendedPA
    public static final String EXTENDED_PA_STATUS_ENROLLED = 'Enrolled';
    public static final String EXTENDED_PA_STATUS_ACTIVE = 'Active';
    public static final String EXTENDED_PA_STATUS_BROKEN = 'Broken';
    public static final String EXTENDED_PA_STATUS_COMPLETED = 'Completed';
    public static final String EXTENDED_PA_STATUS_FUTURE = 'Future';
    public static final Set<String> EXTENDED_PA_ENROLLED_STATUSES = new Set<String>{ EXTENDED_PA_STATUS_ENROLLED, EXTENDED_PA_STATUS_ACTIVE, EXTENDED_PA_STATUS_BROKEN};
    public static final Set<String> EXTENDED_PA_ACTIVE_STATUSES = new Set<String>{EXTENDED_PA_STATUS_ACTIVE, EXTENDED_PA_STATUS_BROKEN};


    public class ExtendedPa {
        public String accountNumber;
        public String systemId;
        public String status;                       // Enrolled, Active, Broken, Completed, NotEnrolled
        public String enrolledDateTime;
        public String financeDownPayment;
        public String financePaymentAmount;
        public String financeTotalAmount;
        public String financeRemainingAmount;
        public String lastUpdateDateTime;
        public Integer installments;
        public List<ExtendedPaInstallment> installmentList;

        public Date enrolledDate {
            get {
                
                if (String.isEmpty(this.enrolledDateTime)) {
                    return null;
                }

                // Return date-only, properly converted from UTC to user's zone
                Datetime gmtDatetime = (Datetime)JSON.deserialize('"' + this.enrolledDateTime + '"', Datetime.class);
                return gmtDatetime.addSeconds(UserInfo.getTimeZone().getOffset(gmtDatetime) / 1000).date();

            }
        }

    }

    public Class ExtendedPaInstallment {
        //public String number;             // Name conflict
        public String amountDue;
        public String dueDate;
        public String status;   // Active, Broken, Completed, Future
    }

}
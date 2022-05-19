public with sharing class BWC_MakePayment {
    
    public class MakePaymentRequest {
        public String locationId;
        public String sourceBusinessUnit;
        public String customerAgreement;
        public String appName;
        public String sourceSystem;
        public String sourceLocation;
        public String sourceUser;
        public String idempotencyKey;
        public String convenienceFee;
        public Integer tncId;
        public Integer autopayTncId;
        public String autopayCustomerAgreement;
        public Boolean storeTermsConditionConsent;
        public String transactionId;
        public List<String> confirmationAddtionalInformation;
        public List<MakePaymentAccountRequest> makePaymentAccountRequest;
        public String[] tokenizedFields;
    }

    public class MakePaymentAccountRequest {
        public String accountNumber;
        public String accountType;
        public String firstName;
        public String lastName;
        public String systemId;
        public String divisionId;
        public List<PaymentItemRequest> makePaymentItemRequest;
    }

    public class PaymentItemRequest {
        public String sequenceNumber;
        public String amount;
        public String profileName;
        public Boolean savePaymentProfile;
        public String futurePaymentDate;
        public String paymentItemCategory;
        public String preAssignedServiceHandle;
        public String invoiceNumber;
        public PaymentMethod paymentMethod;
        public Boolean enrollInAutopay;
        public String pendingPaymentId;
    }

    public class PaymentMethod {
        public String type;
        public BankAccount bankAccount;
        public Card card;
        public PaymentProfile paymentProfile;
        public PromiseToPay promiseToPay;
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

    public class PromiseToPay {
        public String method;
    }

    public class MakePaymentResponse {
	    public MakePaymentResponseContent content;
    }

    public class MakePaymentResponseContent {
        public String transactionId;
        public List<MakePaymentAccountResponse> makePaymentAccountResponse;
    }

    public class MakePaymentAccountResponse {
        public List<MakePaymentItemResponse> makePaymentItemResponse;
        public PaymentArrangementResponse paymentArrangementResponse;
    }

    public class PaymentArrangementResponse {
        public String responseCode;
        public String message;
        public Error error;
    }

    public class MakePaymentItemResponse {
        public String sequenceNumber;
        public String paymentConfirmationNumber;
        public String paymentAmount;
        public Boolean paymentArrangementIndicator;
        public Error error;
    }

    public class Error {
        public String errorId;
        public String message;
        public List<ErrorDetails> details;
    }

    public class ErrorDetails {
        public String code;
        public String message;
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

    public class UpdatePaymentRequest {
        public String locationId;
        public String sourceBusinessUnit;
        public String customerAgreement;
        public String appName;
        public String sourceSystem;
        public String sourceLocation;
        public String sourceUser;
        public String idempotencyKey;
        public String convenienceFee;
        public Integer tncId;
        public Integer autopayTncId;
        public String autopayCustomerAgreement;
        public Boolean storeTermsConditionConsent;
        public String transactionId;
        public String accountNumber;
        public String accountType;
        public String firstName;
        public String lastName;
        public String systemId;
        public String divisionId;
        public List<PendingPaymentId> existingPendingPaymentId;
        public List<PaymentItemRequest> modifyFuturePaymentRequest;
        public String[] tokenizedFields;
    }

    public class PendingPaymentId {
        public String pendingPaymentId;
    }

    public class UpdatePaymentResponse {
        public UpdatePaymentResponseContent content;
    }

    public class UpdatePaymentResponseContent {
        public String transactionId;
        public List<ModifyFuturePaymentResponse> modifyFuturePaymentResponse;
    }

    public class ModifyFuturePaymentResponse {
        public String responseCode;
        public String message;
        public String sequenceNumber;
        public String paymentConfirmationNumber;
        public String amount;
        public String futurePaymentDate;
        public Error error;
    }

    public class CommonData {
        public String appName;
    }

    public class DeletePaymentRequest {
        public CommonData commonData;
        public String accountNumber;
        public String accountType;
        public String systemId;
        public String divisionId;
        public String pendingPaymentId;
    }

    public class DeletePaymentResponse {
        public DeletePaymentResponseContent content;
    }

    public class DeletePaymentResponseContent {
        public String responseCode;
        public String message;
    }

    public class EpaEnrollRequest {
        public String appName;
        public String sourceSystem;
        public String sourceLocation;
        public String sourceUser;
        public String customerAgreement;
        public Integer tncId;
        public String accountNumber;
        public String accountType;
        public String systemId;
        public String divisionId;
        public String enrollmentSource;
        public String financeDownPayment;
        public String financePaymentAmount;
        public String financeTotalAmount;
        public Integer installments;
        public String billCycleEndDate;
        public PaymentItemRequest makePaymentItemRequest;
        public String firstName;
        public String lastName;
        public Boolean savePaymentProfile;
        public String profileName;
        public String experienceCodeDescription;
        public String[] tokenizedFields;
    }

    public class EpaEnrollResponse {
        public String responseCode;
        public String message;
        public String paymentConfirmationNumber;
        public String paymentAmount;
        public StorePaymentMethodResponse storePaymentMethodResponse;
    }

    public class StorePaymentMethodResponse {
        public String responseCode;
        public String message;
        public Error error;
    }

}
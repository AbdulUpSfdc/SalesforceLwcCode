public with sharing class BWC_Order {

    public class OrderHistoryRequest {
        public List<Long> ban;
        public String startDate;
        public String endDate;
        public Integer numberOfOrders;
    }

    public class OrderHistoryResponse extends BWC_Callout.CalloutResponse {
        public List<OrderDetail> orders;
    }

    public class OrderDetailsResponse extends BWC_Callout.CalloutResponse {
        public OrderDetail details;
    }

    public class OrderDetail {
        public String orderId;
        public String revision;
        public String orderDate;
        public String orderingChannel;
        public String orderingSubChannel;
        public String originatingSystem;
        public String requestingSystemId;
        public String inventoryStoreId;
		public String storeId;
        public String orderingStoreId;
        public String salesRepresentativeId;
        public String posReceiptId;
        public String externalOrderSource;
        public OrderStatus orderStatus;
        public Boolean isCancelable;
        public Customer customer;
        public List<Products> products;
        public List<Fulfillments> fulfillments;
        public List<PaymentTenders> paymentTenders;
        public List<Addresses> addresses;
        public List<Accounts> accounts;
		public List<Promotion> promotions;
        public OrderPrice orderPrice;
        public String orderingChannelDescription;
    }

	public class ItemStatus {
		public String code;
		public String friendlyCode;
		public String friendlyDescription;
		public List<ApplicableMilestones> applicableMilestones;
		public String milestone;
    }

    public class Products {
		public String name;
		public ProductStatus productStatus;
		public String lineOfBusiness;
		public Compensation compensation;
		public List<Lines> lines;
		public List<Items> items;
		public String productSequenceNumber;
    }

	public class Customer {
		public String lastName;
		public String emailAddress;
		public String customerLangPreference;
		public List<PhoneNumbers> phoneNumbers;
		public List<CreditChecks> creditChecks;
		public String companyName;
    }

    public class Payments {
		public String paymentTenderSequence;
		public Double amount;
		public String transactionId;
    }

    public class PaymentTenders {
		public String type; // in json: type
		public String tenderSequence;
		public String tenderType;
		public String tenderAmount;
		public String installmentTerms;
		public String monthlyInstallmentAmount;
		public String downPaymentAmount;
		public String giftCardIndicator;
		public String creditCardLastFourDigits;
		public String creditCardType;
    }

    public class Addresses {
		public String addressSequence;
		public String addressClassification;
		public String addressType;
		public String addressSubType;
		public Boolean addressValidationRequired;
		public Boolean addressValidated;
		public String lastName;
		public String address1;
		public String address2;
		public String city;
		public String state;
		public String zip;
		public String zipExtension;
		public String country;
    }

    public class CreditChecks {
		public String creditReferenceId;
		public String creditReferenceDate;
		public String creditCheckStatus;
		public String noOfLinesApproved;
		public Boolean depositRequired;
		public String creditClass;
    }

    public class FulfillmentStatus {
		public String code;
    }

    public class Compensation {
		public String channelRepName;
		public String channelRepId;
		public String repDealer1Code;
		public String repDealer2Code;
		public String salesChannel;
		public String channelType;
    }

    public class Items {
		public String itemSequence;
		public String itemType;
		public Boolean isHardGood;
		public String lineSequence;
		public ServiceProductId_Z itemProductId;
		public String itemDescription;
		public String itemTypeDescription;
		public String itemImageURL;
		public String fulfillmentSequence;
		public Price price;
		public Integer quantityOrdered;
		public Integer quantityShipped;
		public Integer quantityBackordered;
		public Integer quantityCanceled;
		public Boolean isReturnItem;
		public Boolean isTradeInDevice;
		public Integer quantityOnHold;
		public EstimatedShipDateRange estimatedShipDateRange;
		public EstimatedDeliveryDateRange estimatedDeliveryDateRange;
		public Boolean isCancelable;
		public ItemStatus itemStatus;
		public List<Payments> payments;
		public Boolean shipDelayConsentRequired;
		public String make;
		public String model;
		public String type;
		public List<String> serialNumber;
		public String quantity;
		public String tradeInType;
		public TradeInDetails tradeInDetails;
    }

    public class Fulfillments {
		public String type; // in json: type
		public String fulfillmentSequence;
		public String fulfillmentType;
		public ServiceProductId fulfillmentOrderId;
		public ProductStatus fulfillmentStatus;
		public String addressSequence;
		public String storeId;
		public List<Shipment> shipments;
		public List<String> productSequenceNumber;
		public StoreDetails storeDetails;
		public PickupVisits pickupVisits;
    }

	public class PickupVisits{
		public String pickupVisitSequence;
		public List<PickupVisitItem> items;
	}

	public class PickupVisitItem{
		public String itemSequence;
		public String quantity;
	}

	public class StoreDetails{
		public String id;
		public String name;
		public String timeZone;
		public Addresses address;
	}

	public class EstimatedShipDateRange {
		public String fromDate;
		public String toDate;
    }

    public class OrderPrice {
		public Double subTotal;
		public Double tax;
		public Double shippingFee;
		public Double total;
    }

    public class Taxes {
		public String taxSequence;
		public Double taxAmount;
		public Double taxRate;
		public String jurisdictionLevel;
		public String jurisdictionName;
		public String memoOfTax;
		public String taxCode;
		public String taxableFlag;
		public String skuSpecificFlag;
		public String orderTaxAreaId;
		public String orderShipFromTaxAreaId;
		public String orderShipToTaxAreaId;
    }

    public class Price {
		public String priceType;
		public String salePrice;
		public String unitPrice;
		public String totalTax;
		public List<Taxes> taxes;
		public List<Adjustments> adjustments;
    }

	public class Adjustments{
		public String adjustmentType;
		public String promotionSequence;
		public String amount;
		public String name;
	}

    public class Lines {
		public String typeClassification;
		public String lineSequence;
		public String lineType;
		public String name;
		public String accountSequence;
		public List<Services> services;
		public List<String> itemSequences;
		public ProductStatus lineStatus;
		public String type; // in json: type
		public Boolean primaryLine;
		public String customerTelephoneNumber;
		public String activationDate;
		public String lineMarket;
		public String lineSubMarket;
		public String groupIdentifier;
    }

    public class LegalTermsAndConditions {
		public Boolean tcAcceptanceFlag;
		public String tcTimestamp;
    }

    public class OrderStatus {
		public String code;
		public String friendlyCode;
		public String friendlyDescription;
		public String clientStatus;
    }

	public class TradeInDetails{
		public String tradeStatus;
		public String tradeDate;
		public String inspectedDate;
		public String postInspectionValue;
		public String tradeValue;
		public String invoiceNumber;
		public String itemId;
		public ExpectedDetails expectedDetails;
	}

	public class ExpectedDetails{
		public String manufacturer;
		public String modelNumber;
		public String modelName;
		public String capacity;
		public String carrier;
		public String promotionCode;
		public String promotionValue;
	}

    public class ServiceProductId {
		public String value;
		public String type_Z; // in json: type
		public String system_Z; // in json: system
    }

    public class ApplicableMilestones {
		public String id;
		public String name;

    }

    public class SecurityDeposit {
		public Integer amount;
    }

    public class PhoneNumbers {
		public String phoneType;
		public String phoneNumber;
    }

    public class ProductStatus {
		public String code;
		public String friendlyCode;
		public String friendlyDescription;
		public String clientStatus;
		public String clientSubStatus;
	}

    public class ServiceProductId_Z {
		public String value;
		public String type_Z; // in json: type

    }

    public class Services {
		public String type; // in json: type
		public String serviceSequence;
		public String sequenceNumber;
		public String name;
		public String description;
		public String serviceType;
		public ServiceProductId serviceProductId;
		public String serviceProductType;
		public String action;
		public Price price;
		public String socType;
		public Integer contractTermLength;
		public String effectiveDate;
		public Boolean includedWithPlan;
		public String sharedService;
		public String feeSequenceNumber;
		public String feeType;
		public Boolean waived;
    }

    public class Accounts {
		public String accountSequence;
		public String accountNumber;
		public String accountType;
		public String accountSubType;
		public String lastName;
		public String emailAddress;
		public String billingAddressSequence;
		public String serviceAddressSequence;
		public String liabilityType;
		public List<PhoneNumbers> phoneNumbers;
		public String cenetId;
    }

	public class Shipment {
		public String shippedDate;
		public String expectedDeliveryDate;
		public String deliveredDate;
		public String shipmentStatus;
		public String trackingURL;
		public String carrierName;
		public String trackingId;
		public List<Items> items;
	}

	public class Promotion {
		public String promotionSequence;
        public String promotionId;
        List<AlternatePromoIds> alternatePromoIds;
        public String applyLevel;
        public String applySequence;
        public String name;
        public String description;
        public String amount;
        public String promotionType;
        public String effectiveDate;
        public String promotionCycle;
	}

	public class AlternatePromoIds{
		public String value;
		public String type;
		// public String system; reserved word
	}

	public class EstimatedDeliveryDateRange{
		public String fromDate;
		public String toDate;
	}
}
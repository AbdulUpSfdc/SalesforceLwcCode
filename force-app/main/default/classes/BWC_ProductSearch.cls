public with sharing class BWC_ProductSearch {

    public class ProductSearchRequest {
        public String customerId;
        public String accountId;
        public String accountType;
        public String topics;
        public Boolean isDigitalLife;
    }

    public class ProductSearchResponse extends BWC_Callout.CalloutResponse {
        public List<AccountResponse> accounts;
    }

    public class AccountResponse {
        public String accountType;
        public String ban;
        public List<Plan> plans;
        public List<Equipment> equipments;
        public List<Subscriber> subscribers;
        public BWC_MuleServiceError planserror;
        public BWC_MuleServiceError equipmentserror;
        public BWC_MuleServiceError subscriberserror;
        public Details details;
    }

    public class Plan {
       public String accountStatus;
       public String baseAllowanceInformation;
       public String billingProductSubType;
       public String billingProductType;
       public String buyerRemorseDate;
       public String componentProductId;
       public String contractEnd;
       public String contractEndDate;
       public String contractStartDate;
       public Boolean deviceProtection;
       public String featureCode;
       public String featureCodePrice;
       public String featureEffectiveDate;
       public String highestAvailableSpeed;
       public String transportType;
       //public String limit;
       public String maxLimit; // in json: limit
       public String linesOfBusiness;
       public String monthlyCost;
       public Integer numberOfAddOns;
       public Integer numberOfLines;
       public Integer numberOfReceivers;
       public String parentProductId;
       public String phone;
       public String planName;
       public String pricePlanDescription;
       public String product;
       public String productCode;
       public String productConfigurationProductOfferingId;
       public String productConfigurationProductOfferingProductSpecificationId;
       public String productDescription;
       public String productId;
       public String productName;
       public String productType;
       public String quantity;
       public String rateType;
       public String startDate;
       public String status;
       public String usage;
       public List<PlanSubscriber> subscribers;
       public Boolean isSplitLiability;
       public String primarySubscriber;
       public String protectionPlanName;
       public String thirdPartyInternetName;
       public String policyId;
   }

   public class PlanSubscriber {
       public String subscriberId;
       public String subscriberPlanName;
       public String subscriberMonthlyCost;
       List<Feature> features;
   }

   public class Feature {
       public String serviceType;
       public String endDate;
       public String agentCode;
       public String productName;
       public String agentLocation;
       public String genAttribute;
       public Integer maxMembers;
       public Integer maxAllowedCtns;
       public Integer socDuration;
       public Boolean delayRePriceInd;
       public Integer minMRC;
       public String productDescription;
       public String productType;
       public String lteInd;
       public String productId;
       public Integer slbTargetBan;
       public String productCode;
    // public Integer offerInstanceId;    // commenting this as Mule is returning bad data causing deserialize to fail
       public Double retailPrice;
       public String startDate;
       public String socNetwork;
   }

   public class Equipment {
       public String phone;
       public String user;
       public String device;
       public String installments;
       public String installmentAmount;
       public String warranty;
       public Boolean deviceProtection;
       public Boolean upgrade;
       public String groupId;
       public Boolean isPrimary;
       public String status;
       public String technology;
       public String deviceType;
       public String equipmentType;
       public String receiverType;
       public String receiverModel;
       public String room;
       public String serialNumber;
       public String subStatus;
       public String type_Z; // in json: type
       public String bundleDiscExists;
       public String vMake;
       public String vModel;
       public String vYear;
       public String vTrim;
       public String vin;
       public String subscriberSince;
       public String contractStart;
       public String contractEnd;
       public Integer contractLength;
       public String equipmentId;
       public String equipmentAttrDesc;
       public String manufacturer;
       public String modelNumber;
       public String purchaseTerms;
       public String isReceiver;
       public String isDVR;
       public String isHD;
       public String iswholeHomeDVR;
       public String isFreeReceiver;
       public String imei;
       public String sim;
       public String parkInd;
       public String tradeInInd;
       public String totalEarlyPayOfInstAmt; //Device pay off amount
       public String etfAmount; //Early Termination fee. Double
       public String planIdentifier;
       public String productType;
       public String payUpAmount;
       public String manfName;
       public String model;
       public String billingProductCode;
       public String contractType;
       public String subMarket;
       public String location;
       public String subscriberPlanName;
       public String equipmentStatus;
   }

   public class Details {
       public String customerLiabilityType;
       public String serviceDiscount;
       public String bmgContractType;
       public String securityLevel;
       public String languagePreference;
       public String bundleDiscount;
       public String featureCodePrice;
       public String priceCodePlan;
       public String customerSince;
       public String retailServiceable;
       public String myATTAccount;
       public String contractLength;
       public String featureCode;
       public String featureEffectiveDate;
       public String pricePlanDescription;
       public String billingType;
       public String pastDue;
       public String amountDue;
       public String autoPay;
       public String lastPayment;
       public String billingCycle;
       public String paperlessBilling;
       public String billMethod;
       public String billCutDate;
       public String billingAddress;
       public String billLanguage;
       public String cpId;
       public String primaryContactNumber;
       public String primaryContactEmail;
       public String subscription;
       public String contractStatus;
       public String userId;
       public String serviceBRE;
       public String monthsRemaining;
       public String TVReceiverQty;
       public String TVReceiverWithDVRQty;
       public String freeReceiverQty;
   }

   public class Subscriber {
       public String subscriberId;
       public String subscriberName;
       public String subscriberSince;
       public String subscriberStatus;
       public Integer contractLength;
       public String contractStart;
       public String contractEnd;
       public Double etfAmount;
   }

}
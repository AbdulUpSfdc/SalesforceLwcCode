/*
    Common structures for Customer Search API.
*/
public inherited sharing class BWC_CustomerSearch {

    public static final String BILLING_ADDRESS_TYPE = 'BILLING';

    /*
        Request from caller
    */
    public class CustomerSearchRequest {

        public String mode;

        // Mode banWithAccountType
        public String ban;
        public String accountType;

        // Mode phoneNumber
        public String phoneNumber;

        // Mode userId
        public String userId;

        // Mode addressId
        public String addressId;

        // Mode address
        public String addressLine1;
        public String addressLine2;
        public String city;
        public String state;
        public String zip;

        public String orderId;

    }

    /*
        Response to caller
    */
    public class CustomerSearchResponse extends BWC_Callout.CalloutResponse {
        public List<AccountResponse> accountResponses;                          // If returning multiple customers (http 200 or 206)
        public AddressesResponse addressesResponse;                             // If returning multiple address for address earch (http 300)
        public Integer accountResponseCount;
    }

    public class AccountResponse extends BWC_Callout.ResponseNode {
        public AccountHeader accountHeader; 
        public AccountDetails accountDetails; 
        public List<BillingAccount> accounts; 
        public Id accountId;
        public Id personAccountId;  // Same as accountId, for backwards compatibility
    }

    public class AccountHeader {
        public String name; 
        public String firstName; 
        public String lastName; 
        public String contactNumber; 
        public String secondaryPhoneNumber;
        public String email; 
        public Boolean isEmployee; 
        public String primaryProduct; 
        public String ban; 
    }

    public class AccountDetails {
        public String globalProfile; 
        public String globalId; 
        public List<Address> address; 
        public String accountType; 
        public Cpni cpni;
        public Fan fan;
        public Boolean isFirstNet; 
        public String languagePreference; 
        public String visuallyImpaired; 
        public String enrolledInLargePrint; 
        public String unifiedBan; 
        public String wirelessBan; 
        public Boolean isUnified; 
        public String creditClass;
        public String billingMarket;
        public Boolean isMigratedDTV;
        public String fnType;
        public String primaryAccountHolder;
    }

    public class Fan{
        public String fanId; 
        public String fanName; 
        public String fanCategory; 
        public String fanSubCategory1; 
        public String fanSubCategory2; 
        public String fanSubCategory3; 
        public String fanSubCategory4; 
    }

    public class Cpni {
        public String cpniIndicator; 
    }

    public class BillingAccount extends BWC_Callout.ResponseNode {
        public String ban; 
        public String accountTypeLob; 
        public String accountType; 
        public String productName360;
        public String accountStatus; 
        public String languagePreference; 
        public Cpni cpni;
        public String serviceStartDate; 
        public String firstName; 
        public String lastName; 
        public String email; 
        public String contactNumber; 
        public String secondaryPhoneNumber;
        public Boolean isEmployee; 
        public String customerId; 
        public String customerLiabilityType; 
        public Fan fan;
        public String subDiscount; 
        public String passcode; 
        public Boolean isDigitalLife; 
        public Boolean isPrepaidCustomer; 
        public Boolean isFixedWirelessInternetCustomer; 
        public Integer serviceDiscount; 
        public String bmgContractType; 
        public String securityLevel; 
        public String retailServiceable; 
        public String cpid; 
        public String userid; 
        public List<Address> address; 
        public String message; 
        public String unifiedBan; 
        public String wirelessBan; 
        public Boolean isUnified; 
        public Boolean isBundleDiscount;
        public String billingMarket;
        public Boolean isMigratedDTV;
        public Boolean restoreEligible;
        public String serviceNumber;
        public Boolean hboMaxEntitlementIndicator;
        public String suspensionStatus;
        public String primaryAccountHolder;
        public String fnType;
    }

    public class Address {
        public String id; 
        public String type_Z; // in json: type
        public String type;
        public String subType; 
        public String unitType; 
        public String unitNumber; 
        public String streetName1; 
        public String streetName2; 
        public String locality; 
        public String county; 
        public String stateOrProvince; 
        public String country; 
        public String postcode; 
        public String additionalInformation; 
        public Boolean isHsiaHigh; 
        public Boolean isHsiaMedium; 
        public Boolean isHsiaLow; 
        public Boolean isTv; 
        public Boolean isVoip; 
        public Boolean dmaCode; 
        public Integer addressSequence; 
        public String classification; 
        public String firstName; 
        public String lastName; 
        public Boolean isValidationRequired; 
        public Boolean isValidated; 
    }

    public class AddressesResponse extends BWC_Callout.ResponseNode {
        public String matchStatus;
        public List<MduAddress> addresses;
    }

    public class MduAddress {
        public String addressLine1;
        public String addressLine2;
        public String city;
        public String state;
        public String zip;
        public String country;
        public String addressId;
    }

    public class CBRResponse extends BWC_Callout.CalloutResponse{
        public List<Customer> customers;
        public Boolean performSearch;
        public List<CBRSelection> accounts;
    }

    public class Customer {
        public String customerId;
        public String firstName;
        public String lastName;
        public String emailAddress;
        public String systemOfRecord;
        public List<String> phoneNumbers;
        public List<Accounts> accounts;
    }

    public class Accounts {
        public String ban;
        public String accountStatus;
        public String accountType;
        public String systemOfRecord;
        public Profile profile;
        public List<AddressCBR> addresses;
        public String startServiceDate;
        public String billingAccountType;
        public String billingMarket;
        public List<Subscriber> subscribers;
    }

    public class Subscriber {
        public String subscriberId;
        public String accountId;
        public String effectiveDate;
        public String status;
        public String firstName;
        public String lastName;
        public String phoneNumber;
        public String sim;
        public String imei;
        public List<AddressCBR> addresses;
        public String subMarket;
    }

    public class AddressCBR {
        public String subscriberId;
        public String addressId;
        public String addressLine1;
        public String city;
        public String state;
        public String zip;
        public String zip4;
        public String country;
        public String addressType;
        public String addressCategory;
    }

    public class Profile {
        public String firstName;
        public String lastName;
        public String emailAddress;
        public String emailStatus;
        public String phoneNumber;
    }

    public class CBRSelection {
        public String accountNumber;
        public String accountType;
        public String ban;
        public String lob;
        public String status;
        public String zipCode;
        public String name;
        public String email;
        public String phoneNumber;
    }

}
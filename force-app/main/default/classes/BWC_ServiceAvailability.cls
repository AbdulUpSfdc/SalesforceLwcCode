public  class BWC_ServiceAvailability {

    public class ServiceAvailabilityRequest{
        public String customertype;
        public String mode;
        public String addressLine1;
        public String addressLine2;
        public String city;
        public String state;
        public String zip;

        public String unitType1;
        public String unitNumber1;
        public String addressId;
    }

    public class ServiceAvailabilityResponses extends BWC_Callout.CalloutResponse {
        public ServiceAvailabilityResponse response;
    } 

    public class ServiceAvailabilityResponse extends BWC_Callout.ResponseNode {
        public Content content;
    }

    public class Content {
        public String availabilityStatus;
        public AddressFeatures addressFeatures;
        public AvailableServices availableServices;
        public ExistingServices existingServices;
        public UserInput userInput;
        public List<MduAddress> mduAddress;
        public List<MduAddress> closeMatchAddress;
    }

    public class AvailableServices{
        //All of these are boolean
        public String ATTTVInternetBundleAvailable; //ATTTV under TV
        public String cafiiIndicator;
        public String d2LiteEligible;
        public String dslAvailable;
        public String dtvAvailable;
        public String fiberAvailable;
        public String fixedWirelessInternetAvailable;
        public String hsiaAvailable;
        public String iptvAvailable;
        public String lightGigAvailable;
        public String lightSpeedAvailable;
        public String maxInternetDisplayText; //String
        public String maxInternetDownloadSpeedAvailableMBPS; //Integer
        public String maxInternetHSIACode; //String
        public String potsAvailable;
        public String voipAvailable;
        public String wirelessAvailable;
        public String wllCapacity;
    }

    public class ExistingServices{
        public String dslServiceExisting;
        public String dtvServiceExisting;
        public String lightSpeedPending;
        public String telcoServiceExisting;
        public String uverseServiceExisting;
        public String wirelessServiceExisting;
        public String wirelineServiceExisting;
        public String wllServiceExisting;
    }

    public class AddressFeatures{
        public String addressId;
        public String addressLine1;
        public String addressLine2;
        public String city;
        public String countyFIPScode;
        public String countyName;
        public String dma;
        public String dwellingType;
        public DwellingTypeDetails dwellingTypeDetails;
        public String fmoRegion;
        public String globalLocationId;
        public String instantHSIAOnIndicator;
        public String nation;
        public String outOfUverseFootPrint;
        public String singleDispatchIndicator;
        public String state;
        public String wireCenterCode;
        public String zip;
    }

    public class DwellingTypeDetails{
        //All of these values are boolean;
        public String isACC;
        public String isBulkBilling;
        public String isDTVConnectedProperty;
        public String isDTVDealerRestricted;
        public String isMdu;
    }

    public class UserInput{
        public String addressLine1;
        public String addressLine2;
        public String addressId;
        public String city;
        public String state;
        public String country;
        public String zip;
        public String clientName;
        public String unitNumber1;
        public String unitType1;
        public String glid;
        public String mode;
    }

    public class MduAddress{
        public String addressLine1;
        public String addressLine2;
        public String addressId;
        public String city;
        public String state;
        public String country;
        public String zip;
    }
}
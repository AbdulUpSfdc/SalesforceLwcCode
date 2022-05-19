public with sharing class BWC_AddressValidation {

    // API expects a list of this data type
    public class AddressValidationRequest {
        public String city;
        public String postcode;
        public String stateOrProvince;
        public List<AddressCharacteristic> addressCharacteristic;
    }

    public class AddressCharacteristic{
        public String name;
        public String value;
    }

    public class AddressValidationResponse extends BWC_Callout.CalloutResponse {
        public String id;
        public Boolean provideAlternative;
        public String validationDate;
        public String validationResult;
        public String validationResultCode;
        public String validationResultDescription;
        public List<ValidationTypeRecommendation> validationTypeRecommendation;
        public List<AlternateGeographicAddress> alternateGeographicAddress;
        public ValidGeographicAddress validGeographicAddress;
    }

    public class ValidationTypeRecommendation {
        public String validationType;
        public String validationRecommendation;
    }

    public class ValidGeographicAddress{
        public String id;
        public String city;
        public String country;
        public String locality;
        public String postcode;
        public String postCodeExtension;
        public String stateOrProvince;
        public String streetName;
        public String streetNr;
        public String streetType;
        public List<GeographicSubAddress> geographicSubAddress;
    }

    public class GeographicSubAddress{
        public String subUnitType;
        public String subUnitNumber;
    }

    public class AlternateGeographicAddress{
        public String id;
        public String city;
        public String country;
        public String locality;
        public String postcode;
        public String postCodeExtension;
        public String stateOrProvince;
        public String streetName;
        public String streetNr;
        public String streetType;
        public List<GeographicSubAddress> geographicSubAddress;
        public List<AddressCharacteristic> addressCharacteristic;
    }
}
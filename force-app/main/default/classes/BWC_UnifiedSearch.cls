public with sharing class BWC_UnifiedSearch {

    public static final String CANCELED_ACCOUNT_STATUS = 'Canceled';
    public static final String CONTACT_MEDIUM_POSTAL_ADDRESS = 'postalAddress';
    public static final String CONTACT_MEDIUM_EMAIL = 'email';
    public static final String CONTACT_MEDIUM_PHONE_NUMBER = 'telephone';
    public static final String CONTACT_TYPE_OTHER = 'other';
    public static final String PRIMARY_SUBCONTACT_TYPE = 'primary';
    public static final String SECONDARY_SUBCONTACT_TYPE = 'secondary';
    public static final String BILLING_ADDRESS_TYPE = 'billing';
    public static final String SHIPPING_ADDRESS_TYPE = 'shipping';
    public static final String CPNI_NOTIFICATION_TYPE = 'CPNI';
    public static final String WORK_CONTACT_TYPE = 'work';
    public static final String HOME_CONTACT_TYPE = 'home';
    public static final String OTHER_CONTACT_TYPE = 'other';

    public static final String SERVICE_ADDRESS_TYPE = 'service';
    public static final String SERVICE_ADDRESS_USPS_TYPE = 'serviceusps';
    public static final String SERVICE_ADDRESS_SAG_TYPE = 'servicesag';
    public static final String SERVICE_ADDRESS_FSP_TYPE = 'servicefsp';
    public static final Set<String> SERVICE_ADDRESS_TYPES_SET = new Set<String>{
        SERVICE_ADDRESS_TYPE,
        SERVICE_ADDRESS_USPS_TYPE,
        SERVICE_ADDRESS_SAG_TYPE,
        SERVICE_ADDRESS_FSP_TYPE
    };

    public class UnifiedSearchRequest {
        public String phoneNumber;
        public String orderId;
        public String accountNumber;
        public String serviceType;
        public String addressId;
        public String emailAddress;
        public String addressLine1;
        public String addressLine2;
        public String zipCode;
        public String userId;
        public String individualId;
    }

    public class UnifiedSearchResponse extends BWC_Callout.CalloutResponse {
        public List<IndividualResponse> individuals;
        public List<IndividualFound> individualsFound;
        public Integer accountResponseCount;
    }

    public class IndividualResponse {
        public String id;
        public String givenName;
        public String familyName;
        public List<ContactMedium> contactMedium;
        public List<Accounts> accounts;
        public String digitalCustomer;
        public List<LanguageAbility> languageAbility;
        public Boolean isEmployee;
    }

    public class ContactMedium {
        public String mediumType;
        public Boolean preferred;
        public Characteristic characteristic;
    }

    public class Characteristic {
        public String contactType;
        public String subContactType;
        public String phoneNumber;
        public String emailAddress;
        public String street1;
        public String city;
        public String stateOrProvince;
        public String postCode;
        public String country;
        public Place place;
    }

    public class Place{
        public String id;
    }

    public class Accounts {
        public String id;
        public String state;
        public String createdOn;
        public String accountType;
        public String accountSubType;
        public Details details;
        public List<ContactResponse> contact;
        public List<Subscriber> subscribers;
        public String billingMarket;
        public FanDetails fanDetails;
        public List<ConsentPreferences> consentPreferences;
        public String givenName;
        public String familyName;
        public String serviceType;
        public String emailStatus;
        public String systemOfRecord;
        public String wirelessBan;
        public String unifiedBan;
        public Boolean isUnifiedBan;
        public String isFirstNet;
        public String oldestCTN;
    }

    public class Details {
        public String productName360;
        public String serviceNumber;
        public String firstNetType;
        public Boolean isFirstNet;
        public Boolean isPrepaid;
        public Boolean hboMaxEntitlementIndicator;
    }

    public class ContactResponse {
        public List<ContactMedium> contactMedium;
    }

    public class Subscriber {
        public String subscriberId;
        public String id;
        public String effectiveDate;
        public String givenName;
        public String familytName;
        public String sim;
        public String imei;
        public String subMarket;
        public List<ContactResponse> contact;
    }

    public class FanDetails {
        public String fanId;
        public String fanName;
        public String fanDiscountEnabled;
        public String fanAssociationDate;
        public String fanCategory;
        public String fanSubCategory1;
        public String fanSubCategory2;
        public String fanSubCategory3;
        public String fanSubCategory4;
    }

    public class IndividualFound {
        public String globalId;
        public String accountId;
        public String fullName;
        public String email;
        public String contactNumber;
        public List<AccountFound> accounts;
    }

    public class AccountFound {
        public String lineOfBusiness;
        public String billingAccountId;
        public String accountNumber;
        public String status;
        public String zipCode;
    }

    public class ConsentPreferences {
        public String notificationType; //TODO: first instance where notificationType is equals CPNI
        public String electionCode;
        public String electionDate;
    }

    public class LanguageAbility {
        public String languageCode;
        public String languageName;
    }

    public static String getPhoneNumber(List<ContactMedium> contactMedium, String subContactType){

        if(contactMedium==null){
            return null;
        }

        String phoneNumber;
        for(ContactMedium medium : contactMedium){
            if(medium.mediumType == CONTACT_MEDIUM_PHONE_NUMBER && medium.characteristic.subContactType == subContactType){
                phoneNumber = medium.characteristic.phoneNumber;
            }
        }

        return phoneNumber;
    }

    public static String getPhoneNumberIndividual(List<ContactMedium> contactMedium, String contactType){

        if(contactMedium==null){
            return null;
        }

        String phoneNumber;
        String otherPhoneNumber; //Default value when phone number is not found for a given contact type
        for(ContactMedium medium : contactMedium){
            if(medium.mediumType == CONTACT_MEDIUM_PHONE_NUMBER && medium.characteristic.contactType == contactType){
                phoneNumber = medium.characteristic.phoneNumber;
            }

            if(medium.mediumType == CONTACT_MEDIUM_PHONE_NUMBER && medium.characteristic.contactType == OTHER_CONTACT_TYPE){
                otherPhoneNumber = medium.characteristic.phoneNumber;
            }
        }

        return phoneNumber != null ? phoneNumber : otherPhoneNumber;

    }

    public static String getContactMedium(List<ContactMedium> contactMedium, String mediumType, String contactType){

        if(contactMedium==null){
            return null;
        }

        String result='';
        Characteristic medium;
        for(ContactMedium item : contactMedium){

            if(item.mediumType == mediumType && item.characteristic.contactType == contactType){
                medium = item.characteristic;
                break;
            }

        }

        if(mediumType == CONTACT_MEDIUM_PHONE_NUMBER){
            result = medium?.phoneNumber;
        }else if(mediumType == CONTACT_MEDIUM_EMAIL){
            result = medium?.emailAddress;
        }

        return result;
    }

    public static Characteristic getAddress(List<ContactMedium> contactMedium, Set<String> addressType){

        if(contactMedium==null){
            return null;
        }

        Characteristic address;
        for(ContactMedium item : contactMedium){

            String contactTypeLowerCase = item.characteristic.contactType?.toLowerCase();

            if(item.mediumType == CONTACT_MEDIUM_POSTAL_ADDRESS && addressType.contains(contactTypeLowerCase) ){
                address = item.characteristic;
                break;
            }
        }

        return address;
    }

    public static ConsentPreferences getPreferenceByNotificationType(List<ConsentPreferences> preferences,  String notificationType){

        if(preferences==null){
            return null;
        }

        ConsentPreferences result;

        for(ConsentPreferences preference : preferences){
            if(preference.notificationType == notificationType){
                result =  preference;
                break;
            }
        }
        return result;
    }

}
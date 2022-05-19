/*
    Shared code for CustomerAccount API.
*/
public with sharing class BWC_CustomerAccount {

    public class AccountDetailsResponse extends BWC_Callout.CalloutResponse  {
        public AccountData account;
    }

    public class AccountData {
        public AccountDetails details;
        public AccessIds accessIds;
        public NotifPreferences notifPreferences;
    }

    public class AccountDetails extends BWC_MuleResponseObject {
        public ContactInfos contactInfo;
    }

    public class ContactInfos {
        List<ContactInfo> contacts;
    }

    public class ContactInfo extends BWC_MuleResponseObject {
        public String contactType;      // 'email', 'phone'
        public String contactValue;     // email address or phone number (no punctuation in phone number)
        public String lastUpdatedDate;
        public Boolean isVerified;
        public Boolean isPrimary;
        public Boolean isEligible;
    }

    public class AccessIds extends BWC_MuleResponseObject {
        public List<AssociatedUser> users;
    }

    public class AssociatedUser {
        public String slid;
        public String avatar;
        public String userLockLevel;        // 1 or 2
        public ContactInfos contactInfo;
    }

    public class NotifPreferences extends BWC_MuleResponseObject {
        public List<Preference> preferences;
    }

    public class Preference {
        public String notificationType;     // SERVICEALERTS, PAYBILL, ECONSENT
        public Boolean notifyByEmail;
        public Boolean notifyByPhone;
        public Boolean notifyBySMS;
        public String notificationPhoneNumber;
        public String phoneNumberType;
        public String electionDate;
    }
    
    public class PutBillingInfoRequest {
        public PutAccountRequest account;
    }

    public class PutAccountRequest {
        public PutAccountDetails details;
        public NotifPreferences notifPreferences;
    }

    public class PutAccountDetails {
        List<ContactInfo> contactInfo;
    }

    public class PutBillingInfoResponse {
        public UpdateResult contactUpdateResult;
        public UpdateResult preferencesUpdateResult;
    }

    public class UpdateResult extends BWC_MuleResponseObject {
        public String status;
    }

    /**
     * Update Billing Account Passcode request and response
     */

    public class UpdateAccountPasscodeRequest {
        public UpdatePasscodeAccount account;
    }

    public class UpdatePasscodeAccount {
        public UpdatePasscodeAccountProfile profile;
    }

    public class UpdatePasscodeAccountProfile {
        public String accountPasscode;
    }

    public class UpdateAccountPasscodeResponse {
        public String status;
    }

}
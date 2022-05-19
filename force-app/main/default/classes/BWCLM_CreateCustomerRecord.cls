/*
    Shared code ingest Create Customer record JSON.
*/

global class BWCLM_CreateCustomerRecord {

  public class Addresses {
    public String addressType {get;set;}
    public String address1;
    public String address2;
    public String city;
    public String state;
    public String zip;
    public String zipExtension;
    public String country;
  }

  public class PhonesNumbers {
    public String phoneType;
    public String phoneNumber;
  }

  public String firstName;
  public String lastName;
  public String middleName;
  public String customerLangPreference;
  public List<PhonesNumbers> phonesNumbers;
  public String email;
  public String accountFirstName;
  public String accountLastName;
  public String accountMiddleName;
  public String accountNumber_ban;
  public String accountNumber_ctn;
  public String accountBillingSystem;
  public String accountStatus;
  public String accountSource;
  public String accessId; /*added the field jignesh T. */
  public String accountType; /*added the field jignesh T. */
  public List<Addresses> addresses;


}
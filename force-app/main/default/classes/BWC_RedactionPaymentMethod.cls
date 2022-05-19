public inherited sharing abstract class BWC_RedactionPaymentMethod {
  public enum CreditCardType {
    VISA,
    MASTERCARD,
    AMEX,
    DINERS,
    DISCOVER
  }

  public inherited sharing class CardMeta {
    public CreditCardType type;
    public String label;
    public Pattern regEx;

    public CardMeta(CreditCardType type, String label, Pattern regEx) {
      this.type = type;
      this.label = label;
      this.regEx = regEx;
    }
  }

  public static final Map<CreditCardType, CardMeta> cardTypeToMeta = new Map<CreditCardType, CardMeta>{
    CreditCardType.VISA => new CardMeta(
      CreditCardType.VISA,
      CreditCardType.VISA.name().toLowerCase().capitalize(),
      Pattern.compile('^4[0-9]{12}(?:[0-9]{3})?$')
    ),
    CreditCardType.MASTERCARD => new CardMeta(
      CreditCardType.MASTERCARD,
      CreditCardType.MASTERCARD.name().toLowerCase().capitalize(),
      Pattern.compile(
        '^(?:5[1-5][0-9]{2}|222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)[0-9]{12}$'
      )
    ),
    CreditCardType.AMEX => new CardMeta(
      CreditCardType.AMEX,
      'American Express',
      Pattern.compile('^3[47][0-9]{13}$')
    ),
    CreditCardType.DINERS => new CardMeta(
      CreditCardType.DINERS,
      'Diners Club',
      Pattern.compile('^3(?:0[0-5]|[68][0-9])[0-9]{11}$')
    ),
    CreditCardType.DISCOVER => new CardMeta(
      CreditCardType.DISCOVER,
      CreditCardType.DISCOVER.name().toLowerCase().capitalize(),
      Pattern.compile(
        '^65[4-9][0-9]{13}|64[4-9][0-9]{13}|6011[0-9]{12}|(622(?:12[6-9]|1[3-9][0-9]|[2-8][0-9][0-9]|9[01][0-9]|92[0-5])[0-9]{10})$'
      )
    )
  };

  private static final String PROFILE_NAME_SEPARATOR = ' ...';

  public inherited sharing class CreditCard {
    @AuraEnabled
    public String ccName { get; set; }
    @AuraEnabled
    public String ccNumber { get; set; }
    @AuraEnabled
    public String ccExpiration { get; set; }
    @AuraEnabled
    public String ccSecurityCode { get; set; }
    @AuraEnabled
    public String ccZip { get; set; }

    public String existingPaymentProfile { get; set; }

    private CardMeta meta;

    public CardMeta getMeta() {
      meta = null;
      // if ( String.isBlank( existingPaymentProfile ) ) {
        for (CardMeta cm : cardTypeToMeta.values()) {
          if (cm.regEx.matcher(ccNumber).matches()) {
            meta = cm;
            break;
          }
        }
      // }
      // else {
      //   System.debug( LoggingLevel.DEBUG, '--->>> existingPaymentProfile [' + existingPaymentProfile + ']' );
      //   Integer endOfMeta = existingPaymentProfile.indexOf( ' ' );
      //   String strMeta = existingPaymentProfile.substring( 0, endOfMeta );
      //   System.debug( LoggingLevel.DEBUG, '--->>> strMeta [' + strMeta + ']' );
      //   meta = cardTypeToMeta.get( CreditCardType.valueOf( strMeta ) );
      //   System.debug( LoggingLevel.DEBUG, '--->>> meta [' + meta + ']' );
      // }
      return meta;
    }

    public String profileName() {
      if ( !String.isBlank( existingPaymentProfile ) ) {
        return existingPaymentProfile;
      }
      return getMeta()?.label + PROFILE_NAME_SEPARATOR + ccNumber?.right(4);
    }

    public BWC_PaymentProfile.PaymentMethod save() {
      BWC_PaymentProfile.PaymentMethod pm = new BWC_PaymentProfile.PaymentMethod();
      pm.type = BWC_Constants.PAYMENT_METHOD_TYPE_CARD;
      pm.card = new BWC_PaymentProfile.Card();
      pm.card.cardHolderName = ccName;
      pm.card.cardNumber = ccNumber;
      pm.card.securityCode = ccSecurityCode;

      List<String> parts = ccExpiration?.split('\\/');
      if (parts != null && parts.size() == 2 && parts[1].length() == 2) {
        parts[1] = '20' + parts[1];
      }

      pm.card.expireMonth = parts[0];
      pm.card.expireYear = parts[1];
      pm.card.merchantId = BWC_Constants.MERCHANT_ID;
      pm.card.billingAddress = new BWC_PaymentProfile.BillingAddress();
      pm.card.billingAddress.zipCode = ccZip;
      return pm;
    }
  }

  public enum BankAccountType {
    CHECKING,
    SAVINGS
  }

  public inherited sharing class BankMeta {
    public BankAccountType type;
    public String label;
    public String longLabel;

    public BankMeta(BankAccountType type, String label, String longLabel) {
      this.type = type;
      this.label = label;
      this.longLabel = longLabel;
    }
  }

  public final static Map<BankAccountType, BankMeta> bankAccTypeToMeta = new Map<BankAccountType, BankMeta>{
    bankAccountType.CHECKING => new BankMeta(
      bankAccountType.CHECKING,
      bankAccountType.CHECKING.name().toLowerCase().capitalize(),
      'Checking Account'
    ),
    bankAccountType.SAVINGS => new BankMeta(
      bankAccountType.SAVINGS,
      bankAccountType.SAVINGS.name().toLowerCase().capitalize(),
      'Savings Account'
    )
  };

  public inherited sharing class BankInfo {
    @AuraEnabled
    public String bankNameOnAcc { get; set; }
    @AuraEnabled
    public String bankRoutingNumber { get; set; }
    @AuraEnabled
    public String bankAccNumber { get; set; }
    @AuraEnabled
    public String bankCheckNumber { get; set; }

    private BankMeta meta;

    public BankMeta getMeta() {
      return bankAccTypeToMeta.get(BankAccountType.CHECKING);
    }

    private String profileName() {
      return getMeta().label + PROFILE_NAME_SEPARATOR + bankAccNumber?.right(4);
    }

    public BWC_PaymentProfile.PaymentMethod save() {
      BWC_PaymentProfile.PaymentMethod pm = new BWC_PaymentProfile.PaymentMethod();
      pm.type = BWC_Constants.PAYMENT_METHOD_TYPE_BANKACCOUNT;
      pm.bankAccount = new BWC_PaymentProfile.BankAccount();
      pm.bankAccount.accountType = bankAccountType.CHECKING.name();
      pm.bankAccount.accountHolderName = bankNameOnAcc;
      pm.bankAccount.bankAccountNumber = bankAccNumber;
      pm.bankAccount.routingNumber = bankRoutingNumber;
      pm.bankAccount.checkNumber = bankCheckNumber;
      return pm;
    }
  }

  public inherited sharing class RequestResponseWrapper {
    public BWC_PaymentProfile.PaymentProfile request;
    public BWC_PaymentProfile.PaymentProfileResponse response;

    public RequestResponseWrapper(
      BWC_PaymentProfile.PaymentProfile request,
      BWC_PaymentProfile.PaymentProfileResponse response
    ) {
      this.request = request;
      this.response = response;
    }
  }

  public inherited sharing class Method {
    @AuraEnabled
    public CreditCard creditCard { get; set; }
    @AuraEnabled
    public BankInfo bankInfo { get; set; }

    public RequestResponseWrapper save(
      String agentATTUID,
      Billing_Account__c ban,
      Account customer,
      String callId
    ) {
      BWC_PaymentProfile.PaymentProfile pp = commonData(
        agentATTUID,
        ban,
        customer,
        callId
      );

      BWC_PaymentProfile.PaymentMethod pm = creditCard?.save();
      pp.profileName = creditCard?.profileName();

      if (pm == null && bankInfo != null) {
        pm = bankInfo.save();
        pp.profileName = bankInfo.profileName();
      }

      pp.paymentMethod = pm;
      BWC_PaymentProfile.PaymentProfileResponse resp;
      if (System.Test.isRunningTest()) {
        resp = new BWC_PaymentProfile.PaymentProfileResponse();
        resp.error = new BWC_PaymentProfile.Error();
        resp.content = new BWC_PaymentProfile.ResponseContent();
        resp.content.responseCode = '200';
        resp.content.message = 'All good';
        resp.content.token = 'Token123';
        resp.content.applePaytoken = 'AppleToken123';
        resp.content.cardToken = 'CardToken123';
      } else {
        Boolean isUpdatingCC = (creditCard != null &&
        creditCard.ccNumber != null &&
        creditCard.ccNumber.startsWith('XXX'));
        if (isUpdatingCC) {
          System.debug(LoggingLevel.DEBUG, '--->>> Tryng to UPDATE Credit card ' + creditCard );
          resp = BWC_PaymentProfileService.postPaymentProfile(
            pp,
            BWC_PaymentProfile.MODE_UPDATE,
            false // false because of the PERSISTENT profile flag
          );
          System.debug(LoggingLevel.DEBUG, '--->>> AFTER Credit card Update ' + resp );
        } else {
          // Emulate upsert. Dirty. Should be done in the Mule
          // Correct Mule approach:
          // 1) Upsert req comes to Mule
          // 2) Mule tries to find previously saved payment method
          // 2.1) If found rename it (move)
          // 2.2) Insert new "version"
          // 2.2.1) If insert fails move old to it's original state
          // 2.3) remove old renamed PM
          // 3) Id not found just insert new PM

          // Below is simplified naive version of the upsert
          try {
            resp = BWC_PaymentProfileService.postPaymentProfile(
              pp,
              BWC_PaymentProfile.MODE_ADD,
              true // true because of the temp profile flag
            );
          } catch (Exception ex) {
            System.debug(
              System.LoggingLevel.INFO,
              '--->>> Add payment failed. Attempting update...' + ex
            );
            resp = BWC_PaymentProfileService.postPaymentProfile(
              pp,
              BWC_PaymentProfile.MODE_UPDATE,
              true // true because of the temp profile flag
            );
          }
        }
      }

      return new RequestResponseWrapper(pp, resp);
    }

    private BWC_PaymentProfile.PaymentProfile commonData(
      String agentATTUID,
      Billing_Account__c ban,
      Account customer,
      String callId
    ) {
      BWC_PaymentProfile.PaymentProfile pp = new BWC_PaymentProfile.PaymentProfile();
      pp.commonData = new BWC_PaymentProfile.CommonData();
      pp.commonData.appName = BWC_Constants.APP_NAME;
      pp.paySource = new BWC_PaymentProfile.PaySource();
      pp.paySource.sourceUser = agentATTUID;
      if (ban != null) {
        pp.accountId = ban.Billing_Account_Number__c;
        pp.accountType = ban.Account_Type__c;
        pp.paySource.sourceSystem = BWC_Constants.SOURCE_SYSTEM;
        pp.paySource.sourceLocation = BWC_Constants.SOURCE_LOCATION;
      } else {
        pp.individualId = customer.Id;
        pp.paySource.sourceSystem = BWC_Constants.SOURCE_SYSTEM_BSSE;
        pp.paySource.sourceLocation = BWC_Constants.SOURCE_LOCATION_BSSE;
      }
      pp.firstName = customer.FirstName;
      pp.lastName = customer.LastName;
      pp.temporaryProfileKey = callId;
      pp.customerAgreement = BWC_Constants.CUSTOMER_AGREEMENT;
      pp.tncId = 123; // ???
      pp.storeTermsAndConditionsConsent = true;

      return pp;
    }
  }

  public inherited sharing class PaymentMethod {
    @AuraEnabled
    public Method primary { get; set; }
    @AuraEnabled
    public Method secondary { get; set; }
  }
}
public without sharing class BWC_RedactionPaymentMethodController {
  public final static String PARAM_OTID = 'OTID'; // One time hash
  public final static String PARAM_LANG = 'LANG';

  private final static Integer MAX_RIGHT_DIGITS = 4;

  private String hash;
  private transient SecureInformationExchange__c seiRec { get; private set; }
  public String redactionType { get; private set; }
  public String errorMessage { get; private set; }
  public Date dueDate { get; private set; }
  public String ban { get; private set; }
  public String language { get; private set; }
  public Boolean isOTPVerified { get; private set; }
  public String otp { get; private set; }
  public String capabilities { get; private set; }
  public String cardPaymentMethod { get; set; }
  public String customerId { get; set; }

  public BWC_RedactionPaymentMethodController() {
    errorMessage = '';
    Map<String, String> params = ApexPages.currentPage()?.getParameters();
    if (params == null) {
      return;
    }
    language = params.get(PARAM_LANG);
    if (String.isBlank(language)) {
      language = 'en-US';
    }
    hash = params.get(PARAM_OTID);
    if ( BWC_RedactionService.crudeIsOneWayHashBad( hash ) ) {
      throw new BWC_RedactionService.RedactionServiceException('Hash is empty');
    }
  }

  public void initSecInfoExchg() {
    // if (hash == null) {
    //   return;
    // }
    BWC_RedactionService.Service srv = new BWC_RedactionService.Service(hash);
    System.debug('--->>> Reading SEI one time');
    try {
      seiRec = srv.startCustomerEntry();
      System.debug('--->>> seiRec ' + seiRec);
      isOTPVerified = seiRec.IsOtpVerified__c;
      otp = seiRec.OneTimeText__c;
      redactionType = srv.getRedactionType();
      System.debug('--->>> controller data ' + this);
      dueDate = srv.getDueDate();

      Billing_Account__c tmpBan = srv.getBillingAccount();
      ban = '';
      customerId = '';
      if (tmpBan != null) {
        Integer l = tmpBan.Billing_Account_Number__c.length();
        if (l < MAX_RIGHT_DIGITS) {
          ban = tmpBan.Billing_Account_Number__c;
        } else {
          ban =
            '*'.repeat(l - MAX_RIGHT_DIGITS) + tmpBan.Billing_Account_Number__c.right(MAX_RIGHT_DIGITS);
        }
      } else {
        customerId = srv.getCustomer().Id;
      }
      capabilities = JSON.serialize( srv.requestedCapabilities(), true ); // capabilities
      System.debug( '--->>> requested capabilities "' + capabilities + '"' );
      this.cardPaymentMethod = seiRec.PaymentProfileName__c?.replaceAll( '[^\\d]', '' );
    } catch (BWC_RedactionService.RedactionServiceException e) {
      System.debug(
        System.LoggingLevel.ERROR,
        '--->>> Exception ' + e.getMessage()
      );
      errorMessage = e.getMessage();
    }
  }

  // // Tests
  // public void initTest(String hash) {
  //   this.hash = hash;
  //   initSecInfoExchg();
  // }

  @AuraEnabled
  public static Boolean savePaymentMethod(
    String hash,
    BWC_RedactionPaymentMethod.PaymentMethod paymentMethods
  ) {
    System.debug(
      '--->>> savePaymentMethod hash=[' +
      hash +
      '] paymentMethods=' +
      paymentMethods
    );
    try {
      BWC_RedactionService.Service srv = new BWC_RedactionService.Service(hash);
      srv.savePaymentMethod(paymentMethods);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return true;
  }

  @AuraEnabled
  public static Boolean checkOTPVerificationStatus(String hash) {
    BWC_RedactionService.Service srv = new BWC_RedactionService.Service(hash);
    return srv.checkOTPVerificationStatus();
  }
}
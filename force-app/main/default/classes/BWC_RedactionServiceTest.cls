@isTest
public class BWC_RedactionServiceTest {
  private enum SEI_REC_TYPE {
    InvestigationExchange,
    PaymentExchange,
    RefundExchange
  }

  private static final String URL_BASE = 'SecureInformationExchange';
  public static final String TEMPLATE = 'Redaction_OT_URL';

  @TestSetup
  public static void makeData() {
    final User currUser = new User(Id = UserInfo.getUserId());
    System.runAs(currUser) {
      BWC_OutboundMessageTest.makeData();
    }

    System.runAs(currUser) {
      // adjust email template
      List<EmailTemplate> ets = [
        select Id from EmailTemplate 
        where DeveloperName = :TEMPLATE
      ];
      ets[ 0 ].Subject = 'Some text without data';
      ets[ 0 ].HtmlValue = 'Some body without data to merge';
      ets[ 0 ].Body = ets[ 0 ].HtmlValue; 
      update ets;
    }

    List<Account> accs = [select Id, name from Account];

    Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();
    interaction.Customer__c = accs[ 0 ].Id;
    update interaction;

    Billing_Account__c ban = BWC_TestDataFactory.createBillingAccount( 
      BWC_Constants.BillingAccount_AccountType_Wireless, accs[ 0 ] 
    );
    
    Interaction_Activity__c activity = new Interaction_Activity__c(
      Billing_Account__c = ban.Id,
      Customer__c = accs[ 0 ].Id,
      Interaction__c = interaction.Id
    );
    insert activity;


    Case c = new Case(
      Subject = 'Some test',
      AccountId = accs[ 0 ].Id,
      Billing_Account__c = ban.Id
    );
    insert c;
    
    Case_Interaction__c ci = new Case_Interaction__c(
      Case__c = c.Id,
      Interaction__c = interaction.Id
    );
    insert ci;
  }

  private static Boolean testServiceWithGoodInitiator( ID initiatorId ) {
    Boolean isgood = false;
    System.Test.startTest();
    BWC_RedactionService.Service svc = new BWC_RedactionService.Service( initiatorId );
    System.Test.stopTest();
    isGood = true;
    return isGood;
  }

  @isTest
  public static void testSIEServiceInterActivityInitiator() {
    List<Interaction_Activity__c> ias = [select id from Interaction_Activity__c];
    Boolean res = testServiceWithGoodInitiator( ias[ 0 ].Id );
    System.assert( 
      res, 
      'Expect no exceptions creating service from Interaction Activity' 
    );
  }

  @isTest
  public static void testSIEServiceCaseInitiator() {
    List<Case> cs = [select id from Case];
    Boolean res = testServiceWithGoodInitiator( cs[ 0 ].Id );
    System.assert( 
      res, 
      'Expect no exceptions creating service from Case' 
    );
  }

  @isTest
  public static void testSIEServiceBadInitiator() {
    Boolean isException = false;
    final ID uid = UserInfo.getUserId();
    System.Test.startTest();
    try {
      BWC_RedactionService.Service svc = new BWC_RedactionService.Service( uid );
    }
    catch ( BWC_RedactionService.RedactionServiceException ex ) {
      final String msg = ex.getMessage();
      isException = msg.contains( (String)uid );
    }
    System.Test.stopTest();

    System.assert( isException, 'Should throw if wrong ID of the initiator object is used' );
  }

  private static SecureInformationExchange__c testStartSecureExchange( 
    ID initiatorId,
    BWC_RedactionService.MessageType msgType,
    String target,
    String language
  ) {
    BWC_RedactionService.Service svc = new BWC_RedactionService.Service( initiatorId );
    System.Test.startTest();
    svc.startSecureXchange( msgType, target, language );
    System.Test.stopTest();
    List<SecureInformationExchange__c> sie = [select id, Case__c, InteractionActivity__c from SecureInformationExchange__c];
    return sie[ 0 ];
  }

  private static void testStartXchgInteractionActivity(
    String callerMethodName,
    BWC_RedactionService.MessageType msgType,
    String lang
  ) {
    List<Interaction_Activity__c> ias = [select id from Interaction_Activity__c];
    SecureInformationExchange__c sie = testStartSecureExchange( 
      ias[ 0 ].Id,
      msgType,
      'some phone or email',
      lang
    );

    System.assert( 
      sie != null && sie.InteractionActivity__c == ias[ 0 ].Id, 
      callerMethodName + ' SecureInformationExchange record is wrong ' + sie 
    );
  }

  @IsTest
  public static void testStartXchgInteractionActivityEmailEn() {
    testStartXchgInteractionActivity( 
      'testStartXchgInteractionActivityEmailEn',
      BWC_RedactionService.MessageType.EMAIL,
      'en-US'
    );
  }

  @IsTest
  public static void testStartXchgInteractionActivitySMSEn() {
    testStartXchgInteractionActivity( 
      'testStartXchgInteractionActivitySMSEn',
      BWC_RedactionService.MessageType.SMS,
      'en-US'
    );
  }

  @IsTest
  public static void testStartXchgInteractionActivityEmailES() {
    testStartXchgInteractionActivity( 
      'testStartXchgInteractionActivityEmailES',
      BWC_RedactionService.MessageType.EMAIL,
      'es-MX'
    );
  }

  @IsTest
  public static void testStartXchgInteractionActivitySMSES() {
    testStartXchgInteractionActivity( 
      'testStartXchgInteractionActivitySMSES',
      BWC_RedactionService.MessageType.SMS,
      'es-MX'
    );
  }

  private static void testStartXchgCase(
    String testMethodName,
    BWC_RedactionService.MessageType msgType, 
    String lang
  ) {
    List<Case> cs = [select id from Case];
    SecureInformationExchange__c sie = testStartSecureExchange( 
      cs[ 0 ].Id,
      msgType,
      'some email or phone',
      lang
    );

    System.assert( 
      sie != null && sie.Case__c == cs[ 0 ].Id, 
      testMethodName + ' SecureInformationExchange record is wrong ' + sie 
    );
  }

  @IsTest
  public static void testStartXchgCaseEmailEn() {
    testStartXchgCase( 'testStartXchgCaseEmailEn', BWC_RedactionService.MessageType.EMAIL, 'en-US' );
  }

  @IsTest
  public static void testStartXchgCaseSMSEn() {
    testStartXchgCase( 'testStartXchgCaseSMSEn', BWC_RedactionService.MessageType.SMS, 'en-US' );
  }

  @IsTest
  public static void testStartXchgCaseEmailES() {
    testStartXchgCase( 'testStartXchgCaseEmailES', BWC_RedactionService.MessageType.EMAIL, 'es-MX' );
  }

  @IsTest
  public static void testStartXchgCaseSMSES() {
    testStartXchgCase( 'testStartXchgCaseSMSES', BWC_RedactionService.MessageType.SMS, 'es-MX' );
  }

  public static BWC_RedactionService.Service getCustomerFacingService() {
    List<Interaction_Activity__c> ias = [select id from Interaction_Activity__c];
    BWC_RedactionService.Service svc = new BWC_RedactionService.Service( ias[ 0 ].Id );
    svc.startSecureXchange( BWC_RedactionService.MessageType.EMAIL, ' some email', 'es-MX' );
    List<SecureInformationExchange__c> sies = [select Id, RequestID__c from SecureInformationExchange__c];
    svc = new BWC_RedactionService.Service( sies[ 0 ].RequestID__c );
    SecureInformationExchange__c sie = svc.startCustomerEntry();
    return svc;
  }

  @IsTest
  public static void testCheckOTPVerificationStatus() {
    BWC_RedactionService.Service svc = getCustomerFacingService();
    System.Test.startTest();
    Boolean isVerified = svc.checkOTPVerificationStatus();
    System.Test.stopTest();

    System.assert( !isVerified, 'Secure Information Exchange should not be verified' );
  }

  @IsTest
  public static void testGetRedactionType() {
    BWC_RedactionService.Service svc = getCustomerFacingService();
    System.Test.startTest();
    String redaction = svc.getRedactionType();
    System.Test.stopTest();

    System.assert( !String.isBlank( redaction ), 'Redaction Type should not be empty' );
  }

  @IsTest
  public static void testGetDueDate() {
    BWC_RedactionService.Service svc = getCustomerFacingService();
    System.Test.startTest();
    Date dd = svc.getDueDate();
    System.Test.stopTest();

    System.assert( dd == null, 'Due date should be null since we do not test integration' );
  }

  @IsTest
  public static void testGetBillingAccount() {
    BWC_RedactionService.Service svc = getCustomerFacingService();
    System.Test.startTest();
    Billing_Account__c ba = svc.getBillingAccount();
    System.Test.stopTest();

    System.assert( ba != null, 'Billing Account should not be null' );
  }

  @isTest
  public static void testSavePaymentMethodOTPNotVerified() {
    BWC_RedactionService.Service svc = getCustomerFacingService();
    Boolean isException =false;
    String err;
    BWC_RedactionPaymentMethod.PaymentMethod pm = new BWC_RedactionPaymentMethod.PaymentMethod();
    System.Test.startTest();
    try {
      Boolean isSaved = svc.savePaymentMethod( pm );
    }
    catch ( BWC_RedactionService.RedactionServiceException ex ) {
      isException = true;
      err = ex.getMessage();
    }
    System.Test.stopTest();

    System.assert( 
      isException && err.contains( 'verified' ), 
      'SIE is verfied, but it should not be' 
    );
  }

  public static BWC_RedactionPaymentMethod.PaymentMethod paymentMethodFactory() {
    BWC_RedactionPaymentMethod.PaymentMethod pm = new BWC_RedactionPaymentMethod.PaymentMethod();
    pm.primary = new BWC_RedactionPaymentMethod.Method();
    pm.primary.bankInfo = new BWC_RedactionPaymentMethod.BankInfo();
    pm.primary.bankInfo.bankNameOnAcc = 'Some Person';
    pm.primary.bankInfo.bankRoutingNumber = '071000505';
    pm.primary.bankInfo.bankAccNumber = '240123401';
    pm.primary.bankInfo.bankCheckNumber = '123';

    pm.secondary = new BWC_RedactionPaymentMethod.Method();
    pm.secondary.creditCard = new BWC_RedactionPaymentMethod.CreditCard();
    pm.secondary.creditCard.ccName = 'Some person';
    pm.secondary.creditCard.ccNumber = '4127612347841100';
    pm.secondary.creditCard.ccExpiration = '12/24';
    pm.secondary.creditCard.ccSecurityCode = '123';
    pm.secondary.creditCard.ccZip = '707048';

    return pm;
  }

  @isTest
  public static void testSavePaymentMethodOTPVerified() {
    BWC_RedactionService.Service svc = getCustomerFacingService();

    List<SecureInformationExchange__c> sies = [select Id, OneTimeText__c from SecureInformationExchange__c];
    svc.verifyOTP( sies[ 0 ].OneTimeText__c );

    BWC_RedactionPaymentMethod.PaymentMethod pm = paymentMethodFactory();

    System.Test.startTest();
    Boolean isSaved = svc.savePaymentMethod( pm );
    System.Test.stopTest();

    System.assert( isSaved, 'Payment data was not saved: ' + pm );
  }

  private static Boolean testHash( String hash, String partOfExceptionMsg ) {
    Boolean isException = false;
    System.Test.startTest();
    try {
      BWC_RedactionService.Service svc = new BWC_RedactionService.Service( hash );
    }
    catch ( BWC_RedactionService.RedactionServiceException ex ) {
      final String msg = ex.getMessage();
      isException = msg.contains( partOfExceptionMsg );
    }
    System.Test.stopTest();

    return isException;
  }

  @isTest
  public static void testSIEServiceEmptyHash() {
    System.assert( testHash( null, 'empty' ), 'Should throw if Hash is blank (including null)' );
  }

  @isTest
  public static void testSIEServiceBadHash() {
    System.assert( testHash( 'ASDASDASDAS', 'Hash is empty' ), 'Should throw if Hash is blank (including null)' );
  }


}
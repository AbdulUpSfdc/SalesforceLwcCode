@IsTest
public class BWC_RedactionPaymentMethodControllerTest {
  @TestSetup
  private static void makeData() {
    BWC_RedactionServiceTest.makeData();
    BWC_RedactionServiceTest.getCustomerFacingService();
  }

  private static BWC_RedactionPaymentMethodController controllerFactory( Boolean isGoodHash ) {
    List<SecureInformationExchange__c> sies = [
      SELECT id, OneTimeText__c, RequestID__c
      FROM SecureInformationExchange__c
    ];

    Test.setCurrentPage(Page.SecureInformationExchange);

    Map<String, String> params = ApexPages.currentPage().getParameters();
    final String hash = (isGoodHash) ? sies[0].RequestID__c : 'FAKE_BAD_HASH';
    params.put(
      BWC_RedactionPaymentMethodController.PARAM_OTID,
      hash
    );
    params.put(BWC_RedactionPaymentMethodController.PARAM_LANG, 'es-MX');

    BWC_RedactionPaymentMethodController controller = new BWC_RedactionPaymentMethodController();
    return controller;
  }

  @IsTest
  public static void testControllerConstructor() {
    Test.startTest();
    BWC_RedactionPaymentMethodController ctrlr = controllerFactory( true );
    Test.stopTest();

    System.assert(ctrlr.language == 'es-MX', 'Expect correct Hash');
  }

  @IsTest
  public static void testControllerInitActionWithCorrectHash() {
    BWC_RedactionPaymentMethodController ctrlr = controllerFactory( true );

    List<SecureInformationExchange__c> sies = [
      SELECT Id
      FROM SecureInformationExchange__c
    ];
    sies[0].RequestAccessedAt__c = null;
    update sies;

    Test.startTest();
    ctrlr.initSecInfoExchg();
    Test.stopTest();

    System.assert(
      ctrlr.ban.startsWith('*'),
      'Expect ban masked and init finished'
    );
  }

  @IsTest
  public static void testControllerInitActionException() {
    BWC_RedactionPaymentMethodController ctrlr = controllerFactory( true );

    Test.startTest();
    ctrlr.initSecInfoExchg();
    Test.stopTest();

    System.assert( 
      !String.isBlank( ctrlr.errorMessage ) && ctrlr.errorMessage?.contains( 'Already' ),
      'Expected to get error about Already Accessed Exception...'
    );
  }

  @isTest
  public static void testSavePaymentMethod() {
    BWC_RedactionPaymentMethodController ctrlr = controllerFactory( true );

    List<SecureInformationExchange__c> sies = [
      SELECT Id, RequestID__c
      FROM SecureInformationExchange__c
    ];
    sies[0].RequestAccessedAt__c = null;
    update sies;

    ctrlr.initSecInfoExchg();

    update new SecureInformationExchange__c(
      Id = sies[0].Id,
      IsOtpVerified__c = true
    );

    BWC_RedactionPaymentMethod.PaymentMethod pm = BWC_RedactionServiceTest.paymentMethodFactory();
    Test.startTest();
    Boolean isSaved = BWC_RedactionPaymentMethodController.savePaymentMethod(
      sies[0].RequestID__c,
      pm
    );
    Test.stopTest();

    System.assert(isSaved, 'Suppose to save payment method');
  }

  @IsTest
  public static void testCheckOTPVerificationStatus() {
    BWC_RedactionPaymentMethodController ctrlr = controllerFactory( true );

    List<SecureInformationExchange__c> sies = [
      SELECT Id, RequestID__c
      FROM SecureInformationExchange__c
    ];

    Test.startTest();
    Boolean isVerified = BWC_RedactionPaymentMethodController.checkOTPVerificationStatus(
      sies[0].RequestID__c
    );
    Test.stopTest();

    System.assert(!isVerified, 'It should not be verified here');
  }
}
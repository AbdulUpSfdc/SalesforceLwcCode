@isTest
public class BWC_RedactionSummaryControllerTest {

    private static final String NAME_ON_BANK_ACC        = 'Some Dude';
    private static final String ROUTING_NO              = '123456789';
    private static final String BANK_ACC_NO             = '987654321';
    private static final String CHK_NO                  = '56473829';
    private static final String PROFILE_BANK_NAME       = 'Checking ...4321';
    private static final String PROFILE_CC_NAME         = 'Visa ...5674';
    private static final String SECURE_TOKEN            = '34234234342342422';

    @TestSetup
    private static void makeData() {
      BWC_RedactionServiceTest.makeData();

      List<Case> ias = [select id from Case order by Id];
      
      BWC_RedactionService.Service svc = new BWC_RedactionService.Service( ias[ 0 ].Id );
      svc.startSecureXchange( BWC_RedactionService.MessageType.EMAIL, ' some email', 'es-MX' );
      List<SecureInformationExchange__c> sies = [
        select Id, RequestID__c, RequestorATTUID__c, OneTimeText__c 
        from SecureInformationExchange__c where Case__c = :ias[0].Id
        order by RequestID__c
      ];
      svc = new BWC_RedactionService.Service( sies[ 0 ].RequestID__c );
      SecureInformationExchange__c sie = svc.startCustomerEntry();

      BWC_RedactionPaymentMethod.PaymentMethod paymentMethods = new 
        BWC_RedactionPaymentMethod.PaymentMethod();
      paymentMethods.primary = new BWC_RedactionPaymentMethod.Method();
      paymentMethods.primary.bankInfo = new BWC_RedactionPaymentMethod.BankInfo();   
      paymentMethods.primary.bankInfo.bankNameOnAcc = NAME_ON_BANK_ACC;
      paymentMethods.primary.bankInfo.bankRoutingNumber = ROUTING_NO;
      paymentMethods.primary.bankInfo.bankAccNumber = BANK_ACC_NO;
      paymentMethods.primary.bankInfo.bankCheckNumber = CHK_NO;
      paymentMethods.secondary = new BWC_RedactionPaymentMethod.Method();
      paymentMethods.secondary.creditCard = new BWC_RedactionPaymentMethod.CreditCard();
      paymentMethods.secondary.creditCard.ccName = NAME_ON_BANK_ACC;
      paymentMethods.secondary.creditCard.ccExpiration = '01/21';
      paymentMethods.secondary.creditCard.ccNumber = '5507032638919100';
      paymentMethods.secondary.creditCard.ccSecurityCode = '123';
      paymentMethods.secondary.creditCard.ccZip = '12345';
      
      BWC_RedactionController.verifyOTP( ias[ 0 ].Id, sies[ 0 ].OneTimeText__c );
      BWC_RedactionPaymentMethodController.savePaymentMethod(
        sies[ 0 ].RequestID__c,
        paymentMethods
      );
    

      // // Update SIE to emulate user input
      // SecureInformationExchange__c primaryMethod = sies[0];
      // primaryMethod.IsOtpVerified__c=true;
      // primaryMethod.Case__c = ias[ 0 ].Id;

      // SecureInformationExchange__c secondaryMethod = primaryMethod.clone(false,true,false,false);

      // primaryMethod.NameOnBankAccount__c = NAME_ON_BANK_ACC;
      // primaryMethod.NameOnBankAccountMasked__c = svc.mask( NAME_ON_BANK_ACC );
      // primaryMethod.RoutingBankNumber__c = ROUTING_NO;
      // primaryMethod.RoutingBankNumberMasked__c = svc.mask( ROUTING_NO );
      // primaryMethod.BankAccountNumber__c = BANK_ACC_NO;
      // primaryMethod.BankAccountNumberMasked__c = svc.mask( BANK_ACC_NO );
      // primaryMethod.CheckNumber__c = CHK_NO;
      // primaryMethod.PaymentProfileName__c = PROFILE_BANK_NAME;
      // primaryMethod.PaymentMethodToken__c = '';
      // update primaryMethod;

      // System.debug( '--->>> primaryMethod: ' + primaryMethod );

      // secondaryMethod.PaymentProfileName__c = PROFILE_CC_NAME;
      // secondaryMethod.PaymentMethodToken__c = SECURE_TOKEN;
      // secondaryMethod.RequestID__c = primaryMethod.RequestID__c + '-2';

      // insert secondaryMethod;

      // System.debug( '--->>> secondaryMethod: ' + secondaryMethod );

      // sies = [select id, RequestID__c from SecureInformationExchange__c where case__c = :ias[0].id];
      // System.debug( '--->>> sies ' + sies );
    }

    @isTest
    public static void testLimitedSummaryView() {
      System.debug( '--->>> Entering testLimitedSummaryView()....' );
      final User currUser = new User(Id = UserInfo.getUserId());
      List<Case> cases = [select id from Case order by Id];

      System.runAs(currUser) {
        User limitedUsr = BWC_TestDataFactory.createUser();
        System.runAs(limitedUsr) {
          System.Test.startTest();
          BWC_RedactionSummaryController.SecureInfoSummary summary = 
            BWC_RedactionSummaryController.getSecureInfoSummary( cases[ 0 ].Id );
          System.Test.stopTest();

          System.debug(LoggingLevel.DEBUG, '--->>> limited user summary ' + summary );

          System.assert( 
            summary.payment.bank.nameOnAccount.startsWith( '***' )
            && summary.payment.bank.routingNumber.startsWith( '***' )
            && summary.refund.creditCard.isTokenSaved
            && String.isBlank( summary.refund.creditCard.secureToken )
          );
        }
      }
    }

    @isTest
    public static void testFullSummaryView() {
      System.debug( '--->>> Entering testFullSummaryView()....' );
      final User currUser = new User(Id = UserInfo.getUserId());

      System.runAs(currUser) {
        User allViewUsr = BWC_TestDataFactory.createUser();
        List<PermissionSet> pss = [
          SELECT Id FROM PermissionSet 
          WHERE Name = :BWC_RedactionService.VIEW_SECURE_PAYMENT_INFO_PS
        ];
        insert new PermissionSetAssignment(AssigneeId = allViewUsr.id, PermissionSetId = pss[0].Id);
  
        System.runAs(allViewUsr) {
          List<Case> cases = [select id from Case];
          System.Test.startTest();
          BWC_RedactionSummaryController.SecureInfoSummary summary = 
            BWC_RedactionSummaryController.getSecureInfoSummary( cases[ 0 ].Id );
          System.Test.stopTest();

          System.debug(LoggingLevel.DEBUG, '--->>> view ALL user summary ' + summary );

          System.assert( 
            !summary.payment.bank.nameOnAccount.startsWith( '***' )
            && !summary.payment.bank.routingNumber.startsWith( '***' )
            && summary.refund.creditCard.isTokenSaved
            && !String.isBlank( summary.refund.creditCard.secureToken )
          );
        }
      }
    }
  
}
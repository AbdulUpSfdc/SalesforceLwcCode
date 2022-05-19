@IsTest
public class BWC_RedactionControllerTest {

    @TestSetup
    private static void makeData(){
        BWC_RedactionServiceTest.makeData();
    }

    @IsTest
    public static void testStartEmailSecureXchange() {
        List<Case> cs = [select Id from Case];

        Test.startTest();
        Boolean isStarted  = BWC_RedactionController.startEmailSecureXchange( 
            cs[ 0 ].Id, 'some email', null, 'es-MX'
        );
        Test.stopTest();

        System.assert( isStarted, 'Expected success' );
    }

    @IsTest
    public static void testStartSMSSecureXchange() {
        List<Case> cs = [select Id from Case];

        Test.startTest();
        Boolean isStarted  = BWC_RedactionController.startSMSSecureXchange( 
            cs[ 0 ].Id, 'some phone', null, 'es-MX' 
        );
        Test.stopTest();

        System.assert( isStarted, 'Expected success' );
    }

    @isTest
    public static void testVerifyOTP() {
        List<Interaction_Activity__c> ias = [select id from Interaction_Activity__c];

        BWC_RedactionServiceTest.getCustomerFacingService();
        List<SecureInformationExchange__c> sies = [select Id from SecureInformationExchange__c];
        sies[ 0 ].RequestAccessedAt__c = System.now();
        update sies[ 0 ];

        Test.startTest();
        Boolean isVerified  = BWC_RedactionController.verifyOTP( 
            ias[ 0 ].Id, 'WRONG OTP' 
        );
        Test.stopTest();

        System.assert( !isVerified, 'Expected wrong OTP' );
    }
    
    @isTest
    public static void testPaymentInfoEntered() {
        List<Interaction_Activity__c> ias = [select id from Interaction_Activity__c];
        BWC_RedactionService.Service svc = BWC_RedactionServiceTest.getCustomerFacingService();

        List<SecureInformationExchange__c> sies = [select Id, OneTimeText__c from SecureInformationExchange__c];
        svc.verifyOTP( sies[ 0 ].OneTimeText__c );
    
        BWC_RedactionPaymentMethod.PaymentMethod pm = BWC_RedactionServiceTest.paymentMethodFactory();
    
        Boolean isSaved = svc.savePaymentMethod( pm );
    
        Test.startTest();
        String json = BWC_RedactionController.paymentInfoEntered( ias[ 0 ].Id );
        Test.stopTest();

        System.debug( '--->>> json: ' + json );
    }
}
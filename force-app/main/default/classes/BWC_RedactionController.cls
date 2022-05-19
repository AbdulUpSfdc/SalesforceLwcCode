public with sharing class BWC_RedactionController {

    private static final Integer OTP_SZ = 5;

    public static final String AUX_PAYMENT_METHOD = 'PAYMENT_METHOD';

    // Adjust to handle Mulesoft BWC error structure
    public class RedactionException extends Exception {}    

    @AuraEnabled
    public static String paymentInfoEntered( String sobjId ){
        BWC_RedactionService.Service srv = new BWC_RedactionService.Service( (ID)sobjId, OTP_SZ );
        BWC_PaymentDetails.PaymentProfile pp = srv.getNewTempPaymentProfile();
        System.debug( '--->>> Got profile ' + pp );
        return JSON.serialize(pp, true);
    }

    /**
     * @return BWC_PaymentDetails.PaymentProfile serialized like a JSON string 
     */
    @AuraEnabled
    public static String getRefundPaymentMethod( String sobjId ){
        BWC_RedactionService.Service srv = new BWC_RedactionService.Service( (ID)sobjId );
        return JSON.serialize( srv.getRefundPaymentProfile(), true );
    }

    @AuraEnabled
    public static Boolean startEmailSecureXchange( 
        String sobjId, 
        String email, 
        String[] capabilities, 
        String language 
    ) {
        BWC_RedactionService.Service srv = new BWC_RedactionService.Service( (ID)sobjId, OTP_SZ );
        return srv.startSecureXchange( BWC_RedactionService.MessageType.EMAIL, email, capabilities, language );
    }

    @AuraEnabled
    public static Boolean startSMSSecureXchange( 
        String sobjId, 
        String phone, 
        String[] capabilities, 
        String language 
    ) {
        BWC_RedactionService.Service srv = new BWC_RedactionService.Service( (ID)sobjId, OTP_SZ );
        return srv.startSecureXchange( BWC_RedactionService.MessageType.SMS, phone, capabilities, language );
    }

    public class AuxRequest {
        @AuraEnabled
        public String sobjId { get; set; }
        @AuraEnabled
        public String targetAddress { get; set; }
        @AuraEnabled
        public List<String> capabilities { get; set; }
        @AuraEnabled
        public String language { get; set; }
        @AuraEnabled
        public Map<String,String> auxNvp { get; set; }
    }

    private static Boolean secureXchangeAux( 
        AuxRequest req, 
        BWC_RedactionService.MessageType msgType 
    ) {
        Boolean res = false;

        BWC_RedactionService.Service srv = new BWC_RedactionService.Service( (ID)req.sobjId, OTP_SZ );
        if ( req.capabilities.contains( BWC_RedactionService.PaymentCapability.CREDCARD_CVV_ONLY.name() ) ) {
            if ( req.auxNvp.containsKey( AUX_PAYMENT_METHOD ) ) {
                res = srv.startSecureXchangeCVV( 
                    msgType, 
                    req.targetAddress, 
                    req.language, 
                    req.auxNvp.get( AUX_PAYMENT_METHOD )
                );
            }
        }

        return res;
    }

    @AuraEnabled
    public static Boolean startEmailSecureXchangeAux( AuxRequest req ){
        return secureXchangeAux(req, BWC_RedactionService.MessageType.EMAIL );
    }

    @AuraEnabled
    public static Boolean startSMSSecureXchangeAux( AuxRequest req ){
        return secureXchangeAux(req, BWC_RedactionService.MessageType.SMS );
    }

    @AuraEnabled
    public static Boolean verifyOTP( String sobjId, String otp ){
        BWC_RedactionService.Service srv = new BWC_RedactionService.Service( (ID)sobjId );
        return srv.verifyOTP( otp );
    }

    @AuraEnabled(cacheable=true)
    public static Billing_Account__c getBan( String sobjId ){
        BWC_RedactionService.Service srv = new BWC_RedactionService.Service( (ID)sobjId );
        return srv.getBAN();
    }

    @AuraEnabled(cacheable=true)
    public static Account getCustomer( String sobjId ) {
        BWC_RedactionService.Service srv = new BWC_RedactionService.Service( (ID)sobjId );
        return srv.getCustomer();
    }
}
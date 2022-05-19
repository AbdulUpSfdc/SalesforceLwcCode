public with sharing class BWC_RedactionSummaryController {

    // ' PaymentMethodToken__c,' +
    // ' NameOnBankAccount__c,	NameOnBankAccountMasked__c,' +
    // ' RoutingBankNumber__c, RoutingBankNumberMasked__c,' +
    // ' BankAccountNumber__c,	BankAccountNumberMasked__c,' +
    // ' CheckNumber__c,' +
    // ' PaymentProfileName__c' +

    private static String str( String v ) {
        return (String.isBlank(v)) ? '' : v;
    }

    public class CreditCardSummary {
        @AuraEnabled
        public String cardType { get; private set; }
        @AuraEnabled
        public String secureToken { get; private set; } 
        @AuraEnabled
        public Boolean isTokenSaved { get; private set; }

        public CreditCardSummary( SecureInformationExchange__c sie ) {
            final String paymentMethod = str( sie?.PaymentProfileName__c );
            if ( !String.isBlank( paymentMethod ) ) {
                cardType = paymentMethod.replaceAll( '\\s\\.\\.\\.\\d{4,4}$', '' );
            }
            secureToken = str( sie?.PaymentMethodToken__c );            
            isTokenSaved = ( 
                paymentMethod != '' 
                && 
                !paymentMethod.startsWithIgnoreCase( 
                    BWC_RedactionPaymentMethod.BankAccountType.CHECKING.name() 
                ) 
            );
        }
    }

    public class BankSummary {
        @AuraEnabled
        public String nameOnAccount { get; private set; }
        @AuraEnabled
        public String routingNumber { get; private set; }
        @AuraEnabled
        public String accountNumber { get; private set; }
        @AuraEnabled
        public String checkNumber { get; private set; }

        public BankSummary( SecureInformationExchange__c sie ) {
            nameOnAccount = initPair( 
                sie?.NameOnBankAccount__c, sie?.NameOnBankAccountMasked__c 
            );
            routingNumber = initPair(
                sie?.RoutingBankNumber__c, sie?.RoutingBankNumberMasked__c
            );
            accountNumber = initPair(
                sie?.BankAccountNumber__c, sie?.BankAccountNumberMasked__c
            );    
            checkNumber = str( sie?.CheckNumber__c );
        }

        private String initPair( String primary, String secondary ) {
            System.debug( '--->>> initPair primary [' + primary + '] secondary [' + secondary + ']' );
            String v = str( primary );
            System.debug(  '--->>> v primary [' + v + ']' );
            if ( v == '' ) {
                v = str( secondary );
                System.debug(  '--->>> v scondary [' + v + ']' );
            }
            return v;
        }
    }

    public class SecureInfoStatus {
        @AuraEnabled
        public CreditCardSummary creditCard { get; private set; }
        @AuraEnabled
        public BankSummary bank { get; private set; }

        public SecureInfoStatus( SecureInformationExchange__c sie ) {
            CreditCardSummary ccs = new CreditCardSummary( sie );
            if ( ccs.isTokenSaved ) {
                creditCard = ccs;
            }
            else {
                bank = new BankSummary( sie );
            }
        }
    }

    public class SecureInfoSummary {
        @AuraEnabled
        public SecureInfoStatus payment { get; private set; }
        @AuraEnabled
        public SecureInfoStatus refund { get; private set; }

        public SecureInfoSummary( List<SecureInformationExchange__c> sies ) { 
            System.debug( System.LoggingLevel.DEBUG, '--->>> Processing sies ' + sies );
            for ( SecureInformationExchange__c sie : sies ) {
                // Redaction service can return SecureInformationExchange records which are "empty".
                // Because of that we need to check if record has Id or not.
                if ( sie.Id == null ) {
                    System.debug(LoggingLevel.DEBUG, 'SIE is not permanent. Skipping... ' + sie );
                    continue;
                }
                if ( sie.RecordType.DeveloperName == BWC_RedactionService.SEI_RT_REFUND_XCHG ) {
                    refund = new SecureInfoStatus( sie );
                }
                else {
                    payment = new SecureInfoStatus( sie );
                }                
            }
            // if ( sies.size() >= 1 && sies[ 0 ].Id != null ) {
            //     if ( sies[ 0 ].Recordtype.DeveloperName == BWC_RedactionService.SEI_RT_REFUND_XCHG ) {
            //         refund = new SecureInfoStatus( sies[ 0 ] );
            //     }
            //     else {
            //         payment = new SecureInfoStatus( sies[ 0 ] );
            //     }
            // }   
            // if ( sies.size() == 2 && sies[ 1 ].Id != null ) {
            //     refund = new SecureInfoStatus( sies[ 1 ] );
            // }
            if ( 
                payment != NULL 
                && payment.creditCard != null 
                && payment.creditCard.isTokenSaved 
            ) {
                if ( refund != null ) {
                    System.debug( 
                        System.LoggingLevel.WARN, 
                        'If primary method is CC refund should not exist...'
                        + ' DATA: ' + this
                    );
                }
                refund = null;
            }
        }
    }

    @AuraEnabled(cacheable=true)
    public static SecureInfoSummary getSecureInfoSummary( String sobjId ) {
        BWC_RedactionService.Service srv = new BWC_RedactionService.Service( (ID)sobjId );
        return new SecureInfoSummary( srv.getSIERecords() );
    }

}
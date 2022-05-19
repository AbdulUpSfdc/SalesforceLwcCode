/*
    Unit test coverage for BWC_PaymentProfile.
*/
@isTest
public with sharing class BWC_PaymentProfile_Test {

    @isTest
    private static void testProperties() {

        // Zip code
        BWC_PaymentProfile.Card card = new BWC_PaymentProfile.Card();
        System.assertEquals(null, card.zipCode);
        card.zipCode = '12345';
        System.assertEquals('12345', card.billingAddress.zipCode);
        card.billingAddress.zipCode = '44444';
        System.assertEquals('44444', card.zipCode);

        // Payment method type
        BWC_PaymentProfile.PaymentMethod paymentMethod = new BWC_PaymentProfile.PaymentMethod();
        paymentMethod.type = BWC_Constants.PAYMENT_METHOD_TYPE_CARD;
        System.assertEquals(BWC_Constants.PAYMENT_METHOD_TYPE_CARD, paymentMethod.paymentMethodType);

    }

}
@isTest
public with sharing class BWC_UtilsTest {

    @isTest
    private static void testGetBoolean() {
        System.assertEquals(true, BWC_Utils.getBoolean('true'), 'Failed boolean test.');
        System.assertEquals(true, BWC_Utils.getBoolean('Y'), 'Failed boolean test.');
        System.assertEquals(false, BWC_Utils.getBoolean(null), 'Failed boolean test.');
    }

    @isTest
    private static void testNewGuid() {
        System.assertNotEquals(null, BWC_Utils.newGuid(), 'Create a new GUID failed.');
    }

    @isTest
    private static void testAppendString() {
        System.assertEquals('prefix - suffix', BWC_Utils.appendString('prefix', 'suffix', ' - '), 'Append of string failed.');
        System.assertEquals('suffix', BWC_Utils.appendString('', 'suffix', ' - '), 'Prefix was empty, no join should have been performed.');
        System.assertEquals('prefix', BWC_Utils.appendString('prefix', '', ' - '), 'Suffix was empty, no join should have been performed.');
    }

    @isTest
    private static void testSetStaticResourceMock() {
        System.assertNotEquals(null, BWC_Utils.setStaticResourceMock('staticResourceName', 3), 'Failed to get mocked resource.');
    }


    @isTest
    private static void testMask() {
        String str1 = BWC_Utils.mask('9999 9999 1234 5678');
        String str2 = BWC_Utils.mask('9999-9999-9999-123');
        String str3 = BWC_Utils.mask('999999999123456');
        String str4 = BWC_Utils.mask('9999/9999/1234/5432');
        String str5 = BWC_Utils.mask('912345432');
        String str6 = BWC_Utils.mask('91-23-4543');
        String str7 = BWC_Utils.mask('BAN 999991234');
        String str8 = BWC_Utils.mask('Account Number 999123456');
        String str9 = BWC_Utils.mask('345432');

        System.assertEquals('xxxxxxxxxxx5678', str1, 'Masking Failed.');
        System.assertEquals('xxxxxxxxxxx9123', str2, 'Masking Failed.');
        System.assertEquals('xxxxxxxxxxx3456', str3, 'Masking Failed.');
        System.assertEquals('xxxxxxxxxxx5432', str4, 'Masking Failed.');
        System.assertEquals('xxxxx5432', str5, 'Masking Failed.');
        System.assertEquals('91-23-4543', str6, 'Masking Failed.');
        System.assertEquals('BAN 999991234', str7, 'Masking Failed.');
        System.assertEquals('Account Number 999123456', str8, 'Masking Failed.');
        System.assertEquals('345432', str9, 'Masking Failed.');
    }

    @isTest
    private static void testMaskSentence() {
        String str1 = BWC_Utils.maskSentence('There are many 999999999999999 of passages of Lorem Ipsum available 9999-999999-99999, but the majority have suffered CC  9999999999999999 alteration Credit Card is 9999/999999/99999 in some form 9999/999999/99999, by injected humour, or randomised Mastercard 9999 999999 99999 words which don\'t look even slightly believable. If you are going to use a passage of Lorem Ipsum, you need to be sure there isn\'t anything 9999999999999999 embarrassing hidden 9999/999999/99999 in SSN 999-99-9999 the middle of text. All the Lorem Ipsum generators 9999-9999-9999-9999 on the Internet tend to repeat predefined chunks as necessary, making this the first true generator on the Internet. It uses a dictionary of over 200 Latin words, combined with a Master Card 99999999999999 handful of model sentence structures, to generate Lorem Ipsum which looks reasonable. The Bank Account: 9999 999999 99999  generated Lorem Ipsum is therefore always free from account number 9999 999999 999999999 repetition, injected American Express 9999 999999 999999  humour, or non-characteristic words etc.');
        System.assertEquals('There are many 999999999999999 of passages of Lorem Ipsum available xxxxxxxxxxx9999, but the majority have suffered CC  xxxxxxxxxxx9999 alteration Credit Card is 9999/999999/99999 in some form 9999/999999/99999, by injected humour, or randomised Mastercard xxxxxxxxxxx9999 words which don\'t look even slightly believable. If you are going to use a passage of Lorem Ipsum, you need to be sure there isn\'t anything 9999999999999999 embarrassing hidden 9999/999999/99999 in SSN xxxxx9999 the middle of text. All the Lorem Ipsum generators xxxxxxxxxxx9999 on the Internet tend to repeat predefined chunks as necessary, making this the first true generator on the Internet. It uses a dictionary of over 200 Latin words, combined with a Master Card xxxxx9999 handful of model sentence structures, to generate Lorem Ipsum which looks reasonable. The Bank Account: xxxxxxxxxxx9999  generated Lorem Ipsum is therefore always free from account number 9999 999999 999999999 repetition, injected American Express xxxxxxxxxxx9999  humour, or non-characteristic words etc.', str1, 'Failed masking sentence.');
        String str2 = BWC_Utils.maskSentence('Bank Account: 2340985 Bank Account 234092348320958 test test testtest test Bank 23409230958 Bank Account Bank Bank Account: Bankbank');
        System.assertEquals('Bank Account: 2340985 Bank Account xxxxxxxxxxx0958 test test testtest test Bank 23409230958 Bank Account Bank Bank Account: Bankbank', str2, 'Sentences do not match.');
        String str3 = BWC_Utils.maskSentence('Bank Account 234230948230948 Bank Account 3423423 Bank Account 3 Bank Account 23409230582 Bank Account 234092305823 Bank Account 2340923058245 Bank Account 23409230582456 Bank Account 234092305824567 Bank Account 2340923058245 6');
        System.assertEquals('Bank Account xxxxxxxxxxx0948 Bank Account 3423423 Bank Account 3 Bank Account xxxxx0582 Bank Account xxxxx5823 Bank Account xxxxx8245 Bank Account xxxxx2456 Bank Account xxxxxxxxxxx4567 Bank Account xxxxx2456', str3, 'Masking Bank Account Numbers failed.');
        String str4 = BWC_Utils.maskSentence('bank account 234230948230948');
        System.assertEquals('bank account xxxxxxxxxxx0948', str4, 'The regex is case sensitive.');
        String str5 = BWC_Utils.maskSentence('Bank Account-123458351632-Authenticated,UVERSE-123454864-Unauthenticated,dtvs-36851113-Authenticated Interaction Summary Actions: Inquiry,Product Service,Profile Management Detailed Actions Performed: Inquiry-Authentication-,Product Service-Add a line-,Product Service-Change Plan-,Inquiry-Inquiry-Service,Profile Management-Change contact info-Email Agent Notes: This is a note for the file');
        System.assertEquals('Bank Account-xxxxx1632-Authenticated,UVERSE-123454864-Unauthenticated,dtvs-36851113-Authenticated Interaction Summary Actions: Inquiry,Product Service,Profile Management Detailed Actions Performed: Inquiry-Authentication-,Product Service-Add a line-,Product Service-Change Plan-,Inquiry-Inquiry-Service,Profile Management-Change contact info-Email Agent Notes: This is a note for the file', str5, 'We did not want to mask. Failed.');
        String str6 = BWC_Utils.maskSentence('WIRELESS-123458351632-Authenticated,UVERSE-123454864-Unauthenticated,dtvs-36851113-Authenticated Interaction Summary Actions: Inquiry,Product Service,Profile Management Detailed Actions Performed: Inquiry-Authentication-,Product Service-Add a line-,Product Service-Change Plan-,Inquiry-Inquiry-Service,Profile Management-Change contact info-Email Agent Notes: This is a note for the file');
        System.assertEquals('WIRELESS-123458351632-Authenticated,UVERSE-123454864-Unauthenticated,dtvs-36851113-Authenticated Interaction Summary Actions: Inquiry,Product Service,Profile Management Detailed Actions Performed: Inquiry-Authentication-,Product Service-Add a line-,Product Service-Change Plan-,Inquiry-Inquiry-Service,Profile Management-Change contact info-Email Agent Notes: This is a note for the file', str6, 'We did not want to mask. Failed.');
   }

   @isTest
   private static void testGetDayOfMonthOrdinal() {

        System.assertNotEquals(null, BWC_Utils.getDayOfMonthOrdinal(Date.today()), 'failed to get ordinal for date.');
        System.assertEquals('1st', BWC_Utils.getDayOfMonthOrdinal(Date.newInstance(2021, 1, 1)), 'Day of the month Ordinal is incorrect.');
        System.assertEquals('2nd', BWC_Utils.getDayOfMonthOrdinal(Date.newInstance(2021, 1, 2)), 'Day of the month Ordinal is incorrect.');
        System.assertEquals('3rd', BWC_Utils.getDayOfMonthOrdinal(Date.newInstance(2021, 1, 3)), 'Day of the month Ordinal is incorrect.');
        System.assertEquals('4th', BWC_Utils.getDayOfMonthOrdinal(Date.newInstance(2021, 1, 4)), 'Day of the month Ordinal is incorrect.');

   }

    @IsTest
    static void getAutoCTIIdentTest(){

        String result = BWC_Utils.getAutoCTIIdent();
        System.assert(result.containsIgnoreCase('Automated'), 'CTI Ident does not contain the Automated prefix');
    }

    @IsTest
    static void test_maskPhoneNumber(){
        String result = BWC_Utils.maskPhoneNumber('1234567890');
        System.assertEquals('(***) **6-7890', result);
    }

    @IsTest
    static void test_maskEmailAddress(){
        String result = BWC_Utils.maskEmailAddress('test@email.com');
        System.assertEquals('t****@email.com', result);
    }

    @IsTest
    static void test_hashContactMethod() {
        Blob valueStrBlob = Blob.valueOf('1234567890');
        Blob valueHash = Crypto.generateDigest('MD5', valueStrBlob); 
        String valueHashed = EncodingUtil.base64Encode(valueHash);

        String result = BWC_Utils.hashContactMethod('1234567890');
        System.assertEquals(valueHashed, result);
    }

    @IsTest
    static void test_formatPhone() {
        String result = BWC_Utils.formatPhone('1234567890');
        System.assertEquals('(123) 456-7890', result);

        String result11Digits = BWC_Utils.formatPhone('11234567890');
        System.assertEquals('+1 (123) 456-7890', result11Digits);
    }
}
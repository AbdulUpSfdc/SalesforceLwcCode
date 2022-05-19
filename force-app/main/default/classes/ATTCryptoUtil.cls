global inherited sharing class ATTCryptoUtil {

    private static final Integer AES_KEY_SIZE = 256;
    private static final Integer HMAC_KEY_SIZE = 128;

    private static final String SECRET_API_NAME = 'DEFAULT_BTDC';
    private static final String ENCODING_SCHEME = 'UTF-8';

    private MTLS_Detail__mdt MTLS_Detail;
    private enum supportedCryptoAlgorithm {
        AES128,
        AES192,
        AES256
    }

    global class BTDC_signature {

        private final String PRIVATE_KEY = ATTCryptoUtil.getHmacPrivateKey();

        global String data { global get; private set; }

        global String signature {
            global get {
                if (String.isNotBlank(this.data))
                    return EncodingUtil.base64Encode(
                        Crypto.generateMac(
                            'HmacSHA256',
                            Blob.valueOf(this.data),
                            EncodingUtil.base64Decode(PRIVATE_KEY)
                        )
                    );
                return null;
            }
        }

        global boolean verifySignature(String mac) {
            return Crypto.verifyHMac(
                'HmacSHA256',
                Blob.valueOf(this.data),
                EncodingUtil.base64Decode(PRIVATE_KEY),
                EncodingUtil.base64Decode(mac)
            );
        }

        global BTDC_signature(String data) {
            this.data = data;
        }
    }

    global ATTCryptoUtil() {
        MTLS_Detail__mdt MTLSDetails = MTLS_Detail__mdt.getInstance('Default');
        if (MTLSDetails?.Base64HmacKey__c != null)
        {
            this.MTLS_Detail = MTLSDetails;
        } else{
            throw new EncryptionException('Encryption Keys Not present on MTLS_Detail__mdt');
        }
    }

//****************************************** */
    public static String getHmacPrivateKey() {
        ATTCryptoUtil cu = new ATTCryptoUtil();
        return cu.MTLS_Detail.Base64HmacKey__c;
    }
//****************************************** */
//***************** */
    public String addHMAC(String message) {
        if (String.isBlank(message)) {
            return message;
        }
        ATTCryptoUtil.BTDC_signature signedMsg = new ATTCryptoUtil.BTDC_signature(message);
        return String.isNotBlank(signedMsg.signature) ? signedMsg.signature + '_' + signedMsg.data : message;
    }
//***************** */

//***************** */
    public String verifyAndRemoveHMAC(String message) {
        if (!message.contains('_')) {
            return null;
        }

        BTDC_signature signedMsg = new BTDC_signature(message.substringAfter('_'));
        if (!signedMsg.verifySignature(message.substringBefore('_'))) {
            return null;
        }
        return signedMsg.data;
    }
//***************** */

public class EncryptionException extends Exception {}

}
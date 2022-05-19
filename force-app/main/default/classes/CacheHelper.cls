public with sharing class CacheHelper {

    //system.debug('Category id to be hashed: ' + categoryId);
    // Need to hash string as cache keys CAN ONLY contain alphanumeric (data cat api names contain '_' which will not work)
            
    public static String getHashedKey(String objectKey) {
     	Blob targetBlob = Blob.valueOf(objectKey);
        Blob hash = Crypto.generateDigest('MD5', targetBlob);
        String hashedString = EncodingUtil.convertToHex(hash);  
        return hashedString;
    }

}
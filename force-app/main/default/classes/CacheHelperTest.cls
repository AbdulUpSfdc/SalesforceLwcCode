@isTest
public with sharing class CacheHelperTest {

    public static testMethod void testGetHashedKey(){
    	String key = 'TestKey';
        System.assertNotEquals(null, CacheHelper.getHashedKey(key));
      
    }
}
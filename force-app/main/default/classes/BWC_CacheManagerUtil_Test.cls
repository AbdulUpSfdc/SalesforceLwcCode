@IsTest
public with sharing class BWC_CacheManagerUtil_Test {

    @IsTest
    static void makeKeyTest(){

        Test.startTest();
        String key = BWC_CacheManagerUtil.makeKey('testCTI', 'testPartionName');
        Test.stopTest();

    }
}
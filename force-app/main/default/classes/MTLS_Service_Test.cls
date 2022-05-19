@isTest
public with sharing class MTLS_Service_Test {

    @isTest
    public static void testCase00(){
        MTLS_Detail__mdt MDT_Record = [SELECT id,UUID__c, KEY256__c, Proxy_Endpoint__c FROM MTLS_Detail__mdt WHERE Label ='Default' ];
        RestContext.request = new RestRequest();
        RestContext.Response = new RestResponse();
        
        RestContext.request.requestURI = '/service/apexrest/SFA/v1/Mahalo_requests/jsonp';
        RestContext.request.addHeader('X-ALOHA-SIP','attone');
        RestContext.request.addHeader('X-ALOHA-PROXY-UUID','65979520-b134-4769-9a30-c6b9d5a2c22');
        RestContext.request.httpMethod = 'get';
    	MTLS_Service.doGet();

        RestContext.request.addHeader('X-ALOHA-PROXY-UUID','65979520-b134-4769-9a30-c6b');
    	MTLS_Service.doGet();
        System.assertNotEquals(null, MTLS_Service.getVerify(MDT_Record, JSON.serialize(RestContext.response.responseBody)));

        RestContext.request.addHeader('X-ALOHA-PROXY-UUID',MDT_Record.UUID__c);
    	MTLS_Service.doGet();
        System.assertNotEquals(null, MTLS_Service.getVerify(MDT_Record, JSON.serialize(RestContext.response.responseBody)));

        RestContext.request.addHeader('X-ALOHA-SIP','testingFailure');
    	MTLS_Service.doGet();
        System.assertNotEquals(null, MTLS_Service.getVerify(MDT_Record, JSON.serialize(RestContext.response.responseBody)));

        RestContext.request.requestURI = '/service/apexrest/SFA/v1/Mahalo_requests';
    	MTLS_Service.doGet();
        System.assertNotEquals(null, MTLS_Service.getVerify(MDT_Record, JSON.serialize(RestContext.response.responseBody)));

    }
    @isTest
    public static void testCase01(){
		System.assertNotEquals(true,MTLS_Service.isUserValid('CN=testUser,'));
    }
    @isTest
    public static void testCase02(){
        MTLS_Detail__mdt MDT_Record = [SELECT id,UUID__c, KEY256__c, Proxy_Endpoint__c FROM MTLS_Detail__mdt WHERE Label ='Default' ];
       	
        MTLS_Service.Ticket ServiceTicket = new MTLS_Service.Ticket('attone', 'SUCCESS', 'Some_crt', 'CN=testUser,');
        Blob privateKey = EncodingUtil.base64Decode(JSON.serialize(Crypto.generateAesKey(256)).replace('"',''));
        Blob clearText = Blob.valueOf(JSON.serialize(ServiceTicket, true));
        ATTCryptoUtil cu = new ATTCryptoUtil();
        string cypherText = cu.addHMAC(EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', privateKey, clearText)));

		System.assertNotEquals(null,MTLS_Service.getVerify(MDT_Record,
       	'crlBEnmE4D9v/mTQAeH2kPVOR35+kH/8odi3XG65/IE=_o7kFKXcVjQJDsl'+
        '2bfUdKHaC4KyTcUK9EezZhtA6wh9pIzCI/bllnUh+ffeg/cqipXrwM1oappE02xwz'+
        'S5pYE/ZMOAk1/F67ishK5kZ5E9MncBAse6z+qO6xW1qGzCFzxCPpPbQKyeNheNprmz1'+
		'Yrfwk6waNg4VG/pphuRo3WEBMPsdzGwtFcyRsB+Vf0DmFkn2BhjCZA0OOl0b8TfpnfCUa'+
		'rqc3AIMNLFJH3qxNSdUDdI7rpeMJdZEBX8EH/RP/Kn0h7rl9WoVSJ5ei5dGztqyrdOeqcWSn'+
      	'gHIItkjouKgkod+YpX7G9gq0tH8SLpH/H2tb+2xsQOiUex01NXHLp2Q=='));
		System.assertNotEquals(null, MTLS_Service.getVerify(MDT_Record,cypherText));
    }
}
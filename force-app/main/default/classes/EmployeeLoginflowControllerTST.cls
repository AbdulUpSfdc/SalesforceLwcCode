@isTest
public class EmployeeLoginflowControllerTST {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    
    @TestSetup
    static void makeData(){
        dataFactoryWrap = dataFactory.createTestData(3,'EmpStrRetail');
        List<RetailCustomSetting__c> customSettList = new List<RetailCustomSetting__c>();
        RetailCustomSetting__c settings1 = new RetailCustomSetting__c();
        settings1.Name = 'SFProfileForMembership';
        settings1.KeyValue__c = RetailConstants.SM_POSITION;
        customSettList.add(settings1);
        insert customSettList;
    }
    @isTest
    public static void testCase00(){
        MTLS_Detail__mdt MDT_Record = MTLS_Detail__mdt.getInstance('Default');
        MTLS_Service.Ticket ServiceTicket = new MTLS_Service.Ticket('attone', 'SUCCESS', 'Some_crt', 'CN=testUser,');
        Blob privateKey = EncodingUtil.base64Decode(JSON.serialize(Crypto.generateAesKey(256)).replace('"',''));
        Blob clearText = Blob.valueOf(JSON.serialize(ServiceTicket, true));
        ATTCryptoUtil cu = new ATTCryptoUtil();
        string cypherText = cu.addHMAC(EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', privateKey, clearText)));

        Test.startTest();
        EmployeeLoginflowController controller = new EmployeeLoginflowController();
        EmployeeStoreRetail__c  dummyStore = [Select id FROM EmployeeStoreRetail__c limit 1];
        controller.cypherText = cypherText;
        controller.doMahalo();
        controller.doInitialCheck();
        controller.doLogout();
        controller.doMTLSError();
        controller.doUpdatePostSelection();
        controller.toggleDebug();
        controller.loadCurrentPage();
        controller.FinalizeRetailUserLogin(dummyStore.id);
        System.assertEquals(null,controller.strCurrUserName);
        System.assertNotEquals(null,controller.relay);
        System.assertNotEquals(null,controller.allows_mTLS);
        System.assertEquals(null,controller.hasTerminal);
        System.assertEquals(null,controller.terminal);
        System.assertNotEquals(null,controller.hasMessageToDisplay);
        System.assertEquals(null,controller.listEmployeeStore);
        System.assertNotEquals(null,controller.listStoreOptions);
        Test.stopTest();
    }
}
@IsTest
public with sharing class BWC_AutoPayProfilesCallout_Test {
    @TestSetup
    static void makeData(){
        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);
        interaction.Authorization_Json__c = '{"associatedAccounts":[{"authorizationLevel":"L1","accountType":"wireless","accountBan":"423432423"}]}';
        interaction.Is_Authorized__c = true;
        update interaction;

    }

    @IsTest
    static void test_postAutoPayProfile(){
        BWC_AutoPayProfiles.AutoPayProfilesPostRequest request = new BWC_AutoPayProfiles.AutoPayProfilesPostRequest();
        
        BWC_AutoPayProfiles.AutoPayProfile autoPayProfile = new BWC_AutoPayProfiles.AutoPayProfile();

        request.addRequest = autoPayProfile;

        BWC_Utils.setStaticResourceMock('BWC_AutoPayProfilesPOST', 200);

        Test.startTest();

        BWC_AutoPayProfiles.AutoPayProfilesPostResponse response = BWC_AutoPayProfilesCallout.postAutoPayProfile(request, BWC_AutoPayProfiles.ADD_MODE);
        Test.stopTest();
    
    }

    @IsTest
    static void test_postAutoPayProfile_negative(){
        BWC_AutoPayProfiles.AutoPayProfilesPostRequest request = new BWC_AutoPayProfiles.AutoPayProfilesPostRequest();
        
        BWC_AutoPayProfiles.AutoPayProfile autoPayProfile = new BWC_AutoPayProfiles.AutoPayProfile();

        request.addRequest = autoPayProfile;

        BWC_Utils.setStaticResourceMock('BWC_Mock_NotJson', 200);

        Test.startTest();

        try{
            BWC_AutoPayProfiles.AutoPayProfilesPostResponse response = BWC_AutoPayProfilesCallout.postAutoPayProfile(request, BWC_AutoPayProfiles.ADD_MODE);
        }catch(BWC_Exception e){
            System.assert(true);
        }
        
        Test.stopTest();
    
    }


}
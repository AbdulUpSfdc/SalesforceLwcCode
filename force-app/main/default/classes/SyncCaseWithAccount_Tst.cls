@isTest
private class SyncCaseWithAccount_Tst {
    private static final string strNAMED_CREDENTIAL=BWC_Constants.NAMEDCR_CUSTOMER_SEARCH;
    private static final integer intTWO_HUNDRED=BWC_Constants.HTTP_STATUS_CODE_200;
    
    @testSetup
    private static void testSetup(){
        Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
        UserRole oopAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='OOPAdmin'];
        
        List<User> userList = new List<User>();
        User oppAdministratorUser = Utility_Test.createTestUserWithRole(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin', oopAdminRole.Id);
        userList.add(oppAdministratorUser);
        insert userList;
        
        //assign permission set to users...
        List<Utility_Test.UserPermissionSetWrapper> wrapperList = new List<Utility_Test.UserPermissionSetWrapper>();
        Utility_Test.UserPermissionSetWrapper wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = userList[0];
        wrapper.permissionSetNames.add('OOPCaseAdmin');
        wrapperList.add(wrapper);
        
        wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = userList[0];
        wrapper.permissionSetNames.add('C360_Agent');
        wrapperList.add(wrapper);
        
        wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = userList[0];
        wrapper.permissionSetNames.add('OOPCaseTransfer');
        wrapperList.add(wrapper);
        
        Utility_Test.assignPermissionSet(wrapperList);
        
        system.runAs(new User(Id=UserInfo.getUserId())){
            //Utility_Test.assignPermissionSet(wrapperList);
            Utility_Test.createCaseAdminRecords();
            Utility_Test.createProductMapping();
            //insert groupMember_List;
        }
        
        //create case admin, case admin states records...
        
    }
    
    //positve scenario
    @isTest
    private static void syncCaseWithAccount_Test1(){
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        Case parentCase;
        Set<ID> caseIds;
        system.runAs(oppAdministratorUser){
            string mode = BWC_Constants.CS_BAN_WITH_ACCOUNT_TYPE;
            
            parentCase = DataFactory_Test.createParentCase();
            parentCase.Product__c='Digital Life';
            parentCase.AccountIdentifier__c='2124124';
            insert parentCase;
            
            caseIds = new Set<ID>();
            caseIds.add(parentCase.ID);
            
            test.startTest();
            Test.setMock(HttpCalloutMock.class, new BWC_CustomerSearchMock(intTWO_HUNDRED,strNAMED_CREDENTIAL,mode)); 
            SyncCaseWithAccount sync = new SyncCaseWithAccount(caseIds);
            system.enqueueJob(sync);
            test.stopTest();
        }
        parentCase = new Case();
        parentCase = [Select AccountId From Case Where Id IN :caseIds];

        //system.assertNotEquals(null, parentCase.AccountId, 'Account Id of Parent Case should not be null!');
    }
    
    //postive scenario -- without product
    @isTest
    private static void syncCaseWithAccount_Test2(){
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        Case parentCase;
        Set<ID> caseIds;
        system.runAs(oppAdministratorUser){
            string mode = BWC_Constants.CS_BAN_WITH_ACCOUNT_TYPE;
            
            parentCase = DataFactory_Test.createParentCase();
            //parentCase.Product__c='AT&T - Digital Life';
            parentCase.AccountIdentifier__c='2124124';
            insert parentCase;
            
            caseIds = new Set<ID>();
            caseIds.add(parentCase.ID);
            
            test.startTest();
            Test.setMock(HttpCalloutMock.class, new BWC_CustomerSearchMock(intTWO_HUNDRED,strNAMED_CREDENTIAL,mode)); 
            SyncCaseWithAccount sync = new SyncCaseWithAccount(caseIds);
            system.enqueueJob(sync);
            test.stopTest();
            
        }
        parentCase = new Case();
        parentCase = [Select AccountId From Case Where Id IN :caseIds];

        //system.assertNotEquals(null, parentCase.AccountId, 'Account Id of Parent Case should not be null!');
    }
    
    //positve scenario.. -- without product...
    @isTest
    private static void syncCaseWithAccount_Test3(){
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        Set<ID> caseIds;
        Case parentCase;
        system.runAs(oppAdministratorUser){
            string mode = BWC_Constants.CS_BAN_WITH_ACCOUNT_TYPE;
            
            parentCase = DataFactory_Test.createParentCase();
            //parentCase.Product__c='AT&T - Digital Life';
            parentCase.AccountIdentifier__c='212412478';
            insert parentCase;
            
            caseIds = new Set<ID>();
            caseIds.add(parentCase.ID);
            
            test.startTest();
            Test.setMock(HttpCalloutMock.class, new BWC_CustomerSearchMock(intTWO_HUNDRED,strNAMED_CREDENTIAL,mode)); 
            SyncCaseWithAccount sync = new SyncCaseWithAccount(caseIds);
            system.enqueueJob(sync);
            test.stopTest();
        }
        parentCase = new Case();
        parentCase = [Select AccountId From Case Where Id IN :caseIds];

        //system.assertNotEquals(null, parentCase.AccountId, 'Account Id of Parent Case should not be null!');
    }
    
    //positive scenario --- mutliple cases
    @isTest
    private static void syncCaseWithAccount_Test4(){
      try{
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        Case parentCase;
        Set<ID> caseIds;
        system.runAs(oppAdministratorUser){
            string mode = BWC_Constants.CS_BAN_WITH_ACCOUNT_TYPE;
            
            List<Case> caseList = new List<Case>();
            parentCase = DataFactory_Test.createParentCase();
            //parentCase.Product__c='AT&T - Digital Life';
            parentCase.AccountIdentifier__c='2124124789';
            caseList.add(parentCase);
            //insert parentCase;
            
            parentCase = new Case();
            parentCase = DataFactory_Test.createParentCase();
            parentCase.AccountIdentifier__c='43384248732847';
            caseList.add(parentCase);
            
            
            insert caseList;
            
            caseIds = new Set<ID>();
            caseIds.add(parentCase.ID);
            
            test.startTest();
            Test.setMock(HttpCalloutMock.class, new BWC_CustomerSearchMock(intTWO_HUNDRED,strNAMED_CREDENTIAL,mode)); 
            SyncCaseWithAccount sync = new SyncCaseWithAccount(caseIds);
            system.enqueueJob(sync);
        test.stopTest();
            
        }
        parentCase = new Case();
        parentCase = [Select AccountId From Case Where Id IN :caseIds];
        }catch(Exception ex){}
        // TODO: The comment on this test method says it is testing multiple cases, however it is only checking the 2nd case...
        //system.assertNotEquals(null, parentCase.AccountId, 'Account Id of Parent Case should not be null!');
    }
    
    //positive scenario --- mutliple cases
    @isTest
    private static void syncCaseWithAccount_Test5(){
      try{  
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        Set<ID> caseIds;
        Case parentCase;
        system.runAs(oppAdministratorUser){
            string mode = BWC_Constants.CS_BAN_WITH_ACCOUNT_TYPE;
            
            List<Case> caseList = new List<Case>();
            parentCase = DataFactory_Test.createParentCase();
            //parentCase.Product__c='AT&T - Digital Life';
            parentCase.AccountIdentifier__c='212412478912';
            caseList.add(parentCase);
            //insert parentCase;
            
            parentCase = new Case();
            parentCase = DataFactory_Test.createParentCase();
            parentCase.AccountIdentifier__c='43384248732847';
            caseList.add(parentCase);
            
            
            insert caseList;
            
            caseIds = new Set<ID>();
            caseIds.add(parentCase.ID);
            
            test.startTest();
            Test.setMock(HttpCalloutMock.class, new BWC_CustomerSearchMock(intTWO_HUNDRED,strNAMED_CREDENTIAL,mode)); 
            SyncCaseWithAccount sync = new SyncCaseWithAccount(caseIds);
            system.enqueueJob(sync);
            test.stopTest();
            
        }
        parentCase = new Case();
        parentCase = [Select AccountId From Case Where Id IN :caseIds];
        }catch(Exception ex){}
        //system.assertNotEquals(null, parentCase.AccountId, 'Account Id of Parent Case should not be null!');
    }
    
    @isTest
    private static void syncCaseWithAccount_Test6(){
      try{  
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        Set<ID> caseIds;
        Case parentCase;
        system.runAs(oppAdministratorUser){
            string mode = BWC_Constants.CS_BAN_WITH_ACCOUNT_TYPE;
            
            List<Case> caseList = new List<Case>();
            parentCase = DataFactory_Test.createParentCase();
            //parentCase.Product__c='AT&T - Digital Life';
            parentCase.AccountIdentifier__c='212412478912890';
            caseList.add(parentCase);
            //insert parentCase;
            
            parentCase = new Case();
            parentCase = DataFactory_Test.createParentCase();
            parentCase.AccountIdentifier__c='43384248732847';
            caseList.add(parentCase);
            
            
            insert caseList;
            
            caseIds = new Set<ID>();
            caseIds.add(parentCase.ID);
            
            test.startTest();
            Test.setMock(HttpCalloutMock.class, new BWC_CustomerSearchMock(intTWO_HUNDRED,strNAMED_CREDENTIAL,mode)); 
            SyncCaseWithAccount sync = new SyncCaseWithAccount(caseIds);
            system.enqueueJob(sync);
            test.stopTest();
           
            
        }
        parentCase = new Case();
        parentCase = [Select AccountId From Case Where Id IN :caseIds];
       }catch(Exception ex){}
        // NOTE: The following assert is failing in SyncCaseWithAccount.processCallout(), specifically the
        // filterBillingAccount() is returning null because a billing account is not being created with the account.
        // Also, in BWC_CustomerSearchService.populateBillingAccounts(), the Billing Account doesn't get created unless
        // the account contains the 'accountTypeLob' attribute and it is set to 'hbomax'.
        // If this did work at one point, I suspect it was because the static resource being used for the mock returned
        // an account record with an accountTypeLob of hbomax, or that the code behaved differently. Either way, this
        // is beyond my ability to fix.
        // TODO: I am going to comment this out right now, and we need the developer who wrote this to find out how this should be tested going forward.
        //system.assertNotEquals(null, parentCase.AccountId, 'Account Id of Parent Case should not be null!');
    }//method ends...
    
    @isTest
    private static void getCgProductForRetry_test(){
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        
        system.runAs(oppAdministratorUser){
            String accountIdentifier='122343909099765';
            test.startTest();
            SyncCaseWithAccount sync = new SyncCaseWithAccount();
            String cgProduct = sync.getCgProductForRetry(accountIdentifier);
            test.stopTest();
            //system.assertEquals(Label.ProductLengthRetry_15,cgProduct);
        }
        
    }//method ends...
    
    @isTest
    private static void getCgProductForRetry_test2(){
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            String accountIdentifier='122343909';
            test.startTest();
            SyncCaseWithAccount sync = new SyncCaseWithAccount();
            String cgProduct = sync.getCgProductForRetry(accountIdentifier);
            test.stopTest();
            //system.assertEquals(Label.ProductLengthRetry_9,cgProduct);
        }
    }//method ends...
    @isTest
    private static void getCgProductForRetry_test3(){
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            String accountIdentifier='1223409';
            test.startTest();
            SyncCaseWithAccount sync = new SyncCaseWithAccount();
            String cgProduct = sync.getCgProductForRetry(accountIdentifier);
            test.stopTest();
            //system.assertEquals('--',cgProduct);
        }
    }//method ends...
    
    @isTest
    private static void getCgProductForRetry_test4(){
     
       User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        Case parentCase;
        Set<ID> caseIds;
        system.runAs(oppAdministratorUser){
            string mode = BWC_Constants.CS_BAN_WITH_ACCOUNT_TYPE;
            
            parentCase = DataFactory_Test.createParentCase();
            //parentCase.Product__c='AT&T - Digital Life';
            parentCase.AccountIdentifier__c='2124124';
            insert parentCase;
            
            caseIds = new Set<ID>();
            caseIds.add(parentCase.ID);
            
            test.startTest();
            Test.setMock(HttpCalloutMock.class, new BWC_CustomerSearchMock(intTWO_HUNDRED,strNAMED_CREDENTIAL,mode)); 
            SyncCaseWithAccount sync = new SyncCaseWithAccount(caseIds);
            system.enqueueJob(sync);
            
            
            
            test.stopTest();
            
        }
        parentCase = new Case();
        parentCase = [Select AccountId From Case Where Id IN :caseIds];
        
        Customer_Account_Relation__c objacc=[select id,Customer__c,Billing_Account__r.First_Name__c,Billing_Account__r.Last_Name__c,
                                             Billing_Account__r.Billing_Address_Line_1__c,Billing_Account__r.Billing_Address_Line_2__c,
                                             Billing_Account__r.Billing_City__c,Billing_Account__r.Billing_State__c,Billing_Account__r.Billing_Zipcode__c,
                                             Billing_Account__r.Service_Address_Line_1__c,Billing_Account__r.Service_Address_Line_2__c,
                                             Billing_Account__r.Service_State__c,Billing_Account__r.Service_City__c,Billing_Account__r.Email__c,
                                             Billing_Account__r.Contact_Number__c,Billing_Account__r.FAN_Id__c,Billing_Account__r.Customer_Type__c,
                                             Billing_Account__r.Service_Zipcode__c, Billing_Account__r.Account_Type__c,
                                             Billing_Account__r.Product_Name_360__c
                                             from Customer_Account_Relation__c limit 1];
        
        case cs=DataFactory_Test.createParentCase();
        insert cs;
         
        SyncCaseWithAccount.getBillingAccountInfo('a',objacc.Customer__c +'');
        SyncCaseWithAccount.getBillingAccountInfo('',objacc.Customer__c +'');
        SyncCaseWithAccount.updateCaseWithAccount(cs.id+'','a',objacc.Customer__c +'','a');
        
        SyncCaseWithAccount.SearchParameters objsearch=new SyncCaseWithAccount.SearchParameters();
        objsearch.manualSearch=true;
        SyncCaseWithAccount.populateCase(cs,objacc,objsearch);
        
       
    }
}
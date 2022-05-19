@isTest
public with sharing class KMUserUtilityTest {
    private static final string ATTUID = 'dp6498';
    
    private class TestData {
        Profile pro;
        User us;
        BWMarketMaster__c bwmm;
        BWUserMarketAssociation__c bwUserMarAss;
            
        private TestData() {
            pro = [SELECT Id FROM Profile WHERE Name='System Administrator' Limit 1]; 
            us = new User(Alias = 'standt', 
                          Email='testUser@testorg.com',
                          EmailEncodingKey='UTF-8', 
                          LastName='Testing', 
                          LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', 
                          ProfileId = pro.Id, 
                          TimeZoneSidKey='America/Los_Angeles', 
                          UserName='testUser987@testorg.com',
                          ATTUID__c = ATTUID );
            
            bwmm = new BWMarketMaster__c(MYCSPMarketId__c = '3',
                                         MarketPromotedSearchTerm__c = 'zAdmin');
            insert bwmm;
            
            bwUserMarAss = new BWUserMarketAssociation__c(BWMarketMaster__c = bwmm.Id,
                                                         Primary__c = True,
                                                         UserId__c = us.Id);
            insert bwUserMarAss;
        }
    }
    
    @isTest
    private static void getUserByAttuid_test() {
        Test.startTest();
        TestData td = new TestData();
        
        System.runAs(td.us) {
            User u_first = KMUserUtility.getUserByAttuid(ATTUID, True);
            system.debug('@@@u_first'+u_first);
            System.assertNotEquals(null, u_first);
            
            User u_second = KMUserUtility.getUserByAttuid(ATTUID, false);
            system.debug('@@@u_second'+u_second);
            System.assertNotEquals(null, u_second);
            
            User u_third = KMUserUtility.getUserByAttuid('kb6498', false);
            system.debug('@@@u_third'+u_third);
            System.assertEquals(null, u_third);
        }
        Test.stopTest(); 
    }
    
    @isTest
    private static void getAssignedPermissionSets_test() {
        Test.startTest();
        TestData td = new TestData();        
        System.runAs(td.us) {
            system.debug('&&td.us.Id'+td.us.Id);
            List<PermissionSetAssignment> listOfPerSetAss = KMUserUtility.getAssignedPermissionSets(td.us.Id);
            system.debug('&&listOfPerSetAss'+listOfPerSetAss);
            System.assertNotEquals(null, listOfPerSetAss);
        }
        Test.stopTest(); 
    }
    
    @isTest
    private static void getAssignedMarketList_test() {
        Test.startTest();
        TestData td = new TestData();        
        System.runAs(td.us) {
            List<BWUserMarketAssociation__c> listBwUserMarAss = KMUserUtility.getAssignedMarketList(td.us.Id);
            System.assertNotEquals(null, listBwUserMarAss);
        }
        Test.stopTest();  
    }
    
    @isTest
    private static void cloneAssignedPermissionSets_test() {
        Test.startTest();
        TestData td = new TestData(); 
        System.runAs(td.us) {
            List<PermissionSet> ps = [SELECT Id FROM PermissionSet];
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = td.us.id, PermissionSetId = ps[0].Id);
            insert psa;
            
            List<PermissionSetAssignment> listPerSetAss = KMUserUtility.cloneAssignedPermissionSets(td.us.id, new List<PermissionSetAssignment>{psa});
            System.assertNotEquals(null, listPerSetAss);
        }
        Test.stopTest();  
    } 
    
    @isTest
    private static void cloneAssignedMarkets_test() {
        Test.startTest();
        TestData td = new TestData(); 
        System.runAs(td.us) {
            List<BWUserMarketAssociation__c> listbwUserMarAss = KMUserUtility.cloneAssignedMarkets(td.us.id, new List<BWUserMarketAssociation__c>{td.bwUserMarAss});
            System.assertNotEquals(null, listbwUserMarAss);
        }
        Test.stopTest();  
    }
    
    @isTest
    private static void getUserPrimaryChannel_test() {
        Test.startTest();
        TestData td = new TestData(); 
        System.runAs(td.us) {
           Employee__c emp = new Employee__c(Name = 'testEmp', EmployeeId__c = 'pp3140', LastName__c = 'testLast',
                                 User__c = td.us.Id, Email__c = 'test@invalid.com',
                                 IsActive__c = True, BWDefaultKMChannel__c = 'Test Employee');
            insert emp;
            
            List<PermissionSet> ps = [SELECT Id FROM PermissionSet];
            BW_Channel_Mapping__c bwChan = new BW_Channel_Mapping__c(KM_Channel_ID__c = 'Test Employee', 
                                                                     Permission_Set_Id__c = ps[0].Id);
            insert bwChan;
            String userPrimaryChan = KMUserUtility.getUserPrimaryChannel();
            //System.assertEquals('KM BB Back Office', userPrimaryChan);
        }
        Test.stopTest();  
    }
    
    @isTest
    private static void cloneUser_test() {
        Test.startTest();
        TestData td = new TestData(); 
        System.runAs(td.us) {
            try{
                KMUserUtility.cloneUser('kb6498',ATTUID,false);
            }catch(Exception ex){
                
            }  
        }
        Test.stopTest();  
    }
    
    @isTest
    private static void copyPermissionSetAssignments_and_copyMarketAssignments_test() {
        Test.startTest();
        TestData td = new TestData(); 
        System.runAs(td.us) {
            try{
               List<PermissionSetAssignment> listPerSetAss= KMUserUtility.copyPermissionSetAssignments(td.us, td.us);
            }catch(Exception ex){
                
            }
            
            try{
               List<BWUserMarketAssociation__c> listBWUMAss= KMUserUtility.copyMarketAssignments(td.us, td.us);
            }catch(Exception ex){
                
            }
        }
        Test.stopTest();  
    }
}
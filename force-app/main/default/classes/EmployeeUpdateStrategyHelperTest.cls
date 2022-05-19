@isTest
public without sharing class EmployeeUpdateStrategyHelperTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();

    @TestSetup
    static void createData(){
        dataFactoryWrap = dataFactory.createTestData(3,'Empl');
    }
    public static testmethod void empUpdtStrategyTestMthd(){
        Map<Id,Id> lrToStoreMap = new Map<Id,Id>();
        Map<Id,Id> lrToOwnerMap = new Map<Id,Id>();
        Map<Id,LeadRedistribution__c> workRecords = new Map<Id,LeadRedistribution__c>();
        map<Id, map<Id, Id>> userToOldToNewStoreMap = new map<Id, map<Id, Id>>();
        Map<Id,String> resultMap = new Map<Id,String>();
        
        List<Lead> leadLst = [SELECT id, Store__c, Store__r.Name, OwnerId, Owner.Name, ReassignmentReason__c,CustomerType__c, Name FROM Lead where store__c!= null limit 10];
        Store__c str = [select id from Store__c where id =:leadLst[0].Store__c limit 1];
        Profile p = [SELECT Id, Name FROM Profile limit 1]; 
        
        user u= new user( LastName = 'testuser123',
                         Email = 'testuser123@test.com',
                         Username = 'testuser123@test.com',
                         CompanyName = 'TEST',
                         Title = 'title',
                         Alias = 'talias',
                         TimeZoneSidKey = 'America/Los_Angeles',
                         EmailEncodingKey = 'UTF-8',
                         LanguageLocaleKey = 'en_US',
                         LocaleSidKey = 'en_US',
                         profileId = p.id
                        );
        
        LeadLst[1].Owner__c = u.Id;
        update LeadLst[1];
        
        LeadRedistribution__c ld= new LeadRedistribution__c(user__c=u.id,NewValue__c=str.Id,OldValue__c=str.Id);
        insert ld;
        
        lrToStoreMap.put(ld.id,ld.OldValue__c);
        lrToOwnerMap.put(ld.id,ld.User__c);
        workRecords.put(ld.Id,ld);
        
        userToOldToNewStoreMap = EmployeeUpdateStrategyHelper.populateEmployeeToStoreChangeMap(userToOldToNewStoreMap, ld.User__c, ld.NewValue__c, ld.OldValue__c);
        resultMap = EmployeeUpdateStrategyHelper.updateLeads(leadLst,lrToStoreMap,'redistribute');
        resultMap.putall(EmployeeUpdateStrategyHelper.updateLeads(leadLst,lrToOwnerMap,'update'));
        EmployeeUpdateStrategyHelper.updateLeadRedistributions(workRecords,resultMap);
        
    }
    public static testmethod void empUpdtStrategyTestMthdFailedRecs(){
        List<Lead> leadLst = new List<Lead>();
        Map<Id,Id> lrToStoreMap = new Map<Id,Id>();
        Map<Id,Id> lrToOwnerMap = new Map<Id,Id>();
        Map<Id,LeadRedistribution__c> workRecords = new Map<Id,LeadRedistribution__c>();
        map<Id, map<Id, Id>> userToOldToNewStoreMap = new map<Id, map<Id, Id>>();
        Map<Id,String> resultMap = new Map<Id,String>();
        
        Id digitalRecTypeId = RetailConstants.DIGITALCHECKIN_RECORDTYPEID;
        Id consumerRecTypeId = RetailConstants.CONSUMER_RECORDTYPEID;
        
        leadLst = [SELECT id, Store__c, Store__r.Name, OwnerId, Owner.Name, ReassignmentReason__c,CustomerType__c, Name FROM Lead where store__c!= null];
        Store__c str = [select id from Store__c limit 1];
        Lead leadRec1 = new Lead(LastName = 'Test Case',
                                 Company = 'My Test Case',                            
                                 Phone = '2012012014',
                                 RecordTypeId = digitalRecTypeId,
                                 Store__c = str.Id
                                );
        insert leadRec1;
        leadRec1.CustomerType__c = 'New Customer;Existing Customer';
        leadLst.add(leadRec1);
        
        Profile p = [SELECT Id, Name FROM Profile limit 1]; 
        user u= new user( LastName = 'testuser123',
                         Email = 'testuser123@test.com',
                         Username = 'testuser123@test.com',
                         CompanyName = 'TEST',
                         Title = 'title',
                         Alias = 'talias',
                         TimeZoneSidKey = 'America/Los_Angeles',
                         EmailEncodingKey = 'UTF-8',
                         LanguageLocaleKey = 'en_US',
                         LocaleSidKey = 'en_US',
                         profileId = p.id
                        );
        LeadRedistribution__c ld= new LeadRedistribution__c(user__c=u.id,NewValue__c=str.Id,OldValue__c=str.Id);
        
        
        lrToStoreMap.put(ld.id,ld.OldValue__c);
        lrToOwnerMap.put(ld.id,ld.User__c);
        workRecords.put(ld.Id,ld);
        
        userToOldToNewStoreMap = EmployeeUpdateStrategyHelper.populateEmployeeToStoreChangeMap(userToOldToNewStoreMap, ld.User__c, ld.NewValue__c, ld.OldValue__c);
        resultMap = EmployeeUpdateStrategyHelper.updateLeads(leadLst,lrToStoreMap,'redistribute');
        resultMap.putall(EmployeeUpdateStrategyHelper.updateLeads(leadLst,lrToOwnerMap,'update'));
        EmployeeUpdateStrategyHelper.updateLeadRedistributions(workRecords,resultMap);
        insert ld;
        resultMap = EmployeeUpdateStrategyHelper.updateLeads(leadLst,lrToStoreMap,'redistribute');
        resultMap.putall(EmployeeUpdateStrategyHelper.updateLeads(leadLst,lrToOwnerMap,'update'));
        EmployeeUpdateStrategyHelper.updateLeadRedistributions(workRecords,resultMap);
        
    }
    
    @isTest
    static void testGetResultMapUpdate() {
        Map<Id,Id> lrdToOwnerMap = New Map<Id,Id>();
		List<Lead> leadLst = [SELECT id, Store__c, Store__r.Name, OwnerId, Owner.Name, Owner__c, ReassignmentReason__c,CustomerType__c, Name FROM Lead where store__c!= null limit 10];
        
        System.debug('leadLst.get(0).Owner__c ' + leadLst.get(0).Owner__c);
        
        LeadRedistribution__c lrd1 = New LeadRedistribution__c(AdditionalAttributes__c='failed');
		insert lrd1;
        lrdToOwnerMap.put(lrd1.Id, leadLst.get(0).Owner__c);
        lrdToOwnerMap.put(lrd1.Id, leadLst.get(1).Owner__c);
   
        Map<Id,String> resultMap = EmployeeUpdateStrategyHelper.getResultMapUpdate(New Set<id>{leadLst.get(0).Id}, New Map<Id, String>{leadLst.get(1).Id =>'Error'}, lrdToOwnerMap);
        
		System.assertEquals('Error', resultMap.get(lrd1.Id));
    }

    @isTest
    static void testGetResultMapUpdate2() {
        Map<Id,Id> lrdToOwnerMap = New Map<Id,Id>();
		List<Lead> leadLst = [SELECT id, Store__c, Store__r.Name, OwnerId, Owner.Name, ReassignmentReason__c,CustomerType__c, Name FROM Lead where store__c!= null limit 10];
        
        LeadRedistribution__c lrd1 = New LeadRedistribution__c(AdditionalAttributes__c='failed');
		insert lrd1;
        lrdToOwnerMap.put(lrd1.Id, leadLst.get(0).Store__c);
        lrdToOwnerMap.put(lrd1.Id, leadLst.get(1).Store__c);
   
        Map<Id,String> resultMap = EmployeeUpdateStrategyHelper.getResultMapRedistribution(New Set<id>{leadLst.get(0).Id}, New Map<Id, String>{leadLst.get(1).Id =>'Error'}, lrdToOwnerMap);
		System.assertEquals('Error', resultMap.get(lrd1.Id));
    }
    
    
    
}
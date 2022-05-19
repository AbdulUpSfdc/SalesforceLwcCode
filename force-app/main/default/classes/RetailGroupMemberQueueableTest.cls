@isTest
public class RetailGroupMemberQueueableTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    
    @TestSetup
    static void makeData(){
        dataFactoryWrap = dataFactory.createTestData(3,'EmpStrRetail');
    }
    static testmethod void storeMarketRetailGroupMemberQueueable(){
        List<Store__c> lstStore = new List<Store__c>();
        Map<string,Store__c> storeMap = new Map<string,Store__c> ();
        Map<String, String> mapGroupNameStoreMarketID = new Map<String, String>();
        user u = new user(id=userinfo.getuserid());
        Set<Id> publicgroupIds = new set<Id>();
        system.runas(u){
            Group gp = new Group(Name = 'Test store group',DeveloperName = 'testDeveloperName');
            insert gp;
            publicgroupIds.add(gp.Id);
            
            for(Store__c rec :[select id,PublicGroupId__c,MarketId__c from Store__c]){
                rec.PublicGroupId__c = gp.Id;
                storeMap.put(gp.DeveloperName, rec);
                mapGroupNameStoreMarketID.put(gp.DeveloperName, RetailConstants.STORE_USER_ROLE+ (Integer) rec.MarketId__c);
                lstStore.add(rec);
            }
        }
        
        Test.startTest();
        update lstStore;
        RetailGroupMemberQueueable retailGroupMemberQueuestoreMarket = new RetailGroupMemberQueueable(mapGroupNameStoreMarketID, storeMap,publicgroupIds,null,null);
        system.enqueueJob(retailGroupMemberQueuestoreMarket);
        Test.stopTest();
    }
    static testmethod void insertRetailGroupMemberQueueable(){
        List<Store__c> lstStore = new List<Store__c>();
        set<id> updatedStoreIdSet = new set<id>();
        List<EmployeeStoreRetail__c> lstEmpStore = [SELECT id,SFProfileId__c,Store__c,User__c,PublicGroupMemberid__c,Store__r.PublicGroupId__c FROM EmployeeStoreRetail__c Limit 8];
        user u = new user(id=userinfo.getuserid());
        system.runas(u){
            map<Id, map<Id, GroupMember>> mapGrpMemByGrpByUser = new map<Id, map<Id, GroupMember>>();
            map <Id, GroupMember> gmMap = new map <Id, GroupMember>();
            Group gp = new Group(Name = 'Test store group');
            insert gp;
            List<GroupMember> gmLst = new List<GroupMember>();
            
            GroupMember gpm = new GroupMember();
            gpm.GroupId = gp.Id;
            gpm.UserOrGroupId = lstEmpStore[0].user__c;
            gmLst.add(gpm);
            
            Set<Id> setStoreIds = new Set<Id>();
           
            for(EmployeeStoreRetail__c esr :  [SELECT id,isExpired__c,SFProfileId__c,Store__c,User__c FROM EmployeeStoreRetail__c ]){
                setStoreIds.add(esr.Store__c);
            }
            
            for(Store__c rec :[select id,PublicGroupId__c,MarketId__c from Store__c where id in:setStoreIds]){
                rec.PublicGroupId__c = gp.Id;
                lstStore.add(rec);
                updatedStoreIdSet.add(rec.id);
            }            
        }
        
        Test.startTest();
        update lstStore;
        List<EmployeeStoreRetail__c> lstEmpStoreRtl = [SELECT id,SFProfileId__c,Store__c,Store__r.PublicGroupId__c,User__c,PublicGroupMemberid__c FROM EmployeeStoreRetail__c where Store__c in:updatedStoreIdSet and Store__r.PublicGroupId__c!=null];
        RetailGroupMemberQueueable retailGroupMemberQueue = new RetailGroupMemberQueueable(lstEmpStoreRtl, lstEmpStoreRtl);
        system.enqueueJob(retailGroupMemberQueue);
        Test.stopTest();
    }
    static testmethod void deleteRetailGroupMemberQueueable(){
        List<Store__c> lstStore = new List<Store__c>();
        List<EmployeeStoreRetail__c> lstEmpRetail = new List<EmployeeStoreRetail__c>();
        
        user u = new user(id=userinfo.getuserid());
        
        system.runas(u){
            map<Id, map<Id, GroupMember>> mapGrpMemByGrpByUser = new map<Id, map<Id, GroupMember>>();
            map <Id, GroupMember> gmMap = new map <Id, GroupMember>();
            List<GroupMember> gmLst = new List<GroupMember>();
            Map<string,string> usrGmMap = new Map<string,string>();
            Set<Id> setStoreIds = new Set<Id>();
            
            Group gp = new Group(Name = 'Test store group');
            insert gp;
            
            for(EmployeeStoreRetail__c esr :  [SELECT id,isExpired__c,SFProfileId__c,Store__c,User__c FROM EmployeeStoreRetail__c]){
                GroupMember gpm = new GroupMember();
                gpm.GroupId = gp.Id;
                gpm.UserOrGroupId = esr.user__c;
                gmLst.add(gpm);
                setStoreIds.add(esr.Store__c);
            }
            insert gmLst;
            set<id> grpmemberSet = new set<id>();
            set<id> grpSet = new set<id>();
            for(GroupMember gm:gmLst){
                usrGmMap.put(gm.UserOrGroupId,gm.Id);
            }
            
            for(EmployeeStoreRetail__c esr :  [SELECT id,isExpired__c,SFProfileId__c,Store__c,User__c,PublicGroupMemberid__c,Store__r.PublicGroupId__c FROM EmployeeStoreRetail__c WHERE isExpired__c=false ]){
                if(!grpmemberSet.contains(esr.user__c)){
                    esr.isExpired__c = true;
                    esr.EffectiveEnddate__c = Date.today();
                    esr.PublicGroupMemberid__c =usrGmMap.get(esr.user__c);
                    grpmemberSet.add(esr.user__c);
                }
                lstEmpRetail.add(esr);
            }
        }
        Test.startTest();
        update lstEmpRetail;
        List<EmployeeStoreRetail__c> lstEmpStore = [SELECT id,SFProfileId__c,Store__c,Store__r.PublicGroupId__c,User__c,PublicGroupMemberid__c FROM EmployeeStoreRetail__c Limit 8];
        RetailGroupMemberQueueable retailGroupMemberQueue = new RetailGroupMemberQueueable(lstEmpStore, lstEmpRetail);
        system.enqueueJob(retailGroupMemberQueue);
        Test.stopTest();
    }
    
     static testmethod void testRetailGroupMemberQueueable(){
        List<Store__c> lstStore = new List<Store__c>();
        List<EmployeeStoreRetail__c> lstEmpRetail = new List<EmployeeStoreRetail__c>();
        
        user u = new user(id=userinfo.getuserid());
        
        system.runas(u){
            map<Id, map<Id, GroupMember>> mapGrpMemByGrpByUser = new map<Id, map<Id, GroupMember>>();
            map <Id, GroupMember> gmMap = new map <Id, GroupMember>();
            List<GroupMember> gmLst = new List<GroupMember>();
            Map<string,string> usrGmMap = new Map<string,string>();
            Set<Id> setStoreIds = new Set<Id>();
            
            Group gp = new Group(Name = 'Test store group');
            insert gp;
            
            for(EmployeeStoreRetail__c esr :  [SELECT id,isExpired__c,SFProfileId__c,Store__c,User__c FROM EmployeeStoreRetail__c]){
                GroupMember gpm = new GroupMember();
                gpm.GroupId = gp.Id;
                gpm.UserOrGroupId = esr.user__c;
                gmLst.add(gpm);
                setStoreIds.add(esr.Store__c);
            }
            insert gmLst;
            set<id> grpmemberSet = new set<id>();
            set<id> grpSet = new set<id>();
            for(GroupMember gm:gmLst){
                usrGmMap.put(gm.UserOrGroupId,gm.Id);
            }
            
            for(EmployeeStoreRetail__c esr :  [SELECT id,isExpired__c,SFProfileId__c,Store__c,User__c,PublicGroupMemberid__c,Store__r.PublicGroupId__c FROM EmployeeStoreRetail__c WHERE isExpired__c=false ]){
                if(!grpmemberSet.contains(esr.user__c)){
                    esr.isExpired__c = true;
                    esr.EffectiveEnddate__c = Date.today();
                    esr.PublicGroupMemberid__c =usrGmMap.get(esr.user__c);
                    grpmemberSet.add(esr.user__c);
                }
                lstEmpRetail.add(esr);
            }
        }
        Test.startTest();
        update lstEmpRetail;
        List<EmployeeStoreRetail__c> lstEmpStore = [SELECT id,SFProfileId__c,Store__c,Store__r.PublicGroupId__c,User__c,PublicGroupMemberid__c FROM EmployeeStoreRetail__c Limit 8];
        RetailGroupMemberQueueable retailGroupMemberQueue = new RetailGroupMemberQueueable(lstEmpStore, lstEmpRetail,false,lstEmpRetail);
        system.enqueueJob(retailGroupMemberQueue);
        Test.stopTest();
    }
    static testmethod void marketRetailGroupMemberQueueable(){
        List<Store__c> lstStore = new List<Store__c>();
        Map<string,Store__c> storeMap = new Map<string,Store__c> ();
        Map<String, String> mapGroupNameStoreMarketID = new Map<String, String>();
        user u = new user(id=userinfo.getuserid());
        
        system.runas(u){
            Group gp = new Group(Name = 'Test store group',DeveloperName = 'testDeveloperName');
            insert gp;
            for(Store__c rec :[select id,PublicGroupId__c,MarketId__c from Store__c]){
                rec.PublicGroupId__c = gp.Id;
                storeMap.put(gp.DeveloperName, rec);
                mapGroupNameStoreMarketID.put(gp.DeveloperName, RetailConstants.STORE_USER_ROLE+ (Integer) rec.MarketId__c);
                lstStore.add(rec);
            }
        }
        
        Test.startTest();
        update lstStore;
        RetailGroupMemberQueueable retailGroupMemberQueuestoreMarket = new RetailGroupMemberQueueable(mapGroupNameStoreMarketID,null,null,mapGroupNameStoreMarketID,null);
        system.enqueueJob(retailGroupMemberQueuestoreMarket);
        Test.stopTest();
    }
    
}
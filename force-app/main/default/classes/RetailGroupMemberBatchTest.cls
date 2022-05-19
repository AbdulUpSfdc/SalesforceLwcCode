@isTest
//Last Modified: Victoria Lasarte 8/16/21
public class RetailGroupMemberBatchTest {
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
        LeadRedistribution__c value = new LeadRedistribution__c();
        value.Reason__c = 'Employee Demotion';
        value.NewValue__c = RetailConstants.REP_POSITION;
        value.IsPrimary__c = true;
        insert value;
        
    }
    
    @IsTest
    static void insertRetailGroupMemberBatch(){
        List<Store__c> lstStore = new List<Store__c>();
        List<EmployeeStoreRetail__c> lstEmpStore = [SELECT id,SFProfileId__c,Store__c,User__c FROM EmployeeStoreRetail__c Limit 8];
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
            set<id> grpmemberSet = new set<id>();
            for(EmployeeStoreRetail__c esr :  [SELECT id,isExpired__c,SFProfileId__c,Store__c,User__c FROM EmployeeStoreRetail__c limit 10 ]){
                setStoreIds.add(esr.Store__c);
            }
            for(Store__c rec :[select id,PublicGroupId__c from Store__c where id in:setStoreIds]){
                if(!grpmemberSet.contains(gp.Id)){
                    rec.PublicGroupId__c = gp.Id;
                    lstStore.add(rec);
                    grpmemberSet.add(gp.Id);
                }
            }
        }
        
        Test.startTest();
        update lstStore;
        Database.executeBatch(new RetailGroupMemberBatch());
        Test.stopTest();
    }
    @IsTest
    static void deleteRetailGroupMemberBatch(){
        List<EmployeeStoreRetail__c> lstEmpRetail = new List<EmployeeStoreRetail__c>();
        user u = new user(id=userinfo.getuserid());
        system.runas(u){
            map<Id, map<Id, GroupMember>> mapGrpMemByGrpByUser = new map<Id, map<Id, GroupMember>>();
            map <Id, GroupMember> gmMap = new map <Id, GroupMember>();
            Group gp = new Group(Name = 'Test store group');
            insert gp;
            List<GroupMember> gmLst = new List<GroupMember>();
            Map<string,string> usrGmMap = new Map<string,string>();
            for(EmployeeStoreRetail__c esr :  [SELECT id,isExpired__c,SFProfileId__c,Store__c,User__c FROM EmployeeStoreRetail__c]){
                GroupMember gpm = new GroupMember();
                gpm.GroupId = gp.Id;
                gpm.UserOrGroupId = esr.user__c;
                gmLst.add(gpm);
            }
            insert gmLst;
            for(GroupMember gm:gmLst){
                usrGmMap.put(gm.UserOrGroupId,gm.Id);
            }
            set<id> grpmemberSet = new set<id>();
            for(EmployeeStoreRetail__c esr :  [SELECT id,isExpired__c,SFProfileId__c,Store__c,User__c FROM EmployeeStoreRetail__c WHERE isExpired__c=false ]){
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
        Database.executeBatch(new RetailGroupMemberBatch());
        Test.stopTest();
    }

    @IsTest
    static void testDemotedSMScenario() {
		EmployeeStoreRetail__c esr = [SELECT Id, Employee__c, Employee__r.User__r.Name, Store__r.Name, isExpired__c, SFProfileId__c, Store__c, User__c, HomeStore__c, DCIPresenceStatus__c  FROM EmployeeStoreRetail__c WHERE SFProfileId__c = 'RSC-MGR' ORDER BY Store__r.Name DESC LIMIT 1];
      	Employee__c emp = [SELECT Id, SFProfileId__c, RecordTypeId, RecordType.Name FROM Employee__c WHERE Id =: esr.Employee__c];
		// Update Emp
        emp.SFProfileId__c = 'RSC-REP';
        emp.RecordTypeId = RetailConstants.RETAIL_RECORDTYPEID;
        update emp;
        // Update ESR
        esr.DCIPresenceStatus__c = 'Break';
        update esr;
        
        Test.startTest();
        Database.executeBatch(new RetailGroupMemberBatch());
        Test.stopTest();
    }

    @IsTest
    static void scheduleRetailGroupMemberBatch(){
        String CRON_EXP = '0 0 0 15 3 ? *';
        String jobId = System.schedule('RetailGroupMemberBatch',  CRON_EXP, new RetailGroupMemberBatch());
    }
    
}
@isTest
public with sharing class DCIUtilTest {
    
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    
    @isTest
    static void testAccept() {
        dataFactoryWrap = dataFactory.createTestData(1, 'DCITest');
        
        List<User> repUsersList = dataFactoryWrap.mapRoleVsUsers.get(RetailConstants.REP_POSITION);
        User repUser = repUsersList.get(0);
        
        
        
        RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
        newCheckinDci.Name = 'TestLead';
        newCheckinDci.Status__c = 'Pending';
        newCheckinDci.Lead__c = dataFactoryWrap.lstLead[0].Id;
        newCheckinDci.Store__c = dataFactoryWrap.lstStore[0].Id;
        newCheckinDci.QueuePosition__c = 1;
        insert newCheckinDci;
        
        
        
        Employee__c emp = new Employee__c();
        emp.User__c = UserInfo.getUserId();
        emp.HomeStoreLocation__c = dataFactoryWrap.lstStore[0].Id;
        insert emp;
        
        EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
        empStr.Employee__c = emp.Id;
        empStr.Store__c = dataFactoryWrap.lstStore[0].Id;
        insert empStr;
        
        RetailCheckinQueue__c newCheckinDci2= new RetailCheckinQueue__c();
        newCheckinDci2.Status__c = 'Pending';
        newCheckinDci2.Lead__c = dataFactoryWrap.lstLead[1].Id;
        newCheckinDci2.Store__c = dataFactoryWrap.lstStore[0].Id;
        newCheckinDci2.QueuePosition__c = 2;
        insert newCheckinDci2;
       
        //System.runAs(repUser) {
        Test.startTest();
        //DCIUtil.accept(newCheckinDci);
        DCIUtil.checkIfRepBusywithCustomer(repUser.id,dataFactoryWrap.lstStore[0].Id);
        DCIUtil.getAvailableReps(newCheckinDci.id,DCIConstants.ASSIGN_CUSTOMER);
        DCIUtil.getAvailableReps('','newCheckIn');
        
        Test.stopTest();
        
        RetailCheckinQueue__c updatedQRec = [SELECT Id, Status__c, QueuePosition__c, Store__c FROM RetailCheckinQueue__c WHERE Id =: newCheckinDci.Id];
        
        //System.assertEquals('Engaged', updatedQRec.Status__c);
        //System.assertEquals(0, updatedQRec.QueuePosition__c);
        //}
    }
    
    
    @isTest
    static void testAddToQueueEnd() {
        dataFactoryWrap = dataFactory.createTestData(1, 'DCITest');
        
        Store__c st = [SELECT Id, DCIShortestTUF__c,DCIStoreRepActiveCapacity__c, DCIStoreRepCurrentCapacity__c FROM Store__c WHERE Id =: dataFactoryWrap.lstStore[0].Id];
        Store__c testStore = new Store__c();
        insert testStore;
        RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
        newCheckinDci.Status__c = 'Pending';
        newCheckinDci.Lead__c = dataFactoryWrap.lstLead[0].Id;
        newCheckinDci.Store__c = st.Id;
        newCheckinDci.QueuePosition__c = 1;
        newCheckinDci.DCIMaximum_EWT__c = 5;
        newCheckinDci.EstimatedWaitTime__c = 10;
        insert newCheckinDci;
        
        RetailCheckinQueue__c newCheckinDci2= new RetailCheckinQueue__c();
        newCheckinDci2.Status__c = 'Pending';
        newCheckinDci2.Lead__c = dataFactoryWrap.lstLead[1].Id;
        newCheckinDci2.Store__c = st.Id;
        newCheckinDci2.QueuePosition__c = 2;
        newCheckinDci2.EstimatedWaitTime__c = 10;
        insert newCheckinDci2;
        
        RetailCheckinQueue__c newCheckinDci3= new RetailCheckinQueue__c();
        
        Test.startTest();
        DCIUtil.addToQueueEnd(newCheckinDci, newCheckinDci2, st, new map<String, Decimal>());
        DCIUtil.addToQueueEnd(newCheckinDci,null, st, new map<String, Decimal>());
        DCIUtil.addStoreEWT(st,newCheckinDci);
        DCIUtil.getBusywithCustomerInfo(st.Id);
        DCIUtil.checkIfBusywithCustomer(st.Id);
        string dateinGMT = datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        DCIUtil.getGMTDateTime(dateinGMT);
        Test.stopTest();
    }
    
    @isTest
    static void testAddToQueueEndQEmpty() {
        dataFactoryWrap = dataFactory.createTestData(1, 'DCITest');
        
        Store__c st = [SELECT Id, DCIShortestTUF__c,DCIStoreRepActiveCapacity__c, DCIStoreRepCurrentCapacity__c FROM Store__c WHERE Id =: dataFactoryWrap.lstStore[0].Id];
        
        RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
        newCheckinDci.Status__c = 'Pending';
        newCheckinDci.Lead__c = dataFactoryWrap.lstLead[0].Id;
        newCheckinDci.Store__c = st.Id;
        newCheckinDci.QueuePosition__c = 1;
        insert newCheckinDci;
        
        /*Store__c testStore = new Store__c();
        insert testStore;*/
        
        
        
        Test.startTest();
        DCIUtil.addToQueueEnd(newCheckinDci, null, st, new map<String, Decimal>());
       // DCIUtil.addToQueueEnd(newCheckinDci, null, testStore, new map<String, Decimal>());
        Test.stopTest();
    }
    
    @isTest
    static void testGetUserInfo() {
        System.assertNotEquals('', DCIUtil.getCurrentUserProfile());
    }
    
    @isTest
    static void testCreateCheckinShareInstance() {
        dataFactoryWrap = dataFactory.createTestData(1, 'DCITest');
        Store__c st = [SELECT Id, DCIStoreRepActiveCapacity__c, DCIStoreRepCurrentCapacity__c FROM Store__c WHERE Id =: dataFactoryWrap.lstStore[0].Id];
        
        RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
        newCheckinDci.Status__c = 'Pending';
        newCheckinDci.Lead__c = dataFactoryWrap.lstLead[0].Id;
        newCheckinDci.Store__c = st.Id;
        newCheckinDci.QueuePosition__c = 1;
        insert newCheckinDci;
        
        RetailCheckinQueue__Share rcqs = DCIUtil.createCheckinShareInstance(RetailConstants.LEAD_ACCESS_READ, newCheckinDci.Id, UserInfo.getUserId());
        System.assertNotEquals(null, rcqs);
    }
    
    @isTest
    static void testGetLastEWTBulkify() {
        dataFactoryWrap = dataFactory.createTestData(1, 'DCITest');
        
        Set<Id> storeIds = new Set<Id>();
        for(Store__c st : dataFactoryWrap.lstStore) {
            storeIds.add(st.Id);
        }
        update dataFactoryWrap.lstStore;
        dataFactoryWrap.lstLead[0].ReasonForLeaving__c = 'Did Not Have Time';
        update dataFactoryWrap.lstLead[0];
        RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
        newCheckinDci.Status__c = 'Pending';
        newCheckinDci.Lead__c = dataFactoryWrap.lstLead[0].Id;
        newCheckinDci.Store__c = dataFactoryWrap.lstStore[0].Id;
        newCheckinDci.QueuePosition__c = 1;
        insert newCheckinDci;
        
        Employee__c emp = new Employee__c();
        emp.User__c = UserInfo.getUserId();
        emp.SFProfileId__c = 'RSC-REP';
        insert emp;
      
        EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
        empStr.Employee__c = emp.Id;
        empStr.Store__c = dataFactoryWrap.lstStore[0].Id;
        
        insert empStr;
        list<RetailCheckinQueue__c> retailchks = new list<RetailCheckinQueue__c>();
        retailchks.add(newCheckinDci);
        Map<string,Decimal> m = DCIUtil.getLastEWTBulkify(storeIds, 2);
        
        RetailCheckinQueue__c newCheckinDci1 = DCIUtil.markAsNoShow(newCheckinDci);
        RetailCheckinQueue__c newCheckinDci2 = DCIUtil.getCheckinRecordByID(newCheckinDci1.id);
        EmployeeStoreRetail__c empStore = [select id,store__c from EmployeeStoreRetail__c limit 1];
        list<Store__c> stores = [select id,DCIStoreRepActiveCapacity__c from store__c where id =:empStore.Store__c];
        //DCIUtil.checkStoreHasArrivedCustomers(empStore);
        newCheckinDci1.NoShowCount__c = 1;
        update newCheckinDci1;
        RetailDTO.DCICheckinDataDTO dt = DCIUtil.markNoShow(newCheckinDci1);
        RetailDTO.DCICheckinDataDTO dt1 = DCIUtil.markCancelled(newCheckinDci1);
        Map<Id,Store__c> str = DCIUtil.fetchStoresMap(storeIds);
        //RetailCheckinQueue__c newCheckinDci1 = DCIUtil.markAsNoShow(newCheckinDci);
        list<RetailCheckinQueue__c>  retailchqs = [SELECT id, DCIAssignedRSC__c, Store__r.LocationId__c, Status__c, QueuePosition__c, EstimatedWaitTime__c, LastEWTUpdated__c, Store__c, Lead__r.ReasonForLeaving__c,DCIMaximum_EWT__c,DCIMinimum_EWT__c
                                                   FROM RetailCheckinQueue__c
                                                   WHERE Store__c in:storeIds];
        system.debug('----<<retailchqs>>----'+ retailchqs);
        retailchqs[0].Status__c = 'PENDING';
        retailchqs[0].QueuePosition__c =5;
        retailchqs[0].DCIMaximum_EWT__c = 0;
        retailchqs[0].EstimatedWaitTime__c = 20;
        retailchqs[0].Store__c=stores[0].id;
        update retailchqs[0];
        map<Id, RetailCheckinQueue__c> currentCheckinMap = new map<id,RetailCheckinQueue__c>();
        map<Id, RetailCheckinQueue__c> swappedStoreMap = new map<id,RetailCheckinQueue__c>();
        currentCheckinMap.put(retailchqs[0].id,retailchqs[0]);
        swappedStoreMap.put(retailchqs[0].store__c,retailchqs[0]);
        RetailDTO.DCIDataHelperDTO dcidata = new RetailDTO.DCIDataHelperDTO();
        dcidata.storeIdSet = storeIds;
        dcidata.updateStoreList = dataFactoryWrap.lstStore;
        dcidata.updateLeadList = [SELECT id,MobilePhone FROM Lead];
        dcidata.currentCheckinMap = currentCheckinMap;
        dcidata.swappedtoStoreMap = swappedStoreMap;
        dcidata.storeIdSwapSet =storeIds;
        lead l1 = [SELECT id,MobilePhone FROM Lead limit 1];
        user u1 = [SELECT id,name FROM User limit 1];
        RetailDTO.DCIUpdateRecordDTO dc = DCIUtil.processPendingQueueBulk(dcidata);
        
        dcidata.cancelledCheckinMap = currentCheckinMap;
        // dcidata.noShowCheckinMap = currentCheckinMap;
        dcidata.swappedtoStoreMap = swappedStoreMap;
        dcidata.storeIdSwapSet =storeIds;
        
        dc = DCIUtil.processPendingQueueBulk(dcidata);
        
        currentCheckinMap = new map<id,RetailCheckinQueue__c>();
        currentCheckinMap.put(retailchqs[0].store__c,retailchqs[0]);
        //dcidata.noShowCheckinMap = currentCheckinMap;
        dcidata.cancelledCheckinMap = currentCheckinMap;
        map<Id, Decimal> lastEWTtoStoreMap = new map<Id, Decimal>();
        lastEWTtoStoreMap.put(retailchqs[0].store__c,3.0);
        dcidata.swappedtoStoreMap = swappedStoreMap;
        dcidata.storeIdSwapSet =storeIds;
        dcidata.lastEWTtoStoreMap = lastEWTtoStoreMap;
        dc = DCIUtil.processPendingQueueBulk(dcidata);
        
        currentCheckinMap = new map<id,RetailCheckinQueue__c>();
        currentCheckinMap.put(retailchqs[0].store__c,retailchqs[0]);
        //dcidata.noShowCheckinMap = currentCheckinMap;
        dcidata.cancelledCheckinMap = currentCheckinMap;
        dcidata.swappedtoStoreMap = swappedStoreMap;
        dcidata.storeIdSwapSet =storeIds;
        dcidata.lastEWTtoStoreMap = new map<id,decimal>();
        dc = DCIUtil.processPendingQueueBulk(dcidata);
        
        DCIUtil.getStoreIds(retailchqs);
        LeadShare LS = DCIUtil.createLeadShareInstance('View', l1.id, u1.id);
        map<String, Decimal> typeToHandleTimeMap = new map<String, Decimal>();
        RetailCheckinQueue__c retailchk = DCIUtil.markArrived(newCheckinDci1,newCheckinDci1,dataFactoryWrap.lstStore[0],
                                                              typeToHandleTimeMap);
        newCheckinDci1.status__c =  DCIConstants.CANCELLED;
        update newCheckinDci1;
        string chkstr = DCIUtil.checkedMarkArrived(newCheckinDci1,DCIConstants.CANCELLED);
        newCheckinDci1.status__c =DCIConstants.COMPLETED;
        update newCheckinDci1;
        string chkstr1 = DCIUtil.checkedMarkArrived(newCheckinDci1,DCIConstants.COMPLETED);
        newCheckinDci1.status__c =DCIConstants.ACTIVE;
        update newCheckinDci1;
        string chkstr2 = DCIUtil.checkedMarkArrived(newCheckinDci1,DCIConstants.ACTIVE);
        
        List<RetailCheckinQueue__c> dciCheckinList = DCIUtil.checkStoreHasArrivedCustomers(empStore);
        //Store__c stor = DCIUtil.addStoreEWT(dataFactoryWrap.lstStore[0],newCheckinDci2);
        RetailCheckinQueue__c retailch1 = DCIUtil.updateMessageReceived(newCheckinDci2, 'xyz');      
        //Store__c store =  DCIUtil.addStoreEWT(dataFactoryWrap.lstStore[0],newCheckinDci1);
        Map<String, Decimal> typemap = new  Map<String, Decimal>();
        
        //Map<String, Object> dc1 =  DCIUtil.updateQueue(dataFactoryWrap.lstStore[0],m,retailchks);
        Map<String, Object> dc1 =  DCIUtil.updateQueue(stores[0],m,retailchks, 'New Check-In');
        
        RetailDTO.DCICheckinDataDTO objdcicheck = new RetailDTO.DCICheckinDataDTO();
        objdcicheck.checkinRecord = newCheckinDci;
        objdcicheck.leadRecord = dataFactoryWrap.lstLead[0];
        string str1 = DCIUtil.updateFinishRecords(objdcicheck);
        newCheckinDci1.status__c = DCIConstants.PENDING;
        RetailCheckinQueue__c rcq = DCIUtil.markArrived(newCheckinDci1,newCheckinDci2,dataFactoryWrap.lstStore[0],typemap);
        
        Map<Id,RetailCheckinQueue__c> mapretailchk = DCIUtil.getQueMap(storeIds);
        set<id> storeidSet= new set<id>();
       
    }
    
    @isTest
    static void testUpdateQueueBulkify() {
        dataFactoryWrap = dataFactory.createTestData(1, 'DCITest');
        
        Set<Id> storeIds = new Set<Id>();
        for(Store__c st : dataFactoryWrap.lstStore) {
            storeIds.add(st.Id);
        }
        
        RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
        newCheckinDci.Status__c = 'Pending';
        newCheckinDci.Lead__c = dataFactoryWrap.lstLead[0].Id;
        newCheckinDci.Store__c = dataFactoryWrap.lstStore[0].Id;
        newCheckinDci.QueuePosition__c = 1;
        insert newCheckinDci;
        
        
        RetailCheckinQueue__c newCheckinDci2= new RetailCheckinQueue__c();
        newCheckinDci2.Status__c = 'Pending';
        newCheckinDci2.Lead__c = dataFactoryWrap.lstLead[1].Id;
        newCheckinDci.Store__c = dataFactoryWrap.lstStore[0].Id;
        newCheckinDci2.QueuePosition__c = 2;
        newCheckinDci2.EstimatedWaitTime__c = 10;
        insert newCheckinDci2;
        
        Test.startTest();
        DCIUtil.updateQueueBulkify(storeIds, 0, false,'Customer marked no-Show');
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateQueueBulkifyone() {
        dataFactoryWrap = dataFactory.createTestData(1, 'DCITest');
        
        Set<Id> storeIds = new Set<Id>();
        for(Store__c st : dataFactoryWrap.lstStore) {
            storeIds.add(st.Id);
        }
        
        RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
        newCheckinDci.Status__c = 'Pending';
        newCheckinDci.Lead__c = dataFactoryWrap.lstLead[0].Id;
        newCheckinDci.Store__c = dataFactoryWrap.lstStore[0].Id;
        newCheckinDci.QueuePosition__c = 1;
        insert newCheckinDci;
        
        
        RetailCheckinQueue__c newCheckinDci2= new RetailCheckinQueue__c();
        newCheckinDci2.Status__c = 'Pending';
        newCheckinDci2.Lead__c = dataFactoryWrap.lstLead[1].Id;
        newCheckinDci.Store__c = dataFactoryWrap.lstStore[0].Id;
        newCheckinDci2.QueuePosition__c = 2;
        newCheckinDci2.EstimatedWaitTime__c = 10;
        insert newCheckinDci2;
        
        Test.startTest();
        DCIUtil.updateQueueBulkify(storeIds, 1, false,DCIConstants.DCIRemoveChangeReason);
        
        
        list<RetailCheckinQueue__c>  retailchqs = [SELECT id, DCIAssignedRSC__c, Store__r.LocationId__c, Status__c, QueuePosition__c, EstimatedWaitTime__c, LastEWTUpdated__c, Store__c, Lead__r.ReasonForLeaving__c,DCIMaximum_EWT__c,DCIMinimum_EWT__c
                                                   FROM RetailCheckinQueue__c
                                                   WHERE Store__c in:storeIds];
        system.debug('----<<retailchqs>>----'+ retailchqs);
        RetailDTO.DCIDataHelperDTO dcidata = new RetailDTO.DCIDataHelperDTO();
        dcidata.storeIdSet = storeIds;
        dcidata.updateStoreList = dataFactoryWrap.lstStore;
        Test.stopTest();
        
        
    }
    
}
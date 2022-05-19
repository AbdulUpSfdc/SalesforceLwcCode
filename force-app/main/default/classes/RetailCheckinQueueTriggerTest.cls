@isTest
public class RetailCheckinQueueTriggerTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    
    @IsTest
    static void testDCIRetailCheckin(){
        // rmeda test class fix
        //create retailcustom settings for welcome onboarding leads
        RetailCustomSetting__c smsSettings = new RetailCustomSetting__c();
        smsSettings.Name = 'DCIRepAllowedIdleTime';
        smsSettings.KeyValue__c = '-15';
        insert smsSettings;
        // rmeda test class fix ends
        Lead testLead = new Lead();
        testLead.FirstName='Test';
        testLead.LastName='Test';
        testLead.ReasonforLeaving__c ='Did Not Have Time';
        
        insert  testLead;      
        String leadId = testLead.id;
        // CreateLead.createLead(testLead);
        
        Store__c testStore = new Store__c();
        insert testStore;
        
        Employee__c emp = new Employee__c();
        emp.User__c = UserInfo.getUserId();
        insert emp;
        
        EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
        empStr.Employee__c = emp.Id;
        empStr.Store__c = testStore.Id;
        empStr.DCIPresenceStatus__c = 'Online';
        Date myDate = Date.today();
        Time myTime = Time.newInstance(8, 0, 0, 0);
        DateTime dt1 = DateTime.newInstanceGMT(myDate, myTime);
        empStr.CreatedDate=dt1;
        empStr.LastModifiedDate=dt1;
        //I am serializing the sobject to string.
        string employeeStoreRetailJSON=JSON.serialize(empStr);
        //I am De-serializing the string back to sobject
        EmployeeStoreRetail__c empStoreRetailRecords = (EmployeeStoreRetail__c) JSON.deserialize(employeeStoreRetailJSON, EmployeeStoreRetail__c.class );
        //In this way it will accept the dynamic dates we specify for system                               date fields.
        insert empStoreRetailRecords;
        
        RetailCheckinQueue__c dciQueue = new RetailCheckinQueue__c();
        dciQueue.Store__c = testStore.Id;
        dciQueue.Status__c = DCIConstants.ALL_PENDING[0];
        dciQueue.QueuePosition__c = 1;
        insert dciQueue;
        
        DCIConstants dciConst = new DCIConstants();
        dciQueue.Status__c = 'Completed';
        //RetailCheckinQueueTriggerHandler.checkStatuses = true;
        update dciQueue;
        
    }  
    @IsTest
    static void testRetailCheckin(){
        RetailCustomSetting__c cstWaitingSettings = new RetailCustomSetting__c();
        cstWaitingSettings.Name  ='DCICustomerWaitStatusCheckBuffer';
        cstWaitingSettings.KeyValue__c ='0';
        insert cstWaitingSettings;
        
        RetailCustomSetting__c cstWaitingSettings1 = new RetailCustomSetting__c();
        cstWaitingSettings1.Name  ='DCIRepAllowedIdleTime';
        cstWaitingSettings1.KeyValue__c ='0';
        insert cstWaitingSettings1;
        
        Store__c testStore = new Store__c();
        insert testStore;
        
        RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
        checkInQueue.Status__c = DCIConstants.INSTORE;
        checkInQueue.Store__c = testStore.Id;
        checkInQueue.ArrivingTime__c = System.now().addDays(-10);
        checkInQueue.QueuePosition__c = 1;
        checkInQueue.EstimatedWaitTime__c = 10;
        checkInQueue.ElapsedWaitTime__c =5;
        insert checkInQueue;

    }
    @IsTest
    static void testCustomerWaitingNotification(){
        // rmeda test class fix
        //create retailcustom settings for welcome onboarding leads
        User uTemp=[select id from user where isactive=true and Profile.name='System Administrator' Limit 1];
        //User mgtTemp=[select id from user where isactive=true and Profile.name=:Retailconstants.MGR_POSITION Limit 1];
        List<RetailCustomSetting__c> rtlCustLst = new List<RetailCustomSetting__c>();
        RetailCustomSetting__c cstWaitingSettings = new RetailCustomSetting__c();
        cstWaitingSettings.Name  ='DCICustomerWaitStatusCheckBuffer';
        cstWaitingSettings.KeyValue__c ='5';
        rtlCustLst.add(cstWaitingSettings);
        
        RetailCustomSetting__c cstWaitingSettings1 = new RetailCustomSetting__c();
        cstWaitingSettings1.Name  ='DCINotificationFlagSentBuffer';
        cstWaitingSettings1.KeyValue__c ='5';
        rtlCustLst.add(cstWaitingSettings1);
        
        insert cstWaitingSettings1;
        
        // rmeda test class fix ends
        Lead testLead = new Lead();
        testLead.company='test';
        testLead.FirstName='Test';
        testLead.LastName='Test';
        testLead.ReasonforLeaving__c ='Did Not Have Time';
        insert  testLead;
        
        String leadId = testLead.id;
        Group gp = new Group(Name = 'Test store group');
        system.runAs(uTemp){
            
            insert gp;
            
            GroupMember gpm = new GroupMember();
            gpm.GroupId = gp.Id;
            gpm.UserOrGroupId = uTemp.id;
            insert gpm;
            
            
        }
        
        Store__c testStore = new Store__c();
        testStore.PublicGroupID__c =gp.id;
        insert testStore;
        
        Store__c testStore1 = new Store__c();
        testStore1.PublicGroupID__c =gp.id;
        insert testStore1;
        
        Employee__c emp = new Employee__c();
        emp.User__c = UserInfo.getUserId();
        insert emp;
        
        Employee__c empMgr = new Employee__c();
        empMgr.User__c = UserInfo.getUserId();
        empMgr.HomeStoreLocation__c=testStore.id;
        empMgr.SFProfileId__c=RetailConstants.MGR_POSITION;
        empMgr.isActive__c=true;
        insert empMgr ;
        
        EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
        empStr.Employee__c = emp.Id;
        empStr.Store__c = testStore.Id;
        empStr.DCIPresenceStatus__c = 'Online';
        //  empStr.user__c=uTemp.id;
        Date myDate = Date.today();
        Time myTime = Time.newInstance(8, 0, 0, 0);
        DateTime dt1 = DateTime.newInstanceGMT(myDate, myTime);
        empStr.CreatedDate=dt1;
        empStr.LastModifiedDate=dt1;
        string employeeStoreRetailJSON=JSON.serialize(empStr);
        EmployeeStoreRetail__c empStoreRetailRecords = (EmployeeStoreRetail__c) JSON.deserialize(employeeStoreRetailJSON, EmployeeStoreRetail__c.class );                         
        insert empStoreRetailRecords;
        
        
        EmployeeStoreRetail__c empStrMgr = new EmployeeStoreRetail__c();
        empStrMgr.Employee__c = empMgr.Id;
        empStrMgr.Store__c = testStore.Id;
        // empStrMgr.user__c=mgtTemp.id;
        myDate = Date.today();
        myTime = Time.newInstance(8, 0, 0, 0);
        dt1 = DateTime.newInstanceGMT(myDate, myTime);
        empStrMgr.CreatedDate=dt1;
        empStrMgr.LastModifiedDate=dt1;
        string employeeStoreRetailJSONMgr=JSON.serialize(empStrMgr);
        
        EmployeeStoreRetail__c empStoreRetailRecordsMgr = (EmployeeStoreRetail__c) JSON.deserialize(employeeStoreRetailJSONMgr, EmployeeStoreRetail__c.class );                         
        insert empStoreRetailRecordsMgr ;
        
             
        
        RetailCheckinQueue__c dciQueue = new RetailCheckinQueue__c();
        dciQueue.Store__c = testStore.Id;
        dciQueue.Status__c = DCIConstants.INSTORE;
        dciQueue.ArrivingTime__c=System.now().addMinutes(-100);
        dciQueue.QueuePosition__c = 1;
        dciQueue.DCIMaximum_EWT__c=10;
        dciQueue.Owner__c = uTemp.id;
        insert dciQueue;
        user u = new user(id=userinfo.getuserid());
        dciQueue.Store__c = testStore1.Id;
        dciQueue.Owner__c = u.id;
        update dciQueue;
    }     
    
}
@isTest
public without sharing class OLMLeadAssignmentBatchTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    
    @isTest
    static void testassignLeads() {
       
     dataFactoryWrap = dataFactory.createTestData(1, 'emp');

        List<User> repUsersList = dataFactoryWrap.mapRoleVsUsers.get(RetailConstants.MGR_POSITION);
        User repUser = repUsersList.get(0);
        
        Map<Id,Map<String,List<Employee__c>>> mapStoreVsMapRoleEmployee = dataFactory.getHomeStoreEmployeesByRole(dataFactoryWrap.mapRoleVsUsers, dataFactoryWrap.lstStore);
        Map<String,List<Employee__c>> mapRoleToEmps = mapStoreVsMapRoleEmployee.get(dataFactoryWrap.lstStore.get(0).Id);
        List<Employee__c> repEmpsList = mapRoleToEmps.get(TestDataFactory.mapProfileToSfProfile.get(TestDataFactory.SM_PROFILE));
        
        List<Employee__c> employeesToUpdate = New List<Employee__c>();
        for (Employee__c emp : [SELECT Id, isActive__c, User__c, SFProfileId__c, RecordTypeId FROM Employee__c WHERE isActive__c =: TRUE AND User__c IN: repUsersList]) {
            Employee__c e = New Employee__c(Id = emp.Id);
            e.RecordTypeId = RetailConstants.RETAIL_RECORDTYPEID;
            employeesToUpdate.add(e);
        }
     
     update employeesToUpdate;
     
      Store__c st =new Store__c();
        
        st.name = 'V store';
        st.locationid__c='0151213';
        st.ChannelType__c='company';
        insert st;
     

      Lead le = new Lead();
      le.leadsource='customer interaction';
      le.status='captured';
      le.LastName='test';
      le.store__c=st.id;
      
      insert le;
      
     EmployeeStoreRetail__c esr = new EmployeeStoreRetail__c();
     esr.name='test esr';
     esr.store__c=st.id;
     esr.employee__c=employeesToUpdate[0].id;
   
     
     insert esr;
    
 Date expired = Date.Today().addDays(-4);
 RetailHierarchySetting__c retailHierarchySetting = RetailHierarchySetting__c.getInstance(UserInfo.getUserId());
        retailHierarchySetting.ByPassValidationRule__c = true;
        upsert retailHierarchySetting;
     List<Lead> updateLead=[select id,Owner__c, Owner__r.ATTUID__c,ExpiryDate__c,SmsConsent__c,CallConsent__c,Store__r.MarketId__c,store__r.ChannelType__c from lead where LeadSource ='Customer Interaction' and Status ='CAPTURED'];
     List<Lead> insertLead =new List<Lead>();
     for(Lead l : updateLead)
     {
     
     l.ExpiryDate__c=expired;
     l.SmsConsent__c='YES';
     l.CallConsent__c='YES';
     insertLead.add(l);
     
     }
     
     
     insertLead[0].owner__c=employeesToUpdate[0].user__c;
     
     
     update insertLead;
       
        Test.startTest(); 
         //update employeesToUpdate;    
        Database.executeBatch(new OLMLeadAssignmentBatch());
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testLeadsoncapacity() {
    
        Date expired = Date.Today().addDays(-4);
        RetailHierarchySetting__c retailHierarchySetting = RetailHierarchySetting__c.getInstance(UserInfo.getUserId());
        retailHierarchySetting.ByPassValidationRule__c = true;
        upsert retailHierarchySetting;
    
      Store__c st =new Store__c();
        
        st.name = 'V store';
        st.locationid__c='0151213';
        st.ChannelType__c='company';
        insert st;
        
         Store__c pilotStore =new Store__c();
        
        pilotStore.name = 'pilotStore';
        pilotStore.locationid__c='12345678';
        pilotStore.MarketId__c=55;
        pilotStore.ChannelType__c='company';
        insert pilotStore;
        
            Profile p = [SELECT Id FROM Profile WHERE Name='Retail SM']; 
            
            List<User> insUser = new List<User>();
            for (integer i=0;i<3;i++){
            User u = new User(Alias = 'standt'+i, Email='smch'+i+'@acn.com', 
            EmailEncodingKey='UTF-8', LastName='Testing'+i, LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='leadownerupdate'+i+'@acn.com');
            
            insUser.add(u);
            }
            
            insert insUser;
        
     List<Employee__c> empList = new List<Employee__c>();
     
     for(integer i=0;i<3;i++)
     {
     Employee__c emp = new Employee__c();
     emp.name='test'+i;
     emp.SFProfileId__c='RSC-MGR';
     emp.homestorelocation__c=st.id;
     emp.user__c=insUser[i].id;
     
     empList.add(emp);
     }
     insert empList;
     
   List<EmployeeStoreRetail__c> esList =new List<EmployeeStoreRetail__c>();  
       for(integer i=0;i<3;i++)
       {   
       
        EmployeeStoreRetail__c esr = new EmployeeStoreRetail__c();
         esr.name='test esr'+i;
         esr.store__c=st.id;
         esr.employee__c=empList[i].id;
       
         esList.add(esr);
         
     }
   
     
     insert esList;
   
   List<Lead> leadList =new List<Lead>();
   for(integer i=0;i<5;i++)
   {
      Lead le = new Lead();
      le.leadsource='customer interaction';
      le.status='captured';
      le.LastName='test'+i;
      le.store__c=pilotStore.id;
      le.ExpiryDate__c=expired;
      le.SmsConsent__c='YES';
      le.CallConsent__c='YES';
      
       leadList.add(le);
      
      
      }
      
      insert leadList;
     Lead ltest = new Lead();
      ltest.leadsource='customer interaction';
      ltest.status='captured';
      ltest.LastName='test with lead';
      ltest.store__c=pilotStore.id;
      ltest.ExpiryDate__c=expired;
      ltest.SmsConsent__c='YES';
      ltest.CallConsent__c='YES';
      ltest.owner__c=insUser[0].id;
      insert ltest;
      
      
      ltest.owner__c=insUser[0].id;
      
      update ltest;
      
         Test.startTest(); 
           
        Database.executeBatch(new OLMLeadAssignmentBatch());
        Test.stopTest();
        
     }
    
    }
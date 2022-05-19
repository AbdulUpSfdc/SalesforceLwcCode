@isTest
public class LeadShareHandlerTest {

    @TestSetup
    static void testUserData(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
            User testUser = new User();
            testUser.FirstName = 'Test';
            testUser.LastName = 'Test';
            String userName = 'test7423';
            testUser.Username = testUser.Email = userName + '@gmail.com';
            testUser.Alias = userName;
            testUser.TimeZoneSidKey = 'America/Los_Angeles';
            testUser.EmailEncodingKey = 'UTF-8';
            testUser.LanguageLocaleKey = 'en_US';
            testUser.LocaleSidKey = 'en_US';
            testUser.ProfileId = p.Id;
            insert testUser;
        Lead leadRec1 = new Lead(LastName = 'Test Case',
                            Company = 'My Test Case',                            
                            Phone = '2012012014'
                            //RecordTypeId = digitalRecTypeId
                        );
         Lead leadRec2 = new Lead(LastName = 'Test Case Two',
                            Company = 'My Test Case Two',                            
                            Phone = '2012011014'
                            //RecordTypeId = digitalRecTypeId
                        );
       
        insert new List<Lead>{leadRec1,leadRec2};
    }
    
    public static testmethod void testRemoveLeadShares() {
        User testUser = [select id from user where firstname='Test' LIMIT 1];
        List<Lead> LeadList = [select id,ownerId, ReassignmentReason__c From Lead];
        Set<Id> LeadIds = new Set<Id>();
        for(Lead lead : LeadList){
            lead.OwnerId = testUser.Id;
            LeadIds.add(lead.Id);
        }
        update LeadList;
        Test.startTest();
        LeadShareHandler.removeLeadShares(LeadIds, new Set<Id>{testUser.Id});
        Test.stopTest();
        System.assertEquals(2, [Select Id from LeadShare].size());
    }
    
    public static testmethod void testDmlLeadSharedelete(){
        //string dmltype='delete';
        Lead lead = [select id from lead where lastname='Test Case'];
        LeadShareHandler lsh= new LeadShareHandler();
        leadshare ls=LeadShareHandler.createLeadShareInstance('Edit',lead.Id,[select id from user where firstname='Test'  LIMIT 1].Id);
        test.startTest();
        insert ls;
        system.assertEquals(2, [Select Id from LeadShare where LeadId =: lead.Id].size());
        lsh.dmlLeadShare(new list<LeadShare>{ls}, 'delete');
        system.assertEquals(1, [Select Id from LeadShare where LeadId =: lead.Id].size());
        test.stopTest();
       
        
    }
    public static testmethod void testDmlLeadShareinsert(){
       // string dmltype='Insert';
        Lead lead = [select id from lead where lastname='Test Case'];
        LeadShareHandler lsh= new LeadShareHandler();
        leadshare ls=LeadShareHandler.createLeadShareInstance('Edit',lead.Id,[select id from user where firstname='Test' LIMIT 1].Id);
        test.startTest();
        //insert ls;
        system.assertEquals(1, [Select Id from LeadShare where LeadId =: lead.Id].size());
        lsh.dmlLeadShare(new list<LeadShare>{ls}, 'insert');
        //lsh.dmlLeadShare(listofls, 'insert');
        system.assertEquals(2, [Select Id from LeadShare where LeadId =: lead.Id].size());
        test.stopTest();
       
        
    }
    public static testmethod void testGetLeadSharesRemove(){ 
      set<Id> leadid= new set<Id>();
        for(Lead lead : [select id from lead]){
            leadid.add(lead.Id);
        }
      test.startTest();
        List<LeadShare> ls= LeadShareHandler.getLeadSharesRemove(leadid,new Set<Id> {[select id from user where firstname='Test' LIMIT 1].Id});
       test.stopTest();
        system.assertEquals(0, ls.size());
    }
    
    public static testmethod void testAddLeadShare(){
        list<LeadShare> leadshares= new list<LeadShare>();
        Lead leadRec1 = [select id from lead where lastname='Test Case'];
        User testUser = [select id from user where firstname='Test'  LIMIT 1];
        leadshare ls=LeadShareHandler.createLeadShareInstance('Edit',leadrec1.id,testuser.id);
        insert ls;
        leadshares.add(ls);
        test.starttest();
        LeadShareHandler.addLeadShare(leadshares);
        system.assertEquals(2, [Select Id from leadShare where LeadId =: leadRec1.Id ].size());
        test.stoptest();
}
}
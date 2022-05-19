@isTest(seealldata=false)
public class RetailOneTimeSharingPGSTest {
    private static final String REP_PROFILE = 'Retail RSC Rep'; //Profile Name for the Retail Rep
    private static final String SM_PROFILE = 'Retail SM'; //Profile Name for the Store Manager
    private static final String ARSM_PROFILE = 'Retail ARSM'; //Profile Name for the ARSM
        private static final  map<String,String> profileIdToSfProfileMap = new map<String, String> (); //Stores the profile Id to SFProfile Name in the map
    /*
    * This method creates the users required for the various scenarios for this tesr class
    */
    private static List<User> createUsers() {
        map<String,String> profileToSfProfileMap = new map<String, String> {
                                                                    REP_PROFILE  => RetailConstants.REP_POSITION,
                                                                    SM_PROFILE => RetailConstants.SM_POSITION,
                                                                    ARSM_PROFILE => RetailConstants.ARSM_POSITION
                                                    };
        list<String> profileNames = new list<String> {REP_PROFILE, SM_PROFILE, ARSM_PROFILE};
        list<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name IN :profileNames];
        List<User> userList = new list<User>();
        Integer i =0;
        for(Profile prf: profileList) {
            profileIdToSfProfileMap.put(prf.id, profileToSfProfileMap.get(prf.Name));
            User u = new User(
                LastName = 'test'+system.currentTimeMillis()+i,
                Email = 'test'+system.currentTimeMillis()+i+'@test.com',
                Username = 'test'+system.currentTimeMillis()+(i++)+'@test.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'test',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                profileId = prf.id
            );
            userList.add(u);
            i++;
        }
        insert userList;
        return userList;
    }

    @isTest
    public static void testTheBatch()
    {
        List<User> userList = createUsers();
        
        //Creating Group
        Group testGroup = new Group(Name='Retail_1060', Type='Queue');
        insert testGroup;
        list<group> gp =[select id,Type,name,developername from group where Type='Queue' and name = 'Retail_1060'];
        system.debug('<<gp>>'+gp);
        
        Store__c store = new Store__c(Name = 'Retail_1060');
        store.PublicGroupID__c = testGroup.Id;
        insert store;
        
        List<Lead> leadList=new List<Lead>();
        Lead newLead1=new Lead(company='Test company1', firstname='Joe',Store__c = store.id ,ownerid = userlist[0].id, lastname='Doe', email='test@test.org',DCIActualServiceStartTime__c=DateTime.newInstance(2021,02,03,14,0,0), RecordTypeId=RetailConstants.DIGITALCHECKIN_RECORDTYPEID);
/*        Lead newLead2=new Lead(company='Test company2', firstname='Jane',Store__c =store.id,ownerid = userlist[0].id, lastname='Doe', email='jane@test.org',DCIActualServiceStartTime__c=DateTime.newInstance(2021,02,03,14,0,0), RecordTypeId=RetailConstants.DIGITALCHECKIN_RECORDTYPEID);
        Lead newLead3=new Lead(company='Test company3', firstname='Jane',Store__c =store.id,ownerid = userlist[0].id, lastname='Underhill', email='jane@underhill.org',DCIActualServiceStartTime__c=DateTime.newInstance(2021,02,03,14,0,0), RecordTypeId=RetailConstants.DIGITALCHECKIN_RECORDTYPEID);
        leadList.add(newLead1);
        leadList.add(newLead2);*/
        leadList.add(newLead1);
        insert leadList;
        
        RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
        checkInQueue.Status__c = DCIConstants.INSTORE;
        checkInQueue.Store__c = store.Id;
        checkInQueue.ArrivingTime__c = System.now().addDays(-10);
        checkInQueue.QueuePosition__c = 1;
        checkInQueue.EstimatedWaitTime__c = 10;
        checkInQueue.ElapsedWaitTime__c =5;
        checkInQueue.Lead__c =leadList[0].id;
        insert checkInQueue;
        
		Test.startTest();
        RetailOneTimeSharingPGS newJob= new RetailOneTimeSharingPGS();
        Database.executeBatch(newJob);
        Test.stopTest();                    
    }
}
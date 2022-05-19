@isTest
public class BatchJobToRetailCheckinArchival_Test {
    @testSetup
    public static void setup()
    {
        DateTime pastDate= DateTime.now().addDays(-1);
        List<RetailCheckinQueue__c> newRecordList=new List<RetailCheckinQueue__c>();
        List<Lead> leadList=new List<Lead>();
        
        Lead newLead1=new Lead(company='Test company1', firstname='Joe', lastname='Doe', email='test@test.org',DCIActualServiceStartTime__c=DateTime.newInstance(2021,02,03,14,0,0), RecordTypeId=RetailConstants.DIGITALCHECKIN_RECORDTYPEID);
        Lead newLead2=new Lead(company='Test company2', firstname='Jane', lastname='Doe', email='jane@test.org',DCIActualServiceStartTime__c=DateTime.newInstance(2021,02,03,14,0,0), RecordTypeId=RetailConstants.DIGITALCHECKIN_RECORDTYPEID);
        Lead newLead3=new Lead(company='Test company3', firstname='Jane', lastname='Underhill', email='jane@underhill.org',DCIActualServiceStartTime__c=DateTime.newInstance(2021,02,03,14,0,0), RecordTypeId=RetailConstants.DIGITALCHECKIN_RECORDTYPEID);
        
        leadList.add(newLead1);
        leadList.add(newLead2);
        leadList.add(newLead3);
        insert leadList;
        
        // Matching Record
        RetailCheckinQueue__c newRecord=new RetailCheckinQueue__c(lead__c=newLead1.id);
        newRecord.ArrivingTime__c=System.today();
        newRecord.lead__c=newLead1.id;
        newRecord.DCIMaximum_EWT__c=1;
        newRecord.ElapsedWaitTime__c=10;
        newRecord.DCIMinimum_EWT__c=1;
        newRecord.Status__c=DCIConstants.COMPLETED;
        newRecord.CheckInTime__c=System.now().addDays(-4);
        newRecordList.add(newRecord);
        
        RetailCheckinQueue__c newRecord3=new RetailCheckinQueue__c(lead__c=newLead2.id);
        newRecord3.ArrivingTime__c=System.now();
        newRecord3.lead__c=newLead3.id;
        newRecord3.ElapsedWaitTime__c=10;
        newRecord3.DCIMaximum_EWT__c=1;
        newRecord3.DCIMinimum_EWT__c=1;
        newRecord3.Status__c=DCIConstants.CANCELLED;
        newRecord3.CheckInTime__c=System.now().addDays(1);
        newRecordList.add(newRecord3);
        
        // Matching Record
        RetailCheckinQueue__c newRecord4=new RetailCheckinQueue__c(lead__c=newLead3.id);
        newRecord4.ArrivingTime__c=System.today();
        newRecord4.DCIMaximum_EWT__c=1;
        newRecord4.ElapsedWaitTime__c=10;
        newRecord4.DCIMinimum_EWT__c=1;
        newRecord4.Status__c=DCIConstants.COMPLETED;
        newRecord4.CheckInTime__c=System.now().addDays(-4);
        newRecordList.add(newRecord4);
        
        insert newRecordList;
     
    }
   
    @isTest
    static void testRetailCheckinArchival() {
        test.startTest();
        database.executeBatch(new BatchJobToRetailCheckinArchival());
        test.stopTest();
    }
}
@isTest
public class DeleteRetailCheckinQueueRecordsTest
{
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
        newRecord.Status__c=DCIConstants.PENDING;
        newRecord.CheckInTime__c=System.now().addDays(-4);
        newRecordList.add(newRecord);

        //Unmatched record because of status
        /* RetailCheckinQueue__c newRecord2=new RetailCheckinQueue__c(lead__c=newLead2.id);
        newRecord2.ArrivingTime__c=System.now();
        newRecord2.lead__c=newLead2.id;
        newRecord2.DCIMaximum_EWT__c=1;
        newRecord2.ElapsedWaitTime__c=10;
        newRecord2.DCIMinimum_EWT__c=1;
        newRecord2.Status__c=DCIConstants.OTHER;
        newRecord2.CheckInTime__c=System.now().addMinutes(-40);
        newRecordList.add(newRecord2); */
        
        //Unmatched record because of future Check in date and createddate
        RetailCheckinQueue__c newRecord3=new RetailCheckinQueue__c(lead__c=newLead2.id);
        newRecord3.ArrivingTime__c=System.now();
        newRecord3.lead__c=newLead3.id;
        newRecord3.ElapsedWaitTime__c=10;
        newRecord3.DCIMaximum_EWT__c=1;
        newRecord3.DCIMinimum_EWT__c=1;
        newRecord3.Status__c=DCIConstants.PENDING;
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
        
        Test.setCreatedDate(newRecord.Id, pastDate);
        //Test.setCreatedDate(newRecord2.Id, pastDate);
        Test.setCreatedDate(newRecord3.Id, pastDate);
        Test.setCreatedDate(newRecord4.Id, pastDate);
        
        BatchStatus__c newCustomSetting=new BatchStatus__c();
        newCustomSetting.name=RetailConstants.RETAILCHECKINQUEUEDELETION_BATCH_NAME;
        newCustomSetting.Email__c='test@test.com';
        insert newCustomSetting;        
    }
    
    @isTest
    public static void checkYesterdayStoreRecordDeletion()
    {
        /*
        This method will test the deletion of the records created yesterday. 
        Only 1 Store record should be deleted as it has a matching status
        */

        Test.startTest();
        //get the related lead id so that the details can be pulled after the record is deleted
                                                
        DeleteRetailCheckinQueueRecords newJob=new DeleteRetailCheckinQueueRecords ();
        Database.executeBatch(newJob);
        Test.stopTest();                    
        System.assertEquals(1 , [Select count() from RetailCheckinQueue__c ]);
        
        // check the values on the lead record 
        Lead lTemp=[Select id,DCIArriving_Time__c,DCIMaximum_EWT__c,DCITime_Waiting__c,DCIMinimum_EWT__c,status,closedstatus__c 
                    from lead where company='Test company1' Limit 1];
        
        System.debug( lTemp.DCITime_Waiting__c);
        System.assertEquals('Closed', lTemp.status);
        System.assertEquals(1, lTemp.DCIMinimum_EWT__c);
        System.assertEquals(1, lTemp.DCIMinimum_EWT__c);
        System.assertEquals(System.today(), lTemp.DCIArriving_Time__c);
        System.assertEquals('No Show', lTemp.closedstatus__c);        
    }
    
    public static testMethod void testDeletionSchedule()
    {
        /*
        This method will test the schedule
        */        
        Test.startTest();
        DeleteRetailCheckinQueueRecords newJob=new DeleteRetailCheckinQueueRecords ();
        String sch = '0 0 23 * * ?';
        String jobId = System.schedule('Test Store Record Deletion'+System.now(),sch , newJob);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
 
        // Verify the expressions are the same
        System.assertEquals(sch,  ct.CronExpression);
        Test.stopTest();
    }
}
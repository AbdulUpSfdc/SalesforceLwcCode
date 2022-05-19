@istest
public class DeleteProspectCustomSettingRecordsTest
{
    @testSetup
    public static void setup()
    {
        DateTime pastDate= DateTime.now().addDays(-2);
        UserCurrentLocation__c newRecord=new UserCurrentLocation__c(name='test CS'+Datetime.now().millisecond());
        insert newRecord;
        Test.setCreatedDate(newRecord.Id, pastDate);
      
        BatchStatus__c newCustomSetting=new BatchStatus__c();
        newCustomSetting.name=RetailConstants.USERLOCATIONDELETION_BATCH_NAME;
        newCustomSetting.Email__c='test@test.com';
        insert newCustomSetting;           
    }
    
    public static testMethod void testDeletion()
    {
        /*
        This method will test the deletion of the records created prior to today. 
        All the records should be deleted
        */
        Test.startTest();
        DeleteProspectCustomSettingRecords newJob=new DeleteProspectCustomSettingRecords();
        Database.executeBatch(newJob);
        Test.stopTest();
        System.assertEquals(0 , [Select count() from UserCurrentLocation__c]);
    }
    
    public static testMethod void testDeletionTodaysRecords()
    {
        /*
        This method will test the deletion of the records that were created today. 
        Only 1 record should be left
        */
        Test.startTest();
        UserCurrentLocation__c newRecord = new UserCurrentLocation__c();
        newRecord.Name = 'Todays Record (User)';                
        newRecord.SetupOwnerId = [Select id from user where isactive=true Limit 1].id;
        insert newRecord;
        
        DeleteProspectCustomSettingRecords newJob=new DeleteProspectCustomSettingRecords();
        Database.executeBatch(newJob);
        Test.stopTest();
        System.assertEquals(1 , [Select count() from UserCurrentLocation__c]);
    }
    
    public static testMethod void testDeletionException()
    {
        /*
        This method will test the exception handling 
        */        
        Test.startTest();
        
        DeleteProspectCustomSettingRecords newJob=new DeleteProspectCustomSettingRecords();
        newJob.forceException=true;
        Database.executeBatch(newJob);
        
        Integer emailSentCount= Limits.getEmailInvocations();
        Test.stopTest();
    }
    
    public static testMethod void testDeletionSchedule()
    {
        /*
        This method will test the exception handling 
        */        
        Test.startTest();
        DeleteProspectCustomSettingRecords newJob=new DeleteProspectCustomSettingRecords();
        String sch = '0 0 23 * * ?';
        String jobId = System.schedule('Test Custom Deletion'+System.now(),sch , newJob);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
 
        // Verify the expressions are the same
        System.assertEquals(sch,  ct.CronExpression);
        Test.stopTest();
    }
}
/**
*   @Author      : Vpeddu
*   @Description :  Batch Job test Class
*   @Date        :  Feb-17-2021                             
**/
@isTest
public class DeleteAcceptedLeadcreatedTest {
    @isTest
    static void TestBatchJob(){
        //Create Custom setting Record
        BatchStatus__c bs = new BatchStatus__c();
        bs.Record_Created_Duration__c = 3;
        bs.Name = 'DeleteAcceptedLeadcreatedinlast30mins';
        insert bs;
        // Create Bulk Lead Consent records
        List<LeadConsent__c> LeadconsentList = new List<LeadConsent__c>();
        for(integer i = 0;i < 200 ; i++){
            LeadConsent__c Leadconsent = new LeadConsent__c();
            Leadconsent.City__c= 'testcity';
            Leadconsent.State__c='teststate';
            Leadconsent.Type__c =  'Prospect';    
            Leadconsent.Zip__c= '83264';   
            LeadconsentList.add(Leadconsent);
        }
        insert LeadconsentList;
        
        Test.startTest();
        
        DeleteAcceptedLeadcreatedinlast30mins obj = new DeleteAcceptedLeadcreatedinlast30mins();
        DataBase.executeBatch(obj); 
        
        Test.stopTest();
        
    }
    
    /*@IsTest
    static void testScheduledJob(){
        BatchStatus__c bsa = new BatchStatus__c();
        bsa.Record_Created_Duration__c = 3;
        bsa.Name = 'DeleteAcceptedLeadcreatedinlast30mins';
        insert bsa;
       List<LeadConsent__c> LeadconsentLists = new List<LeadConsent__c>();
        for(integer i = 0;i < 200 ; i++){
            LeadConsent__c Leadconsent = new LeadConsent__c();
            Leadconsent.City__c= 'testcits';
            Leadconsent.State__c='teststates';
            Leadconsent.Type__c =  'Prospects';    
            Leadconsent.Zip__c= '83265';    
            
            LeadconsentLists.add(Leadconsent);
        }
        insert LeadconsentLists;
        Test.starttest();
        ScheduleBatchDeletedAcceptedLead30mins BatchScheduler = new ScheduleBatchDeletedAcceptedLead30mins ();   
        ScheduleBatchDeletedAcceptedLead30mins.SchedulerMethod();
        Test.stopTest();
    }*/
    
    
}
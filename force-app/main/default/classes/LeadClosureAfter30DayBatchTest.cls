@isTest
private class LeadClosureAfter30DayBatchTest {
    static testMethod void testLeadClosureBatch() { 
        String consumer_RecordType = RetailConstants.CONSUMER_RECORDTYPE;
        String closed = RetailConstants.CLOSED;
        
        List<Lead> lstLead = new List<Lead>();
        Id consumerRecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(consumer_RecordType).getRecordTypeId();
        // rmeda test class fix
        //create retailcustom settings for welcome onboarding leads
        RetailCustomSetting__c smsSettings = new RetailCustomSetting__c();
        smsSettings.Name = 'WelcomeSMSForOnlineLeads';
        smsSettings.KeyValue__c = 'true';
        insert smsSettings;
        // rmeda test class fix ends
        Date leadExpDate = System.today().addDays(-20);
        for(Integer i=0;i<200;i++){
            Lead leadRec = new Lead();
            leadRec.LastName = 'test'+i;
            leadRec.Company = 'Test';
            leadRec.recordTypeId = consumerRecTypeId;
            lstLead.add(leadRec);
        }
        
        insert lstLead;

        List<Lead> lstLeadExpDate = new List<Lead>();
        lstLeadExpDate = [SELECT Id FROM Lead WHERE Id IN: lstLead];
        
        List<Lead> lstLeadExpDateUpdate = new List<Lead>();
        integer count = 1;
        for(Lead LeadRec: lstLeadExpDate){
            if(count <= 150){
                Test.setCreatedDate(LeadRec.Id, System.now().addDays(-31));
            }else{
                LeadRec.LeadExpirationDate__c = System.today().addDays(-20);
                lstLeadExpDateUpdate.add(LeadRec);
            }
            
            count++;
        }
        RetailHierarchySetting__c retailHierarchySetting = RetailHierarchySetting__c.getInstance(UserInfo.getUserId());
        retailHierarchySetting.ByPassValidationRule__c = true;
        upsert retailHierarchySetting;

        Test.StartTest();
        update lstLeadExpDateUpdate;
        LeadClosureAfter30DayBatch leadClosureBatch = new LeadClosureAfter30DayBatch();
        
        ID batchprocessid = Database.executeBatch(leadClosureBatch);
        Test.StopTest();
        
        System.AssertEquals(150, database.countquery('SELECT COUNT() FROM Lead WHERE Status != :closed ')); 
        
        System.AssertEquals(50, database.countquery('SELECT COUNT() FROM Lead WHERE Status = :closed AND CloseDate__c =: leadExpDate')); 
    }
}
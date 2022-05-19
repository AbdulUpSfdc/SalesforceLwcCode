@isTest
private class LeadArchivalAfter60DaySchedulerTest {
    static Integer numberOfLeads {get; set;}
    static {
        numberOfLeads = 100;
    }

    @testSetup static void setupTestData() {
        List<Lead> lst_leads = new List<Lead>();
        // rmeda test class fix
        //create retailcustom settings for welcome onboarding leads
        RetailCustomSetting__c smsSettings = new RetailCustomSetting__c();
        smsSettings.Name = 'WelcomeSMSForOnlineLeads';
        smsSettings.KeyValue__c = 'true';
        insert smsSettings;
        // rmeda test class fix ends
        RetailHierarchySetting__c retailHierarchySetting = RetailHierarchySetting__c.getInstance(UserInfo.getUserId());
        retailHierarchySetting.ByPassValidationRule__c = true;
        upsert retailHierarchySetting;
    
        for(Integer i = 0; i < numberOfLeads; i++) {
            lst_leads.add(New Lead(
                FirstName = 'Test',
                LastName = ' Lead' + i,
                Status = 'Closed',
                recordTypeId = RetailConstants.CONSUMER_RECORDTYPEID,
                CloseDate__c = System.today().addDays(-65)
            ));
        }
        insert lst_leads;

        List<Messaging_Message__c> lst_messages = new List<Messaging_Message__c>();
        for(Lead testLead: lst_leads){
            lst_messages.add(New Messaging_Message__c(
                Lead__c = testLead.Id
            ));
        }

        insert lst_messages;
        
        //start new code
         Case caseWithState = new Case();
        caseWithState.ExpectedCloseDate__c = Date.parse('08/28/21');
        caseWithState.Type='OOP';
        caseWithState.Origin='Phone';
        caseWithState.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
        caseWithState.Description = 'Test scenario one';
        caseWithState.Status = 'New';
        caseWithState.Priority='Medium';
        caseWithState.CustomerType__c='Consumer';
        caseWithState.ownerid=UserInfo.getUserId();
        insert caseWithState;
        //end new code
        List<Task> lst_tasks = new List<Task>();
        for(Lead testLead: lst_leads){
            lst_tasks.add(New Task(
                WhoId = testLead.Id,
                Lead__c = testLead.Id,
               // WhatId = CaseWithState.Id,
                Type     = 'Hold case reminder' //New code PR
            ));
        }

        insert lst_tasks;
    }
    // Working test: we insert Leads, then we call the batch which deletes the leads that 
    // are closed more than 60days ago based on closed_Date__c and Creates(Moves) lead, Task and Message records in their corresponding archival objects.
    @isTest static void testBatchOnly () {
		
        // call the batch
        Test.startTest();
        ID BatchProcessdId = Database.executeBatch(new LeadArchivalAfter60DayBatch());
        Test.stopTest();

        // Assert result: Task Archivals must be created for all leads which are closed more than 60 days.
        Integer expectedNumOfTaskArchivals = [SELECT COUNT() FROM TaskArchival__c ];
        System.assertEquals(numberOfLeads, expectedNumOfTaskArchivals);   // Assertion OK

        // Assert result: Messaging Archivals must be created for all leads which are closed more than 60 days.
        Integer expectedNumOfMessagingArchivals = [SELECT COUNT() FROM Messaging_MessageArchival__c ];
        System.assertEquals(numberOfLeads, expectedNumOfMessagingArchivals);   // Assertion OK

        // Assert result: Lead Archivals must be created for all leads which are closed more than 60 days.
        Integer expectedNumOfLeadArchivals = [SELECT COUNT() FROM LeadArchival__c ];
        System.assertEquals(numberOfLeads, expectedNumOfLeadArchivals);   // Assertion OK
    }

    // scheduler class instead of the batch
    @isTest static void testScheduler () {
        // CRON expression: every midnight. Because this is a test, 
        // job is supposed to execute immediately after Test.stopTest()
        String cronExpr = '0 0 0 * * ? '; 

        BatchStatus__c batchDetails = new BatchStatus__c(
            Name = RetailConstants.LEAD_ARCHIVAL_BATCH_NAME,
            Email__c = 'cicduser@list.att.com',
            BatchSize__c = 200
        );
        insert batchDetails;
        
        Test.startTest();
        // Schedule the test job
        LeadArchivalAfter60DayScheduler leadArchivalScheduler = new LeadArchivalAfter60DayScheduler();
        String jobId = 
            System.schedule('Archival Job Test', cronExpr, leadArchivalScheduler);
        	//From API 40 Scheduler class execute method needs to be invoked explictly in test classes. Because Test.stopTest() doesn't execute the scheduler, as it would be expected.
        	leadArchivalScheduler.execute(null);
        Test.stopTest();

        // Assert result: Task Archivals must be created for all leads which are closed more than 60 days.
        Integer expectedNumOfTaskArchivals = [SELECT COUNT() FROM TaskArchival__c ];
        System.assertEquals(numberOfLeads, expectedNumOfTaskArchivals);   // Assertion OK

        // Assert result: Messaging Archivals must be created for all leads which are closed more than 60 days.
        Integer expectedNumOfMessagingArchivals = [SELECT COUNT() FROM Messaging_MessageArchival__c ];
        System.assertEquals(numberOfLeads, expectedNumOfMessagingArchivals);   // Assertion OK

        // Assert result: Lead Archivals must be created for all leads which are closed more than 60 days.
        Integer expectedNumOfLeadArchivals = [SELECT COUNT() FROM LeadArchival__c ];
        System.assertEquals(numberOfLeads, expectedNumOfLeadArchivals);   // Assertion OK
    }
    // scheduler class instead of the batch
    @isTest static void testSchedulerWithoutCustomSettingBatchSize () {
        // CRON expression: every midnight. Because this is a test, 
        // job is supposed to execute immediately after Test.stopTest()
        String cronExpr = '0 0 0 * * ? ';

        Test.startTest();
        // Schedule the test job
        LeadArchivalAfter60DayScheduler leadArchivalScheduler = new LeadArchivalAfter60DayScheduler();
        String jobId = 
            System.schedule('Archival Job Test', cronExpr, leadArchivalScheduler);
        	//From API 40 Scheduler class execute method needs to be invoked explictly in test classes. Because Test.stopTest() doesn't execute the scheduler, as it would be expected.
        	leadArchivalScheduler.execute(null);
        Test.stopTest();

        // Assert result: Task Archivals must be created for all leads which are closed more than 60 days.
        Integer expectedNumOfTaskArchivals = [SELECT COUNT() FROM TaskArchival__c ];
        System.assertEquals(numberOfLeads, expectedNumOfTaskArchivals);   // Assertion OK

        // Assert result: Messaging Archivals must be created for all leads which are closed more than 60 days.
        Integer expectedNumOfMessagingArchivals = [SELECT COUNT() FROM Messaging_MessageArchival__c ];
        System.assertEquals(numberOfLeads, expectedNumOfMessagingArchivals);   // Assertion OK

        // Assert result: Lead Archivals must be created for all leads which are closed more than 60 days.
        Integer expectedNumOfLeadArchivals = [SELECT COUNT() FROM LeadArchival__c ];
        System.assertEquals(numberOfLeads, expectedNumOfLeadArchivals);   // Assertion OK
    }
}
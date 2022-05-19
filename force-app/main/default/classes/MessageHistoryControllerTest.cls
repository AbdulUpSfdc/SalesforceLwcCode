@isTest
public with sharing class MessageHistoryControllerTest {
    TestMethod static void testGetMessages(){
        //create retailcustom settings for welcome onboarding leads
        RetailCustomSetting__c smsSettings = new RetailCustomSetting__c();
        smsSettings.Name = 'WelcomeSMSForOnlineLeads';
        smsSettings.KeyValue__c = 'true';
        insert smsSettings;
        
        String consumerRecordTypeId = RetailConstants.CONSUMER_RECORDTYPEID;
        
        Lead leadRec = new Lead(LastName = 'Test',
                                Company = 'Test',
                                LeadSource = RetailConstants.UNICA_LEAD_SOURCE,
                                recordTypeId = consumerRecordTypeId
                               );
        insert leadRec;
        
        Messaging_Message__c message = new Messaging_Message__c();
        message.Lead__c = leadRec.Id;
        message.Was_Sent__c = true;
        insert message;
        
        Test.startTest();
        MessageHistoryController.getMessages(leadRec.Id);
        MessageHistoryController.getMessage(message.Id);
        SMSListViewController.getMessages();
        Test.stopTest();
    }
    /*
    TestMethod static void testGetContactAttachments(){
        Contact testCon = new Contact();
        testCon.LastName = 'Test';
        insert testCon;
        
        //Get Text Channel
        MessagingChannel mc = [SELECT Id FROM MessagingChannel WHERE IsActive = true AND MessageType='Text' LIMIT 1];
        if(String.isEmpty(mc.Id)) {
            System.assertEquals(false, String.isEmpty(mc.Id), 'No Text Channel Available to test!');
            Test.stopTest();
        }
        else {  
            //Create MessagingEndUser with contact Id
            MessagingEndUser meu =  new MessagingEndUser();
            meu.MessageType='Text';
            meu.MessagingChannelId= mc.Id;
            meu.Name='8139404075';
            meu.ContactId = testCon.Id;
            meu.MessagingPlatformKey='8139404075';
            insert meu;  
            system.debug('Messaging End User Created --->' + meu);      
            
            //Create MessagingSession to simulate Bot behavior and then Update
            MessagingSession msgSession = new MessagingSession();
            msgSession.MessagingChannelId = mc.Id;
            msgSession.MessagingEndUserId = meu.Id;
            msgSession.Origin ='InboundInitiated';
            msgSession.Status = 'Ended';
            insert msgSession;
            
            //Create ConversationEntry to simulate Bot creating message
            ConversationEntry ce = new ConversationEntry();
            ce.ActorType = 'EndUser';
            ce.ConversationId = msgSession.Id;
            ce.EntryTime = Datetime.now();
            ce.EntryType = 'Text';
            ce.Message = 'Hello Apex Test Class';
            ce.Seq = 0;
            insert ce;
            system.debug('CONV ENTRY Inserted --->' + ce.Id); 
            
            
            Blob testBlob = Blob.valueOf('Unit Test Attachment Body');
            
            ContentVersion cv = new ContentVersion();
            cv.title = 'test content document';      
            cv.PathOnClient = 'test';           
            cv.VersionData = testBlob;
            insert cv;         
            
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            
            
            ContentDocumentLink contentlink = new ContentDocumentLink();
            contentlink.LinkedEntityId = msgSession.Id;
            contentlink.ContentDocumentId = documents[0].Id;
            contentlink.Visibility = 'AllUsers'; 
            insert contentlink;
            
            
            Test.startTest();
            MessageHistoryController.getContactAttachments(testCon.Id);
            MessageHistoryController.getSessionAttachments(msgSession.Id);
            MessageHistoryController.getContactConversations(testCon.Id);
            MessageHistoryController.getContactName(testCon.Id);
            
            List<String> msgSessionIds = new List<String>();
            msgSessionIds.add(msgSession.Id);
            MessageHistoryController.getAttachmentInformation(msgSessionIds);
            Test.stopTest();
        }
    }*/
}
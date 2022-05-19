@isTest
public with sharing class CacheManagerTest {
    TestMethod static void testPutMessageInCache(){
        Messaging_Message__c message = new Messaging_Message__c();
        insert message;
        
        List<String> messages = new List<String>();
        messages.add(message.Id);
        
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
        Test.startTest();
        try{
            CacheManager.putMessageInCache(messages);
        }catch (exception e){
            system.debug('Exception:'+e.getMessage());
        }
        
        CacheManager.getCacheInterval();
        CacheManager.getCacheTTL('messaging');
        CacheManager.getCacheTTL('store');
        CacheManager.getMessageFromCache(leadRec.Id);
        Test.stopTest();
    }
}
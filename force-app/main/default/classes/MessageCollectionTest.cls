@isTest
/*
* Thpis class is used to test MessageCollection
* Author: Ravindra
*/
private  class MessageCollectionTest {
    
    @isTest 
    static void testMessageCollection() 
    {
        Test.startTest();
       MessageCollection mc = new MessageCollection();
        mc.IsWelcome = 'test';
        mc.SentSMSMessage = 'test';
        mc.RecordIdToAssociateTo = 'test';
        mc.PhoneNumberToMessage = 'test';
        mc.MessagingMessageId = 'test';
        mc.MessagingChannelDeveloperName = 'test';
        mc.MessageToSend = 'test';
        mc.MessageId = 'test';
        
        Test.stopTest();
    }

}
/*
 * Test Class: ContentDocumentLinkTriggerHelperTest
*/
public with sharing class ContentDocumentLinkTriggerHandler {
     public static void delegateProcessing(){
        if(trigger.isBefore && trigger.isDelete){
            ContentDocumentLinkTriggerHelper.filterBeforeDelete(); 
        }
    }
}
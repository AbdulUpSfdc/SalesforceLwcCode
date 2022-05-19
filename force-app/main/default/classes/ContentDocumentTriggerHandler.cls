public class ContentDocumentTriggerHandler {
    public static void delegateProcessing(){
        if(trigger.isBefore && trigger.isDelete){
        	ContentDocumentTriggerHelper.filterBeforeDelete(); 
        }
    }
}
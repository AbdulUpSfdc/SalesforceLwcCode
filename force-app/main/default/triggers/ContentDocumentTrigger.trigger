trigger ContentDocumentTrigger on ContentDocument (before delete) {
    if(boolean.Valueof(System.Label.contentDocumentTriggerBypass)){ return;}
    ContentDocumentTriggerHandler.delegateProcessing();    
}
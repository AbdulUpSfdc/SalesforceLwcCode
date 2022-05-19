trigger ContentDocumentLinkTrigger on ContentDocumentLink (before delete) {
	ContentDocumentLinkTriggerHandler.delegateProcessing();		
}
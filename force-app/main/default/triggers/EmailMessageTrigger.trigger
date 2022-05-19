trigger EmailMessageTrigger on EmailMessage (before insert,after insert) {
	
    //run trigger with before insert method
    if (Trigger.isInsert && Trigger.isBefore){
        EmailMessageHandler.beforeInsert(Trigger.new);   
    }
    if (Trigger.isInsert && Trigger.isAfter){
        EmailMessageHandler.afterInsert(Trigger.new); 
    }
}
trigger CaseTrigger on Case (before insert, before update, after insert, after update) {

SFS_TriggerHandler.run(); //runs trigger code based upon trigger mapping metadata.   

}
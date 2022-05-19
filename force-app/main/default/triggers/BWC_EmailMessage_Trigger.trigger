trigger BWC_EmailMessage_Trigger on EmailMessage(
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    SFS_TriggerHandler.run();
}
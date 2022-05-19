trigger KnowledgeArticleSME on BWKMArticleSME__c (before insert,after insert) {
    if(trigger.isinsert && trigger.isbefore){
        KnowledgeArticleSMETriggerHelper.KnowledgeArticleSMECheckRec(trigger.new);
         
    }
}
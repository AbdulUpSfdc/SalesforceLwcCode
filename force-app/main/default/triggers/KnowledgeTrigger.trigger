trigger KnowledgeTrigger on Knowledge__kav(before insert, before update, after insert, after update ){

    if (trigger.isAfter){
        if (trigger.isInsert){
            //KnowledgeTriggerHelper.afterInsert(trigger.new);
            KnowledgeTriggerHelper.copySMEtoNewArticle(trigger.newMap);
            KnowledgeTriggerHelper.copyArticleInfo(trigger.new);
            //KnowledgeTriggerHelper.CreateDefaultAllDataCategory(trigger.newMap);
        } 
        else if (trigger.isUpdate){
            //KnowledgeTriggerHelper.afterUpdate(trigger.new, trigger.oldMap);
            // KnowledgeTriggerHelper.CreateDefaultAllDataCategory(trigger.newMap);
            KnowledgeTriggerHelper.createSMERecordsOnUpdate(trigger.oldMap, trigger.newMap);
        }
    } 
    else if (trigger.isBefore){
        if (trigger.isInsert){
            KnowledgeTriggerHelper.setFieldValues(trigger.new);
        } 
        else if (trigger.isUpdate){
            //KnowledgeTriggerHelper.validateSmartLinks(trigger.new);
        }
    }
}
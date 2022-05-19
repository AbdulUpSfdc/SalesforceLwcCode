global class EvaluateAgentWorkLoad_CaseAction_sch implements Schedulable {
    global void execute(SchedulableContext sc) {
        EvaluateAgentWorkLoad_CaseAction_btc batch = new EvaluateAgentWorkLoad_CaseAction_btc();
        Database.executeBatch(batch,MetadataSelector.getBatchSize('EvaluateAgentWorkLoad_CaseAction_btc')); 
    }
}
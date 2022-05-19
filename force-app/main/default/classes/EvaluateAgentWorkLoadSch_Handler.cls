/*
*PBCNTRSENT-1475
*/
public class EvaluateAgentWorkLoadSch_Handler implements EvaluateAgentWorkLoad_sch.EvaluateAgentWorkLoadBtc_Dispatch{
    public void execute(SchedulableContext sc){
        EvaluateAgentWorkLoad_btc batch = new EvaluateAgentWorkLoad_btc();
        Database.executeBatch(batch,MetadataSelector.getBatchSize('EvaluateAgentWorkLoad_btc'));
    }
}
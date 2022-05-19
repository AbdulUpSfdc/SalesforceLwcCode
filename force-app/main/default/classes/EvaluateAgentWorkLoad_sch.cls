/*
*PBCNTRSENT-1475
*/
public class EvaluateAgentWorkLoad_sch implements Schedulable{
    public interface EvaluateAgentWorkLoadBtc_Dispatch{ //EvaluateAgentWorkLoadSch_Handler
        void execute(SchedulableContext sc);
    }//interface ends..
    
    public void execute(SchedulableContext sc){
        Type targettype = Type.forName('EvaluateAgentWorkLoadSch_Handler');
        if(targettype!=null){
            EvaluateAgentWorkLoadBtc_Dispatch dispatch = (EvaluateAgentWorkLoadBtc_Dispatch)targettype.newInstance();
            dispatch.execute(sc);
        }
    }
}
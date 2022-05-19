/*******
Name            : UrgentFlagSchedular
Description     : This is the Schedular class runs daily At 1 AM.
*******/
public class UrgentFlagSchedular implements Schedulable{
    
    public void execute(SchedulableContext sc){
        Database.executeBatch(new UrgentFlagBatch());
        System.abortJob(sc.getTriggerId());
        String cronExp = '0 0 0 * * ?';
        UrgentFlagSchedular urgentFlag = new UrgentFlagSchedular();
        String jobID = system.schedule('UrgentFlagBatch', cronExp, urgentFlag);
    }

}
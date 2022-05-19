/*******
Name            : HomepageFlagSchedular
Description     : This is the Schedular class to runs daily At 1 AM.
*******/
public class HomepageFlagSchedular implements Schedulable{
    
    public void execute(SchedulableContext sc){
        Database.executeBatch(new HomepageFlagBatch());
        System.abortJob(sc.getTriggerId());
        
        String cronExp = '0 0 0 * * ?';
        HomepageFlagSchedular homeFlag = new HomepageFlagSchedular();
        String jobID = system.schedule('HomepageFlagSchedular', cronExp, homeFlag);
        
    }

}
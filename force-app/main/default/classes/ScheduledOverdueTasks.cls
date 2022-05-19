// Schedule the OverdueTasksBatch to run daily at 0300
public without sharing class ScheduledOverdueTasks implements Schedulable {
    public void execute(SchedulableContext sc){
        OverdueTasksBatch b = new OverdueTasksBatch();
        Database.executeBatch(b);
    }
}
// Schedule the ScheduledOverdueChildCases to run daily at 0300
public without sharing class ScheduledOverdueChildCases implements Schedulable {
    public void execute(SchedulableContext sc){
        OverdueCasesActionsBatch b = new OverdueCasesActionsBatch();
        Database.executeBatch(b);
    }
}
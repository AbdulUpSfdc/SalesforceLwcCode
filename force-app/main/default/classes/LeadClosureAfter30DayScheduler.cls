global with sharing class LeadClosureAfter30DayScheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
      LeadClosureAfter30DayBatch LeadClosureBatch = new LeadClosureAfter30DayBatch(); 
      database.executebatch(LeadClosureBatch);
   }
}
global class DCIRetailFutureBatchScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
      DCIRetailFutureBatch dciRetailFuture = new DCIRetailFutureBatch(); 
      database.executebatch(dciRetailFuture);
   }
}
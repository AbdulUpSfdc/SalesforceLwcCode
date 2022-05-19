global class DCIPermSetAssignmentBatchScheduler implements schedulable {
    global void execute(SchedulableContext sc) {
        DCIPermSetAssignmentBatch dciPermSetAssignment = new DCIPermSetAssignmentBatch(); 
        database.executebatch(dciPermSetAssignment);
    }
}
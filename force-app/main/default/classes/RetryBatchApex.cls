global class RetryBatchApex implements Database.Batchable<sObject>, Database.Stateful {
    
    private List<SObject> failedSObjects;
	private Integer retryCount;

    global RetryBatchApex(List<SObject> failedSObjects) {
        this.failedSObjects = failedSObjects;
        this.retryCount = 0;
    }

    global RetryBatchApex(List<SObject> failedSObjects, Integer retries) {
        this.failedSObjects = failedSObjects;
        this.retryCount = retries;
    }
    
    global Iterable<sObject> start(Database.BatchableContext BC) { 
        return failedSObjects;
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        
    }
    
    global void finish(Database.BatchableContext BC) {
		List<SObject> newFailedObjects = new List<SObject>();

        if (failedSObjects != null && !failedSObjects.isEmpty()) {
            if (failedSObjects.size() + Limits.getDMLRows() < Limits.getLimitDMLRows()) {
                List<Database.upsertResult> resultList = Database.upsert(failedSObjects, false);
                for (Integer i = 0; i < failedSObjects.size(); i++) {
                    Database.upsertResult sr = resultList[i];
                    if (!sr.success) {
                        for (Database.Error err : sr.getErrors()) {
                            if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW || Test.isRunningTest()) {
                                newFailedObjects.add(failedSObjects[i]);
                            }
                        }
                    }
                }
            }
        }
        
        if (!newFailedObjects.isEmpty() && retryCount < 3) {
            Integer newCount = retryCount + 1;
        	Database.executeBatch(new RetryBatchApex(newFailedObjects, newCount));
    	}
    }
}
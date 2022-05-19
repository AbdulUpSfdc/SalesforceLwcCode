public without sharing class EmployeeCreated implements IEmployeeUpdateStrategy{

    private Map<Id,LeadRedistribution__c> workRecords; 
    
    public EmployeeCreated(Map<Id,LeadRedistribution__c> leadRedistributions) {
        workRecords = leadRedistributions;
    }
    
    public void runStrategy() {
		Map<Id,String> resultMap = new Map<Id,String>();
        for(Id lrd : workRecords.keySet()) {
            resultMap.put(lrd, 'Success');
        }
        
        EmployeeUpdateStrategyHelper.updateLeadRedistributions(workRecords, resultMap);
    }
    
    public void findRecords() {
        
    }
}
/*
* This scheduler Batch class is used for scheduling to delete the Lead Consent Records in Every X minutes  
* Author: Venu Peddu
*/
global with sharing class ScheduleBatchDeletedAcceptedLead30mins implements Schedulable {
global void execute(SchedulableContext sc) { 
  ID BatchId = Database.executeBatch(new DeleteAcceptedLeadcreatedinlast30mins(), 200);
}
 
Public static void SchedulerMethod() {  
  Integer lastTimeCreated = 0;
  BatchStatus__c batchDetails = BatchStatus__c.getValues('DeleteAcceptedLeadcreatedinlast30mins');
  if(batchDetails != null && batchDetails.Batch_Processing_Gap__c != null) {
      lastTimeCreated = Integer.valueOf(batchDetails.Batch_Processing_Gap__c);
      system.debug('lastTimeCreated'+lastTimeCreated);
  } 
string timeinterval = ''+lastTimeCreated+' 0 * * * ?';
  System.schedule('DeleteAcceptedLeadcreatedinlast30mins-Every15mins',timeinterval, new ScheduleBatchDeletedAcceptedLead30mins());
}
}
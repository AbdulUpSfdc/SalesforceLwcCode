/*
 * Author : Mohit Pandey
 * Purpose: This batch class will be executed from Scheduler class every day
 * and will mark the IsExpired__c as TRUE on EmployeeStore records if the EffectiveEndDate is in past.
 * 
 */
public class EmpStoreExpirationDateBatch implements Database.Batchable<sObject> {
    public String query;
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        Date todaysDate = System.today();
        query = 'SELECT Id, IsExpired__c, EffectiveEnddate__c FROM EmployeeStoreRetail__c '
                + 'WHERE EffectiveEnddate__c != null '
                + 'AND EffectiveEnddate__c <: todaysDate '
                + 'AND IsExpired__c = false ' 
                + 'AND SFProfileId__c = \''+RetailConstants.ARSM_POSITION+'\'';
        
        system.debug('Expired Batch Query ---> ' + query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        List <EmployeeStoreRetail__c> expiredEmpStores = new List<EmployeeStoreRetail__c>(); 
        for(sObject s : scope){
            EmployeeStoreRetail__c empStoreRec = (EmployeeStoreRetail__c)s;            
            if(empStoreRec.EffectiveEnddate__c != null && empStoreRec.EffectiveEnddate__c < System.today()){
                empStoreRec.isExpired__c = true;
		 expiredEmpStores.add(empStoreRec);
            }
            
        }
        
        if(expiredEmpStores.size() > 0){
            update expiredEmpStores;
        }
    }
    
    public void finish(Database.BatchableContext BC){
    }
}
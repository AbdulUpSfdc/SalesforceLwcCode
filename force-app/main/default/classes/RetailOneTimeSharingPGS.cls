public without sharing class RetailOneTimeSharingPGS  implements Database.Batchable<SObject>
{ 
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id,Store__c,Store__r.Name, StorePublicGroupId__c, Owner__c, OwnerId
                                        FROM Lead 
                                        WHERE RecordTypeId=:RetailConstants.DIGITALCHECKIN_RECORDTYPEID]);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<Lead> leadsToProcess = (List<Lead>) scope; 
        List<LeadShare> insertLeadShareList = new List<LeadShare>();
        List<RetailCheckinQueue__c> dciToProcess = new List<RetailCheckinQueue__c>();
        List<RetailCheckinQueue__share> deleteDciShareList = new List<RetailCheckinQueue__share>();
        List<RetailCheckinQueue__share> insertDciShareList = new List<RetailCheckinQueue__share>();

        //Fetch all DCI for leads                                
        dciToProcess = [SELECT id, Owner__c, OwnerId, Store__c, StorePublicGroupId__c 
                        FROM RetailCheckinQueue__c
                        WHERE Lead__c IN :leadsToProcess];
        //Fetch all DCI share for dci records                        
        deleteDciShareList = [SELECT id 
                                FROM RetailCheckinQueue__share 
                                WHERE ParentId IN :dciToProcess
                                AND RowCause != :RetailConstants.LEAD_OWNER];

        for(Lead l: leadsToProcess) {
            system.debug('l---->>>'+l);
            if(l.StorePublicGroupId__c != null){
                //Share the lead record with Store PGS
                LeadShare leadShareRec =  createLeadShareInstance(RetailConstants.LEAD_ACCESS_ALL,l.Id,l.StorePublicGroupId__c);
                insertLeadShareList.add(leadShareRec);
                /*if(String.valueOf(l.OwnerId).startsWith('005')) {
                    LeadShare leadShareRec2 =  createLeadShareInstance(RetailConstants.LEAD_ACCESS_ALL,l.Id,l.OwnerId);
                    insertLeadShareList.add(leadShareRec2);
                }*/
            }
            //Update OwnerId and Owner__c for Lead
            if(String.valueOf(l.OwnerId).startsWith('005')) 
            	l.Owner__c = l.OwnerId;
            if(l.OwnerId != RetailConstants.RETAILLEADOWNERQUEUE)
                l.OwnerId = RetailConstants.RETAILLEADOWNERQUEUE;
            system.debug('l---->>>'+l);
            system.debug('insertLeadShareList---->>>'+insertLeadShareList);
        }

        for(RetailCheckinQueue__c dci: dciToProcess) {
            system.debug('dci---->>>'+dci);
            if(dci.StorePublicGroupId__c != null){
                //Share the DCI record with Store PGS
                RetailCheckinQueue__share dciShare =  RetailCheckinQueueTriggerHelper.createDCIShareInstance(RetailConstants.LEAD_ACCESS_ALL, dci.Id, dci.StorePublicGroupId__c);
                insertDciShareList.add(dciShare);
                /*if(String.valueOf(dci.OwnerId).startsWith('005')) {
                    RetailCheckinQueue__share dciShare2 =  RetailCheckinQueueTriggerHelper.createDCIShareInstance(RetailConstants.LEAD_ACCESS_ALL, dci.Id, dci.OwnerId);
                    insertDciShareList.add(dciShare2);
                }*/
            }
            //Update OwnerId and Owner__c for DCI
            if(String.valueOf(dci.OwnerId).startsWith('005'))
                dci.Owner__c = dci.OwnerId;
            if(dci.OwnerId != RetailConstants.RETAILLEADOWNERQUEUE)
            	dci.OwnerId = RetailConstants.RETAILLEADOWNERQUEUE;
			system.debug('dci---->>>'+dci);
            system.debug('insertDciShareList---->>>'+insertDciShareList);
            
        }
        
        
        if(!Test.isRunningTest()) {
            
            //Update Owner__c and OwnerId for existing dci Lead
            update leadsToProcess;
            //Create new PGS leadshare
            insert insertLeadShareList;
            
            //Update Owner__c and OwnerId for existing dci
            update dciToProcess;
            //Delete existing DCIShare
            delete deleteDciShareList;
            //Insert new PGS DciShare
            insert insertDciShareList;
            
        }
        
    }
    
    public void finish(Database.BatchableContext bc)
    {
    }
    
    /* 
    *This method creates lead share instances for lead insert/update
    */
    public static LeadShare createLeadShareInstance(String accessLevel, Id leadId, Id userId) {
        LeadShare leadShareRec = new LeadShare(
            LeadAccessLevel = accessLevel, 
            LeadId = leadId,
            RowCause = Schema.LeadShare.RowCause.Manual,
            UserOrGroupId = userId);
        return leadShareRec;
    }
    
}
/**
 * @description       : Helper Class to assist the Employee Update Strategy instance classes
 * @author            : Erashad Kurawle ekurawle@salesforce.com
 * @group             : 
 * @last modified on  : 01-05-2021
 * @last modified by  : Erashad Kurawle ekurawle@salesforce.com
 * Modifications Log 
 * Ver   Date         Author                                    Modification
 * 1.0   12-31-2020   Erashad Kurawle ekurawle@salesforce.com   Initial Version
**/
public without sharing class EmployeeUpdateStrategyHelper {
    /*
    * @description:     This method populated the emplyee's user id to employees old store to employees new store map
    */
    public static map<Id, map<Id, Id>> populateEmployeeToStoreChangeMap(map<Id, map<Id, Id>> userToOldToNewStoreMap, Id userId, Id newStore, Id oldStore) {
        map<Id ,Id> oldToNewStoreMap = new map<Id, Id>();
        if(userToOldToNewStoreMap.containsKey(userId))
            oldToNewStoreMap = userToOldToNewStoreMap.get(userId);
        oldToNewStoreMap.put(oldStore, newStore);
        userToOldToNewStoreMap.put(userId, oldToNewStoreMap);
        return userToOldToNewStoreMap;
    }
    /**
     * @description:    This method is used to update the leads with new owners or new stores. 
     *                  Once it updates, it tries to match the lead updated to the LR and returns a map that contains the result of the operation
     */
    public static Map<Id,String> updateLeads(List<Lead> leadsToUpdate,Map<Id,Id> leadRedToAttributeMap,String type){
        Map<Id,String> resultMap = new Map <Id,String>();
        Set<Id> successfullLeads = new Set<Id>();
        Map<Id,String> failedLeads = new Map<Id,String>();

        Database.SaveResult[] SRUpdate = Database.update(leadsToUpdate, false);
        //Iterate through each return result
        For(Database.SaveResult SR : SRUpdate){
            If(SR.isSuccess()){
                successfullLeads.add(SR.getId());
            }
            else {   
                for(Database.Error SRError : SR.getErrors()){
                    System.debug('Following error has occured : ');            
                    //Get error status code and message
                    System.debug(SRError.getStatusCode()+' : '+SRError.getMessage());            
                    //Know which fields are affected
                    System.debug('Fields of Leads object which are affected : '+SRError.getFields());
                    //Failed Lead Ids
                    failedLeads.put(SR.getId(),SRError.getMessage());
                }
            }
        }       
        if(type=='redistribute'){
            //In case of redistribute, owner changes and store stays same
            //leadRedToAttributeMap contains LeadRedistribution Id and Store Id
            resultMap  = getResultMapRedistribution(successfullLeads, failedLeads,leadRedToAttributeMap);
        }else if(type=='update'){
            //In case of update, owner stays same and store changes
            //leadRedToAttributeMap contains LeadRedistribution Id and owner Id
            resultMap  = getResultMapUpdate(successfullLeads, failedLeads,leadRedToAttributeMap);

        }
        System.debug('Result Map is'+resultMap);
        return resultMap;
    }

    /**
     * @description:    This method is used to map successfull and failedLeads back to the Lead Redistribution record.
     *                  If a LR record has multiple leads associated with it and 1 lead fails, the entire LR will be marked as failed.
     */
	@testVisible
    private static Map<Id,String> getResultMapRedistribution(Set<Id> successfullLeads, Map<Id,String> failedLeads,Map<id,Id> lrToStoreMap){
        Map<Id,String> allRecords = new Map <Id,String>();
        Map<Id,String> successStores = new Map<Id,String>();
        Map<Id,String> failedStores = new Map<Id,String>();

        //Fill up Success Stores using Successfull Leads
        if(successfullLeads.size()>0){
            //Get the Store Ids for Successfull Leads
            for(Lead successLead : [Select Id,Store__c from lead where Id IN:successfullLeads]){
                successStores.put(successLead.Store__c,'Success');
            }
        }  

        //Fill up Failed Stores using Failed Leads
        if(failedLeads.size()>0){
            //Get the Store Ids for failed Leads
            for(Lead failedLead : [Select Id,Store__c from lead where Id IN:failedLeads.keySet()]){
                String errorMessage = failedLeads.get(failedLead.Id);
                failedStores.put(failedLead.Store__c,errorMessage);
            }
        }  
        //Fill up All records with successfull LRs mapped to successfull stores
        if(successStores.size()>0){
            for(Id lrId:lrToStoreMap.keySet()){
                Id storeId = lrToStoreMap.get(lrid);
                if (successStores.containsKey(storeId)){
                    allRecords.put(lrId,'Success');
                }
            }
        }   
        
        //Fill up All records with Failed Lrs mapped to failed stores.
        //Remove existing successfull LRS from map, if a different store fails for the same LR
        if(failedStores.size()>0){
            for(Id lrId:lrToStoreMap.keySet()){
                Id storeId = lrToStoreMap.get(lrid);
                if (failedStores.containsKey(storeId)){
                    String errorMessage = failedStores.get(storeId);    
                    if(allRecords.containsKey(lrId)){
                        //Remove a successfull LR Id from the map if there is an error on another store
                        allRecords.remove(lrId);
                    }            
                    allRecords.put(lrId,errorMessage);
                }
            }
        } 
        return allRecords;
    }

    /**
     * @description:    This method is used to map successfull and failedLeads back to the Lead Redistribution record.
     *                  If a LR record has multiple leads associated with it and 1 lead fails, the entire LR will be marked as failed.
     */
    @testVisible
    private static Map<Id,String> getResultMapUpdate(Set<Id> successfullLeads, Map<Id,String> failedLeads,Map<id,Id> lrToOwnerMap){
        Map<Id,String> allRecords = new Map <Id,String>();
        Map<Id,String> successOwners = new Map<Id,String>();
        Map<Id,String> failedOwners = new Map<Id,String>();

        //Fill up Success Stores using Successfull Leads
        if(successfullLeads.size()>0){
            //Get the Store Ids for Successfull Leads
            for(Lead successLead : [Select Id,Owner__c from lead where Id IN:successfullLeads]){
                successOwners.put(successLead.Owner__c,'Success');
            }
        }  

        //Fill up Failed Stores using Failed Leads
        if(failedLeads.size()>0){
            //Get the Store Ids for failed Leads
            for(Lead failedLead : [Select Id,Owner__c from lead where Id IN:failedLeads.keySet()]){
                String errorMessage = failedLeads.get(failedLead.Id);
                failedOwners.put(failedLead.Owner__c,errorMessage);
            }
        }  
        //Fill up All records with successfull LRs mapped to successfull owners
        if(successOwners.size()>0){
            for(Id lrId:lrToOwnerMap.keySet()){
                Id ownerId = lrToOwnerMap.get(lrid);
                if (successOwners.containsKey(ownerId)){
                    allRecords.put(lrId,'Success');
                }
            }
        }   
        
        //Fill up All records with Failed Lrs mapped to failed owners.
        //Remove existing successfull LRS from map, if a different owner fails for the same LR
        if(failedOwners.size()>0){
            for(Id lrId:lrToOwnerMap.keySet()){
                Id ownerId = lrToOwnerMap.get(lrid);
                if (failedOwners.containsKey(ownerId)){
                    String errorMessage = failedOwners.get(ownerId);    
                    if(allRecords.containsKey(lrId)){
                        //Remove a successfull LR Id from the map if there is an error on another store
                        allRecords.remove(lrId);
                    }            
                    allRecords.put(lrId,errorMessage);
                }
            }
        } 
        return allRecords;
    }

    /**
     * @description:    This method is used to update the LR records with the result(success/fail) of the redistribution operation
     */
    public static void updateLeadRedistributions(Map<Id,LeadRedistribution__c> workRecords,Map<Id,String> allRecords){
        List<LeadRedistribution__c> listToDeleteLeadDistribution = new List<LeadRedistribution__c>();
		List<LeadRedistribution__c> listToUpdateLeadDistribution = new List<LeadRedistribution__c>();
        if(allRecords.size()>0){
            
            List<LeadRedistribution__c> leadRedistributions = [Select Id,Status__c,ErrorMessage__c,Retry__c from LeadRedistribution__c where Id IN:allRecords.keySet()];
            for(LeadRedistribution__c leadRedistribution:leadRedistributions){
                workRecords.remove(leadRedistribution.Id);
                String currentMessage = allRecords.get(LeadRedistribution.Id);
                if(currentMessage=='Success'){
                    listToDeleteLeadDistribution.add(leadRedistribution);
                } else{
                    leadRedistribution.Retry__c = leadRedistribution.Retry__c+1;
                    leadRedistribution.ErrorMessage__c=currentMessage;
                    leadRedistribution.Status__c='Failed';
		    listToUpdateLeadDistribution.add(leadRedistribution);
                }
            }


        }

        if(workRecords.size()>0){
            //List<LeadRedistribution__c> remainingRecords = new List<LeadRedistribution__c>();
            for(LeadRedistribution__c record: workRecords.values()){
                /*record.Status__c='Success';
                record.AdditionalAttributes__c=record.AdditionalAttributes__c+'--No Leads Found--';
                remainingRecords.add(record);*/
		listToDeleteLeadDistribution.add(record);
            }
            
        }
		try {  
			if(!listToDeleteLeadDistribution.isEmpty()) {
				Database.DeleteResult[] deleteSaveResult = Database.delete(listToDeleteLeadDistribution, false);
			} 
			if(!listToUpdateLeadDistribution.isEmpty()) {
				Database.SaveResult[] updateSaveResult = Database.update(listToUpdateLeadDistribution, false);
			}
        }
		catch (Exception e) {
		   //Send exception to Exception__c custom object for further handling
		   BWC_ExceptionUtils.handleException(e, true);
		}
    }

}
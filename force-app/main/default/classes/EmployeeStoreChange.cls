/**
 * @description       : Strategy class to handle Employee store change scenario
 * @author            : Erashad Kurawle ekurawle@salesforce.com
 * @group             : 
 * @last modified on  : 01-04-2021
 * @last modified by  : Erashad Kurawle ekurawle@salesforce.com
 * Modifications Log 
 * Ver   Date         Author                                    Modification
 * 1.0   12-23-2020   Erashad Kurawle ekurawle@salesforce.com   Initial Version
**/
public without sharing class EmployeeStoreChange implements IEmployeeUpdateStrategy{
    //Map to hold the Lead Redistribution records that need to be worked on. 
    private Map<Id,LeadRedistribution__c> workRecords; 
    
    //List of leads to be redistributed among other store reps using redistribution logic
    private List<Lead> leadsToRedistribute = new List<Lead>(); 
    
    //List of Leads whose store need to be updated.
    private List<Lead> leadsToUpdate = new List<Lead>();

    //Map storing mapping between LR and stores. This will be used to track which LR's have been worked on successfully or failed.
    private Map<Id,Id> lrToStoreMap = new Map<Id,Id>();

    //Map storing mapping between LR and owners. This will be used to track which LR's have been worked on successfully or failed.
    private Map<Id,Id> lrToOwnerMap = new Map<Id,Id>();
    
    //Map containing result of the redistribution/update operation. The id will be LR Id. 
    //The value will be success in case of success and error message in case of failure
    private Map<Id,String> resultMap = new Map<Id,String>();

    /**
     * @description       : Constructor method
     */
    public EmployeeStoreChange(Map<Id,LeadRedistribution__c> leadRedistributions){
        workRecords = leadRedistributions;
    }

    /**
     * @description        : Run the strategy for the Employee store change type
     */
    public void runStrategy(){
		// Copy of Distribution work records to send notifications
		Map<Id,LeadRedistribution__c> notificationsWorkRecords = new Map<Id,LeadRedistribution__c>();
        notificationsWorkRecords.putAll(workRecords);
        //find Lead Records that need to be updated
        findRecords();
        //Do the lead update and fill up resultMap with result of update operation for Redistribute Leads
        resultMap = EmployeeUpdateStrategyHelper.updateLeads(leadsToRedistribute,lrToStoreMap,'redistribute'); 
        //Do the lead update and fill up resultMap with result of update operation for Update Leads
        resultMap.putall(EmployeeUpdateStrategyHelper.updateLeads(leadsToUpdate,lrToOwnerMap,'update')); 
        //Update Lead Redistribution records based on the outcome of the update Lead operation
        EmployeeUpdateStrategyHelper.updateLeadRedistributions(workRecords,resultMap);
        // Notifications
        NotificationsHandler.handleNotificationsFromRedistributionBatch(notificationsWorkRecords, 'EmployeeStoreChange');
    }  

    /**
     * @description        : Finds lead records that need to be updated and redistributed. 
     *                       Also fills up the lrToStoreMap and lrToOwnerMap.
     */
    public void findRecords(){
        set<Id> updateStoreIdSet = new set<Id>(); //set of store ids for which the leads store need to be updated
        set<Id> redistributeLeadUserIdSet = new set<Id>(); //set of user ids from whom the leads need to be redistributed 
        set<Id> redistributeLeadStoreIdSet = new set<Id>(); //set of store ids from which the lead  needs to be redistributed
        set<Id> updateLeadStoreIdSet = new set<Id>(); //set of store ids from which the lead  needs to be redistributed
        map<Id, map<Id, Id>> userToOldToNewStoreMap = new map<Id, map<Id, Id>>(); //user id, to old store id, to new store id map; 

        for (Id key : workRecords.keySet()){
            LeadRedistribution__c leadRedistribution  = workRecords.get(key);
            
            if(leadRedistribution.Action__c=='Redistribute'){
                //If Action is redistribute, fill up UserIdSet and StoreIdSet
                redistributeLeadUserIdSet.add(leadRedistribution.User__c);
                redistributeLeadStoreIdSet.add(leadRedistribution.OldValue__c);
                //LR to Store Map is used to backtrack the result of lead update to the relevant store to the relevant LR record
                lrToStoreMap.put(key,leadRedistribution.OldValue__c);
            }else if(LeadRedistribution.Action__c=='Update'){
                //If Action is update, fill up OldToNewStore Map and StoreIdSet
                userToOldToNewStoreMap = EmployeeUpdateStrategyHelper.populateEmployeeToStoreChangeMap(userToOldToNewStoreMap, leadRedistribution.User__c, leadRedistribution.NewValue__c, leadRedistribution.OldValue__c);
                updateLeadStoreIdSet.add(leadRedistribution.OldValue__c);
                //LR to Owner Map is used to backtrack the result of lead update to the relevant owner to the relevant LR record
                lrToOwnerMap.put(key,leadRedistribution.User__c);
            }
        }

            if(!userToOldToNewStoreMap.isEmpty()){
                //Call RedistributeLeadHandler to get list of leads that need to be updated
                leadsToUpdate=RedistributeLeadHandler.updateLeadStore(userToOldToNewStoreMap, updateLeadStoreIdSet);
            }

            
            if(!redistributeLeadUserIdSet.isEmpty()){
                //Call RedistributeLeadHandler to get list of leads that need to be redistributed
                leadsToRedistribute=RedistributeLeadHandler.redistributeLeads(redistributeLeadUserIdSet, redistributeLeadStoreIdSet, RetailConstants.HOME_STORE_CHANGE);
            }                 


    }

}
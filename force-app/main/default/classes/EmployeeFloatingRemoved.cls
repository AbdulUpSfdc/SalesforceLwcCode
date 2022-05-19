/**
 * @description       : Strategy class to handle Floating Employee Removed scenario
 * @author            : Erashad Kurawle ekurawle@salesforce.com
 * @group             : 
 * @last modified on  : 01-05-2021
 * @last modified by  : Erashad Kurawle ekurawle@salesforce.com
 * Modifications Log 
 * Ver   Date         Author                                    Modification
 * 1.0   12-31-2020   Erashad Kurawle ekurawle@salesforce.com   Initial Version
**/
public with sharing class EmployeeFloatingRemoved implements IEmployeeUpdateStrategy {
    //Map to hold the Lead Redistribution records that need to be worked on. 
    private Map<Id,LeadRedistribution__c> workRecords; 
    
    //List of leads to be redistributed among other store reps using redistribution logic
    private List<Lead> leadsToRedistribute = new List<Lead>(); 

    //Map storing mapping between LR and stores. This will be used to track which LR's have been worked on successfully or failed.
    private Map<Id,Id> lrToStoreMap = new Map<Id,Id>();
    
    //Map containing result of the redistribution/update operation. The id will be LR Id. 
    //The value will be success in case of success and error message in case of failure
    private Map<Id,String> resultMap = new Map<Id,String>();
    
    /**
     * @description       : Constructor method
     */
    public EmployeeFloatingRemoved(Map<Id,LeadRedistribution__c> leadRedistributions){
        workRecords = leadRedistributions;
    }

    /**
     * @description        : Run the strategy for the Employee offboarded change type
     */
    public void runStrategy(){
       	// Copy of Distribution work records to send notifications
        Map<Id,LeadRedistribution__c> notificationsWorkRecords = new Map<Id,LeadRedistribution__c>();
        notificationsWorkRecords.putAll(workRecords);
        findRecords();
        resultMap = EmployeeUpdateStrategyHelper.updateLeads(leadsToRedistribute,lrToStoreMap,'redistribute'); 
        System.debug(workRecords);
        System.debug(resultMap);
        EmployeeUpdateStrategyHelper.updateLeadRedistributions(workRecords,resultMap);
        // Notifications
        NotificationsHandler.handleNotificationsFromRedistributionBatch(notificationsWorkRecords, 'EmployeeFloatingRemoved');
    }  

    /**
     * @description        : Finds lead records that need to be redistributed. Also fills up the lrToStoreMap.
     */
    public void findRecords(){
        set<Id> offboardUserSet = new set<Id>();        //set of user ids from whom the leads need to be redistributed 
        set<Id> offBoardStoreSet = new set<Id>();       //set of store ids from which the lead  needs to be redistributed

        for (Id key : workRecords.keySet()){
            LeadRedistribution__c leadRedistribution  = workRecords.get(key);
            // Fill up OffboardUserSet, StoreSet and lrToStoreMap
            offboardUserSet.add(leadRedistribution.User__c);
            offBoardStoreSet.add(leadRedistribution.NewValue__c);
            lrToStoreMap.put(key,leadRedistribution.NewValue__c);
        }

        if(!offBoardStoreSet.isEmpty()) {
            leadsToRedistribute=RedistributeLeadHandler.redistributeLeads(offboardUserSet, offBoardStoreSet, RetailConstants.EMP_REMOVE_LOCATION);
        }    
    }  
}
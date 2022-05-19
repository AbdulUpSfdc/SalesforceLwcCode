/*
* This class has the logic for Rep/SM related activities for Digital Checkin for Retail track 
* @Autthor: Reshma Jewrani, Alisha Mundaden
*/
public without sharing class DCIRepUtil {
    /**
    * This method updates the Rep's DCI status and updates the queue based on the same
    * @Parameter - EmployeeStoreRetail__c empStore - The Employee Store record for which the status needs to be updated
    *              String status - The new Status to be set
    */
    public static void updateRepStatus(EmployeeStoreRetail__c empStore, String status) {
        empStore.DCIPresenceStatus__c = status;
        if(String.isNotBlank(status) && status == DCIConstants.ONLINE){
            empStore.IsCurrentlyAvailable__c =true;    
        }else if(String.isNotBlank(status) && status == DCIConstants.OFFLINE){
            empStore.IsCurrentlyAvailable__c =false; 
        }
        //update empStore;
        if(Schema.sObjectType.EmployeeStoreRetail__c.fields.DCIPresenceStatus__c.isUpdateable()&&
      Schema.sObjectType.EmployeeStoreRetail__c.fields.IsCurrentlyAvailable__c.isUpdateable()){
          update empStore; 
                 }
        
        System.debug(status); 
        String dciChangeReason = '';
            if(status == 'Online'){
                dciChangeReason = 'Rep went online';    
            }else if(status == 'Offline'){
                dciChangeReason = 'Rep went offline';
            }
        if (DCIConstants.EWTCalculationMethod == DCIConstants.TUF) { 
                DCIUtil.updateQueueBulkifyMinutesUntilFree(new set<Id>{empStore.Store__c}, 0, false, false, dciChangeReason);
        } else {
            DCIUtil.updateQueue(empStore.Store__c, 0,  false, false, dciChangeReason);
        }
    }
    
    public static void updateRepStatusBulkify(List<EmployeeStoreRetail__c> empStore, String dciChangeReason) {
        set<Id> storeIds = new set<Id> ();
        for(EmployeeStoreRetail__c  esr : empStore){
            storeIds.add(esr.store__c);
        }
        update empStore;
        if (DCIConstants.EWTCalculationMethod == DCIConstants.TUF) { // DM Added TUF - EWT Calculation
            DCIUtil.updateQueueBulkifyMinutesUntilFree(storeIds, 0, false, false, dciChangeReason);
        } else {
            DCIUtil.updateQueueBulkify(storeIds, 0,  false, dciChangeReason);
        }
    }

    /**
    * This method updates the Rep's DCI status and updates the queue based on the same
    * @Parameter - EmployeeStoreRetail__c empStore - The Employee Store record for which the status needs to be updated
    *              String status - The new Status to be set
    */
    public static RetailDTO.DCINextCustomerDTO assign(EmployeeStoreRetail__c empStore) {
        RetailDTO.DCINextCustomerDTO customerInfo = new RetailDTO.DCINextCustomerDTO();
        List<RetailCheckinQueue__c> lstNoShowCheckins = new List<RetailCheckinQueue__c>();
        //List<RetailCheckinQueue__c> lstArrivedCheckins = new List<RetailCheckinQueue__c>();
        List<RetailCheckinQueue__c> dciCheckinList = [SELECT ID, Name, lead__c,lead__r.CustomerRequestedRep__c, lead__r.Name,Store__c,Status__c,QueuePosition__c,EstimatedWaitTime__c,Store__r.Name,DCICheckinType__c,NoShowCount__c
                                                FROM RetailCheckinQueue__c 
                                                WHERE Store__c =:empStore.Store__c AND 
                                                QueuePosition__c > 0 WITH SECURITY_ENFORCED
                                                FOR UPDATE ];
     
                                                
        Boolean custAssigned = false;
        /* Get all Arrived checkins */   
        RetailCheckinQueue__c earliestArrivedCheckin;
        RetailCheckinQueue__c firstPositionCheckin;
        RetailCheckinQueue__c lstArrivedCheckins;
        //Must iterate through whole list of check-ins and determine the first customer in line and the lowest queue position arrived customer
        //Cannot use FOR UPDATE in soql to row lock and order by
        for(RetailCheckinQueue__c dciCheckin: dciCheckinList) {
            if(dciCheckin.Status__c == DCIConstants.INSTORE && (dciCheckin.lead__r.CustomerRequestedRep__c == null || dciCheckin.lead__r.CustomerRequestedRep__c == UserInfo.getUserId())) {
                if (earliestArrivedCheckin != null && earliestArrivedCheckin.QueuePosition__c != null) {
                    if (dciCheckin.QueuePosition__c < earliestArrivedCheckin.QueuePosition__c) {
                        earliestArrivedCheckin = dciCheckin; 
                    }
                } else {
                    earliestArrivedCheckin = dciCheckin; 
                }

                //latest Instore CheckIn record which is not assign to other Rep
                if(lstArrivedCheckins == null || (lstArrivedCheckins!= null && lstArrivedCheckins.QueuePosition__c > dciCheckin.QueuePosition__c)){
                    lstArrivedCheckins = dciCheckin;
                }
            } 
            if (dciCheckin.QueuePosition__c == 1) { 
                firstPositionCheckin = dciCheckin;
            }
        }   
        
        if (firstPositionCheckin == null && earliestArrivedCheckin != null) {
            firstPositionCheckin = earliestArrivedCheckin;
        }
                
        //If firstPositionCheckin meets criteria then it should always be equivalent to earliestArrivedCheckin
        if (firstPositionCheckin != null && firstPositionCheckin.Status__c == DCIConstants.INSTORE && (firstPositionCheckin.lead__r.CustomerRequestedRep__c == null || firstPositionCheckin.lead__r.CustomerRequestedRep__c == UserInfo.getUserId())) {
            DCIUtil.accept(firstPositionCheckin);
            customerInfo.checkinId = firstPositionCheckin.Id;
            customerInfo.message = 'Next Customer Assigned';
            custAssigned = true; 
        } else if (firstPositionCheckin != null && firstPositionCheckin.Status__c == DCIConstants.PENDING) {
            firstPositionCheckin.NoShowCount__c = firstPositionCheckin.NoShowCount__c + 1;
            lstNoShowCheckins.add(firstPositionCheckin);
            if (earliestArrivedCheckin != null) {
                DCIUtil.accept(earliestArrivedCheckin);
                customerInfo.checkinId = earliestArrivedCheckin.Id;
                customerInfo.message = 'Next Customer Assigned';
                custAssigned = true;
            }
        }
        // In case next record in queue assigned to other rep, below logic to pick latest unassgined Instore check in
        else if(lstArrivedCheckins != null){
            DCIUtil.accept(lstArrivedCheckins);
            customerInfo.checkinId = lstArrivedCheckins.Id;
            customerInfo.message = 'Next Customer Assigned';
            custAssigned = true; 
        }  
        
        if(lstNoShowCheckins.size() > 0) {
            DCILeadUtil.sendAutoResponseSMS(lstNoShowCheckins, DCIConstants.NO_SHOW);
        }
        
        if(custAssigned && earliestArrivedCheckin != null){
            List<RetailCheckinQueue__c> lstYourTurnCheckins = new List<RetailCheckinQueue__c>();
            lstYourTurnCheckins.add(earliestArrivedCheckin);
            DCILeadUtil.sendAutoResponseSMS(lstYourTurnCheckins, DCIConstants.ACTIVE);
        }
       
        if(!custAssigned) {
            customerInfo.message = 'There are no customers waiting in store to be assigned to you.';
        }
        return customerInfo;
    }
}
/** 
* This class contains the business logic for various actions performed on all DCI Retail Checkin Queue trigger events
**/
public inherited sharing class RetailCheckinQueueTriggerHelper {    
    /**
     * This method iterates over the dci records and performs necessary validations for desired operations
    **/
    public static TriggerHelper.DCITriggerMap checkPriorConditions(TriggerHelper.DCITriggerMap triggerMap, List<sObject> lstNewSObj, List<sObject> lstOldSObj, Map<Id,sObject> mapNewSObj, Map<Id,sObject> mapOldSObj) {
        for(sObject sObj: lstNewSObj) {
            RetailCheckinQueue__c newDci = (RetailCheckinQueue__c) sObj;
            RetailCheckinQueue__c oldDci;
            if(mapOldSObj != null && mapOldSObj.containsKey(newDci.id)) {
                oldDci = (RetailCheckinQueue__c) mapOldSObj.get(newDci.id);
                if(newDci.Owner__c != oldDci.Owner__c) {
                    if(oldDci.Owner__c != null)
                        triggerMap.dciToOwnerRemMap.put(newDci.id, oldDci.Owner__c);
                    if(newDci.Owner__c != null)
                        triggerMap.dciShareAdd.add(createDCIShareInstance( RetailConstants.LEAD_ACCESS_ALL, newDci.id, newDci.Owner__c));
                }
                if(newDci.Store__c != oldDci.Store__c) {
                    if(oldDci.StorePublicGroupId__c != null)
                        triggerMap.dciToOwnerRemMap.put(newDci.id, oldDci.StorePublicGroupId__c);
                    if(newDci.StorePublicGroupId__c != null)
                        triggerMap.dciShareAdd.add(createDCIShareInstance( RetailConstants.LEAD_ACCESS_ALL, newDci.id, newDci.StorePublicGroupId__c));
                }
                if(compareStatusCondition(newDci,oldDci)){
                    triggerMap.storeIdSet.add(newDci.Store__c);
                }
            } else {
                if(newDci.Owner__c != null)
                    triggerMap.dciShareAdd.add(createDCIShareInstance( RetailConstants.LEAD_ACCESS_ALL, newDci.id, newDci.Owner__c));
                if(newDci.StorePublicGroupId__c != null)
                    triggerMap.dciShareAdd.add(createDCIShareInstance( RetailConstants.LEAD_ACCESS_ALL, newDci.id, newDci.StorePublicGroupId__c));
            }
            
        }
        return triggerMap;
    }
    
    /**
     * This method takes the necesssary data from trigger map and performs various operations for the trigger context
    **/
    public static void performOperations(TriggerHelper.DCITriggerMap triggerMap, List<sObject> lstNewSObj, List<sObject> lstOldSObj, Map<Id,sObject> mapNewSObj, Map<Id,sObject> mapOldSObj) {
        if(triggerMap.dciShareAdd.size() > 0) {
            Database.insert(triggerMap.dciShareAdd, false);
        }
        if(triggerMap.dciToOwnerRemMap.size() > 0) {
            removeDCIShare(triggerMap);
        }
        updateAndValidateRepStatus(triggerMap, lstNewSObj, lstOldSObj, mapNewSObj, mapOldSObj);
        if(triggerMap.storeIdSet.size() > 0)
            DCISignageFutureClass.publishSignageEvents(triggerMap.storeIdSet);
    }
//Use to get the EWT SMS Settings from the metadata
static Map<String, String> getEWT_SMS_SettingsMap()
{
    Map<String, String> ewtSMSSettingsMap = new Map<String, String> ();
    
    for(EWT_SMS_Setting__mdt ewtSMSObj : [SELECT Id, MasterLabel, Value__c, DeveloperName FROM EWT_SMS_Setting__mdt]){
        ewtSMSSettingsMap.put(ewtSMSObj.DeveloperName, ewtSMSObj.Value__c);
    }
    
    return ewtSMSSettingsMap;
}

//This method is use to send the sms using queueable class
public static void sendEWTSMS(List<SObject> lstNewSObj, Map<Id, SObject> mapOldSObj){
    
    //fetching the EWT Sms settings from metadata using getEWT_SMS_SettingsMap method.
    Map<String, String> ewtSMSSettingsMap = getEWT_SMS_SettingsMap();
    //getting queue position from map
    String queuePositions = ewtSMSSettingsMap.get('Queue_Positions');
    //Getting threshold from map
    Integer thresholdMinite = Integer.valueOf(ewtSMSSettingsMap.get('EWT_Threshold'));
    
    List<RetailCheckinQueue__c> retailCheckInsWithIncreasedEWT = new List<RetailCheckinQueue__c>();
    List<RetailCheckinQueue__c> retailCheckInsWithDecreasedEWT = new List<RetailCheckinQueue__c>();
    Set<Id> increasedEWT = new Set<Id>();
    Set<Id> decreasedEWT = new Set<Id>();
    for(SObject sObj : lstNewSObj){
        //Type casting new sbject to RetailCheckinQueue__c object
        RetailCheckinQueue__c checkInQueueObj = (RetailCheckinQueue__c)sObj;
        
        //Type casting olddd sbject to RetailCheckinQueue__c object
        RetailCheckinQueue__c oldCheckInQueueObj = (RetailCheckinQueue__c)mapOldSObj.get(checkInQueueObj.Id);
        system.debug(queuePositions+' ::  '+checkIsInCorrectQueue(checkInQueueObj, queuePositions));
        if((checkInQueueObj.Status__c == RetailConstants.ARRIVED ||  checkInQueueObj.Status__c == RetailConstants.PENDING)
           && checkIsInCorrectQueue(checkInQueueObj, queuePositions) && !(oldCheckInQueueObj.QueuePosition__c < 1)
           && oldCheckInQueueObj.QueuePosition__c != checkInQueueObj.QueuePosition__c){
               if(getMinutesBetweenTwoDates(checkInQueueObj.DCICommunicatedStartTime__c, checkInQueueObj.DCIEstimatedStartTime__c) > thresholdMinite){
                   if(checkInQueueObj.DCICheckinType__c == 'Same Day' ||  checkInQueueObj.DCICheckinType__c == 'Future'){
                       retailCheckInsWithIncreasedEWT.add(checkInQueueObj);
                       increasedEWT.add(checkInQueueObj.Id);
                   }
               }
               else{
                   if(checkInQueueObj.DCICheckinType__c == 'Same Day' ||  checkInQueueObj.DCICheckinType__c == 'Future'){
                       retailCheckInsWithDecreasedEWT.add(checkInQueueObj);
                       decreasedEWT.add(checkInQueueObj.Id);
                   }
               }
           }
    }
    if(!decreasedEWT.isEmpty() || !increasedEWT.isEmpty())
        System.enqueueJob(new SendSMSEWTChangesQueable(increasedEWT,decreasedEWT));
    
    //Calling queueable class to send sms
    /* if(!retailCheckInsWithIncreasedEWT.isEmpty() || !retailCheckInsWithDecreasedEWT.isEmpty()){
System.enqueueJob(new SendEWTSMSQueueable(retailCheckInsWithIncreasedEWT, retailCheckInsWithDecreasedEWT));
}*/
    System.debug('retailCheckInsWithIncreasedEWT====' + retailCheckInsWithIncreasedEWT);
    System.debug('retailCheckInsWithDecreasedEWT===' + retailCheckInsWithDecreasedEWT);
}


public static Long getMinutesBetweenTwoDates(DateTime sourceDateTime, DateTime targetDateTime){
    Long minutes = 0;
    if(sourceDateTime!=null && targetDateTime!=null ){
    Long dt1Long = sourceDateTime.getTime();
    Long dt2Long = targetDateTime.getTime();
    Long milliseconds = dt2Long - dt1Long;
    Long seconds = milliseconds / 1000;
    minutes = seconds / 60;
    }
    return minutes;
}
    //Use to check if Retail Check In Queue record is in correct queue
    
    static Boolean checkIsInCorrectQueue(RetailCheckinQueue__c queueObject, String queuePositions)
    {
        Boolean isCorrectQueue = false;
        for(String queuePos : queuePositions.split('\\/')){
            if(queueObject.QueuePosition__c ==  Integer.valueOf(queuePos)){
                isCorrectQueue = true;
                break;
                
            }
        }
        return isCorrectQueue;
    }
    /**
     * This method is used to create DCI share instance with desired parameters
    **/
    public static RetailCheckinQueue__Share createDCIShareInstance(String accessLevel, Id dciId, Id userOrGroupId) {
        RetailCheckinQueue__Share dciShareRec = new RetailCheckinQueue__Share(
                                                                    AccessLevel = accessLevel, 
                                                                    ParentId = dciId,
                                                                    RowCause = Schema.RetailCheckinQueue__Share.RowCause.Manual,
                                                                    UserOrGroupId = userOrGroupId);
        return dciShareRec;
    }

    /**
     * This method is used to query and delete DCI share instance 
    **/
    private static void removeDCIShare(TriggerHelper.DCITriggerMap triggerMap) {
        List<RetailCheckinQueue__Share> deleteDciShareList = [SELECT id 
                                                                FROM RetailCheckinQueue__Share
                                                                WHERE ParentId IN :triggerMap.dciToOwnerRemMap.keyset() AND
                                                                UserOrGroupId IN :triggerMap.dciToOwnerRemMap.values()];
        if(deleteDciShareList.size() > 0) {
            Database.delete(deleteDciShareList);
        }
    }

    /**
     * This method is used to validate if the batch size is 1 and perform necessary operations accordingly
     * This method also avoids recrussion by using the statuc flag TriggerHelper.isSecondRunDciTrigger
     */
    public static void updateAndValidateRepStatus(TriggerHelper.DCITriggerMap triggerMap, List<sObject> lstNewSObj, List<sObject> lstOldSObj, Map<Id,sObject> mapNewSObj, Map<Id,sObject> mapOldSObj) {
        if(!TriggerHelper.isSecondRunDciTrigger && lstNewSObj.size() == 1) {
            TriggerHelper.isSecondRunDciTrigger = true;
            
            List<RetailCheckinQueue__c> dciList = (List<RetailCheckinQueue__c>) lstNewSObj;
            if(dciList[0] != null && dciList[0].Store__c != null) {
                if(doStatusCheck(dciList[0].Store__c)) 
                    updateRepStatus(dciList[0].Store__c);
                sendThresholdCrossedNotification(dciList[0].Store__c);
            }
        }
    }

    /**
     * This method is used to perform the automated Rep offline status followed by Queue update with EWT
     * 
    */
    public static void updateRepStatus(String storeId) {
        dateTime currentTime = system.now();
        dateTime thresholdTime = null;
        List<EmployeeStoreRetail__c> updateEmpStoreList = new List<EmployeeStoreRetail__c>();
        if(RetailCustomSetting__c.getInstance('DCIRepAllowedIdleTime')!=null && String.isNotBlank(RetailCustomSetting__c.getInstance('DCIRepAllowedIdleTime').KeyValue__c)){
            Integer noMin = integer.valueof(RetailCustomSetting__c.getInstance('DCIRepAllowedIdleTime').KeyValue__c);
            thresholdTime = currentTime.addMinutes(noMin);
            updateEmpStoreList = [SELECT Id, Name,IsCurrentlyAvailable__c, Store__c, LastModifiedDate, DCIPresenceStatus__c FROM EmployeeStoreRetail__c WHERE DCIPresenceStatus__c = :DCIConstants.ONLINE AND LastModifiedDate <= :thresholdTime AND Store__c = :storeId];
            for (EmployeeStoreRetail__c updateRecord : updateEmpStoreList) {
                updateRecord.DCIPresenceStatus__c = DCIConstants.OFFLINE;
                updateRecord.IsCurrentlyAvailable__c = false;
                //updateRecord.IsLoginStore__c = false;
            }
        }
        
        if (updateEmpStoreList != null && updateEmpStoreList.size() > 0) {
            try {
                update updateEmpStoreList;
                if (DCIConstants.EWTCalculationMethod == DCIConstants.TUF) { // DM Added TUF
                    DCIUtil.updateQueueBulkifyMinutesUntilFree(new Set<Id>{storeId}, 0, false, false);
                }else {
                    DCIUtil.updateQueue(storeId, 0,  false, false, 'Rep went offline');
                }           
            } 
            catch (Exception e) {
                System.debug('An error occurred updating employees that have gone offline. ' + e.getMessage());
            }
        }
    }
    
    public static Boolean doStatusCheck(String storeId) {
        if (RetailCustomSetting__c.getInstance('DCICustomerWaitStatusCheckBuffer') != null && String.isNotBlank(RetailCustomSetting__c.getInstance('DCICustomerWaitStatusCheckBuffer').KeyValue__c)) {
            Integer noMin = integer.valueof(RetailCustomSetting__c.getInstance('DCICustomerWaitStatusCheckBuffer').KeyValue__c);
            List<RetailCheckinQueue__c> dciArrivedList = [SELECT Id, Status__c, DCITimeWaiting__c 
                                                          FROM RetailCheckinQueue__c 
                                                          WHERE Status__c = :DCIConstants.INSTORE AND Store__c = :storeId];
            
            for (RetailCheckinQueue__c dciRecord : dciArrivedList) {
                if (dciRecord.DCITimeWaiting__c != null && dciRecord.DCITimeWaiting__c.substringBefore(' ') != null && !string.isBlank(dciRecord.DCITimeWaiting__c.substringBefore(' '))) {
                    if (Integer.valueOf(dciRecord.DCITimeWaiting__c.substringBefore(' ')) > noMin) {
                        return true;
                    }
                }       
            }
        }
        
        return false;
    }

    public static void sendThresholdCrossedNotification(String storeId)
    {
        if (RetailCustomSetting__c.getInstance('DCINotificationFlagSentBuffer') != null && String.isNotBlank(RetailCustomSetting__c.getInstance('DCINotificationFlagSentBuffer').KeyValue__c))
        {
            //List<RetailCheckinQueue__c> dciList = (List<RetailCheckinQueue__c>) lstNewSObj;
            //Id storeId=dciList[0].store__c;
           
            Integer noMin = integer.valueof(RetailCustomSetting__c.getInstance('DCINotificationFlagSentBuffer').KeyValue__c);
        
            List<RetailCheckinQueue__c> dciArrivedList=[Select id,DCIMaximum_EWT__c,Notification_1_sent__c,Notification_2_sent__c, 
                                                        DCITimeWaiting__c, lead__r.CustomerRequestedRep__c from RetailCheckinQueue__c where Status__c=:DCIConstants.INSTORE 
                                                        and Store__c=:storeId];
            
            String notificationTitle = System.Label.Customer_Waiting_Title;
            String notificationBody = System.Label.Customer_Waiting_Body;
            List<RetailCheckinQueue__c> updatedDCI=new List<RetailCheckinQueue__c>();
            

            for(RetailCheckinQueue__c dciRecord : dciArrivedList)
            {
                if(dciRecord.lead__r.CustomerRequestedRep__c == null){
                    Integer thresholdLimit=0;
                    if(dciRecord.DCIMaximum_EWT__c != null)
                       thresholdLimit=Integer.valueOf(dciRecord.DCIMaximum_EWT__c)+noMin ;

                    Boolean sendSecondNotification=true;

                    if (dciRecord.DCITimeWaiting__c != null && dciRecord.DCITimeWaiting__c.substringBefore(' ') != null && !string.isBlank(dciRecord.DCITimeWaiting__c.substringBefore(' '))) 
                    {                
                        Integer intDCITimeWaiting=Integer.valueOf(dciRecord.DCITimeWaiting__c.substringBefore(' '));

                        if((intDCITimeWaiting > thresholdLimit) && dciRecord.Notification_1_sent__c==false)
                        {
                            //NotificationsHandler.sendWaitingNotification(notificationTitle, notificationBody,storeId, dciArrivedList.size(),dciRecord);
                            sendSecondNotification=false;
                            dciRecord.Notification_1_sent__c=true;
                            updatedDCI.add(dciRecord);
                        }
                        
                        else if((intDCITimeWaiting > thresholdLimit+noMin) && sendSecondNotification==true && dciRecord.Notification_1_sent__c==true &&  dciRecord.Notification_2_sent__c==false)
                        {
                            //NotificationsHandler.sendWaitingNotification(notificationTitle, notificationBody,storeId, dciArrivedList.size(),dciRecord);
                            dciRecord.Notification_2_sent__c=true;
                            updatedDCI.add(dciRecord);
                            notificationTitle = System.Label.Customer_Waiting_Title_Not2;
                            
                        }
                    }
                }
            }
            
            if(updatedDCI.size()>0){
                Database.update(updatedDCI,false);
                NotificationsHandler.sendWaitingNotification(notificationTitle, notificationBody,storeId, dciArrivedList.size());
            }
        }
    }

    /*
    * This method checks if checkin records are eligible to publish Platform events
    *  
    public static void checkCheckinConditionsSignage(List<sObject> lstNewSObj, List<sObject> lstOldSObj, Map<Id,sObject> mapNewSObj, Map<Id,sObject> mapOldSObj) {
        Set<ID> storeIdSet = new Set<ID>();
       for(sObject sObj :lstNewSObj ) {
           RetailCheckinQueue__c checkinRecord = (RetailCheckinQueue__c) sObj;  
           if(compareStatusCondition(checkinRecord,(Map<Id,RetailCheckinQueue__c>) mapOldSObj)){
               storeIdSet.add(checkinRecord.Store__c);
           }
       }
        
       DCISignageFutureClass.publishSignageEvents(storeIdSet);
    }
   
    /*
    * This method compares statues of checkin records to publish Platform events
    */  
    public static Boolean compareStatusCondition(RetailCheckinQueue__c newRecord,  RetailCheckinQueue__c oldRecord) {
        Boolean publishEvent = false;
        if(oldRecord.Status__c != newRecord.Status__c) {
            //Pending --> Arrived (only for Same Day)
            if(newRecord.Status__c == DCIConstants.INSTORE && oldRecord.Status__c == DCIConstants.PENDING && newRecord.DCICheckinType__c == DCIConstants.SAMEDAY)
                publishEvent = true;
            //Arrived --> Pending
            if(newRecord.Status__c == DCIConstants.PENDING && oldRecord.Status__c == DCIConstants.INSTORE)  
                publishEvent = true;
            //Engaged --> No Show
            if(newRecord.Status__c == DCIConstants.NOSHOW && oldRecord.Status__c == DCIConstants.ACTIVE)  
                publishEvent = true;
            //Engaged --> Completed
            if(newRecord.Status__c == DCIConstants.COMPLETED && oldRecord.Status__c == DCIConstants.ACTIVE)  
                publishEvent = true;
        }
        return publishEvent;
    }
    public static void populateLastModifiedTimeZone(List<sObject> lstNewSObj, Map<Id,sObject> mapOldSObj) {
        Set<Id> storeIdSet = new Set<Id>();
        List<RetailCheckinQueue__c> dciList = (List<RetailCheckinQueue__c>) lstNewSObj;
        Map<Id, RetailCheckinQueue__c> oldMap = (Map<Id, RetailCheckinQueue__c>) mapOldSObj;
        Set<Id> recordIdSet = new Set<Id>();
        
        for (RetailCheckinQueue__c dciRecord : dciList) {
            if (!storeIdSet.contains(dciRecord.Store__c)) {
                storeIdSet.add(dciRecord.Store__c);
            }
        }
        Map<id,string> strIdTimezomeMap = new Map<id,string>();
        
        if(!storeIdSet.isEmpty()){
            for(store__c str:[select id,TimeZone__c from store__c where id in:storeIdSet]){
                if(str.TimeZone__c!=null && str.TimeZone__c!='')
                    strIdTimezomeMap.put(str.id,str.TimeZone__c);
            }
        }
        Schema.SObjectType objType = RetailCheckinQueue__c.getSObjectType(); 
        Map<String, Schema.SObjectField> mapFields = Schema.SObjectType.RetailCheckinQueue__c.fields.getMap(); 
        for(RetailCheckinQueue__c rec : dciList){
            RetailCheckinQueue__c oldRec = oldMap.get(rec.Id);
            for (String str : mapFields.keyset()) 
            {
                if(rec.get(str) != oldRec.get(str))
                { 
                    if(!strIdTimezomeMap.isEmpty() && strIdTimezomeMap.containskey(rec.Store__c))
                        rec.LastModifiedDateLocalTz__c =  String.valueof(system.now().format('yyyy-MM-dd HH:mm:ss', strIdTimezomeMap.get(rec.Store__c)));
                }
            }
        }
        
    }

    public static void populateMinutesUntilFree(List<sObject> lstNewSObj, Map<Id,sObject> mapOldSObj) {
        Set<Id> storeIdSet = new Set<Id>();
        List<RetailCheckinQueue__c> dciList = (List<RetailCheckinQueue__c>) lstNewSObj;
        Map<Id, RetailCheckinQueue__c> oldMap = (Map<Id, RetailCheckinQueue__c>) mapOldSObj;
        Set<Id> recordIdSet = new Set<Id>();
        
        for (RetailCheckinQueue__c dciRecord : dciList) {
            if (!storeIdSet.contains(dciRecord.Store__c)) {
                storeIdSet.add(dciRecord.Store__c);
            }
            recordIdSet.add(dciRecord.Lead__c);
        }
        
        Map<Id, Lead> reasonForVisitMap = new Map<Id, Lead>([SELECT Id, ReasonForLeaving__c FROM Lead WHERE Id IN :recordIdSet]);
        map<String, Decimal> typeToHandleTimeMap = DCIConstants.getStoreHandleTimeMap(storeIdSet);
        
        //Populating when a record becomes engaged
        for (RetailCheckinQueue__c dciRecord : dciList) {
            if (dciRecord.Status__c == DCIConstants.Active && oldMap == null && dciRecord.Lead__c != null) {
                Decimal handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, reasonForVisitMap.get(dciRecord.Lead__c).ReasonForLeaving__c, dciRecord.Store__c);
                dciRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue()); 
            } else if (dciRecord.Status__c == DCIConstants.ACTIVE && oldMap != null && oldMap.get(dciRecord.Id).Status__c == DCIConstants.INSTORE) {
                Decimal handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, reasonForVisitMap.get(dciRecord.Lead__c).ReasonForLeaving__c, dciRecord.Store__c);
                dciRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue());
            }
        }
    }
    public static void populateInitialQP(List<sObject> lstNewSObj) {
        List<RetailCheckinQueue__c> dciList = (List<RetailCheckinQueue__c>) lstNewSObj;
        
        for (RetailCheckinQueue__c dciRecord : dciList) {
            if (dciRecord.QueuePosition__c != null && dciRecord.DCIInitialQueuePosition__c == null) {
                dciRecord.DCIInitialQueuePosition__c = dciRecord.QueuePosition__c;
            }
        }
    }
    
    /**************************************************************************************
    * @Description  This method sets the initial max EWT value when an EWT is communicated 
    * 				to a customer for the first time. Value is needed for reporting.
    * 
    * @Assumption	1) The Initial Maximum EWT of the customer matters for reporting when a
    * 				   customer is communicated a start time
    **************************************************************************************/
    public static void populateInitialMaxEWT(List<sObject> lstNewSObj, Map<Id, sObject> oldsObjMap) {
        List<RetailCheckinQueue__c> dciList = (List<RetailCheckinQueue__c>) lstNewSObj;
        Map<Id, RetailCheckinQueue__c> oldMap = (Map<Id, RetailCheckinQueue__c>) oldsObjMap;
        
        for (RetailCheckinQueue__c dciRecord : dciList) {
            if (oldMap == null || oldMap.size() == 0) {
                if (dciRecord.DCICommunicatedStartTime__c != null) {
                    dciRecord.InitialMaximumEWT__c = dciRecord.DCIMaximum_EWT__c;
                } else if (dciRecord.Status__c == DCIConstants.ACTIVE) { // if record is inserted as active auto set the initial max ewt to the max ewt value (will be same, should be '0')
                    dciRecord.InitialMaximumEWT__c = dciRecord.DCIMaximum_EWT__c;
                }
            } else {
                if (oldMap.get(dciRecord.Id).DCICommunicatedStartTime__c == null && dciRecord.DCICommunicatedStartTime__c != null) {
                    dciRecord.InitialMaximumEWT__c = dciRecord.DCIMaximum_EWT__c;
                }
            }
        }
    }
}
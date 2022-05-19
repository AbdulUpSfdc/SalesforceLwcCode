/*
* This Batch Class will be utilized for the following business scenarios:
* 		- Alert Future Dated Check Ins when they are ~1 hour and ~15 minutes away from their check in time by sms
* @Author : Daniel Muldoon
*/
public without sharing  class DCIRetailFutureBatch implements Database.Batchable<sObject>, Database.Stateful {
    public datetime currentTime;
    public Set<String> dciRecordIds = new Set<String>();
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        currentTime = system.now();
        datetime maxHourAlertTime = currentTime.addMinutes(65); // Add 5 minute buffer to account for potential delay in batch start
        datetime minHourAlertTime = currentTime.addMinutes(40); // Add 5 minute buffer to account for potential delay in batch start
        datetime maxFifteenMinAlertTime = currentTime.addMinutes(20); // Add 5 minute buffer to account for potential delay in batch start
        List<String> properStatuses = new List<String>{DCIConstants.PENDING, DCIConstants.INSTORE};

        string query='SELECT Id, Lead__c, Lead__r.MobilePhone, Store__c,Store__r.TimeZone__c,Store__r.Name,Store__r.Address1__c, Status__c, CheckInTime__c, DCICheckinType__c ,ArrivingTime__c, EstimatedWaitTime__c,';
        query += ' Store__r.City__c,Store__r.State__c,Store__r.Zip__c,Batch_SMS_Status__c, CreatedDate, DCIBOPISOrder__c, Lead__r.ReasonForLeaving__c, DCIMaximum_EWT__c, DCIMinimum_EWT__c, DCITimeWaiting__c FROM RetailCheckinQueue__c';
        query += ' where QueuePosition__c = null and DCICheckinType__c = \'Future\' AND Lead__r.SmsConsent__c=\'Yes\' AND Status__c IN :properStatuses AND ';
        query += '((CheckInTime__c >= :minHourAlertTime AND CheckInTime__c <= :maxHourAlertTime) OR (CheckInTime__c <= :maxFifteenMinAlertTime AND CheckInTime__c >= :currentTime)) ORDER BY Store__c, CreatedDate';
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<RetailCheckinQueue__c> scope){
        try {
            //Get map of stores with members in their queue from the returned list of RetailCheckIns
            Set<Id> storeIds = new Set<Id>();
            for (RetailCheckinQueue__c dciRecord : scope) {
                if (dciRecord.Store__c != null) {
                    if (!storeIds.contains(dciRecord.Store__c)) {
                        storeIds.add(dciRecord.Store__c);
                    }
                    dciRecordIds.add(dciRecord.Id);
                }
            }
            
            //Get records currently associated with that store
            Map<Id, List<RetailCheckinQueue__c>> storeToCurrentQueueItems = new Map<Id, List<RetailCheckinQueue__c>>();
            if (storeIds.size() > 0) {
                for (RetailCheckinQueue__c dciRecord : [SELECT Id, Lead__c, Lead__r.ReasonForLeaving__c, Store__c, DCIMaximum_EWT__c, DCIMinimum_EWT__c, DCIBOPISOrder__c, DCICheckinType__c, QueuePosition__c, EstimatedWaitTime__c, DCITimeWaiting__c FROM RetailCheckinQueue__c WHERE Status__c IN (:DCIConstants.PENDING, :DCIConstants.INSTORE) AND QueuePosition__c != null AND Store__c IN :storeIds AND Id NOT IN :dciRecordIds ORDER BY QueuePosition__c]) {
                    if (storeToCurrentQueueItems.containsKey(dciRecord.Store__c)) {
                        List<RetailCheckinQueue__c> currentQueueMembers = storeToCurrentQueueItems.get(dciRecord.Store__c);
                        currentQueueMembers.add(dciRecord);
                        storeToCurrentQueueItems.put(dciRecord.Store__c, currentQueueMembers);
                    } else {
                        List<RetailCheckinQueue__c> currentQueueMembers = new List<RetailCheckinQueue__c>();
                        currentQueueMembers.add(dciRecord);
                        storeToCurrentQueueItems.put(dciRecord.Store__c, currentQueueMembers);
                    }
                }
            }
            
            Map<Id, RetailCheckinQueue__c> dciRecordUpdateMap = new Map<Id, RetailCheckinQueue__c>();
            Datetime updateQueuePositionTime = currentTime.addMinutes(30);
            for (RetailCheckinQueue__c dciRecord : scope) {
                // checking filters
                if (dciRecord.Store__c != NULL && dciRecord.Lead__r.MobilePhone != null && dciRecord.CheckInTime__c < updateQueuePositionTime) {
                    //Generate Update List By Placing scope in appropriate places in store queue, and update existing queue positions
                    if (storeToCurrentQueueItems.containsKey(dciRecord.Store__c)) {
                        Integer newQueuePosition = 0;
                        Boolean updateFollowingQueueRecords = false;
                        List<RetailCheckinQueue__c> storeQueueList = storeToCurrentQueueItems.get(dciRecord.Store__c);
                        for (Integer i = 0; i < storeQueueList.size(); i++) {
                            if (updateFollowingQueueRecords) {
                                storeQueueList[i].QueuePosition__c++;
                                dciRecordUpdateMap.put(storeQueueList[i].Id, storeQueueList[i]);
                            } else if (dciRecord.DCIBOPISOrder__c != null && storeQueueList[i].DCIBOPISOrder__c == null) {
                                dciRecord.QueuePosition__c = storeQueueList[i].QueuePosition__c;
                                storeQueueList.add(i, dciRecord);
                                updateFollowingQueueRecords = true;
                            } else if (storeQueueList[i].DCIBOPISOrder__c == null && storeQueueList[i].DCICheckinType__c != DCIConstants.FUTURE) {
                                dciRecord.QueuePosition__c = storeQueueList[i].QueuePosition__c;
                                storeQueueList.add(i, dciRecord);
                                updateFollowingQueueRecords = true;
                            } else if (storeQueueList.size() == i + 1) {
                                //Place dci record at end of queue
                                dciRecord.QueuePosition__c = i + 2; // List: {record1}, i = 0, i+1 == list size, queue position should be 2 == i + 2
                                storeQueueList.add(dciRecord);
                                break;
                            }
                        }
                        storeToCurrentQueueItems.put(dciRecord.Store__c, storeQueueList);
                    } else {
                        dciRecord.QueuePosition__c = 1;
                        List<RetailCheckinQueue__c> storeQueueList = new List<RetailCheckinQueue__c>{dciRecord};
                            storeToCurrentQueueItems.put(dciRecord.Store__c, storeQueueList);
                    }
                }                      
            }
            
            //Section: Update EWT's of records in update map
            List<RetailCheckinQueue__c> dciUpdateList = new List<RetailCheckinQueue__c>();
            List<Store__c> storeUpdateList = new List<Store__c>();
            Map<Id,Store__c> storeMap = new Map<Id,Store__c> ([SELECT id, DCIEstimatedWaitTime__c, DCIShortestTUF__c, DCIStoreRepActiveCapacity__c, DCIStoreRepCurrentCapacity__c, DCILeadsinCheckinQueue__c FROM Store__c WHERE id IN:storeToCurrentQueueItems.keySet()]);
            map<String, Decimal> typeToHandleTimeMap = DCIConstants.getStoreHandleTimeMap(storeToCurrentQueueItems.keySet());
            Map<Id, Map<Id, RetailCheckinQueue__c>> engagedQueueMap = DCIUtil.getEngagedQueue(storeToCurrentQueueItems.keySet());
            for (Id storeId : storeToCurrentQueueItems.keySet()) {
                //Need returned:
                //List of Stores to Update
                //List of RetailCheckinQueue records to update
                Map<String,Object> updateMap;
                if (DCIConstants.EWTCalculationMethod == DCIConstants.TUF) {
                    updateMap = DCIUtil.updateQueueBulkifyTUFFuture(storeMap.get(storeId), engagedQueueMap, typeToHandleTimeMap, storeToCurrentQueueItems.get(storeId), 'Future Batch Processed');
                } else {
                    updateMap = DCIUtil.updateQueue(storeMap.get(storeId), typeToHandleTimeMap, storeToCurrentQueueItems.get(storeId), 'Future Batch Processed');
                }
                if (updateMap != null && updateMap.size() > 0) {
                    Object returnedDCIUpdateRecordsObject = updateMap.get('dciRecordsToUpdate');
                    if (returnedDCIUpdateRecordsObject != null) {
                        List<RetailCheckinQueue__c> returnedDCIUpdateRecords = (List<RetailCheckinQueue__c>) returnedDCIUpdateRecordsObject;
                        dciUpdateList.addAll(returnedDCIUpdateRecords);
                    }
                    
                    Object returnedStoreObject = updateMap.get('storeRecordToUpdate');
                    if (returnedStoreObject != null) {
                        Store__c returnedStoreUpdateRecord = (Store__c) returnedStoreObject;
                        storeUpdateList.add(returnedStoreUpdateRecord);
                    }
                }
            }
            
            //Update Queues and Store
            if (dciUpdateList.size() > 0) {
                update dciUpdateList;
            }
            
            if (storeUpdateList.size() > 0) {
                update storeUpdateList;
            }
        } catch(Exception e) {
            //BWC_ExceptionUtils.handleException(e, true);
        }
    }
    
    public void finish(Database.BatchableContext bc){
        if (!Test.isRunningTest()) {
            //Schedule the batch to run 15 minutes in the future
            System.scheduleBatch(new DCIRetailFutureBatch(), 'DCI Future Queue Assignments', 15);
            Database.executeBatch(new DCIRetailFutureAlertBatch(currentTime, dciRecordIds),70);
        }
    }
}
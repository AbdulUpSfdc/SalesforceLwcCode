/**
* This class contains the various utility methods for Digital Checkin  functionality
* @Author - Reshma Jewrani, Alisha Mundaden 
*/
public without sharing class DCIUtil {
    public static string repId = '';
    public static void updateQueueBulkifyMinutesUntilFree(Set<Id> storeIds, Integer sequence, Boolean updateQPosition, Boolean qDecrement) { // DM Added TUF
        if (storeIds != null) {
            Map<Id,Store__c> storeMap = new Map<Id,Store__c> ([SELECT id, DCIShortestTUF__c, DCIEstimatedWaitTime__c, DCIStoreRepActiveCapacity__c, DCIStoreRepCurrentCapacity__c, DCILeadsinCheckinQueue__c FROM Store__c WHERE id IN:storeIds WITH SECURITY_ENFORCED]);
            system.debug('1111111'+storeMap);
            if (storeMap !=  null) {
                Map<string,DateTime> shortestTUFMap = new  Map<string,DateTime>();
                map<String, Decimal> typeToHandleTimeMap = DCIConstants.getStoreHandleTimeMap(storeIds);
                system.debug('2222222'+typeToHandleTimeMap);
                List<RetailCheckinQueue__c> pendingQueue = getPendingQueueBulkify(storeIds, 0);
                Map<Id, Map<Id, RetailCheckinQueue__c>> engagedQueueMap = getEngagedQueue(storeIds);
                Map<Id,List<RetailCheckinQueue__c>> quesizeMap = new Map<Id,List<RetailCheckinQueue__c>> ();
                
                //Iterate through pending queue and assign values
                for (RetailCheckinQueue__c pendingRecord : pendingQueue) {
                    //Get handleTime for specific pending check-in
                    Decimal handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, pendingRecord.Lead__r.ReasonForLeaving__c, pendingRecord.Store__c);
                    system.debug('3333333'+handleTime);
                    if (pendingRecord.QueuePosition__c > sequence && updateQPosition) {
                        pendingRecord.QueuePosition__c = pendingRecord.QueuePosition__c - 1;
                    } else if (pendingRecord.QueuePosition__c > sequence && qDecrement) {
                        pendingRecord.QueuePosition__c = pendingRecord.QueuePosition__c + 1;
                    }
                    
                    Store__c recordStore = storeMap.get(pendingRecord.Store__c);
                    system.debug('4444444'+recordStore);
                    Map<Id, RetailCheckinQueue__c> engagedStoreQueueMap;
                    
                    //Rep A, B = Engaged, C = Online
                    //DCI A, B = Engaged, C = QP1
                    //StoreRepCurrentCapacity == 1, Queue position == 1
                    if(recordStore.DCIStoreRepCurrentCapacity__c > 0 && pendingRecord.QueuePosition__c <= recordStore.DCIStoreRepCurrentCapacity__c){
                        pendingRecord.EstimatedWaitTime__c = 0;
                        pendingRecord.DCIEstimatedStartTime__c = System.Now();
                        //Update comparison map with new time until free value
                        if (engagedQueueMap.containsKey(pendingRecord.Store__c)) {
                            //TUF = Engaged Start Time + HandleTime
                            //engagedStoreQueueMap = <A: {timeUntilFree = 11:52}, B: {timeUntilFree=12:02}, C: {timeUntilFree=12:22}>
                            //Pending Queue: <a, b, c>
                            //A gets processed
                            //A handleTime = 30; EWT: 27; lastEWT = 27
                            //engagedStoreQueueMap = <1, {timeUntilFree = 12:32}; 2, {timeUntilFree=12:02}>
                            //B handleTime = 40; EWT: 37; lastEWT = 37
                            //engagedStoreQueueMap = <1, {timeUntilFree = 12:32}; 2, {timeUntilFree=12:42}>
                            //C handleTime = 30; EWT: 64; lastEWT = 64
                            //engagedStoreQueueMap = Store A Engaged Queue = <1, {timeUntilFree = 1:02}; 2, {timeUntilFree=12:42}>
                            //Checkin D is BOPIS is created
                            engagedStoreQueueMap = engagedQueueMap.get(pendingRecord.Store__c);
                            pendingRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue()); //Time Until Free can remain being set here because it will be officially set when the record becomes engaged. Future iterations will reset this value as well
                            engagedStoreQueueMap.put(pendingRecord.Id, pendingRecord);
                            engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                        } else {
                            engagedStoreQueueMap = new Map<Id, RetailCheckinQueue__c>();
                            pendingRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue()); //Time Until Free can remain being set here because it will be officially set when the record becomes engaged. Future iterations will reset this value as well
                            engagedStoreQueueMap.put(pendingRecord.Id, pendingRecord);
                            engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                        }
                    } else {
                        //If there are records engaged at store, find shortest wait duration from records, update EWT, update shortest wait duration map
                        if (engagedQueueMap.containsKey(pendingRecord.Store__c)) {
                            Datetime shortestWaitDuration;
                            Id shortestWaitRecordId;
                            //find shortest wait duration
                            for (RetailCheckinQueue__c existingRecord : engagedQueueMap.get(pendingRecord.Store__c).values()) {
                                //engagedStoreQueueMap = <1, {timeUntilFree = 11:22}; 2, {timeUntilFree=11:32}>
                                System.debug('*shortestWaitDuration: ' + shortestWaitDuration);
                                System.debug('*existing wiat record in engagedQueueMap: ' + existingRecord.DCITimeUntilFree__c);
                                if (shortestWaitDuration == null) {
                                    shortestWaitDuration = existingRecord.DCITimeUntilFree__c;
                                    shortestWaitRecordId = existingRecord.Id;
                                } else {
                                    Boolean boolValue = shortestWaitDuration > existingRecord.DCITimeUntilFree__c;
                                    System.debug('* shortestWaitDuration > existingRecord.DCITimeUntilFree__c: ' + boolValue);
                                    
                                    if (shortestWaitDuration > existingRecord.DCITimeUntilFree__c) {
                                        shortestWaitDuration = existingRecord.DCITimeUntilFree__c;
                                        shortestWaitRecordId = existingRecord.Id;
                                    }
                                }
                            }
                            
                            //shortestWaitDuration = 11:22
                            
                            //Set EWT to shortest wait duration
                            Long minutes = (shortestWaitDuration.getTime() - System.now().getTime()) / 60000;
                            pendingRecord.EstimatedWaitTime__c = minutes < 0 ? 0 : minutes.intValue() + 1;
                            pendingRecord.DCIEstimatedStartTime__c =  pendingRecord.EstimatedWaitTime__c==0?System.Now():shortestWaitDuration;
                            if(pendingRecord.DCIMaximum_EWT__c < pendingRecord.EstimatedWaitTime__c + Double.valueOf(pendingRecord.DCITimeWaiting__c.replaceall('min',''))){
                                pendingRecord.DCIMaximum_EWT__c = pendingRecord.EstimatedWaitTime__c + Double.valueOf(pendingRecord.DCITimeWaiting__c.replaceall('min',''));
                                pendingRecord.DCITotalRepCount__c = recordStore.DCIStoreRepActiveCapacity__c;
                                pendingRecord.DCIAvailableRepCount__c = recordStore.DCIStoreRepCurrentCapacity__c;
                            }
                            if(pendingRecord.DCIMinimum_EWT__c > pendingRecord.EstimatedWaitTime__c){
                                pendingRecord.DCIMinimum_EWT__c = pendingRecord.EstimatedWaitTime__c;
                            }
                            
                            pendingRecord.LastEWTUpdated__c =  System.now();
                            
                            //Update comparison map with new time until free value (add shortest wait duration to shortest time until free)
                            //engagedStoreQueueMap = <1, {timeUntilFree = 11:22}; 2, {timeUntilFree=11:32}>
                            engagedStoreQueueMap = engagedQueueMap.get(pendingRecord.Store__c);
                            RetailCheckinQueue__c utilizedDCIRecord = engagedStoreQueueMap.get(shortestWaitRecordId);
                            //This should be handle Time
                            utilizedDCIRecord.DCITimeUntilFree__c = utilizedDCIRecord.DCITimeUntilFree__c.addMinutes(handleTime.intValue());
                            engagedStoreQueueMap.put(shortestWaitRecordId, utilizedDCIRecord);
                            engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                        } else {
                            //If there are not any records engaged at the current store, and the check-in is greater than the amount of available reps
                            //Set EWT, update engaged store queue map
                            pendingRecord.EstimatedWaitTime__c = 0;
                            pendingRecord.DCIEstimatedStartTime__c = System.Now();
                            if(pendingRecord.DCIMaximum_EWT__c < pendingRecord.EstimatedWaitTime__c + Double.valueOf(pendingRecord.DCITimeWaiting__c.replaceall('min',''))){
                                pendingRecord.DCIMaximum_EWT__c = pendingRecord.EstimatedWaitTime__c + Double.valueOf(pendingRecord.DCITimeWaiting__c.replaceall('min',''));
                                pendingRecord.DCITotalRepCount__c = recordStore.DCIStoreRepActiveCapacity__c;
                                pendingRecord.DCIAvailableRepCount__c = recordStore.DCIStoreRepCurrentCapacity__c;
                            }
                            if(pendingRecord.DCIMinimum_EWT__c > pendingRecord.EstimatedWaitTime__c){
                                pendingRecord.DCIMinimum_EWT__c = pendingRecord.EstimatedWaitTime__c;
                            }
                            
                            pendingRecord.LastEWTUpdated__c =  System.now();
                            engagedStoreQueueMap = new Map<Id, RetailCheckinQueue__c>();
                            pendingRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue());
                            engagedStoreQueueMap.put(pendingRecord.Id, pendingRecord);
                            engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                        }
                    }
                    
                    
                    List<RetailCheckinQueue__c> storePendingQueue = quesizeMap.get(pendingRecord.Store__c);
                    if(storePendingQueue == null){
                        storePendingQueue = new List<RetailCheckinQueue__c>();
                    }
                    storePendingQueue.add(pendingRecord);
                    quesizeMap.put(pendingRecord.Store__c,storePendingQueue);
                    pendingRecord.DCIEWTCalculationType__c =  DCIConstants.TUF;
                }
                
                update pendingQueue;
                for(Store__c store: storeMap.values()){
                    DateTime shortestTUF;
                    
                    if (engagedQueueMap.containsKey(store.Id)) {
                        if(store.DCIStoreRepActiveCapacity__c > engagedQueueMap.get(store.Id).size()){
                            store.DCIShortestTUF__c = System.now();
                        }
                        else{
                            for (RetailCheckinQueue__c dciRecord : engagedQueueMap.get(store.Id).values()) {
                                if (shortestTUF == null) {
                                    shortestTUF = dciRecord.DCITimeUntilFree__c;
                                } else {
                                    shortestTUF = shortestTUF > dciRecord.DCITimeUntilFree__c ? dciRecord.DCITimeUntilFree__c : shortestTUF;
                                }
                            }
                        }
                    } else {
                        store.DCIShortestTUF__c = System.now();
                    }
                    if(shortestTUF!= null){
                        store.DCIShortestTUF__c =  shortestTUF;  
                    }else {
                        store.DCIShortestTUF__c = System.now();
                    }
                    
                    store.DCIEstimatedWaitTime__c = ((store.DCIShortestTUF__c.getTime() - System.now().getTime()) / 60000) > 0 ? ((store.DCIShortestTUF__c.getTime() - System.now().getTime()) / 60000) + 1: 0;
                    if(quesizeMap != null && quesizeMap.get(store.Id) != null){
                        store.DCILeadsinCheckinQueue__c = quesizeMap.get(store.Id).size();
                    } else {
                        store.DCILeadsinCheckinQueue__c = 0;
                    }
                }
                if(Schema.sObjectType.Store__c.fields.DCIShortestTUF__c.isUpdateable() &&
                   Schema.sObjectType.Store__c.fields.DCILeadsinCheckinQueue__c.isUpdateable()){
                       update storeMap.values();
                   }
            }
        }
    }
    
    public static void updateQueueBulkifyMinutesUntilFree(Set<Id> storeIds, Integer sequence, Boolean updateQPosition, Boolean qDecrement, String dciChangeReason) { // DM Added TUF
        if (storeIds != null) {
            Map<Id,Store__c> storeMap = new Map<Id,Store__c> ([SELECT id, DCIShortestTUF__c, DCIEstimatedWaitTime__c, DCIStoreRepActiveCapacity__c, DCIStoreRepCurrentCapacity__c, DCILeadsinCheckinQueue__c FROM Store__c WHERE id IN:storeIds WITH SECURITY_ENFORCED]);
            system.debug('1111111'+storeMap);
            if (storeMap !=  null) {
                Map<string,DateTime> shortestTUFMap = new  Map<string,DateTime>();
                map<String, Decimal> typeToHandleTimeMap = DCIConstants.getStoreHandleTimeMap(storeIds);
                system.debug('2222222'+typeToHandleTimeMap);
                List<RetailCheckinQueue__c> pendingQueue = getPendingQueueBulkify(storeIds, 0);
                Map<Id, Map<Id, RetailCheckinQueue__c>> engagedQueueMap = getEngagedQueue(storeIds);
                Map<Id,List<RetailCheckinQueue__c>> quesizeMap = new Map<Id,List<RetailCheckinQueue__c>> ();
                
                //Iterate through pending queue and assign values
                for (RetailCheckinQueue__c pendingRecord : pendingQueue) {
                    //Get handleTime for specific pending check-in
                    pendingRecord.DCIChangeReason__c = dciChangeReason;
                    Decimal handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, pendingRecord.Lead__r.ReasonForLeaving__c, pendingRecord.Store__c);
                    system.debug('3333333'+handleTime);
                    if (pendingRecord.QueuePosition__c > sequence && updateQPosition) {
                        pendingRecord.QueuePosition__c = pendingRecord.QueuePosition__c - 1;
                    } else if (pendingRecord.QueuePosition__c > sequence && qDecrement) {
                        pendingRecord.QueuePosition__c = pendingRecord.QueuePosition__c + 1;
                    }
                    
                    Store__c recordStore = storeMap.get(pendingRecord.Store__c);
                    system.debug('4444444'+recordStore);
                    Map<Id, RetailCheckinQueue__c> engagedStoreQueueMap;
                    
                    //Rep A, B = Engaged, C = Online
                    //DCI A, B = Engaged, C = QP1
                    //StoreRepCurrentCapacity == 1, Queue position == 1
                    if(recordStore.DCIStoreRepCurrentCapacity__c > 0 && pendingRecord.QueuePosition__c <= recordStore.DCIStoreRepCurrentCapacity__c){
                        pendingRecord.EstimatedWaitTime__c = 0;
                        pendingRecord.DCIEstimatedStartTime__c = System.Now();
                        //Update comparison map with new time until free value
                        if (engagedQueueMap.containsKey(pendingRecord.Store__c)) {
                            //TUF = Engaged Start Time + HandleTime
                            //engagedStoreQueueMap = <A: {timeUntilFree = 11:52}, B: {timeUntilFree=12:02}, C: {timeUntilFree=12:22}>
                            //Pending Queue: <a, b, c>
                            //A gets processed
                            //A handleTime = 30; EWT: 27; lastEWT = 27
                            //engagedStoreQueueMap = <1, {timeUntilFree = 12:32}; 2, {timeUntilFree=12:02}>
                            //B handleTime = 40; EWT: 37; lastEWT = 37
                            //engagedStoreQueueMap = <1, {timeUntilFree = 12:32}; 2, {timeUntilFree=12:42}>
                            //C handleTime = 30; EWT: 64; lastEWT = 64
                            //engagedStoreQueueMap = Store A Engaged Queue = <1, {timeUntilFree = 1:02}; 2, {timeUntilFree=12:42}>
                            //Checkin D is BOPIS is created
                            engagedStoreQueueMap = engagedQueueMap.get(pendingRecord.Store__c);
                            pendingRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue()); //Time Until Free can remain being set here because it will be officially set when the record becomes engaged. Future iterations will reset this value as well
                            engagedStoreQueueMap.put(pendingRecord.Id, pendingRecord);
                            engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                        } else {
                            engagedStoreQueueMap = new Map<Id, RetailCheckinQueue__c>();
                            pendingRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue()); //Time Until Free can remain being set here because it will be officially set when the record becomes engaged. Future iterations will reset this value as well
                            engagedStoreQueueMap.put(pendingRecord.Id, pendingRecord);
                            engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                        }
                    } else {
                        //If there are records engaged at store, find shortest wait duration from records, update EWT, update shortest wait duration map
                        if (engagedQueueMap.containsKey(pendingRecord.Store__c)) {
                            Datetime shortestWaitDuration;
                            Id shortestWaitRecordId;
                            //find shortest wait duration
                            for (RetailCheckinQueue__c existingRecord : engagedQueueMap.get(pendingRecord.Store__c).values()) {
                                //engagedStoreQueueMap = <1, {timeUntilFree = 11:22}; 2, {timeUntilFree=11:32}>
                                System.debug('*shortestWaitDuration: ' + shortestWaitDuration);
                                System.debug('*existing wiat record in engagedQueueMap: ' + existingRecord.DCITimeUntilFree__c);
                                if (shortestWaitDuration == null) {
                                    shortestWaitDuration = existingRecord.DCITimeUntilFree__c;
                                    shortestWaitRecordId = existingRecord.Id;
                                } else {
                                    Boolean boolValue = shortestWaitDuration > existingRecord.DCITimeUntilFree__c;
                                    System.debug('* shortestWaitDuration > existingRecord.DCITimeUntilFree__c: ' + boolValue);
                                    
                                    if (shortestWaitDuration > existingRecord.DCITimeUntilFree__c) {
                                        shortestWaitDuration = existingRecord.DCITimeUntilFree__c;
                                        shortestWaitRecordId = existingRecord.Id;
                                    }
                                }
                            }
                            
                            //shortestWaitDuration = 11:22
                            
                            //Set EWT to shortest wait duration
                            Long minutes = (shortestWaitDuration.getTime() - System.now().getTime()) / 60000;
                            pendingRecord.EstimatedWaitTime__c = minutes < 0 ? 0 : minutes.intValue() + 1;
                            pendingRecord.DCIEstimatedStartTime__c =  pendingRecord.EstimatedWaitTime__c==0?System.Now():shortestWaitDuration;
                            if(pendingRecord.DCIMaximum_EWT__c < pendingRecord.EstimatedWaitTime__c + Double.valueOf(pendingRecord.DCITimeWaiting__c.replaceall('min',''))){
                                pendingRecord.DCIMaximum_EWT__c = pendingRecord.EstimatedWaitTime__c + Double.valueOf(pendingRecord.DCITimeWaiting__c.replaceall('min',''));
                                pendingRecord.DCITotalRepCount__c = recordStore.DCIStoreRepActiveCapacity__c;
                                pendingRecord.DCIAvailableRepCount__c = recordStore.DCIStoreRepCurrentCapacity__c;
                            }
                            if(pendingRecord.DCIMinimum_EWT__c > pendingRecord.EstimatedWaitTime__c){
                                pendingRecord.DCIMinimum_EWT__c = pendingRecord.EstimatedWaitTime__c;
                            }
                            
                            pendingRecord.LastEWTUpdated__c =  System.now();
                            
                            //Update comparison map with new time until free value (add shortest wait duration to shortest time until free)
                            //engagedStoreQueueMap = <1, {timeUntilFree = 11:22}; 2, {timeUntilFree=11:32}>
                            engagedStoreQueueMap = engagedQueueMap.get(pendingRecord.Store__c);
                            RetailCheckinQueue__c utilizedDCIRecord = engagedStoreQueueMap.get(shortestWaitRecordId);
                            //This should be handle Time
                            utilizedDCIRecord.DCITimeUntilFree__c = utilizedDCIRecord.DCITimeUntilFree__c.addMinutes(handleTime.intValue());
                            engagedStoreQueueMap.put(shortestWaitRecordId, utilizedDCIRecord);
                            engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                        } else {
                            //If there are not any records engaged at the current store, and the check-in is greater than the amount of available reps
                            //Set EWT, update engaged store queue map
                            pendingRecord.EstimatedWaitTime__c = 0;
                            pendingRecord.DCIEstimatedStartTime__c = System.Now();
                            if(pendingRecord.DCIMaximum_EWT__c < pendingRecord.EstimatedWaitTime__c + Double.valueOf(pendingRecord.DCITimeWaiting__c.replaceall('min',''))){
                                pendingRecord.DCIMaximum_EWT__c = pendingRecord.EstimatedWaitTime__c + Double.valueOf(pendingRecord.DCITimeWaiting__c.replaceall('min',''));
                                pendingRecord.DCITotalRepCount__c = recordStore.DCIStoreRepActiveCapacity__c;
                                pendingRecord.DCIAvailableRepCount__c = recordStore.DCIStoreRepCurrentCapacity__c;
                            }
                            if(pendingRecord.DCIMinimum_EWT__c > pendingRecord.EstimatedWaitTime__c){
                                pendingRecord.DCIMinimum_EWT__c = pendingRecord.EstimatedWaitTime__c;
                            }
                            
                            pendingRecord.LastEWTUpdated__c =  System.now();
                            engagedStoreQueueMap = new Map<Id, RetailCheckinQueue__c>();
                            pendingRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue());
                            engagedStoreQueueMap.put(pendingRecord.Id, pendingRecord);
                            engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                        }
                    }
                    
                    
                    List<RetailCheckinQueue__c> storePendingQueue = quesizeMap.get(pendingRecord.Store__c);
                    if(storePendingQueue == null){
                        storePendingQueue = new List<RetailCheckinQueue__c>();
                    }
                    storePendingQueue.add(pendingRecord);
                    quesizeMap.put(pendingRecord.Store__c,storePendingQueue);
                    pendingRecord.DCIEWTCalculationType__c =  DCIConstants.TUF;
                }
            
                update pendingQueue;
                
                for(Store__c store: storeMap.values()){
                    DateTime shortestTUF;
                    
                    if (engagedQueueMap.containsKey(store.Id)) {
                        if(store.DCIStoreRepActiveCapacity__c > engagedQueueMap.get(store.Id).size()){
                            store.DCIShortestTUF__c = System.now();
                        }
                        else{
                            for (RetailCheckinQueue__c dciRecord : engagedQueueMap.get(store.Id).values()) {
                                if (shortestTUF == null) {
                                    shortestTUF = dciRecord.DCITimeUntilFree__c;
                                } else {
                                    shortestTUF = shortestTUF > dciRecord.DCITimeUntilFree__c ? dciRecord.DCITimeUntilFree__c : shortestTUF;
                                }
                            }   
                        }
                    } else {
                        store.DCIShortestTUF__c = System.now();
                    }
                    if(shortestTUF!= null){
                        store.DCIShortestTUF__c =  shortestTUF;  
                    }else {
                        store.DCIShortestTUF__c = System.now();
                    }
                    
                    store.DCIEstimatedWaitTime__c = ((store.DCIShortestTUF__c.getTime() - System.now().getTime()) / 60000) > 0 ? ((store.DCIShortestTUF__c.getTime() - System.now().getTime()) / 60000) + 1: 0;
                    
                    if(quesizeMap != null && quesizeMap.get(store.Id) != null){
                        store.DCILeadsinCheckinQueue__c = quesizeMap.get(store.Id).size();
                    } else {
                        store.DCILeadsinCheckinQueue__c = 0;
                    }
                }
                
                update storeMap.values();
            }
        }
    }
    /**
* This method updates the EWT for whole DCI queue for the store and also the store EWT ( TUF Future Batch)

*/
    public static Map<String, Object> updateQueueBulkifyTUFFuture(Map<Id, Map<Id, RetailCheckinQueue__c>> engagedQueueMap ,Store__c store, Map<String, Decimal> typeToHandleTimeMap, List<RetailCheckinQueue__c> pendingQueue, String dciChangeReason) {  // DM Added TUF
        
        return null;
    }
    
    /*
* Overloaded Method
* Utilized in ProcessMessagingSessionHelper
*/
    public static RetailDTO.DCIUpdateRecordDTO updateQueueBulkifyMinutesUntilFree(RetailDTO.DCIDataHelperDTO helper) { // DM Added TUF
        if (helper.storeIdSet != null) {
            Map<Id,Store__c> storeMap = new Map<Id,Store__c> ([SELECT id, DCIShortestTUF__c, DCIEstimatedWaitTime__c, DCIStoreRepActiveCapacity__c, DCIStoreRepCurrentCapacity__c, DCILeadsinCheckinQueue__c FROM Store__c WHERE id IN:helper.storeIdSet WITH SECURITY_ENFORCED]);
            if (storeMap !=  null) {
                String changeReason = '';
                Map<string,DateTime> shortestTUFMap = new  Map<string,DateTime>();
                map<String, Decimal> typeToHandleTimeMap = DCIConstants.getStoreHandleTimeMap(helper.storeIdSet);
                List<RetailCheckinQueue__c> pendingQueue = getPendingQueueBulkify(helper.storeIdSet, 0);
                Map<Id, Map<Id, RetailCheckinQueue__c>> engagedQueueMap = getEngagedQueue(helper.storeIdSet);
                Map<Id,List<RetailCheckinQueue__c>> quesizeMap = new Map<Id,List<RetailCheckinQueue__c>> ();
                Decimal preSwapEWT = 0;
                
                //Iterate through pending queue and assign values
                for (RetailCheckinQueue__c pendingRecord : pendingQueue) {
                    Boolean processEWT = true;
                    RetailCheckinQueue__c recordTobeMovedBack;
                    //Pick the updated Dci record from this batch of records being processed.
                    if(helper.currentCheckinMap.containsKey(pendingRecord.Id)){
                        pendingRecord = helper.currentCheckinMap.get(pendingRecord.Id);
                    }
                    
                    // One record below Swap record
                    if(helper.swappedtoStoreMap.containsKey(pendingRecord.Store__c)) {
                        //RetailCheckinQueue__c recordTobeMovedBack = helper.swappedtoStoreMap.get(pendingRecord.Store__c);
                        recordTobeMovedBack = helper.swappedtoStoreMap.get(pendingRecord.Store__c);
                        Decimal queuePosition = recordTobeMovedBack.QueuePosition__c;
                        preSwapEWT = recordTobeMovedBack.EstimatedWaitTime__c;
                        //recordTobeMovedBack.QueuePosition__c = pendingRecord.QueuePosition__c + 1;
                        recordTobeMovedBack.QueuePosition__c = pendingRecord.QueuePosition__c;
                        pendingRecord.QueuePosition__c = queuePosition;
                        //Remove record swap to ensure only 1 record gets processed
                        helper.swappedtoStoreMap.remove(pendingRecord.Store__c);
                        
                    } else if(helper.swapCheckinMap.containsKey(pendingRecord.Id)) {
                        changeReason = 'Customer needed more time';
                        helper.swappedtoStoreMap.put(pendingRecord.Store__c,pendingRecord);
                        processEWT = false;
                    }
                    
                    if (helper.noShowCheckinMap.containsKey(pendingRecord.Id)) {
                        changeReason = 'Customer marked no show';
                        helper.noshowtoStoreMap.put(pendingRecord.Store__c,true);
                        processEWT = false;
                    } else if (helper.noshowtoStoreMap.containsKey(pendingRecord.Store__c)) {
                        pendingRecord.QueuePosition__c = pendingRecord.QueuePosition__c - 1;
                        //updateList.add(pendingRecord);
                    }
                    
                    if (helper.cancelledCheckinMap.containsKey(pendingRecord.Id)) {
                        changeReason = 'Cancelled';
                        //Cancelled records here
                        helper.cancelledtoStoreMap.put(pendingRecord.Store__c,true);
                        processEWT = false;
                        //updateList.add(pendingRecord);
                    } else if(helper.cancelledtoStoreMap.containsKey(pendingRecord.Store__c)){
                        pendingRecord.QueuePosition__c = pendingRecord.QueuePosition__c - 1;
                        changeReason = DCIConstants.DCIRemoveChangeReason;
                        //updateList.add(pendingRecord);
                    }
                    
                    
                    if (processEWT) {
                        //Get handleTime for specific pending check-in
                        Decimal handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, pendingRecord.Lead__r.ReasonForLeaving__c, pendingRecord.Store__c);
                        pendingRecord.DCIChangeReason__c = changeReason;
                        Store__c recordStore = storeMap.get(pendingRecord.Store__c);
                        Map<Id, RetailCheckinQueue__c> engagedStoreQueueMap;
                        if(recordStore.DCIStoreRepCurrentCapacity__c > 0 && pendingRecord.QueuePosition__c <= recordStore.DCIStoreRepCurrentCapacity__c){
                            pendingRecord.EstimatedWaitTime__c = 0;
                            pendingRecord.DCIEstimatedStartTime__c = System.Now();
                            //Update comparison map with new time until free value
                            if (engagedQueueMap.containsKey(pendingRecord.Store__c)) {
                                engagedStoreQueueMap = engagedQueueMap.get(pendingRecord.Store__c);
                                pendingRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue()); //Time Until Free can remain being set here because it will be officially set when the record becomes engaged. Future iterations will reset this value as well
                                engagedStoreQueueMap.put(pendingRecord.Id, pendingRecord);
                                engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                            } else {
                                engagedStoreQueueMap = new Map<Id, RetailCheckinQueue__c>();
                                pendingRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue()); //Time Until Free can remain being set here because it will be officially set when the record becomes engaged. Future iterations will reset this value as well
                                engagedStoreQueueMap.put(pendingRecord.Id, pendingRecord);
                                engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                            }
                        } else {
                            //If there are records engaged at store, find shortest wait duration from records, update EWT, update shortest wait duration map
                            if (engagedQueueMap.containsKey(pendingRecord.Store__c)) {
                                Datetime shortestWaitDuration;
                                Id shortestWaitRecordId;
                                //find shortest wait duration
                                for (RetailCheckinQueue__c existingRecord : engagedQueueMap.get(pendingRecord.Store__c).values()) {
                                    if (shortestWaitDuration == null) {
                                        shortestWaitDuration = existingRecord.DCITimeUntilFree__c;
                                        shortestWaitRecordId = existingRecord.Id;
                                    } else {
                                        Boolean boolValue = shortestWaitDuration > existingRecord.DCITimeUntilFree__c;
                                        
                                        if (shortestWaitDuration > existingRecord.DCITimeUntilFree__c) {
                                            shortestWaitDuration = existingRecord.DCITimeUntilFree__c;
                                            shortestWaitRecordId = existingRecord.Id;
                                        }
                                    }
                                }
                                
                                
                                //Set EWT to shortest wait duration
                                Long minutes = (shortestWaitDuration.getTime() - System.now().getTime()) / 60000;
                                pendingRecord.EstimatedWaitTime__c = minutes < 0 ? 0 : minutes.intValue() + 1;
                                pendingRecord.DCIEstimatedStartTime__c =  pendingRecord.EstimatedWaitTime__c==0?System.Now():shortestWaitDuration;
                                if(pendingRecord.DCIMaximum_EWT__c < pendingRecord.EstimatedWaitTime__c + Double.valueOf(pendingRecord.DCITimeWaiting__c.replaceall('min',''))){
                                    pendingRecord.DCIMaximum_EWT__c = pendingRecord.EstimatedWaitTime__c + Double.valueOf(pendingRecord.DCITimeWaiting__c.replaceall('min',''));
                                    pendingRecord.DCITotalRepCount__c = recordStore.DCIStoreRepActiveCapacity__c;
                                    pendingRecord.DCIAvailableRepCount__c = recordStore.DCIStoreRepCurrentCapacity__c;
                                }
                                if(pendingRecord.DCIMinimum_EWT__c > pendingRecord.EstimatedWaitTime__c){
                                    pendingRecord.DCIMinimum_EWT__c = pendingRecord.EstimatedWaitTime__c;
                                }
                                
                                pendingRecord.LastEWTUpdated__c =  System.now();
                                
                                //Update comparison map with new time until free value (add shortest wait duration to shortest time until free)
                                //engagedStoreQueueMap = <1, {timeUntilFree = 11:22}; 2, {timeUntilFree=11:32}>
                                engagedStoreQueueMap = engagedQueueMap.get(pendingRecord.Store__c);
                                RetailCheckinQueue__c utilizedDCIRecord = engagedStoreQueueMap.get(shortestWaitRecordId);
                                //This should be handle Time
                                utilizedDCIRecord.DCITimeUntilFree__c = utilizedDCIRecord.DCITimeUntilFree__c.addMinutes(handleTime.intValue());
                                engagedStoreQueueMap.put(shortestWaitRecordId, utilizedDCIRecord);
                                engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                            } else {
                                //If there are not any records engaged at the current store, and the check-in is greater than the amount of available reps
                                //Set EWT, update engaged store queue map
                                pendingRecord.EstimatedWaitTime__c = 0;
                                pendingRecord.DCIEstimatedStartTime__c = System.Now();
                                if(pendingRecord.DCIMaximum_EWT__c < pendingRecord.EstimatedWaitTime__c + Double.valueOf(pendingRecord.DCITimeWaiting__c.replaceall('min',''))){
                                    pendingRecord.DCIMaximum_EWT__c = pendingRecord.EstimatedWaitTime__c + Double.valueOf(pendingRecord.DCITimeWaiting__c.replaceall('min',''));
                                    pendingRecord.DCITotalRepCount__c = recordStore.DCIStoreRepActiveCapacity__c;
                                    pendingRecord.DCIAvailableRepCount__c = recordStore.DCIStoreRepCurrentCapacity__c;
                                }
                                if(pendingRecord.DCIMinimum_EWT__c > pendingRecord.EstimatedWaitTime__c){
                                    pendingRecord.DCIMinimum_EWT__c = pendingRecord.EstimatedWaitTime__c;
                                }
                                
                                pendingRecord.LastEWTUpdated__c =  System.now();
                                engagedStoreQueueMap = new Map<Id, RetailCheckinQueue__c>();
                                pendingRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue());
                                engagedStoreQueueMap.put(pendingRecord.Id, pendingRecord);
                                engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                            }
                        }
                        
                        
                        helper.queuePostoStoreMap.put(pendingRecord.Store__c,pendingRecord.QueuePosition__c);
                        helper.currentCheckinMap.put(pendingRecord.ID,pendingRecord);
                        
                        if(recordTobeMovedBack!= null)
                        {
                            //Bugfix- 77119 -- Calculate EWT for moved down record
                            
                            Decimal moveDownrec_handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, recordTobeMovedBack.Lead__r.ReasonForLeaving__c, recordTobeMovedBack.Store__c);
                            recordTobeMovedBack.DCIChangeReason__c = changeReason;
                            Store__c moveDownRecordStore = storeMap.get(recordTobeMovedBack.Store__c);
                            Map<Id, RetailCheckinQueue__c> engagedStoreQueueMapForSwap;
                            if(moveDownRecordStore.DCIStoreRepCurrentCapacity__c > 0 && recordTobeMovedBack.QueuePosition__c <= moveDownRecordStore.DCIStoreRepCurrentCapacity__c){
                                recordTobeMovedBack.EstimatedWaitTime__c = 0;
                                recordTobeMovedBack.DCIEstimatedStartTime__c = System.Now();
                                //Update comparison map with new time until free value
                                if (engagedQueueMap.containsKey(recordTobeMovedBack.Store__c)) {
                                    engagedStoreQueueMapForSwap = engagedQueueMap.get(recordTobeMovedBack.Store__c);
                                    recordTobeMovedBack.DCITimeUntilFree__c = System.now().addMinutes(moveDownrec_handleTime.intValue()); //Time Until Free can remain being set here because it will be officially set when the record becomes engaged. Future iterations will reset this value as well
                                    engagedStoreQueueMapForSwap.put(recordTobeMovedBack.Id, recordTobeMovedBack);
                                    engagedQueueMap.put(recordTobeMovedBack.Store__c, engagedStoreQueueMapForSwap);
                                } else {
                                    engagedStoreQueueMapForSwap = new Map<Id, RetailCheckinQueue__c>();
                                    recordTobeMovedBack.DCITimeUntilFree__c = System.now().addMinutes(moveDownrec_handleTime.intValue()); //Time Until Free can remain being set here because it will be officially set when the record becomes engaged. Future iterations will reset this value as well
                                    engagedStoreQueueMapForSwap.put(recordTobeMovedBack.Id, recordTobeMovedBack);
                                    engagedQueueMap.put(recordTobeMovedBack.Store__c, engagedStoreQueueMapForSwap);
                                }
                            } else {
                                //If there are records engaged at store, find shortest wait duration from records, update EWT, update shortest wait duration map
                                if (engagedQueueMap.containsKey(recordTobeMovedBack.Store__c)) {
                                    Datetime shortestWaitDuration;
                                    Id shortestWaitRecordId;
                                    //find shortest wait duration
                                    for (RetailCheckinQueue__c existingRecord : engagedQueueMap.get(recordTobeMovedBack.Store__c).values()) {
                                        if (shortestWaitDuration == null) {
                                            shortestWaitDuration = existingRecord.DCITimeUntilFree__c;
                                            shortestWaitRecordId = existingRecord.Id;
                                        } else {
                                            Boolean boolValue = shortestWaitDuration > existingRecord.DCITimeUntilFree__c;
                                            
                                            if (shortestWaitDuration > existingRecord.DCITimeUntilFree__c) {
                                                shortestWaitDuration = existingRecord.DCITimeUntilFree__c;
                                                shortestWaitRecordId = existingRecord.Id;
                                            }
                                        }
                                    }
                                    
                                    //Set EWT to shortest wait duration
                                    Long minutes = (shortestWaitDuration.getTime() - System.now().getTime()) / 60000;
                                    recordTobeMovedBack.EstimatedWaitTime__c = minutes < 0 ? 0 : minutes.intValue() + 1;
                                    recordTobeMovedBack.DCIEstimatedStartTime__c =  recordTobeMovedBack.EstimatedWaitTime__c==0?System.Now():shortestWaitDuration;
                                    if(recordTobeMovedBack.DCIMaximum_EWT__c < recordTobeMovedBack.EstimatedWaitTime__c + Double.valueOf(recordTobeMovedBack.DCITimeWaiting__c.replaceall('min',''))){
                                        recordTobeMovedBack.DCIMaximum_EWT__c = recordTobeMovedBack.EstimatedWaitTime__c + Double.valueOf(recordTobeMovedBack.DCITimeWaiting__c.replaceall('min',''));
                                        recordTobeMovedBack.DCITotalRepCount__c = moveDownRecordStore.DCIStoreRepActiveCapacity__c;
                                        recordTobeMovedBack.DCIAvailableRepCount__c = moveDownRecordStore.DCIStoreRepCurrentCapacity__c;
                                    }
                                    if(recordTobeMovedBack.DCIMinimum_EWT__c > recordTobeMovedBack.EstimatedWaitTime__c){
                                        recordTobeMovedBack.DCIMinimum_EWT__c = recordTobeMovedBack.EstimatedWaitTime__c;
                                    }
                                    
                                    recordTobeMovedBack.LastEWTUpdated__c =  System.now();
                                    
                                    engagedStoreQueueMapForSwap = engagedQueueMap.get(recordTobeMovedBack.Store__c);
                                    RetailCheckinQueue__c utilizedDCIRecord = engagedStoreQueueMapForSwap.get(shortestWaitRecordId);
                                    //This should be handle Time
                                    utilizedDCIRecord.DCITimeUntilFree__c = utilizedDCIRecord.DCITimeUntilFree__c.addMinutes(moveDownrec_handleTime.intValue());
                                    engagedStoreQueueMapForSwap.put(shortestWaitRecordId, utilizedDCIRecord);
                                    engagedQueueMap.put(recordTobeMovedBack.Store__c, engagedStoreQueueMapForSwap);
                                } else {
                                    //If there are not any records engaged at the current store, and the check-in is greater than the amount of available reps
                                    //Set EWT, update engaged store queue map
                                    recordTobeMovedBack.EstimatedWaitTime__c = 0;
                                    recordTobeMovedBack.DCIEstimatedStartTime__c = System.Now();
                                    if(recordTobeMovedBack.DCIMaximum_EWT__c < recordTobeMovedBack.EstimatedWaitTime__c + Double.valueOf(recordTobeMovedBack.DCITimeWaiting__c.replaceall('min',''))){
                                        recordTobeMovedBack.DCIMaximum_EWT__c = recordTobeMovedBack.EstimatedWaitTime__c + Double.valueOf(recordTobeMovedBack.DCITimeWaiting__c.replaceall('min',''));
                                        recordTobeMovedBack.DCITotalRepCount__c = moveDownRecordStore.DCIStoreRepActiveCapacity__c;
                                        recordTobeMovedBack.DCIAvailableRepCount__c = moveDownRecordStore.DCIStoreRepCurrentCapacity__c;
                                    }
                                    if(recordTobeMovedBack.DCIMinimum_EWT__c > recordTobeMovedBack.EstimatedWaitTime__c){
                                        recordTobeMovedBack.DCIMinimum_EWT__c = recordTobeMovedBack.EstimatedWaitTime__c;
                                    }
                                    
                                    recordTobeMovedBack.LastEWTUpdated__c =  System.now();
                                    engagedStoreQueueMapForSwap = new Map<Id, RetailCheckinQueue__c>();
                                    recordTobeMovedBack.DCITimeUntilFree__c = System.now().addMinutes(moveDownrec_handleTime.intValue());
                                    engagedStoreQueueMapForSwap.put(recordTobeMovedBack.Id, recordTobeMovedBack);
                                    engagedQueueMap.put(recordTobeMovedBack.Store__c, engagedStoreQueueMapForSwap);
                                }
                            }
                            
                            helper.queuePostoStoreMap.put(recordTobeMovedBack.Store__c,recordTobeMovedBack.QueuePosition__c);
                            helper.currentCheckinMap.put(recordTobeMovedBack.ID,recordTobeMovedBack);
                            Decimal ewtDiff =  recordTobeMovedBack.EstimatedWaitTime__c - preSwapEWT;
                            helper.ewtDiffTrecords.put(recordTobeMovedBack.Id,ewtDiff);
                            
                        }
                    }
                }
                //update pendingQueue;
                List<Store__c> updateStoreList = new List<Store__c>();    
                
                for(Store__c store: storeMap.values()){
                    DateTime shortestTUF;
                    
                    if (engagedQueueMap.containsKey(store.Id)) {
                        if(store.DCIStoreRepActiveCapacity__c > engagedQueueMap.get(store.Id).size()){
                            store.DCIShortestTUF__c = System.now();
                        }
                        else{
                            for (RetailCheckinQueue__c dciRecord : engagedQueueMap.get(store.Id).values()) {
                                if (shortestTUF == null) {
                                    store.DCIShortestTUF__c = dciRecord.DCITimeUntilFree__c;
                                } else {
                                    store.DCIShortestTUF__c = store.DCIShortestTUF__c > dciRecord.DCITimeUntilFree__c ? dciRecord.DCITimeUntilFree__c : store.DCIShortestTUF__c;
                                }
                            }   }
                    } else {
                        store.DCIShortestTUF__c = System.now();
                    }
                    store.DCIEstimatedWaitTime__c = ((store.DCIShortestTUF__c.getTime() - System.now().getTime()) / 60000) > 0 ? ((store.DCIShortestTUF__c.getTime() - System.now().getTime()) / 60000) : 0;
                    store.DCILeadsinCheckinQueue__c = helper.queuePostoStoreMap.get(store.Id);
                    updateStoreList.add(store);
                }
                
                
                RetailDTO.DCIUpdateRecordDTO updateRecords = new RetailDTO.DCIUpdateRecordDTO();
                updateRecords.updateStoreList = updateStoreList;
                return updateRecords;
            }
        }
        
        return null;
    }
    
    /**
* This method updates the EWT for whole DCI queue for the store and also the store EWT ( TUF Future Batch)
*/
    public static Map<String, Object> updateQueueBulkifyTUFFuture(Store__c store, Map<Id, Map<Id, RetailCheckinQueue__c>> engagedQueueMap, Map<String, Decimal> typeToHandleTimeMap, List<RetailCheckinQueue__c> pendingQueue, String dciEventType) {  // DM Added TUF
        Map<Id,List<RetailCheckinQueue__c>> quesizeMap = new Map<Id,List<RetailCheckinQueue__c>> ();
        
        //Iterate through pending queue and assign values
        for (RetailCheckinQueue__c pendingRecord : pendingQueue) {
            //Get handleTime for specific pending check-in
            pendingRecord.DCIChangeReason__c = dciEventType;
            Decimal handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, pendingRecord.Lead__r.ReasonForLeaving__c, pendingRecord.Store__c);
            Map<Id, RetailCheckinQueue__c> engagedStoreQueueMap;
            
            //Rep A, B = Engaged, C = Online
            //DCI A, B = Engaged, C = QP1
            //StoreRepCurrentCapacity == 1, Queue position == 1
            if(store.DCIStoreRepCurrentCapacity__c > 0 && pendingRecord.QueuePosition__c <= store.DCIStoreRepCurrentCapacity__c){
                pendingRecord.EstimatedWaitTime__c = 0;
                pendingRecord.DCIEstimatedStartTime__c = System.Now();
                //Update comparison map with new time until free value
                if (engagedQueueMap.containsKey(pendingRecord.Store__c)) {
                    //TUF = Engaged Start Time + HandleTime
                    //engagedStoreQueueMap = <A: {timeUntilFree = 11:52}, B: {timeUntilFree=12:02}, C: {timeUntilFree=12:22}>
                    //Pending Queue: <a, b, c>
                    //A gets processed
                    //A handleTime = 30; EWT: 27; lastEWT = 27
                    //engagedStoreQueueMap = <1, {timeUntilFree = 12:32}; 2, {timeUntilFree=12:02}>
                    //B handleTime = 40; EWT: 37; lastEWT = 37
                    //engagedStoreQueueMap = <1, {timeUntilFree = 12:32}; 2, {timeUntilFree=12:42}>
                    //C handleTime = 30; EWT: 64; lastEWT = 64
                    //engagedStoreQueueMap = Store A Engaged Queue = <1, {timeUntilFree = 1:02}; 2, {timeUntilFree=12:42}>
                    //Checkin D is BOPIS is created
                    engagedStoreQueueMap = engagedQueueMap.get(pendingRecord.Store__c);
                    pendingRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue()); //Time Until Free can remain being set here because it will be officially set when the record becomes engaged. Future iterations will reset this value as well
                    engagedStoreQueueMap.put(pendingRecord.Id, pendingRecord);
                    engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                } else {
                    engagedStoreQueueMap = new Map<Id, RetailCheckinQueue__c>();
                    pendingRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue()); //Time Until Free can remain being set here because it will be officially set when the record becomes engaged. Future iterations will reset this value as well
                    engagedStoreQueueMap.put(pendingRecord.Id, pendingRecord);
                    engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                }
            } else {
                //If there are records engaged at store, find shortest wait duration from records, update EWT, update shortest wait duration map
                if (engagedQueueMap.containsKey(pendingRecord.Store__c)) {
                    Datetime shortestWaitDuration;
                    Id shortestWaitRecordId;
                    //find shortest wait duration
                    for (RetailCheckinQueue__c existingRecord : engagedQueueMap.get(pendingRecord.Store__c).values()) {
                        //engagedStoreQueueMap = <1, {timeUntilFree = 11:22}; 2, {timeUntilFree=11:32}>
                        System.debug('*shortestWaitDuration: ' + shortestWaitDuration);
                        System.debug('*existing wiat record in engagedQueueMap: ' + existingRecord.DCITimeUntilFree__c);
                        if (shortestWaitDuration == null) {
                            shortestWaitDuration = existingRecord.DCITimeUntilFree__c;
                            shortestWaitRecordId = existingRecord.Id;
                        } else {
                            Boolean boolValue = shortestWaitDuration > existingRecord.DCITimeUntilFree__c;
                            System.debug('* shortestWaitDuration > existingRecord.DCITimeUntilFree__c: ' + boolValue);
                            
                            if (shortestWaitDuration > existingRecord.DCITimeUntilFree__c) {
                                shortestWaitDuration = existingRecord.DCITimeUntilFree__c;
                                shortestWaitRecordId = existingRecord.Id;
                            }
                        }
                    }
                    
                    //shortestWaitDuration = 11:22
                    
                    //Set EWT to shortest wait duration
                    Long minutes = (shortestWaitDuration.getTime() - System.now().getTime()) / 60000;
                    pendingRecord.EstimatedWaitTime__c = minutes < 0 ? 0 : minutes.intValue() + 1;
                    pendingRecord.DCIEstimatedStartTime__c =  pendingRecord.EstimatedWaitTime__c==0?System.Now():shortestWaitDuration;
                    if(pendingRecord.DCIMaximum_EWT__c < pendingRecord.EstimatedWaitTime__c + Double.valueOf(pendingRecord.DCITimeWaiting__c.replaceall('min',''))){
                        pendingRecord.DCIMaximum_EWT__c = pendingRecord.EstimatedWaitTime__c + Double.valueOf(pendingRecord.DCITimeWaiting__c.replaceall('min',''));
                        pendingRecord.DCITotalRepCount__c = store.DCIStoreRepActiveCapacity__c;
                        pendingRecord.DCIAvailableRepCount__c = store.DCIStoreRepCurrentCapacity__c;
                    }
                    if(pendingRecord.DCIMinimum_EWT__c > pendingRecord.EstimatedWaitTime__c){
                        pendingRecord.DCIMinimum_EWT__c = pendingRecord.EstimatedWaitTime__c;
                    }
                    
                    pendingRecord.LastEWTUpdated__c =  System.now();
                    
                    //Update comparison map with new time until free value (add shortest wait duration to shortest time until free)
                    //engagedStoreQueueMap = <1, {timeUntilFree = 11:22}; 2, {timeUntilFree=11:32}>
                    engagedStoreQueueMap = engagedQueueMap.get(pendingRecord.Store__c);
                    RetailCheckinQueue__c utilizedDCIRecord = engagedStoreQueueMap.get(shortestWaitRecordId);
                    //This should be handle Time
                    utilizedDCIRecord.DCITimeUntilFree__c = utilizedDCIRecord.DCITimeUntilFree__c.addMinutes(handleTime.intValue());
                    engagedStoreQueueMap.put(shortestWaitRecordId, utilizedDCIRecord);
                    engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                } else {
                    //If there are not any records engaged at the current store, and the check-in is greater than the amount of available reps
                    //Set EWT, update engaged store queue map
                    pendingRecord.EstimatedWaitTime__c = 0;
                    pendingRecord.DCIEstimatedStartTime__c = System.Now();
                    if(pendingRecord.DCIMaximum_EWT__c < pendingRecord.EstimatedWaitTime__c + Double.valueOf(pendingRecord.DCITimeWaiting__c.replaceall('min',''))){
                        pendingRecord.DCIMaximum_EWT__c = pendingRecord.EstimatedWaitTime__c + Double.valueOf(pendingRecord.DCITimeWaiting__c.replaceall('min',''));
                        pendingRecord.DCITotalRepCount__c = store.DCIStoreRepActiveCapacity__c;
                        pendingRecord.DCIAvailableRepCount__c = store.DCIStoreRepCurrentCapacity__c;
                    }
                    if(pendingRecord.DCIMinimum_EWT__c > pendingRecord.EstimatedWaitTime__c){
                        pendingRecord.DCIMinimum_EWT__c = pendingRecord.EstimatedWaitTime__c;
                    }
                    
                    pendingRecord.LastEWTUpdated__c =  System.now();
                    engagedStoreQueueMap = new Map<Id, RetailCheckinQueue__c>();
                    pendingRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue());
                    engagedStoreQueueMap.put(pendingRecord.Id, pendingRecord);
                    engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                }
            }
            
            
            List<RetailCheckinQueue__c> storePendingQueue = quesizeMap.get(pendingRecord.Store__c);
            if(storePendingQueue == null){
                storePendingQueue = new List<RetailCheckinQueue__c>();
            }
            storePendingQueue.add(pendingRecord);
            quesizeMap.put(pendingRecord.Store__c,storePendingQueue);
        }
        DateTime shortestTUF;
        
        if (engagedQueueMap.containsKey(store.Id)) {
            for (RetailCheckinQueue__c dciRecord : engagedQueueMap.get(store.Id).values()) {
                if (shortestTUF == null) {
                    shortestTUF = dciRecord.DCITimeUntilFree__c;
                } else {
                    shortestTUF = shortestTUF > dciRecord.DCITimeUntilFree__c ? dciRecord.DCITimeUntilFree__c : shortestTUF;
                }
            }
        } else {
            store.DCIShortestTUF__c = System.now();
        }
        if (shortestTUF!= null) {
            store.DCIShortestTUF__c =  shortestTUF;  
        } else {
            store.DCIShortestTUF__c = System.now();
        }
        
        store.DCIEstimatedWaitTime__c = ((store.DCIShortestTUF__c.getTime() - System.now().getTime()) / 60000) > 0 ? ((store.DCIShortestTUF__c.getTime() - System.now().getTime()) / 60000) + 1: 0;
        
        if(quesizeMap != null && quesizeMap.get(store.Id) != null){
            store.DCILeadsinCheckinQueue__c = quesizeMap.get(store.Id).size();
        } else {
            store.DCILeadsinCheckinQueue__c = 0;
        }
        
        Map<String, Object> returnMap = new Map<String, Object>();
        returnMap.put('dciRecordsToUpdate', pendingQueue);
        returnMap.put('storeRecordToUpdate',store);
        return returnMap;
    }
    
    public static Map<Id, Map<Id, RetailCheckinQueue__c>> getEngagedQueue(Set<Id> storeIds) { // DM Added TUF
        Map<Id, Set<String>> storeManagerMap = new Map<Id, Set<String>>();
        for (EmployeeStoreRetail__c emp : [SELECT Id, User__c, IsCurrentlyAvailable__c, Store__c FROM EmployeeStoreRetail__c WHERE Store__c IN :storeIds AND SFProfileId__c = :DCIConstants.EMPSTORE_SM_PROFILE AND IsExpired__c = false WITH SECURITY_ENFORCED]) {
            Set<String> storeManagers;
            if (storeManagerMap.containsKey(emp.Store__c) && emp.IsCurrentlyAvailable__c == false) {
                storeManagers = storeManagerMap.get(emp.Store__c);
                storeManagers.add(emp.User__c);
                storeManagerMap.put(emp.Store__c, storeManagers);
            } else if(emp.IsCurrentlyAvailable__c == false) {
                storeManagers = new Set<String>();
                storeManagers.add(emp.User__c);
                storeManagerMap.put(emp.Store__c, storeManagers);
            }
        }
        
        Map<Id, Map<Id, RetailCheckinQueue__c>> engagedStoreMap = new Map<Id, Map<Id, RetailCheckinQueue__c>>();
        for (RetailCheckinQueue__c dciRecord : [SELECT Id, Owner__c, OwnerId, Store__c, Minutes_until_Free__c, DCITimeUntilFree__c, Lead__r.ReasonForLeaving__c 
                                                FROM RetailCheckinQueue__c WHERE Status__c = :DCIConstants.ACTIVE 
                                                AND Minutes_Until_Free__c != NULL AND Store__c IN :storeIds 
                                                WITH SECURITY_ENFORCED ORDER BY Minutes_Until_Free__c ASC ]) {
                                                    Set<String> managerIds;
                                                    if (storeManagerMap.containsKey(dciRecord.Store__c)) {
                                                        managerIds = storeManagerMap.get(dciRecord.Store__c);
                                                    }
                                                    
                                                    if(dciRecord.DCITimeUntilFree__c < System.now()){
                                                        dciRecord.DCITimeUntilFree__c = System.now();
                                                    }
                                                    
                                                    if (managerIds == null || (managerIds != null && !managerIds.contains(dciRecord.Owner__c) && !managerIds.contains(dciRecord.OwnerId))) {
                                                        if (engagedStoreMap.containsKey(dciRecord.Store__c)) {
                                                            Map<Id, RetailCheckinQueue__c> newEngagedList = engagedStoreMap.get(dciRecord.Store__c);
                                                            newEngagedList.put(dciRecord.Id, dciRecord);
                                                            engagedStoreMap.put(dciRecord.Store__c, newEngagedList);
                                                        } else {
                                                            Map<Id, RetailCheckinQueue__c> newEngagedList = new Map<Id, RetailCheckinQueue__c>();
                                                            newEngagedList.put(dciRecord.Id, dciRecord);
                                                            engagedStoreMap.put(dciRecord.Store__c, newEngagedList);
                                                        }
                                                    }
                                                }
        return engagedStoreMap;
    }
    
    public static void recalculateStoreTUF(Set<Id> storeIds) { // DM Added TUF
        List<Store__c> updatedStores = new List<Store__c>();
        if (storeIds != null) {
            Map<Id,Store__c> storeMap = new Map<Id,Store__c> ([SELECT id, DCIEstimatedWaitTime__c, DCIStoreRepActiveCapacity__c, DCIStoreRepCurrentCapacity__c, DCILeadsinCheckinQueue__c FROM Store__c WHERE id IN:storeIds WITH SECURITY_ENFORCED]);
            if (storeMap !=  null) {
                map<String, Decimal> typeToHandleTimeMap = DCIConstants.getStoreHandleTimeMap(storeIds);
                List<RetailCheckinQueue__c> pendingQueue = getPendingQueueBulkify(storeIds, 0);
                Map<Id, Map<Id, RetailCheckinQueue__c>> engagedQueueMap = getEngagedQueue(storeIds);
                Map<Id, List<RetailCheckinQueue__c>> pendingQueueMap = new Map<Id, List<RetailCheckinQueue__c>>();
                
                //Iterate through pending queue and assign values
                for (RetailCheckinQueue__c pendingRecord : pendingQueue) {
                    Decimal handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, pendingRecord.Lead__r.ReasonForLeaving__c, pendingRecord.Store__c);
                    Store__c recordStore = storeMap.get(pendingRecord.Store__c);
                    Map<Id, RetailCheckinQueue__c> engagedStoreQueueMap;
                    
                    if(recordStore.DCIStoreRepCurrentCapacity__c > 0 && pendingRecord.QueuePosition__c <= recordStore.DCIStoreRepCurrentCapacity__c){
                        pendingRecord.EstimatedWaitTime__c = 0;
                        pendingRecord.DCIEstimatedStartTime__c = System.Now();
                        //Update comparison map with new time until free value
                        if (engagedQueueMap.containsKey(pendingRecord.Store__c)) {
                            engagedStoreQueueMap = engagedQueueMap.get(pendingRecord.Store__c);
                            pendingRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue()); //Time Until Free can remain being set here because it will be officially set when the record becomes engaged. Future iterations will reset this value as well
                            engagedStoreQueueMap.put(pendingRecord.Id, pendingRecord);
                            engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                        } else {
                            engagedStoreQueueMap = new Map<Id, RetailCheckinQueue__c>();
                            pendingRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue()); //Time Until Free can remain being set here because it will be officially set when the record becomes engaged. Future iterations will reset this value as well
                            engagedStoreQueueMap.put(pendingRecord.Id, pendingRecord);
                            engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                        }
                    } else {
                        //If there are records engaged at store, find shortest wait duration from records, update EWT, update shortest wait duration map
                        if (engagedQueueMap.containsKey(pendingRecord.Store__c)) {
                            Datetime shortestWaitDuration;
                            Id shortestWaitRecordId;
                            //find shortest wait duration
                            for (RetailCheckinQueue__c existingRecord : engagedQueueMap.get(pendingRecord.Store__c).values()) {
                                if (shortestWaitDuration == null) {
                                    shortestWaitDuration = existingRecord.DCITimeUntilFree__c;
                                    shortestWaitRecordId = existingRecord.Id;
                                } else {
                                    Boolean boolValue = shortestWaitDuration > existingRecord.DCITimeUntilFree__c;
                                    
                                    if (shortestWaitDuration > existingRecord.DCITimeUntilFree__c) {
                                        shortestWaitDuration = existingRecord.DCITimeUntilFree__c;
                                        shortestWaitRecordId = existingRecord.Id;
                                    }
                                }
                            }
                            
                            //Update comparison map with new time until free value (add shortest wait duration to shortest time until free)
                            //engagedStoreQueueMap = <1, {timeUntilFree = 11:22}; 2, {timeUntilFree=11:32}>
                            engagedStoreQueueMap = engagedQueueMap.get(pendingRecord.Store__c);
                            RetailCheckinQueue__c utilizedDCIRecord = engagedStoreQueueMap.get(shortestWaitRecordId);
                            //This should be handle Time
                            utilizedDCIRecord.DCITimeUntilFree__c = utilizedDCIRecord.DCITimeUntilFree__c.addMinutes(handleTime.intValue());
                            engagedStoreQueueMap.put(shortestWaitRecordId, utilizedDCIRecord);
                            engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                        } else {
                            engagedStoreQueueMap = new Map<Id, RetailCheckinQueue__c>();
                            pendingRecord.DCITimeUntilFree__c = System.now().addMinutes(handleTime.intValue());
                            engagedStoreQueueMap.put(pendingRecord.Id, pendingRecord);
                            engagedQueueMap.put(pendingRecord.Store__c, engagedStoreQueueMap);
                        }
                    }
                    
                    if (pendingQueueMap.containsKey(pendingRecord.Store__c)) {
                        List<RetailCheckinQueue__c> storePendingQueue = pendingQueueMap.get(pendingRecord.Store__c);
                        storePendingQueue.add(pendingRecord);
                        pendingQueueMap.put(pendingRecord.Store__c, storePendingQueue);
                    } else {
                        pendingQueueMap.put(pendingRecord.Store__c, new List<RetailCheckinQueue__c>{pendingRecord});
                    }
                }
                
                //Find shortest TUF for all stores in engaged queue map
                if (engagedQueueMap != null && engagedQueueMap.size() > 0) {
                    for (Id storeId : engagedQueueMap.keySet()) {
                        //Engaged Queue:
                        //Record A : TUF = 1:30pm ; Rep A
                        //Record B : TUF = 1:40pm ; Rep B
                        //Record C: TUF = 1:20pm ; Rep C
                        //Record D: TUF = 1:10pm ---> Should be latestTimeUntilFree ; Rep D
                        //Record E: Estimated Start Time = 1:10pm 
                        //
                        //Rep D's TUF = 1:10 + Record E's Handle Time (update in cache)
                        //
                        //Scenarios that would require recalculation and overwriting cache:
                        //Reps Online
                        //Reps Offline
                        //Swap
                        //Cancel
                        //Help Next Customer
                        //BOPIS Creation
                        //Future Processed
                        //
                        //Cache helps with: Creation of new check-in at end of queue
                        //Equivalent to using Time Until Free field on Store
                        DateTime latestTimeUntilFree;
                        Store__c recordStore = storeMap.get(storeId);
                        if(recordStore.DCIStoreRepActiveCapacity__c > engagedQueueMap.get(storeId).size()){
                            latestTimeUntilFree = System.now();
                        }
                        else{
                            for (RetailCheckinQueue__c currentCheckin : engagedQueueMap.get(storeId).values()) {
                                if (latestTimeUntilFree == null) {
                                    latestTimeUntilFree = currentCheckin.DCITimeUntilFree__c;
                                } else {
                                    if (latestTimeUntilFree > currentCheckin.DCITimeUntilFree__c) {
                                        latestTimeUntilFree = currentCheckin.DCITimeUntilFree__c;
                                    }
                                }
                            }
                        }
                        
                        Integer leadsInCheckinQueue = pendingQueueMap.containsKey(storeId) ? pendingQueueMap.get(storeId).size() : 0;
                        Long minutes = (latestTimeUntilFree.getTime() - System.now().getTime()) / 60000;
                        Integer estimatedWaitTime = minutes < 0 ? 0 : minutes.intValue() + 1;
                        
                        updatedStores.add(new Store__c(Id = storeId, DCIShortestTUF__c = latestTimeUntilFree, DCILeadsinCheckinQueue__c = leadsInCheckinQueue, DCIEstimatedWaitTime__c = estimatedWaitTime));
                    }
                } else {
                    for (Id storeId : storeIds) {
                        Integer leadsInCheckinQueue = 0;
                        Integer estimatedWaitTime = 0;
                        
                        updatedStores.add(new Store__c(Id = storeId, DCIShortestTUF__c = System.now(), DCILeadsinCheckinQueue__c = leadsInCheckinQueue, DCIEstimatedWaitTime__c = estimatedWaitTime));
                    }
                }
            }
        }
        
        //Add to org cache here?
        update updatedStores;
    }
    /**
* This method updates the EWT of all the records below the affected DCI record in the store
* This  method is called  in ProcessMessagingSessionHelper to process Cancelled checkin in bulk
* Parameters 
* storeIdSet -> Set of all Salesforce record id of the stores in the batch
* cancelledCheckinMap -> Map of all checkin records to be cancelled only
* currentCheckinMap -> Map of all checkin records that are getting updated in this batch
*/   
    public static RetailDTO.DCIUpdateRecordDTO processPendingQueueBulk(RetailDTO.DCIDataHelperDTO helper){
        //List<RetailCheckinQueue__c> updateCheckinList = new List<RetailCheckinQueue__c>();
        map<Id,Store__c> storeMap = fetchStoresMap(helper.storeIdSet);
        map<Id,Store__c> storeSwapMap = fetchStoresMap(helper.storeIdSwapSet);
        map<Id,Store__c> storeNoshowMap = fetchStoresMap(helper.storeIdNoShowSet);
        helper.storeIdSet.addAll(helper.storeIdSwapSet);
        helper.storeIdSet.addAll(helper.storeIdNoShowSet);
        map<String, Decimal> typeToHandleTimeMap = DCIConstants.getStoreHandleTimeMap(helper.storeIdSet);
        system.debug(helper.currentCheckinMap); 
        system.debug(helper.swapCheckinMap);  
        system.debug(helper.cancelledCheckinMap);  
        system.debug('SELECT id, Status__c, QueuePosition__c, EstimatedWaitTime__c, LastEWTUpdated__c, Store__c, Lead__r.ReasonForLeaving__c, DCIMaximum_EWT__c, DCIMinimum_EWT__c '+
                     +'FROM RetailCheckinQueue__c'+
                     +'WHERE Store__c in '+helper.storeIdSet+ ' AND '
                     +'Status__c IN '+DCIConstants.ALL_PENDING+' AND '
                     +'QueuePosition__c  > 0'
                     +'ORDER BY Store__c,QueuePosition__c');
        List<RetailCheckinQueue__c> pendingQueue = [SELECT id, DCIAssignedRSC__c, Store__r.LocationId__c, Status__c, QueuePosition__c, EstimatedWaitTime__c, LastEWTUpdated__c, Store__c, Lead__r.ReasonForLeaving__c,DCIMaximum_EWT__c,DCIMinimum_EWT__c
                                                    FROM RetailCheckinQueue__c
                                                    WHERE Store__c in :helper.storeIdSet AND 
                                                    Status__c IN :DCIConstants.ALL_PENDING AND  
                                                    QueuePosition__c  > 0
                                                    WITH SECURITY_ENFORCED ORDER BY Store__c,QueuePosition__c];
        
        for(RetailCheckinQueue__c dciRecord: pendingQueue){
            //Pick the updated Dci record from this batch of records being processed.
            if(helper.currentCheckinMap.containsKey(dciRecord.Id)){
                dciRecord = helper.currentCheckinMap.get(dciRecord.Id);
            }
            
            // One record below Swap record
            if(helper.swappedtoStoreMap.containsKey(dciRecord.Store__c)){ 
                if(dciRecord.Status__c != DCIConstants.CANCELLED){
                    RetailCheckinQueue__c recordTobeMovedBack = helper.swappedtoStoreMap.get(dciRecord.Store__c);
                    Decimal ewtDiff =  dciRecord.EstimatedWaitTime__c - recordTobeMovedBack.EstimatedWaitTime__c;
                    helper.ewtDiffTrecords.put(recordTobeMovedBack.Id,ewtDiff);
                    System.debug('ewtDiff:: '+ewtDiff);
                    Boolean swapSuccess = swapRecords(helper.currentCheckinMap,typeToHandleTimeMap,recordTobeMovedBack,dciRecord,storeSwapMap);
                    System.debug('swapSuccess:: '+swapSuccess);
                    if(swapSuccess){
                        recordTobeMovedBack.DCIChangeReason__c = 'Move Up';
                        dciRecord.DCIChangeReason__c = 'Move Up';
                        helper.currentCheckinMap.put(recordTobeMovedBack.ID,recordTobeMovedBack);
                        helper.currentCheckinMap.put(dciRecord.ID,dciRecord);
                    }
                    helper.swappedtoStoreMap.remove(dciRecord.Store__c);
                }
            }
            
            if(helper.swapCheckinMap.containsKey(dciRecord.Id)){
                helper.swappedtoStoreMap.put(dciRecord.Store__c,dciRecord);
            }
            
            //Pick the updated Dci record from this batch of records being processed.
            if(helper.currentCheckinMap.containsKey(dciRecord.Id)){
                dciRecord = helper.currentCheckinMap.get(dciRecord.Id);
            }
            
            if(helper.noShowCheckinMap.containsKey(dciRecord.Id)){
                //Cancelled records here
                System.debug('Noshow Record '+dciRecord.QueuePosition__c);
                helper.noshowtoStoreMap.put(dciRecord.Store__c,true);
                System.debug('Noshow Record '+helper.noshowtoStoreMap);
            }else if(helper.noshowtoStoreMap.containsKey(dciRecord.Store__c)){
                //all records below Noshow records get updated here
                
                System.debug('Below Noshow Record '+dciRecord.QueuePosition__c);
                Store__c store = storeNoShowMap.get(dciRecord.Store__c);
                if(helper.lastEWTtoStoreMapNS.containsKey(dciRecord.Store__c)){
                    String transactionType = null; 
                    if(dciRecord.Lead__c != null && dciRecord.Lead__r.ReasonForLeaving__c != null){
                        transactionType = dciRecord.Lead__r.ReasonForLeaving__c;
                        Decimal handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, transactionType, dciRecord.Store__c);
                        dciRecord.EstimatedWaitTime__c = calculateEstimatedWaitTime(helper.lastEWTtoStoreMapNS.get(dciRecord.Store__c), store, handleTime);
                        dciRecord.DCIEstimatedStartTime__c = System.now().addMinutes(Integer.valueOf(dciRecord.EstimatedWaitTime__c));
                        if(dciRecord.DCIMaximum_EWT__c<dciRecord.EstimatedWaitTime__c){
                            dciRecord.DCIMaximum_EWT__c = dciRecord.EstimatedWaitTime__c;
                            dciRecord.DCITotalRepCount__c=store.DCIStoreRepActiveCapacity__c;
                            dciRecord.DCIAvailableRepCount__c=store.DCIStoreRepCurrentCapacity__c;
                        }
                        
                        if(dciRecord.DCIMinimum_EWT__c>dciRecord.EstimatedWaitTime__c){
                            dciRecord.DCIMinimum_EWT__c = dciRecord.EstimatedWaitTime__c;
                        }
                        
                        dciRecord.LastEWTUpdated__c =  System.now();
                        if(helper.queuePostoStoreMapNS.containsKey(dciRecord.Store__c))
                            dciRecord.QueuePosition__c = helper.queuePostoStoreMapNS.get(dciRecord.Store__c) + 1;
                    }                
                }else{
                    dciRecord.EstimatedWaitTime__c = 0;
                    dciRecord.DCIEstimatedStartTime__c = System.now();
                    if(dciRecord.DCIMaximum_EWT__c<dciRecord.EstimatedWaitTime__c){
                        dciRecord.DCIMaximum_EWT__c = dciRecord.EstimatedWaitTime__c;
                        dciRecord.DCITotalRepCount__c=store.DCIStoreRepActiveCapacity__c;
                        dciRecord.DCIAvailableRepCount__c=store.DCIStoreRepCurrentCapacity__c;
                    }
                    
                    if(dciRecord.DCIMinimum_EWT__c>dciRecord.EstimatedWaitTime__c){
                        dciRecord.DCIMinimum_EWT__c = dciRecord.EstimatedWaitTime__c;
                    }
                    
                    dciRecord.QueuePosition__c = 1;
                    dciRecord.LastEWTUpdated__c =  System.now();
                }
                helper.lastEWTtoStoreMapNS.put(dciRecord.Store__c,dciRecord.EstimatedWaitTime__c);
                helper.queuePostoStoreMapNS.put(dciRecord.Store__c,dciRecord.QueuePosition__c);
                dciRecord.DCIChangeReason__c = 'Customer marked no-Show';
                helper.currentCheckinMap.put(dciRecord.ID,dciRecord);
            }else{
                //Update Map values for other records
                helper.lastEWTtoStoreMapNS.put(dciRecord.Store__c,dciRecord.EstimatedWaitTime__c);
                helper.queuePostoStoreMapNS.put(dciRecord.Store__c,dciRecord.QueuePosition__c); 
            }
            
            //Pick the updated Dci record from this batch of records being processed.
            if(helper.currentCheckinMap.containsKey(dciRecord.Id)){
                dciRecord = helper.currentCheckinMap.get(dciRecord.Id);
            }
            
            if(helper.cancelledCheckinMap.containsKey(dciRecord.Id)){
                //Cancelled records here
                System.debug('Cancelled Record '+dciRecord.QueuePosition__c);
                helper.cancelledtoStoreMap.put(dciRecord.Store__c,true);
            }else if(helper.cancelledtoStoreMap.containsKey(dciRecord.Store__c)){
                //all records below Cancelled records get updated here
                Store__c store = storeMap.get(dciRecord.Store__c);
                if(helper.lastEWTtoStoreMap.containsKey(dciRecord.Store__c)){
                    String transactionType = null; 
                    if(dciRecord.Lead__c != null && dciRecord.Lead__r.ReasonForLeaving__c != null){
                        transactionType = dciRecord.Lead__r.ReasonForLeaving__c;
                        Decimal handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, transactionType, dciRecord.Store__c);
                        dciRecord.EstimatedWaitTime__c = calculateEstimatedWaitTime(helper.lastEWTtoStoreMap.get(dciRecord.Store__c), store, handleTime);
                        dciRecord.DCIEstimatedStartTime__c = System.now().addMinutes(Integer.valueOf(dciRecord.EstimatedWaitTime__c));
                        if(dciRecord.DCIMaximum_EWT__c<dciRecord.EstimatedWaitTime__c){
                            dciRecord.DCIMaximum_EWT__c = dciRecord.EstimatedWaitTime__c;
                            dciRecord.DCITotalRepCount__c=store.DCIStoreRepActiveCapacity__c;
                            dciRecord.DCIAvailableRepCount__c=store.DCIStoreRepCurrentCapacity__c;
                        }
                        
                        if(dciRecord.DCIMinimum_EWT__c>dciRecord.EstimatedWaitTime__c){
                            dciRecord.DCIMinimum_EWT__c = dciRecord.EstimatedWaitTime__c;
                        }
                        
                        dciRecord.LastEWTUpdated__c =  System.now();
                        if(helper.queuePostoStoreMap.containsKey(dciRecord.Store__c))
                            dciRecord.QueuePosition__c = helper.queuePostoStoreMap.get(dciRecord.Store__c) + 1;
                    }                
                }else{
                    dciRecord.EstimatedWaitTime__c = 0;
                    dciRecord.DCIEstimatedStartTime__c = System.now();
                    if(dciRecord.DCIMaximum_EWT__c<dciRecord.EstimatedWaitTime__c){
                        dciRecord.DCIMaximum_EWT__c = dciRecord.EstimatedWaitTime__c;
                        dciRecord.DCITotalRepCount__c=store.DCIStoreRepActiveCapacity__c;
                        dciRecord.DCIAvailableRepCount__c=store.DCIStoreRepCurrentCapacity__c;
                    }
                    
                    if(dciRecord.DCIMinimum_EWT__c>dciRecord.EstimatedWaitTime__c){
                        dciRecord.DCIMinimum_EWT__c = dciRecord.EstimatedWaitTime__c;
                    }
                    
                    dciRecord.QueuePosition__c = 1;
                    dciRecord.LastEWTUpdated__c =  System.now();
                }
                helper.lastEWTtoStoreMap.put(dciRecord.Store__c,dciRecord.EstimatedWaitTime__c);
                helper.queuePostoStoreMap.put(dciRecord.Store__c,dciRecord.QueuePosition__c);
                dciRecord.DCIChangeReason__c = DCIConstants.DCIRemoveChangeReason;
                helper.currentCheckinMap.put(dciRecord.ID,dciRecord);
            }else{
                //Update Map values for other records
                helper.lastEWTtoStoreMap.put(dciRecord.Store__c,dciRecord.EstimatedWaitTime__c);
                helper.queuePostoStoreMap.put(dciRecord.Store__c,dciRecord.QueuePosition__c); 
            }
        } 
        List<Store__c> updateStoreList = new List<Store__c>();
        for(Id storeId : storeMap.keyset()){
            Store__c store = storeMap.get(storeId);
            Decimal handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, null, null);
            Decimal lastEwt = helper.lastEWTtoStoreMap.get(store.Id);
            if(lastEwt!=null){
                store.DCIEstimatedWaitTime__c = calculateEstimatedWaitTime(lastEwt, store, handleTime);
                store.DCILeadsinCheckinQueue__c = helper.queuePostoStoreMap.get(store.Id);    
            }else{
                store.DCIEstimatedWaitTime__c = 0;
                store.DCILeadsinCheckinQueue__c = 0; 
            }
            System.debug('Store: '+store.Name +' '+store.DCIEstimatedWaitTime__c+' '+store.DCILeadsinCheckinQueue__c);
            updateStoreList.add(store);
        }
        
        for(Id storeId : storeNoShowMap.keyset()){
            System.debug('lastEWTtoStoreMapNS :: '+helper.lastEWTtoStoreMapNS);
            System.debug('queuePostoStoreMapNS :: '+helper.queuePostoStoreMapNS);
            Store__c store = storeNoShowMap.get(storeId);
            Decimal handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, null, null);
            Decimal lastEwt = helper.lastEWTtoStoreMapNS.get(store.Id);
            if(lastEwt!=null){
                store.DCIEstimatedWaitTime__c = calculateEstimatedWaitTime(lastEwt, store, handleTime);
                store.DCILeadsinCheckinQueue__c = helper.queuePostoStoreMapNS.get(store.Id);    
            }else{
                store.DCIEstimatedWaitTime__c = 0;
                store.DCILeadsinCheckinQueue__c = 0; 
            }
            System.debug('Noshow Store: '+store.Name +' '+store.DCIEstimatedWaitTime__c+' '+store.DCILeadsinCheckinQueue__c);
            updateStoreList.add(store);
        }
        
        RetailDTO.DCIUpdateRecordDTO updateRecords = new RetailDTO.DCIUpdateRecordDTO();
        updateRecords.updateStoreList = updateStoreList;
        
        return updateRecords;
    }
    /*get store Ids in this method*/
    public static set<Id> getStoreIds (List<RetailCheckinQueue__c> dciQueue){
        set<Id> storeIds = new set<Id> ();
        for(RetailCheckinQueue__c rcq: dciQueue){
            storeIds.add(rcq.Store__c);
        }
        return storeIds;
    }
    /* This method provides RetailCheckinQueue__c Map and */
    public static  Map<Id,RetailCheckinQueue__c> getQueMap(set<Id> storeIds){
        List<RetailCheckinQueue__c> dciLeadsList = [Select ID,Store__c,Status__c,QueuePosition__c,EstimatedWaitTime__c from RetailCheckinQueue__c where Store__c IN:storeIds and QueuePosition__c > 0 and Status__c IN :DCIConstants.ALL_PENDING WITH SECURITY_ENFORCED order by QueuePosition__c desc];
        Map<Id,RetailCheckinQueue__c> queMap = new Map<Id,RetailCheckinQueue__c> (); 
        for(RetailCheckinQueue__c rcq: dciLeadsList){
            RetailCheckinQueue__c x= queMap.get(rcq.Store__c);
            if(x == null){
                x = rcq;
            }else if(rcq.QueuePosition__c > x.QueuePosition__c){
                x= rcq;
            }
            queMap.put(rcq.Store__c,x);
        }
        return queMap;
    }
    
    /*
*This method swaps the two checkin records
*/
    public static Boolean swapRecords(map<Id, RetailCheckinQueue__c> currentCheckinMap,map<String, Decimal> typeToHandleTimeMap, RetailCheckinQueue__c dciRecordTobeSwapped, RetailCheckinQueue__c dciRecordTobeSwappedWith, map<Id,Store__c> storeSwapMap) {      
        try {
            Decimal dciRecordTobeSwappedHandleTime = 0; Decimal dciRecordTobeSwappedWithHandleTime = 0;
            if(dciRecordTobeSwapped.Lead__c != null && dciRecordTobeSwapped.Lead__r.ReasonForLeaving__c != null)
                dciRecordTobeSwappedHandleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, dciRecordTobeSwapped.Lead__r.ReasonForLeaving__c, dciRecordTobeSwapped.Store__c);
            if(dciRecordTobeSwappedWith.Lead__c != null && dciRecordTobeSwappedWith.Lead__r.ReasonForLeaving__c != null)
                dciRecordTobeSwappedWithHandleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, dciRecordTobeSwappedWith.Lead__r.ReasonForLeaving__c, dciRecordTobeSwappedWith.Store__c);
            
            System.debug('swap:: '+dciRecordTobeSwapped);
            System.debug('swapWith:: '+dciRecordTobeSwappedWith);
            Store__c swapStore = storeSwapMap.get(dciRecordTobeSwapped.Store__c); 
            System.debug('Store:: '+swapStore.DCIStoreRepActiveCapacity__c);
            
            Decimal tempEWT = dciRecordTobeSwapped.EstimatedWaitTime__c;
            Decimal tempQP = dciRecordTobeSwapped.QueuePosition__c; 
            Decimal Difference = 0;
            if (swapStore.DCIStoreRepActiveCapacity__c > 0) {            
                Difference = (dciRecordTobeSwappedWithHandleTime - dciRecordTobeSwappedHandleTime)/swapStore.DCIStoreRepActiveCapacity__c;
            } else {
                Difference = dciRecordTobeSwappedWithHandleTime - dciRecordTobeSwappedHandleTime;
            }
            System.debug('Difference:: '+Difference);
            dciRecordTobeSwapped.QueuePosition__c = dciRecordTobeSwappedWith.QueuePosition__c;
            dciRecordTobeSwappedWith.QueuePosition__c = tempQP;
            dciRecordTobeSwapped.EstimatedWaitTime__c = dciRecordTobeSwappedWith.EstimatedWaitTime__c;
            dciRecordTobeSwapped.DCIEstimatedStartTime__c = System.now().addMinutes(Integer.valueOf(dciRecordTobeSwapped.EstimatedWaitTime__c));
            dciRecordTobeSwappedWith.EstimatedWaitTime__c = tempEWT + Difference; 
            dciRecordTobeSwappedWith.DCIEstimatedStartTime__c = System.now().addMinutes(Integer.valueOf(dciRecordTobeSwappedWith.EstimatedWaitTime__c));
            
            if(dciRecordTobeSwapped.DCIMaximum_EWT__c<dciRecordTobeSwapped.EstimatedWaitTime__c){
                dciRecordTobeSwapped.DCIMaximum_EWT__c = dciRecordTobeSwapped.EstimatedWaitTime__c;
                dciRecordTobeSwapped.DCITotalRepCount__c=swapStore.DCIStoreRepActiveCapacity__c;
                dciRecordTobeSwapped.DCIAvailableRepCount__c=swapStore.DCIStoreRepCurrentCapacity__c;
            }
            
            if(dciRecordTobeSwapped.DCIMinimum_EWT__c>dciRecordTobeSwapped.EstimatedWaitTime__c){
                dciRecordTobeSwapped.DCIMinimum_EWT__c = dciRecordTobeSwapped.EstimatedWaitTime__c;
            }
            
            if(dciRecordTobeSwappedWith.DCIMaximum_EWT__c<dciRecordTobeSwappedWith.EstimatedWaitTime__c){
                dciRecordTobeSwappedWith.DCIMaximum_EWT__c = dciRecordTobeSwappedWith.EstimatedWaitTime__c;
                dciRecordTobeSwapped.DCITotalRepCount__c=swapStore.DCIStoreRepActiveCapacity__c;
                dciRecordTobeSwapped.DCIAvailableRepCount__c=swapStore.DCIStoreRepCurrentCapacity__c;
            }
            
            if(dciRecordTobeSwappedWith.DCIMinimum_EWT__c>dciRecordTobeSwappedWith.EstimatedWaitTime__c){
                dciRecordTobeSwappedWith.DCIMinimum_EWT__c = dciRecordTobeSwappedWith.EstimatedWaitTime__c;
            } 
            return true;  
        } catch (Exception e){
            System.debug('Exception in Swapping'+e.getMessage());
            return false;
        }
    }
    /**
* Thismethod updates the EWT for whole DCI queue for the store and also the store EWT
* This  method is called  after, Rep status change, Lead  acceptance
* Parameters 
* storeId -> Salesforce record id of the store
* sequence -> The queue EWT post this seq is updated
* updateQPosition -> This  boolean flag determines if the queue position is supoosed to be decrementedby 1 or not
*                    This is set to true only during accept scenario
*/
    public static void updateQueueBulkify(Set<Id> storeIds, Integer sequence, Boolean updateQPosition, String dciChangeReason) {
        system.debug(DCIConstants.ALL_PENDING);
        if(storeIds != null) {
            Decimal  storeEWT = 0;
            Set<Id> storeIdSet = new Set<Id>();
            Map<Id,Store__c> storeMap = new Map<Id,Store__c> ([SELECT id, DCIEstimatedWaitTime__c, DCIStoreRepActiveCapacity__c, DCIStoreRepCurrentCapacity__c, DCILeadsinCheckinQueue__c FROM Store__c WHERE id IN:storeIds WITH SECURITY_ENFORCED]);
            storeIdSet.addAll(storeIds);
            if(storeMap !=  null){
                map<String, Decimal> typeToHandleTimeMap = DCIConstants.getStoreHandleTimeMap(storeIdSet);
                List<RetailCheckinQueue__c> pendingQueue = getPendingQueueBulkify(storeIdSet, sequence);
                Decimal handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, null, null);
                Map<string,Decimal> lastEwtMap = new  Map<string,Decimal>();
                if(sequence > 0) {
                    lastEwtMap = getLastEWTBulkify(storeIdSet, sequence);
                }
                for(RetailCheckinQueue__c pendingDci: pendingQueue) {
                    string storeId = pendingDci.Store__c;
                    Store__c store = storeMap.get(pendingDci.Store__c);
                    Decimal lastEwt = 0;                                 
                    if(lastEwtMap != null && lastEwtMap.get(pendingDci.Store__c) != null ){
                        lastEwt =lastEwtMap.get(pendingDci.Store__c);
                    }
                    String transactionType = null; 
                    if(pendingDci.Lead__c != null && pendingDci.Lead__r.ReasonForLeaving__c != null){
                        transactionType = pendingDci.Lead__r.ReasonForLeaving__c;
                    }
                    handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, transactionType, storeId);
                    system.debug('pendingDci.QueuePosition__c' +pendingDci.QueuePosition__c);
                    if(updateQPosition){
                        pendingDci.QueuePosition__c = pendingDci.QueuePosition__c - 1;
                    }
                    system.debug('lastEwt' +lastEwt);
                    system.debug('store' +store);
                    system.debug('handleTime' +handleTime);
                    pendingDci.EstimatedWaitTime__c = calculateEstimatedWaitTime(lastEwt, store, handleTime);
                    pendingDci.DCIEstimatedStartTime__c = System.now().addMinutes(Integer.valueOf(pendingDci.EstimatedWaitTime__c));
                    if(pendingDci.QueuePosition__c  == 1  && store.DCIStoreRepCurrentCapacity__c > 0){
                        pendingDci.EstimatedWaitTime__c = 0;
                        pendingDci.DCIEstimatedStartTime__c = System.now();
                    }
                    if(pendingDci.DCIMaximum_EWT__c<pendingDci.EstimatedWaitTime__c){
                        pendingDci.DCIMaximum_EWT__c = pendingDci.EstimatedWaitTime__c;
                        pendingDci.DCITotalRepCount__c=store.DCIStoreRepActiveCapacity__c;
                        pendingDci.DCIAvailableRepCount__c=store.DCIStoreRepCurrentCapacity__c;
                    }
                    if(pendingDci.DCIMinimum_EWT__c>pendingDci.EstimatedWaitTime__c){
                        pendingDci.DCIMinimum_EWT__c = pendingDci.EstimatedWaitTime__c;
                    }
                    pendingDci.LastEWTUpdated__c =  System.now();
                    pendingDci.DCIChangeReason__c = dciChangeReason;
                    storeEWT = pendingDci.EstimatedWaitTime__c;
                    lastEwt = pendingDci.EstimatedWaitTime__c;
                    lastEwtMap.put(storeId,lastEwt);
                }

                update pendingQueue;  
                
                Map<Id,List<RetailCheckinQueue__c>> quesizeMap = new Map<Id,List<RetailCheckinQueue__c>> ();
                List<RetailCheckinQueue__c> pq = getPendingQueueBulkify(storeIdSet, 0);
                for(RetailCheckinQueue__c rcq: pq){
                    List<RetailCheckinQueue__c> x= quesizeMap.get(rcq.Store__c);
                    if(x == null){
                        x = new List<RetailCheckinQueue__c>();
                    }
                    x.add(rcq);
                    quesizeMap.put(rcq.Store__c,x);
                }
                for(Store__c store: storeMap.values()){
                    Decimal lastEwt = 0;                                 
                    if(lastEwtMap != null && lastEwtMap.get(store.Id) != null ){
                        lastEwt =lastEwtMap.get(store.Id);
                    }
                    handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, null, null);
                    store.DCIEstimatedWaitTime__c = calculateEstimatedWaitTime(lastEwt, store, handleTime);
                    if(quesizeMap != null && quesizeMap.get(store.Id) != null){
                        store.DCILeadsinCheckinQueue__c = quesizeMap.get(store.Id).size();
                    }
                }
                
                if(Schema.sObjectType.Store__c.fields.DCIEstimatedWaitTime__c.isUpdateable() && 
                   Schema.sObjectType.Store__c.fields.DCILeadsinCheckinQueue__c.isUpdateable()){
                       update storeMap.values();
                   }
            } else {
                throw new RetailError.ServerSideException('Please share a valid store Id for EWT recalculations');
            }
        }else{
            throw new RetailError.ServerSideException('Please share a valid store Id for EWT recalculations');
        }
    }
    /*
* This method gets the all the pending DCI records in store queue post the provided sequence 
* Parameters
* storeId -> Salesforce record id of the store
* sequence -> Fetch the queue records post this sequence only
* Return-> List of fetched  REtail
*/
    public static List<RetailCheckinQueue__c> getPendingQueueBulkify(set<Id> storeId, Integer sequence) {
        system.debug('SELECT id, Status__c, QueuePosition__c, EstimatedWaitTime__c, LastEWTUpdated__c, Store__c, Lead__r.ReasonForLeaving__c, DCIMaximum_EWT__c, DCIMinimum_EWT__c '+
                     +'FROM RetailCheckinQueue__c'+
                     +'WHERE Store__c ='+storeId+ ' AND '
                     +'Status__c IN '+DCIConstants.ALL_PENDING+' AND '
                     +'QueuePosition__c  > '+sequence +' '
                     +'ORDER BY QueuePosition__c');
        List<RetailCheckinQueue__c> pendingQueue = [SELECT id, Status__c, QueuePosition__c, EstimatedWaitTime__c, LastEWTUpdated__c, Store__c, Lead__c, Lead__r.ReasonForLeaving__c, DCIMaximum_EWT__c, DCIMinimum_EWT__c, DCITimeWaiting__c
                                                    FROM RetailCheckinQueue__c
                                                    WHERE Store__c IN :storeId AND 
                                                    Status__c IN :DCIConstants.ALL_PENDING AND  
                                                    QueuePosition__c  > :sequence
                                                    WITH SECURITY_ENFORCED ORDER BY QueuePosition__c];
        return pendingQueue;
    }
    
    /**
* Thismethod updates the EWT for whole DCI queue for the store and also the store EWT
* This  method is called  after, Rep status change, Lead  acceptance
* Parameters 
* storeId -> Salesforce record id of the store
* sequence -> The queue EWT post this seq is updated
* updateQPosition -> This  boolean flag determines if the queue position is supoosed to be decrementedby 1 or not
*                    This is set to true only during accept scenario
*/
    public static void updateQueue(Id storeId, Integer sequence, Boolean updateQPosition, Boolean qDecrement, String dciChangeReason) {
        system.debug('Inside Update Queue--storeId-->'+storeId+'--sequence-->'+sequence);
        system.debug(DCIConstants.ALL_PENDING);
        if(storeId != null) { //If storeId is null, do not proceed
            Decimal  storeEWT = 0;
            Set<Id> storeIdSet = new Set<Id>();
            Store__c store  = fetchStore(storeId);
            storeIdSet.add(storeId);
            if(store !=  null) {
                map<String, Decimal> typeToHandleTimeMap = DCIConstants.getStoreHandleTimeMap(storeIdSet);
                List<RetailCheckinQueue__c> pendingQueue = getPendingQueue(storeId, sequence);
                system.debug('pendingQueue--->>'+pendingQueue);
                Decimal handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, null, null);
                Decimal lastEwt = 0;
                if(sequence > 0) {
                    lastEwt = getLastEWT(storeId, sequence);
                }
                for(RetailCheckinQueue__c pendingDci: pendingQueue) {
                    String transactionType = null; 
                    if(pendingDci.Lead__c != null && pendingDci.Lead__r.ReasonForLeaving__c != null)
                        transactionType = pendingDci.Lead__r.ReasonForLeaving__c;
                    handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, transactionType, storeId);
                    system.debug('pendingDci before-->>'+pendingDci);
                    if(updateQPosition && qDecrement)
                        pendingDci.QueuePosition__c = pendingDci.QueuePosition__c - 1;
                    else if(updateQPosition && !qDecrement)
                        pendingDci.QueuePosition__c = pendingDci.QueuePosition__c + 1;
                    
                    pendingDci.EstimatedWaitTime__c = calculateEstimatedWaitTime(lastEwt, store, handleTime);
                    pendingDci.DCIEstimatedStartTime__c = System.now().addMinutes(Integer.valueOf(pendingDci.EstimatedWaitTime__c));
                    if(pendingDci.QueuePosition__c  == 1  && store.DCIStoreRepCurrentCapacity__c > 0)
                        pendingDci.EstimatedWaitTime__c = 0;
                    pendingDci.DCIEstimatedStartTime__c = System.now();
                    
                    if(pendingDci.DCIMaximum_EWT__c<pendingDci.EstimatedWaitTime__c){
                        pendingDci.DCIMaximum_EWT__c = pendingDci.EstimatedWaitTime__c;
                        pendingDci.DCITotalRepCount__c=store.DCIStoreRepActiveCapacity__c;
                        pendingDci.DCIAvailableRepCount__c=store.DCIStoreRepCurrentCapacity__c;
                    }
                    
                    if(pendingDci.DCIMinimum_EWT__c>pendingDci.EstimatedWaitTime__c){
                        pendingDci.DCIMinimum_EWT__c = pendingDci.EstimatedWaitTime__c;
                    }
                    pendingDci.LastEWTUpdated__c =  System.now();
                    pendingDci.DCIChangeReason__c = dciChangeReason;
                    storeEWT = pendingDci.EstimatedWaitTime__c;
                    lastEwt = pendingDci.EstimatedWaitTime__c;
                    system.debug('pendingDci after-->>'+pendingDci);
                }
                
                update pendingQueue;
                handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, null, null);
                if(Schema.sObjectType.Store__c.fields.DCIEstimatedWaitTime__c.isUpdateable() && 
                   Schema.sObjectType.Store__c.fields.DCILeadsinCheckinQueue__c.isUpdateable()){
                       store.DCIEstimatedWaitTime__c = calculateEstimatedWaitTime(lastEwt, store, handleTime);
                       store.DCILeadsinCheckinQueue__c = getPendingQueue(storeId, 0).size();
                       update store;
                   }
            } else {
                throw new RetailError.ServerSideException('Please share a valid store Id for EWT recalculations');
            }
        }else{
            throw new RetailError.ServerSideException('Please share a valid store Id for EWT recalculations');
        }
    }
    
    
    /**
* Thismethod updates the EWT for whole DCI queue for the store and also the store EWT
* This  method is called after future DCI records have been added to the queue
* Parameters 
* storeId -> Salesforce record id of the store
* sequence -> The queue EWT post this seq is updated
* updateQPosition -> This  boolean flag determines if the queue position is supoosed to be decrementedby 1 or not
*                    This is set to true only during accept scenario
*/
    public static Map<String, Object> updateQueue(Store__c store, Map<String, Decimal> typeToHandleTimeMap, List<RetailCheckinQueue__c> pendingQueue, String dciChangeReason) {
        Decimal  storeEWT = 0;
        if(store !=  null) {
            Decimal handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, null, null);
            Decimal lastEwt = 0;
            
            for(RetailCheckinQueue__c pendingDci: pendingQueue) {
                String transactionType = null; 
                if(pendingDci.Lead__c != null && pendingDci.Lead__r.ReasonForLeaving__c != null) {
                    transactionType = pendingDci.Lead__r.ReasonForLeaving__c;
                }
                handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, transactionType, store.Id);
                
                pendingDci.EstimatedWaitTime__c = calculateEstimatedWaitTime(lastEwt, store, handleTime);
                pendingDci.DCIEstimatedStartTime__c = System.now().addMinutes(Integer.valueOf(pendingDci.EstimatedWaitTime__c));
                if(pendingDci.QueuePosition__c  == 1  && store.DCIStoreRepCurrentCapacity__c > 0) {
                    pendingDci.EstimatedWaitTime__c = 0;
                    pendingDci.DCIEstimatedStartTime__c = System.now();
                }
                
                if(pendingDci.DCIMaximum_EWT__c<pendingDci.EstimatedWaitTime__c) {
                    pendingDci.DCIMaximum_EWT__c = pendingDci.EstimatedWaitTime__c;
                    pendingDci.DCITotalRepCount__c=store.DCIStoreRepActiveCapacity__c;
                    pendingDci.DCIAvailableRepCount__c=store.DCIStoreRepCurrentCapacity__c;
                }
                
                if(pendingDci.DCIMinimum_EWT__c>pendingDci.EstimatedWaitTime__c) {
                    pendingDci.DCIMinimum_EWT__c = pendingDci.EstimatedWaitTime__c;
                }
                
                pendingDci.LastEWTUpdated__c =  System.now();
                pendingDci.DCIChangeReason__c = dciChangeReason;
                storeEWT = pendingDci.EstimatedWaitTime__c;
                lastEwt = pendingDci.EstimatedWaitTime__c;
            }
            Map<String, Object> returnMap = new Map<String, Object>();
            returnMap.put('dciRecordsToUpdate', pendingQueue);
            handleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, null, null);
            store.DCIEstimatedWaitTime__c = calculateEstimatedWaitTime(lastEwt, store, handleTime);
            store.DCILeadsinCheckinQueue__c = pendingQueue.size();
            returnMap.put('storeRecordToUpdate',store);
            return returnMap;
        } else {
            throw new RetailError.ServerSideException('Please share a valid store Id for EWT recalculations');
        }
    }
    
    /*
* This method gets the all the pending DCI records in store queue post the provided sequence 
* Parameters
* storeId -> Salesforce record id of the store
* sequence -> Fetch the queue records post this sequence only
* Return-> List of fetched  REtail
*/
    public static List<RetailCheckinQueue__c> getPendingQueue(Id storeId, Integer sequence) {
        system.debug('SELECT id, Status__c, QueuePosition__c, EstimatedWaitTime__c, LastEWTUpdated__c, Store__c, Lead__r.ReasonForLeaving__c, DCIMaximum_EWT__c, DCIMinimum_EWT__c, DCITimeWaiting__c '+
                     +'FROM RetailCheckinQueue__c'+
                     +'WHERE Store__c ='+storeId+ ' AND '
                     +'Status__c IN '+DCIConstants.ALL_PENDING+' AND '
                     +'QueuePosition__c  > '+sequence +' '
                     +'ORDER BY QueuePosition__c');
        List<RetailCheckinQueue__c> pendingQueue = [SELECT id, Status__c, QueuePosition__c, EstimatedWaitTime__c, LastEWTUpdated__c, Store__c, Lead__c, Lead__r.ReasonForLeaving__c, DCIMaximum_EWT__c, DCIMinimum_EWT__c, DCITimeWaiting__c
                                                    FROM RetailCheckinQueue__c
                                                    WHERE Store__c = :storeId AND 
                                                    Status__c IN :DCIConstants.ALL_PENDING AND  
                                                    QueuePosition__c  > :sequence
                                                    WITH SECURITY_ENFORCED ORDER BY QueuePosition__c];
        return pendingQueue;
    }
    /*
* This method gets the all the EWT of last DCI record  in queue
* Parameters
* storeId -> Salesforce record id of the store
* sequence -> Fetch the last EWT for queue record prior to this sequence 
* Return-> Last EWT
*/
    public static Decimal getLastEWT(Id storeId, Integer sequence) {
        Decimal  lastEwt = 0;
        List<RetailCheckinQueue__c> ewtCheckinList = [SELECT id, Status__c, QueuePosition__c, EstimatedWaitTime__c, LastEWTUpdated__c, Store__c, Lead__r.ReasonForLeaving__c
                                                      FROM RetailCheckinQueue__c
                                                      WHERE Store__c = :storeId AND   
                                                      QueuePosition__c  < :sequence
                                                      WITH SECURITY_ENFORCED ORDER BY QueuePosition__c DESC LIMIT 1];
        if(ewtCheckinList.size()>0)
            lastEwt = ewtCheckinList[0].EstimatedWaitTime__c;
        
        return lastEwt;
    }
    
    /*
* This method gets the all the EWT of last DCI record  in queue
* Parameters
* storeId -> Salesforce record id of the store
* sequence -> Fetch the last EWT for queue record prior to this sequence 
* Return-> Last EWT
*/
    public static Map<string,Decimal> getLastEWTBulkify(Set<Id> storeIds, Integer sequence) {
        Decimal  lastEwt = 0;
        map<String, Decimal> ewtMap = new map<String, Decimal>();
        List<RetailCheckinQueue__c> ewtCheckinList = [SELECT id, Status__c, QueuePosition__c, EstimatedWaitTime__c, LastEWTUpdated__c, Store__c, Lead__r.ReasonForLeaving__c
                                                      FROM RetailCheckinQueue__c
                                                      WHERE Store__c  IN:storeIds AND   
                                                      QueuePosition__c  < :sequence
                                                      WITH SECURITY_ENFORCED ORDER BY QueuePosition__c DESC LIMIT 1];
        if(ewtCheckinList.size()>0){
            for(RetailCheckinQueue__c rcq : ewtCheckinList){
                if(rcq.EstimatedWaitTime__c != null){
                    ewtMap.put(rcq.Store__c,rcq.EstimatedWaitTime__c);
                }else{
                    ewtMap.put(rcq.Store__c,0);
                }
                
            }
        }
        
        return ewtMap;
    }
    
    /**
* This method fetches the store details from the storeId
* Parameters
* storeId -> Salesforce record id of the store
*/

//6070
    @AuraEnabled
    public static Store__c fetchStore(Id storeId) {
        List<Store__c> storeList = [SELECT id,DCIShortestTUF__c,TimeZone__c, DCIEstimatedWaitTime__c, DCIStoreRepActiveCapacity__c,Name,  DCIStoreRepCurrentCapacity__c, DCILeadsinCheckinQueue__c, LocationId__c FROM Store__c WHERE id =:storeId WITH SECURITY_ENFORCED];
        if(storeList.size()  > 0)  {
            return storeList.get(0);
        }
        return null;
    }
    
    /**
* This method fetches the store details from the storeIdSet into Map
* Parameters
* setstoreId -> Salesforce record id of the store
*/
    //6070
    public static Map<Id,Store__c> fetchStoresMap(Set<Id> storeIdSet) {
        Map<Id,Store__c> storeMap = new Map<Id,Store__c>();
        List<Store__c> storeList = [SELECT id,DCIShortestTUF__c,TimeZone__c, Name, DCIEstimatedWaitTime__c, DCIStoreRepActiveCapacity__c, DCIStoreRepCurrentCapacity__c, DCILeadsinCheckinQueue__c, LocationId__c FROM Store__c WHERE id in :storeIdSet WITH SECURITY_ENFORCED];
        for(Store__c store:storeList){
            storeMap.put(store.id,store);
        }
        return storeMap;
    }
    
    /**
* This method uses the formula to calculate the EWT with goven parameters
* @Parameters - Decimal lastEwt - EWT of the Last Lead - 0 if the thiss is first Lead
*               Store__c leadStore - Store record to get active reps
*               Decimal handleTime - HandleTime for this specific transaction
* @Return Decimal EWT -> The EWT of this Lead
*/
    public static Decimal calculateEstimatedWaitTime(Decimal lastEwt, Store__c leadStore, Decimal handleTime){
        Decimal estimatedWaitTime;
        system.debug('lead store '+leadStore);
        if(leadStore != Null){
            if(leadStore.DCIStoreRepActiveCapacity__c<=0){ 
                estimatedWaitTime = lastEwt + handleTime;
            }  else {
                estimatedWaitTime =lastEwt + (handleTime/leadStore.DCIStoreRepActiveCapacity__c) ;
            } 
            estimatedWaitTime  = estimatedWaitTime.round(System.RoundingMode.CEILING);
        }
        
        return estimatedWaitTime;
    }
    
    /**
* This method handles the logic to accept the a DCI record by the Rep/SM
* @Parameters - RetailCheckinQueue__c dciRecord -> The dciRecord to be accepted
*/
    public static void accept(RetailCheckinQueue__c dciRecord) {
        Integer quePos;
        Store__c strRec = fetchStore(dciRecord.Store__c);
        if(Schema.sObjectType.RetailCheckinQueue__c.fields.Status__c.isUpdateable() &&
           Schema.sObjectType.RetailCheckinQueue__c.fields.QueuePosition__c.isUpdateable() &&
           Schema.sObjectType.RetailCheckinQueue__c.fields.EstimatedWaitTime__c.isUpdateable() &&
           Schema.sObjectType.RetailCheckinQueue__c.fields.DCIEstimatedStartTime__c.isUpdateable() &&
           Schema.sObjectType.RetailCheckinQueue__c.fields.Owner__c.isUpdateable() &&
           Schema.sObjectType.RetailCheckinQueue__c.fields.DCIChangeReason__c.isUpdateable()){
               quePos = dciRecord.QueuePosition__c.intValue();
               dciRecord.Status__c = DCIConstants.ACTIVE;
               dciRecord.QueuePosition__c = 0;
               dciRecord.EstimatedWaitTime__c = 0;
               dciRecord.DCIEstimatedStartTime__c = System.Now();
               
               if(!string.isBlank(repId))
               {
                  dciRecord.Owner__c = repId; //when called from Assign button in Retail Checkin Queue record 
               }
               else
               {
                   dciRecord.Owner__c = UserInfo.getUserId(); //when called from HelpNext Customer on RetailHomePage
               }
               dciRecord.DCIChangeReason__c= 'Help This Customer'; //tapaswini
               update dciRecord;
           }
        system.debug('dciRecord-->>'+dciRecord);
        List<EmployeeStoreRetail__c> empStoreList = [SELECT id, DCIPresenceStatus__c, User__c,IsCurrentlyAvailable__c FROM EmployeeStoreRetail__c  
                                                     WHERE Employee__r.User__c =:UserInfo.getUserId() AND
                                                     Store__c = :dciRecord.Store__c WITH SECURITY_ENFORCED];
        
        
        //Make the Rep's Presence status - Busy
        EmployeeStoreRetail__c empStore;
        if(empStoreList.size() > 0) {
            System.debug(empStoreList.get(0)+UserInfo.getUserId());
            empStore = empStoreList.get(0);
            // if(getCurrentUserProfile().equalsIgnoreCase(DCIConstants.REP_PROFILE) || empStore.IsCurrentlyAvailable__c ==  true){
            //if(getCurrentUserProfile().equalsIgnoreCase(DCIConstants.REP_PROFILE) || getCurrentUserProfile().equalsIgnoreCase(DCIConstants.SM_PROFILE) ||empStore.IsCurrentlyAvailable__c ==  true){ // Make Manager status Busy
                if(Schema.sObjectType.EmployeeStoreRetail__c.fields.DCIPresenceStatus__c.isUpdateable() &&
                   Schema.sObjectType.EmployeeStoreRetail__c.fields.IsCurrentlyAvailable__c.isUpdateable()){
                       empStore.DCIPresenceStatus__c =  'Busy';
                       empStore.IsCurrentlyAvailable__c =  true;
                       update empStore;     
                   }
           //}                
        }
        
        
        if(dciRecord.Lead__c != null && Schema.sObjectType.Lead.fields.Owner__c.isUpdateable() && Schema.sObjectType.Lead.fields.DCIActualServiceStartTime__c.isUpdateable()) {
            List<Lead> leadList = new List<Lead>();
            Lead leadRecord = new Lead(id = dciRecord.Lead__c, Owner__c = UserInfo.getUserId(),DCIActualServiceStartTime__c = System.now());
            //6070
            if(strRec.TimeZone__c !=null && strRec.TimeZone__c !=''){
               leadRecord.DciActualServiceStartTimeLocalTz__c=  String.valueof(system.now().format('yyyy-MM-dd HH:mm:ss', strRec.TimeZone__c));
            }
            leadList.add(leadRecord);
            try{
                upsert leadList;
            }catch(Exception e){
                throw new RetailError.ServerSideException('EWT for queue could not be updated.'+e.getMessage()); 
            }
        }
        //Bug fix - CDEX-71458
        if (DCIConstants.EWTCalculationMethod == DCIConstants.TUF && DCIConstants.DCI_OPUS_DEFAULT_LEAD_NAME != dciRecord.Name) { // DM Added TUF - EWT Calculation
            if(quePos == 0){
                DCIUtil.updateQueueBulkifyMinutesUntilFree(new Set<Id>{dciRecord.Store__c}, quePos, false, false, 'Help This Customer');
            }
            else{
                DCIUtil.updateQueueBulkifyMinutesUntilFree(new Set<Id>{dciRecord.Store__c}, quePos, true, false, 'Help This Customer');
            }
        } else if (DCIConstants.DCI_OPUS_DEFAULT_LEAD_NAME != dciRecord.Name) {
            DCIUtil.updateQueue(dciRecord.Store__c, quePos, true, true, 'Help This Customer');
        } else if(DCIConstants.EWTCalculationMethod == DCIConstants.TUF && DCIConstants.DCI_OPUS_DEFAULT_LEAD_NAME == dciRecord.Name){
            DCIUtil.updateQueue(dciRecord.Store__c, quePos, true, true, 'Rep performed a quick sale');
        }
    }
    
    /*     
* This method creates checkin share instances for checkin records
* @Parameters - String accessLevel - level of access desired
Id checkinId - id of RetailCheckinQueue__c record to be shared
Id userId - id of user with whom the Checkin record needs to be shared 
* @Return - RetailCheckinQueue__Share - the RetailCheckinQueue__Share record to be inserted
*/
    public static RetailCheckinQueue__Share createCheckinShareInstance(String accessLevel, Id checkinId, Id userId) {
        RetailCheckinQueue__Share checkinShareRec = new RetailCheckinQueue__Share(
            AccessLevel = accessLevel, 
            ParentId = checkinId,
            RowCause = Schema.RetailCheckinQueue__Share.RowCause.Manual,
            UserOrGroupId = userId);
        return checkinShareRec;
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
    
    /*
*This method marks the DCI arrived and updates Arriving time
*/
    public static RetailCheckinQueue__c markArrived(RetailCheckinQueue__c dciRecord,RetailCheckinQueue__c rcqRecord,Store__c store,  map<String, Decimal> typeToHandleTimeMap ) {
        if(dciRecord.Status__c != DCIConstants.ACTIVE && dciRecord.Status__c != DCIConstants.CANCELLED && dciRecord.Status__c != DCIConstants.COMPLETED) {
            if((dciRecord.Lead__c != null && dciRecord.Lead__r.DCICheckinType__c != null && dciRecord.Lead__r.DCICheckinType__c.equalsIgnoreCase(DCIConstants.FUTURE)) || 
               (dciRecord.Status__c != null && dciRecord.Status__c == DCIConstants.NO_SHOW)) {
                   if(dciRecord.QueuePosition__c == null || (dciRecord.QueuePosition__c != null && dciRecord.QueuePosition__c == -1)) {
                       dciRecord = DCIUtil.addToQueueEnd(dciRecord,rcqRecord,store,typeToHandleTimeMap);
                   }
               }
            if(dciRecord.Status__c != DCIConstants.INSTORE)
                dciRecord.ArrivingTime__c = System.now();
            dciRecord.Status__c = DCIConstants.INSTORE;
            //6070
            if(store.TimeZone__c!=null && store.TimeZone__c!='' )
            dciRecord.ArrivingTimeLocalTz__c = String.valueof(system.now().format('yyyy-MM-dd HH:mm:ss', store.TimeZone__c));
            return dciRecord;
        }
        return null;
    }
    
    /*
*This method marks the DCI Cancelled and returns the Lead and Checkin record for updations
*/
    public static RetailDTO.DCICheckinDataDTO markCancelled(RetailCheckinQueue__c dciRecord){
        RetailDTO.DCICheckinDataDTO checkinDataDTO = new RetailDTO.DCICheckinDataDTO();
        dciRecord.QueuePosition__c = -1; 
        dciRecord.EstimatedWaitTime__c = 0;
        dciRecord = updateStatus(dciRecord, DCIConstants.CANCELLED);
        //dciRecord.DCIChangeReason__c = DCIConstants.DCIRemoveChangeReason;  
        checkinDataDTO.checkinRecord = dciRecord;
        if(dciRecord.Lead__c!=null){
            Lead dciLead = new Lead();
            dciLead.Id = dciRecord.Lead__c; 
            dciLead.Status = RetailConstants.CLOSED;
            dciLead.ClosedStatus__c = DCIConstants.CANCELLED;
            checkinDataDTO.leadRecord = dciLead;
        }  
        return checkinDataDTO;       
    }
    
    /*
*This method marks the DCI as NoShow and returns the Lead and Checkin record for updations
*/
    public static RetailDTO.DCICheckinDataDTO markNoShow(RetailCheckinQueue__c dciRecord){
        RetailDTO.DCICheckinDataDTO checkinDataDTO = new RetailDTO.DCICheckinDataDTO();  
        /* For 1st NoShow incremnet count by 1*/
        if(dciRecord.NoShowCount__c == 0){
            dciRecord.NoShowCount__c++;
            checkinDataDTO.checkinRecord = dciRecord;
        }
        /* On 2nd NoShow change status to NoShow and updateQueue */
        else if(dciRecord.NoShowCount__c == 1)  {  
            Integer quePos = dciRecord.QueuePosition__c.intValue();
            dciRecord.NoShowCount__c++;
            dciRecord.QueuePosition__c = -1; 
            dciRecord.EstimatedWaitTime__c = 0; 
            dciRecord = updateStatus(dciRecord, DCIConstants.NO_SHOW);       
            //DCIUtil.updateQueue(dciRecord.Store__c, quePos, true, true);
            checkinDataDTO.checkinRecord = dciRecord;
            if(dciRecord.Lead__c!=null){
                Lead dciLead = new Lead();
                dciLead.Id = dciRecord.Lead__c;             
                checkinDataDTO.leadRecord = dciLead;
            }  
        }
        return checkinDataDTO;       
    }
    
    /*
*This method marks the DCI arrived and updates Arriving time
*/
    public static String checkedMarkArrived(RetailCheckinQueue__c dciRecord, String keyCode) {
        if(dciRecord.Status__c == DCIConstants.CANCELLED) {        
            return DCIConstants.GENERIC_CLOSED;
        }
        if(dciRecord.Status__c == DCIConstants.COMPLETED) {
            return DCIConstants.COMPLETED_CLOSED;
        }
        if(dciRecord.Status__c == DCIConstants.ACTIVE) {
            return DCIConstants.ENGAGED_CLOSED;
        }
        return keyCode;
    }
    /* This method add in End of the Queue*/
    public static RetailCheckinQueue__c addToQueueEnd(RetailCheckinQueue__c dciRecord,RetailCheckinQueue__c rcqRecord,Store__c store,map<String, Decimal> typeToHandleTimeMap){
        Boolean queueIsEmpty = false;
        DateTime shortestWaitDurationcalculation;
        if(shortestWaitDurationcalculation==null)
        {
            shortestWaitDurationcalculation= store.DCIShortestTUF__c;
        }
        if(rcqRecord == null){
            rcqRecord  = new  RetailCheckinQueue__c();
            rcqRecord.QueuePosition__c = 0;
            rcqRecord.EstimatedWaitTime__c = 0;
            rcqRecord.DCIEstimatedStartTime__c = System.Now();
            queueIsEmpty = true;
        }
        if( dciRecord.QueuePosition__c != rcqRecord.QueuePosition__c){
            dciRecord.QueuePosition__c =rcqRecord.QueuePosition__c + 1;
        }
        if(queueIsEmpty){
            if(!(store.DCIStoreRepCurrentCapacity__c>0)){
                string reason='';
                if(dciRecord.Lead__c != null){
                    reason =dciRecord.Lead__r.ReasonForLeaving__c;
                }
                if(DCIConstants.EWTCalculationMethod ==DCIConstants.TUF){
                    long minutescalculation = (shortestWaitDurationcalculation.getTime()-System.now().getTime())/60000;
                    dcirecord.EstimatedWaitTime__c= minutescalculation <0 ?0: minutescalculation.intValue()+1;
                    dcirecord.DCIEstimatedStartTime__c =  dcirecord.EstimatedWaitTime__c==0?System.Now():shortestWaitDurationcalculation;
                }
                else{
                    Decimal leadHandleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, reason,dciRecord.Store__c); 
                    dciRecord.EstimatedWaitTime__c = DCIUtil.calculateEstimatedWaitTime(rcqRecord.EstimatedWaitTime__c,store, leadHandleTime); 
                    dciRecord.DCIEstimatedStartTime__c = System.now().addMinutes(Integer.valueOf(dciRecord.EstimatedWaitTime__c));   
                }    
            }else{
                dciRecord.EstimatedWaitTime__c = 0;
                dciRecord.DCIEstimatedStartTime__c = System.Now();
            }
        }else{
            string reason='';
            if(dciRecord.Lead__c != null){
                reason =dciRecord.Lead__r.ReasonForLeaving__c;
            }
            if(DCIConstants.EWTCalculationMethod ==DCIConstants.TUF) {
                long minutescalculation2 = (shortestWaitDurationcalculation.getTime()-System.now().getTime())/60000;
                dcirecord.EstimatedWaitTime__c= minutescalculation2 <0 ?0: minutescalculation2.intValue()+1;
                dcirecord.DCIEstimatedStartTime__c =  dcirecord.EstimatedWaitTime__c==0?System.Now():shortestWaitDurationcalculation;
                
            }
            else{
                Decimal leadHandleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, reason,dciRecord.Store__c); 
                dciRecord.EstimatedWaitTime__c = DCIUtil.calculateEstimatedWaitTime(rcqRecord.EstimatedWaitTime__c,store, leadHandleTime); 
                dciRecord.DCIEstimatedStartTime__c = System.now().addMinutes(Integer.valueOf(dciRecord.EstimatedWaitTime__c));
            }
        }
        
        if(dciRecord.DCIMaximum_EWT__c<dciRecord.EstimatedWaitTime__c) {
            dciRecord.DCIMaximum_EWT__c=dciRecord.EstimatedWaitTime__c;
            dciRecord.DCITotalRepCount__c=store.DCIStoreRepActiveCapacity__c;
            dciRecord.DCIAvailableRepCount__c=store.DCIStoreRepCurrentCapacity__c;
        }
        if(dciRecord.DCIMinimum_EWT__c>dciRecord.EstimatedWaitTime__c) {
            dciRecord.DCIMinimum_EWT__c=dciRecord.EstimatedWaitTime__c;
        }
        return dciRecord;
    }
    
    /* This method add in Store EWT*/
    public static Store__c addStoreEWT(Store__c store,RetailCheckinQueue__c updatedDci){
        Decimal storeHandleTime = DCIConstants.getHandleTime(store.Id, null);   
        store.DCILeadsinCheckinQueue__c = DCIUtil.getPendingQueue(store.Id, 0).size() + 1;
        store.DCIEstimatedWaitTime__c =  DCIUtil.calculateEstimatedWaitTime(updatedDci.EstimatedWaitTime__c, store, storeHandleTime);
        return store;
    }
    /*
*This method updates the Status field on the Checkin Queue record
*/
    public static RetailCheckinQueue__c updateStatus(RetailCheckinQueue__c dciRecord, String status) {
        dciRecord.Status__c = status;     
        
        return dciRecord;
    }
    
    /*
*This method updates the last message received from the Lead on the Checkin Queue record
*/
    public static RetailCheckinQueue__c updateMessageReceived(RetailCheckinQueue__c dciRecord, String message) {      
        dciRecord.LastMessageReceived__c = message;
        return dciRecord;
    }
    
    
    
    /*
* This method is used to format the GMT String into DateTime field. 
*/
    public static DateTime getGMTDateTime(String gmtString){
        if(gmtString == null)
            return null;
        try{
            gmtString = gmtString.removeEnd('Z');
            List<String> parts = gmtString.split('T');
            if(parts.size()==2){
                List<String> dateparts = parts[0].split('-');
                List<String> timeparts = parts[1].split(':');
                System.Debug(dateparts);
                System.Debug(timeparts);
                if(dateparts.size()==3 && timeparts.size()==3){
                    Date myDate = Date.newInstance(Integer.valueOf(dateparts[0]), Integer.valueOf(dateparts[1]), Integer.valueOf(dateparts[2]));
                    Time myTime = Time.newInstance(Integer.valueOf(timeparts[0]), Integer.valueOf(timeparts[1]), Integer.valueOf(timeparts[2]), 0);
                    DateTime dt = DateTime.newInstanceGMT(myDate, myTime);
                    System.Debug('Future Checkin Time in GMT'+ dt);
                    return dt;
                }else{
                    return null;  
                }
            }else{
                return null;  
            }
        }catch(Exception e){
            return null;
        }
    }
    
    /* 
*This method is used to get the profile name of current user . 
*/
    public static String getCurrentUserProfile(){
        String strProfileName = '';
        Profile prof = [SELECT id,Name FROM Profile WHERE id=:UserInfo.getProfileId()];
        if(prof <> NULL){
            strProfileName = prof.Name;
        }
        System.debug('***** ' +strProfileName);
        return strProfileName;
    }
    
    /* 
*This method is used to check if the current store has Customer to be engaged with
*/
    public static List<RetailCheckinQueue__c> checkStoreHasArrivedCustomers(EmployeeStoreRetail__c empStore){
        List<RetailCheckinQueue__c> dciCheckinList = [SELECT ID,lead__c,lead__r.Name, DCICheckinType__c,NoShowCount__c,Store__c,Status__c,QueuePosition__c,EstimatedWaitTime__c,Store__r.Name
                                                      FROM RetailCheckinQueue__c WHERE Store__c =:empStore.Store__c AND Status__c = :DCIConstants.INSTORE WITH SECURITY_ENFORCED];
        return dciCheckinList;
    }
    
    /* 
*This method is used to update Finish Checkins and leads
*/
    public static String updateFinishRecords(RetailDTO.DCICheckinDataDTO checkinInfo){
        String Message;
        try{
            if(checkinInfo!=null){
               
                if(checkinInfo.checkinRecord!=null){
                    
                    RetailCheckinQueue__c dciRecord = checkinInfo.checkinRecord;
                    
                    update dciRecord;
                    
                    if(dciRecord.Store__c!=null){
                        List<EmployeeStoreRetail__c> empStoreList;
                        empStoreList = [SELECT ID,Name, IsCurrentlyAvailable__c, DCIPresenceStatus__c,Store__c,Store__r.Name,Store__r.DCIEstimatedWaitTime__c,Store__r.DCIStoreRepActiveCapacity__c,Store__r.DCIStoreRepCurrentCapacity__c,Store__r.DCILeadsinCheckinQueue__c,User__c,SFProfileId__c FROM EmployeeStoreRetail__c  
                                        WHERE Employee__r.User__c =:UserInfo.getUserId() and (SFProfileId__c = 'RSC-REP' OR IsCurrentlyAvailable__c = True)  and Store__c=:dciRecord.Store__c WITH SECURITY_ENFORCED];
                        if(empStoreList.size()>0 && Schema.sObjectType.EmployeeStoreRetail__c.fields.DCIPresenceStatus__c.isUpdateable()){
                            EmployeeStoreRetail__c empStore = empStoreList[0];
                            empStore.DCIPresenceStatus__c = DCIConstants.ONLINE;
                            update empStore;
                        }
                        recalculateStoreTUF(new Set<Id>{dciRecord.Store__c});
                    }
                }   
                
                if(checkinInfo.leadRecord!=null && Schema.sObjectType.Lead.fields.DCIActualServiceEndTime__c.isUpdateable()){
                    
                    store__c storeRec = fetchStore(checkinInfo.leadRecord.Store__c);//6070
                    Lead dciLead = checkinInfo.leadRecord;
                    dciLead.DCIActualServiceEndTime__c = system.now();
                    //6070
                    if(storeRec.TimeZone__c !=null && storeRec.TimeZone__c !=''){
                        dciLead.DCIActualServiceEndTimeLocalTz__c = String.valueof(system.now().format('yyyy-MM-dd HH:mm:ss', storeRec.TimeZone__c));
                    }
                    update dciLead;
                }
                
                Message = 'Success! Your engagement with '+checkinInfo.leadRecord.Name+' has been completed.';
            }
            
        }catch(Exception e){
            throw new AuraHandledException('Error in updating this Checkin record: '+e.getMessage());
        }
        
        return Message;
    }
    
    /* 
*This method is used to retrieve CustomSettings using getInstance()
*/
    public static String getRetailCustomSettings(String key){
        RetailCustomSetting__c retailSetting = RetailCustomSetting__c.getInstance(key); 
        if(retailSetting != null)
            return retailSetting.KeyValue__c;
        return null;
    }
    
    /*
* This method is used to Mark DCIcustomer as No show 
*/
    public static RetailCheckinQueue__c  markAsNoShow(RetailCheckinQueue__c currentRecord)
    {
        Integer quePos = currentRecord.QueuePosition__c.intValue();
        string currentRecordstatus = currentRecord.Status__c;
        if(Schema.sObjectType.RetailCheckinQueue__c.fields.QueuePosition__c.isUpdateable() && 
           Schema.sObjectType.RetailCheckinQueue__c.fields.EstimatedWaitTime__c.isUpdateable()){
               string status = currentRecord.Status__c;
               currentRecord.QueuePosition__c=-1;
               currentRecord.EstimatedWaitTime__c=0;
               currentRecord = updateStatus(currentRecord, DCIConstants.NO_SHOW); 
               update currentRecord;
           }
        
        /*if(status != DCIConstants.ACTIVE){
DCIUtil.updateQueue(currentRecord.Store__c, quePos, true, true);
}*/
        if(Schema.sObjectType.Lead.fields.DCIActualServiceEndTime__c.isUpdateable()){
            Lead lTemp=new Lead(id=currentRecord.lead__c);
            //lTemp.Status='Closed';
            //lTemp.ClosedStatus__c='No Show';
            String profileName = [select id, profile.name from user where id =: UserInfo.getUserId()].profile.name;
            if(currentRecordstatus == DCIConstants.ACTIVE && profileName != DCIConstants.REP_PROFILE && profileName != DCIConstants.SM_PROFILE)
            {
            lTemp.DCIActualServiceEndTime__c=System.now();
            }
            update lTemp; 
        }
        
        if(currentRecord.Store__c!=null){
            List<EmployeeStoreRetail__c> empStoreList;
            empStoreList = [SELECT ID,Name,IsCurrentlyAvailable__c,DCIPresenceStatus__c,Store__c FROM EmployeeStoreRetail__c  
                            WHERE Employee__r.User__c =:UserInfo.getUserId() and (SFProfileId__c = 'RSC-REP' OR IsCurrentlyAvailable__c = True) and Store__c=:currentRecord.Store__c WITH SECURITY_ENFORCED];
            
            if(empStoreList.size()>0 && Schema.sObjectType.EmployeeStoreRetail__c.fields.DCIPresenceStatus__c.isUpdateable()){
                EmployeeStoreRetail__c empStore = empStoreList[0];
                empStore.DCIPresenceStatus__c = DCIConstants.ONLINE;
                update empStore;
            }
        }
        
        if (DCIConstants.EWTCalculationMethod == DCIConstants.TUF) { 
            updateQueueBulkifyMinutesUntilFree(new Set<Id>{currentRecord.Store__c}, 0, false, false, 'Customer marked no-Show');    
        }
        
        return currentRecord;
    }
    
    /*
* This method returns the  RetailCheckinQueue__c record for the passed recordId
*/
    public static RetailCheckinQueue__c  getCheckinRecordByID(Id checkinId){
        RetailCheckinQueue__c checkinRecord;
        List<RetailCheckinQueue__c> dciCheckinList = [SELECT ID,checkInTime__c,lead__c,Store__c,Status__c,QueuePosition__c,EstimatedWaitTime__c,Store__r.Name
                                                      FROM RetailCheckinQueue__c WHERE Id = :checkinId WITH SECURITY_ENFORCED];
        if(dciCheckinList.size()>0){
            checkinRecord = dciCheckinList[0];
        }
        return checkinRecord;
    }
    
    
    /*
* This method returns the  List<EmployeeStoreRetail__c> for the passed recordId and actiontype
* common utility function for reuseable Available reps component.
*/
    @AuraEnabled (cacheable=true)
    public static List<EmployeeStoreRetail__c> getAvailableReps(String recordId, String actionType)  
    {
        List<EmployeeStoreRetail__c> empStoreRetail = new List<EmployeeStoreRetail__c>();
        
        if(actionType == DCIConstants.ASSIGN_CUSTOMER )
        {
            try{
                RetailCheckinQueue__c checkInRec = [SELECT id, Status__c, Store__c FROM RetailCheckinQueue__c WHERE Id =:recordId WITH SECURITY_ENFORCED];
                
                empStoreRetail = [Select Id,User__c,Employee__r.name,UserIsActive__c,DCIPresenceStatus__c From EmployeeStoreRetail__c where 
                                  Store__c =: checkInRec.Store__c
                                  And UserIsActive__c = true  
                                  AND SFProfileId__c =: RetailConstants.RSC_REP 
                                  AND IsExpired__c = False 
                                  And User__c!=: UserInfo.getUserId()
                                  And Employee__r.IsActive__c = true
                                  And DCIPresenceStatus__c IN: DCIConstants.AVAILABLE_DCI_PRESENCE_STATUS WITH SECURITY_ENFORCED];
            }
            catch(Exception e){      
                empStoreRetail = null;
            }
        }else if(actionType == 'newCheckIn') {
            String storeId = StoreController.getStoreFromCache();
            if(String.isBlank(storeId)){
                Store__c repsStore = LeadForm.getHomeStore('true'); 
                if(repsStore!=null){
                    storeId = repsStore.Id;
                }
            } 
            if(String.isNotBlank(storeId)){
                empStoreRetail = [Select Id,User__c,Employee__r.name,UserIsActive__c,DCIPresenceStatus__c,Store__c,IsManagerOnDuty__c
                                  From EmployeeStoreRetail__c where 
                                  Store__c =: storeId
                                  And UserIsActive__c = true  
                                  AND SFProfileId__c =: RetailConstants.RSC_REP 
                                  AND IsExpired__c = False 
                                  And User__c!=: UserInfo.getUserId()
                                  And Employee__r.IsActive__c = true
                                  And (DCIPresenceStatus__c IN: DCIConstants.AVAILABLE_DCI_PRESENCE_STATUS
                                       OR IsManagerOnDuty__c= true) WITH SECURITY_ENFORCED];
            }
        }       
        return empStoreRetail;
    }
    
    /*
* This method returns the Boolean for the passed storeId
* common utility function to check if logged user is Busy or engaged with Customer or not.
*/
    public static Boolean checkIfBusywithCustomer(String storeId){
        List<RetailCheckinQueue__c> existingRetailCheckinQueue = new List<RetailCheckinQueue__c>([SELECT Id, Store__c, Store__r.Name FROM RetailCheckinQueue__c WHERE Status__c = :DCIConstants.ACTIVE  AND Store__c = :storeId  AND Lead__r.Owner__c = :UserInfo.getUserId() WITH SECURITY_ENFORCED]);
        if(!existingRetailCheckinQueue.isEmpty()){
            return true;  
        }
        return false;
    }
    
    @AuraEnabled (cacheable=true)
    public static Boolean checkIfRepBusywithCustomer(String repId, String storeId) {
        List<RetailCheckinQueue__c> activeEngageCheckIns = new List<RetailCheckinQueue__c>();
        Boolean isValidated = false;
        if(!String.isEmpty(repId) && !String.isEmpty(storeId)) {
            activeEngageCheckIns = [Select Id,Status__c,Lead__c,Store__c from RetailCheckinQueue__c where Lead__r.Owner__c =: repId
                                    And Status__c= 'Engaged' And Store__c=: storeId WITH SECURITY_ENFORCED];
            
            if(activeEngageCheckIns.size() > 0)
                isValidated = false;
            else
                isValidated =  true;
        }
        return isValidated;
    }
    
    //Krishna 
    public static RetailCheckinQueue__c getBusywithCustomerInfo(String storeId){
        List<RetailCheckinQueue__c> existingRetailCheckinQueue = new List<RetailCheckinQueue__c>([SELECT Id,Lead__r.Name,Store__c, Store__r.Name FROM RetailCheckinQueue__c WHERE Status__c='Engaged' AND Store__c = :storeId AND DAY_ONLY(CheckInTime__c) = :Date.today() AND Lead__r.Owner__c = :UserInfo.getUserId() WITH SECURITY_ENFORCED]);        
        
        if(!existingRetailCheckinQueue.isEmpty()){
            return existingRetailCheckinQueue[0]; 
        }
        return null;
    }
}
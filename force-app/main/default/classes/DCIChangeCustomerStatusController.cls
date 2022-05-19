public without sharing class DCIChangeCustomerStatusController {
    public Static RetailCheckinQueue__c customerCheckIn {get; set;}
    public Static map<String, String> result;
    //Constructor for aura component
    public DCIChangeCustomerStatusController() {
    }
    public DCIChangeCustomerStatusController(ApexPages.StandardController stdController) {
        customerCheckIn = (RetailCheckinQueue__c) stdController.getRecord();
    }

    /*
    * This method is called from visualforce page and aura component
    * It accepts the list of Lead Ids for whom the redistribution needs to be performed
    * Last modified on - 03/25/2021
    * Last modified by - Akshay Kumar akshay.kumar@salesforce.com
    */
    @RemoteAction
    @AuraEnabled
    public static map<String, String> changeCustomerStatus(String recordId, String action) {
        map<String, String> resultMap = new map<String, String>();
        result = new map<String, String> ();
        String errorMessage = '';
        String successMessssage = '';
        
        List<RetailCheckinQueue__c> customerCheckInsList = new List<RetailCheckinQueue__c>();
        customerCheckInsList = [SELECT id, Name, Status__c,Store__c, ArrivingTime__c, Lead__c, Lead__r.MobilePhone, store__r.DCIStoreRepActiveCapacity__c, store__r.DCIStoreRepCurrentCapacity__c, Lead__r.Store__r.LocationId__c, Store__r.TimeZone__c,Store__r.DCIShortestTUF__c,DCITimeUntilFree__c,LastMessageReceived__c,
        QueuePosition__c, ElapsedWaitTime__c, EstimatedWaitTime__c, LastEWTUpdated__c, CheckInTime__c, Lead__r.ReasonForLeaving__c, Lead__r.DCICheckinType__c, NoShowCount__c, DCIAssignedRSC__c, DCIMaximum_EWT__c,DCIMinimum_EWT__c,Lead__r.FirstName,Lead__r.LastName,Store__r.Name FROM RetailCheckinQueue__c WHERE Id =:recordId WITH SECURITY_ENFORCED]; // Added Keyword SECURITY_ENFORCED(4440)
        set<Id> storeIds= DCIUtil.getStoreIds(customerCheckInsList);
        map<Id,RetailCheckinQueue__c> queMap = DCIUtil.getQueMap(storeIds);
        map<Id,Store__c> storeMap = DCIUtil.fetchStoresMap(storeIds);
        map<Id,Store__c> updateStoreMap = new map<Id,Store__c>();
        map<String, Decimal> typeToHandleTimeMap = DCIConstants.getStoreHandleTimeMap(storeIds);
        //status update
        List<RetailCheckinQueue__c> updateList = New List<RetailCheckinQueue__c>();
        List<RetailCheckinQueue__c> removeList = New List<RetailCheckinQueue__c>();
        for(RetailCheckinQueue__c checkinRecord : customerCheckInsList){
       system.debug('checkinRecord--->>'+checkinRecord);
       if(action == DCIConstants.MARK_PENDING) {
            if(checkinRecord.Status__c != DCIConstants.PENDING){
			  if (Schema.sObjectType.RetailCheckinQueue__c.fields.Status__c.isUpdateable() &&
			   Schema.sObjectType.RetailCheckinQueue__c.fields.ElapsedWaitTime__c.isUpdateable()&&
               Schema.sObjectType.RetailCheckinQueue__c.fields.ArrivingTime__c.isUpdateable()) {
                checkinRecord.Status__c = DCIConstants.PENDING;
                if(checkinRecord.ArrivingTime__c != null){
                    Datetime arrivingTime = checkinRecord.ArrivingTime__c;
                    Long milliseconds = System.now().getTime() - arrivingTime.getTime();
                    Long seconds = milliseconds / 1000;
                    Long minutes = seconds / 60;
                     if(checkinRecord.ElapsedWaitTime__c != null)
                        checkinRecord.ElapsedWaitTime__c += minutes;
                    else 
                        checkinRecord.ElapsedWaitTime__c = minutes;
                    checkinRecord.ArrivingTime__c = null;
                }
			   }
                updateList.add(checkinRecord);
                if(!test.isRunningTest())
                successMessssage = System.Label.DCIStatusUpdateSuccess.replace('{0}', updateList.get(0).Lead__r.FirstName + ' ' + updateList.get(0).Lead__r.LastName)+'.';
            } else {
                errorMessage = System.Label.MarkPendingError;
            }
        }
        // Status Arrived begin

        if(action == DCIConstants.MARK_ARRIVED){
            Boolean updateStoreEWT = false;
            if(checkinRecord.Status__c == DCIConstants.PENDING || checkinRecord.Status__c==DCIConstants.NO_SHOW)  {
                string status = checkinRecord.Status__c;

                if((checkinRecord.Lead__c != null && checkinRecord.Lead__r.DCICheckinType__c != null && checkinRecord.Lead__r.DCICheckinType__c.equalsIgnoreCase(DCIConstants.FUTURE)) || 
                   (checkinRecord.Status__c != null && checkinRecord.Status__c == DCIConstants.NO_SHOW)) { 
                       if(checkinRecord.QueuePosition__c == null || (checkinRecord.QueuePosition__c != null && checkinRecord.QueuePosition__c == -1)) {
                           updateStoreEWT = true;
                       }else{
                           updateStoreEWT = false;
                       }
                }
                checkinRecord = DCIUtil.markArrived(checkinRecord,queMap.get(checkinRecord.Store__c),storeMap.get(checkinRecord.Store__c),typeToHandleTimeMap); 
               
                if(checkinRecord != null) {
                    updateList.add(checkinRecord);
                    if(updateStoreEWT){
                        Store__c updateStore = DCIUtil.addStoreEWT(storeMap.get(checkinRecord.Store__c),checkinRecord);
                        updateStoreMap.put(updateStore.Id,updateStore);   
                    }
                    if(!test.isRunningTest())
                    successMessssage = System.Label.DCIStatusArrivedUpdateSuccess.replace('{0}', updateList.get(0).Lead__r.FirstName + ' ' + updateList.get(0).Lead__r.LastName)+'.';
                } else {
                    errorMessage = System.Label.MarkArrivedError;
                }
            } else {
                errorMessage = System.Label.MarkArrivedError;
            }
        } 
        //Status  Arrived end

         //Status Remove start  - KRISHNA 
         if(action == DCIConstants.MARK_REMOVE){   //"Success! [Customer Name] was removed from the queue."
         Boolean updateStoreEWT = false;
         if(checkinRecord.Status__c == DCIConstants.PENDING || checkinRecord.Status__c==DCIConstants.INSTORE)  {
         //checkinRecord.Status__c = DCIConstants.CANCELLED;
         checkinRecord.LastMessageReceived__c ='C';
         updateList.add(checkinRecord);
         removeList.add(checkinRecord);
         successMessssage = 'Success! '+ checkinRecord.Lead__r.FirstName + ' ' + checkinRecord.Lead__r.LastName +' was removed from the queue.';
       }
     }                                                                                        
       //Status Remove End  - KRISHNA 

        if(action==DCIConstants.HELP_NEXT) { 
            if(checkinRecord.QueuePosition__c !=null){ 
                if(checkinRecord.Status__c == DCIConstants.INSTORE){           
                    DCIUtil.accept(checkinRecord);
                    successMessssage =  System.Label.DCIHelpCustomerSuccess.replace('{0}', checkinRecord.Lead__r.FirstName + ' ' + checkinRecord.Lead__r.LastName)+'.';
                }
                else {
                    errorMessage = System.Label.HelpNextCustomerError;
                }
            }else{
                errorMessage = System.Label.HelpNextCustomerFDCIError;
            }
        }
           
        if(action==DCIConstants.MARK_NOSHOW)
        { 
            if(checkinRecord.Status__c== DCIConstants.PENDING || checkinRecord.Status__c == DCIConstants.INSTORE || checkinRecord.Status__c== DCIConstants.COMPLETED || checkinRecord.Status__c== DCIConstants.CANCELLED) 
            {
                errorMessage = System.Label.MarkNoShowError;
            }else{
             
            if(checkinRecord.Status__c== DCIConstants.NOSHOW) 
            {
                errorMessage = System.Label.AlreadyMarkedNoShowError;
            }
            else 
            {
                List<MessagingRequest> lstMessagingInputs = new List<MessagingRequest>(); 
                String autoResponse = ''; 
                map<String, map<String,String>> shortCodeResponseMap = ProcessMessagingSessionHelper.getDCIAutoResponses();
                
                Lead lead = [SELECT Id, MobilePhone, IsAttCtn__c, PreferedLanguage__c, Store__r.LocationId__c FROM Lead WHERE Id=: checkinRecord.Lead__c WITH SECURITY_ENFORCED]; // Added Keyword SECURITY_ENFORCED(4440)
                checkInRecord.Lead__r.PreferedLanguage__c = lead.PreferedLanguage__c;
                checkInRecord.Store__r.LocationId__c = lead.Store__r.LocationId__c;
                autoResponse = ProcessMessagingSessionHelper.getResponseFormat('NOSHOWQUICKACTION', checkinRecord, shortCodeResponseMap);  
                lstMessagingInputs =  MessagingRequestHandler.processOutboundMessaging(autoResponse, checkinRecord.Lead__c, Lead.MobilePhone, lstMessagingInputs, false, Lead.IsAttCtn__c);  
                checkinRecord = DCIUtil.markAsNoShow(checkinRecord); 
                if(checkinRecord != null)
                {
                    updateList.add(checkinRecord); 
                    if(!test.isRunningTest())
                        successMessssage=System.Label.DCIStatusNoShowUpdateSuccess.replace('{0}', updateList.get(0).Lead__r.FirstName + ' ' + updateList.get(0).Lead__r.LastName)+'.';
                } 
                else
                {
                    errorMessage = System.Label.MarkNoShowError;
                }
                 if(lstMessagingInputs != null && lstMessagingInputs.size() > 0)
            MessagingRequestHandler.sendOutboundSMS(lstMessagingInputs, 'MessageInput', DCIConstants.DCI_OUTBOUNDTEXT_FLOW);
            }
          }
        }
    }

        if(updateList.size() > 0 && Schema.sObjectType.RetailCheckinQueue__c.isUpdateable()){
            update updateList; 
        }
        
        if(updateStoreMap.size() >0 ){
            if(DCIConstants.EWTCalculationMethod==DCIConstants.TUF){
                DCIUtil.recalculateStoreTUF(new Set<Id> {updateStoreMap.values()[0].Id});
            }
            else{
			if(Schema.sObjectType.Store__c.isUpdateable()){
            update updateStoreMap.values();
            }
		  }
        }

        //Krishna
        if(removeList.size()>0){
            DCILeadUtil.sendAutoResponseSMS(removeList,DCIConstants.REMOVE);
        }
      
        system.debug(errorMessage);
        if(errorMessage != null && errorMessage != '')  {
            resultMap.put('status', System.Label.Error);
            resultMap.put('message', errorMessage);
            resultMap.put('type', 'error');
        } else {
            
            resultMap.put('status', System.Label.Success);
            resultMap.put('message', successMessssage);
            resultMap.put('type', 'success');
                
        }
        result.putAll(resultMap);
        return resultMap;
    }

    /*
    * This method is called to validate if tthe mark pendign or arrived are valid for current record
    */
    @RemoteAction
    @AuraEnabled
    public static map<String, Object> validateStatus(String recordId, String action) {
        map<String, Object> resultMap = new map<String, Object>();
        RetailCheckinQueue__c checkinRecord;
        List<RetailCheckinQueue__c> customerCheckInsList = [SELECT id, Status__c,Store__c, ArrivingTime__c, Lead__c, Lead__r.MobilePhone, Lead__r.Store__r.LocationId__c, Store__r.TimeZone__c, LastMessageReceived__c,
        QueuePosition__c, EstimatedWaitTime__c, LastEWTUpdated__c, CheckInTime__c, Lead__r.ReasonForLeaving__c, Lead__r.DCICheckinType__c, NoShowCount__c, DCIAssignedRSC__c, DCIMaximum_EWT__c,DCIMinimum_EWT__c,Lead__r.FirstName,Lead__r.LastName,Store__r.Name FROM RetailCheckinQueue__c WHERE Id = :recordId WITH SECURITY_ENFORCED]; // Added Keyword SECURITY_ENFORCED(4440)
        if(customerCheckInsList.size() >  0) {
            checkinRecord = customerCheckInsList.get(0);
            if(action == DCIConstants.MARK_PENDING) {
                if(checkinRecord.Status__c == DCIConstants.INSTORE ){
                    resultMap.put('isValid', true);
                } else {
                    resultMap.put('isValid', false);
                    resultMap.put('errorMessage', System.Label.MarkPendingError);
                }
            }

            if(action == DCIConstants.MARK_ARRIVED){
                if(checkinRecord.Status__c == DCIConstants.PENDING || checkinRecord.Status__c==DCIConstants.NO_SHOW){
                    resultMap.put('isValid', true);
                } else {
                    resultMap.put('isValid', false);
                    resultMap.put('errorMessage', System.Label.MarkArrivedError);
                }
            }
            
            if (action == DCIConstants.MOVE_UP) {
                if(checkinRecord.Status__c == DCIConstants.INSTORE){
                    resultMap.put('isValid', true);
                } else {
                    resultMap.put('isValid', false);
                    resultMap.put('errorMessage', checkinRecord.Lead__r.FirstName + ' ' + checkinRecord.Lead__r.LastName + ' has not Arrived and cannot be moved up in the queue');
                }
            }
       
            if(action == DCIConstants.MARK_NOSHOW){
                if(checkinRecord.Status__c != DCIConstants.INSTORE && checkinRecord.Status__c != DCIConstants.PENDING && checkinRecord.Status__c != DCIConstants.CANCELLED && checkinRecord.Status__c != DCIConstants.COMPLETED && checkinRecord.Status__c != DCIConstants.NOSHOW)
                {
                    resultMap.put('isValid', true);
                } 
                else if(checkinRecord.Status__c == DCIConstants.NOSHOW)
                {
                    resultMap.put('isValid', false);
                    resultMap.put('errorMessage', System.Label.AlreadyMarkedNoShowError);
                } 
                else {
                                        resultMap.put('isValid', false);
                    resultMap.put('errorMessage', System.Label.MarkNoShowError);
                }
            }
            if (action == DCIConstants.ASSIGN_CUSTOMER) {
                system.debug('** in side Assign ****');
                if(checkinRecord.Status__c == DCIConstants.INSTORE || checkinRecord.Status__c == DCIConstants.PENDING){
                    resultMap.put('isValid', true);
                } else {
                    resultMap.put('isValid', false);
                    resultMap.put('errorMessage', 'This customer has already started or missed their check-in, so you can’t assign them to a rep.');
                }
            }

             //Krishna
             if (action == DCIConstants.MARK_REMOVE) {
                system.debug('** in side REMOVE****');
                if(checkinRecord.Status__c == DCIConstants.INSTORE || checkinRecord.Status__c == DCIConstants.PENDING){
                    resultMap.put('isValid', true);
                } else if(checkinRecord.Status__c == DCIConstants.ACTIVE){
                    resultMap.put('isValid', false); //This customer’s already been helped, so we can’t remove them from the queue
                    resultMap.put('errorMessage', 'This customer’s already been helped, so we can’t remove them from the queue.');
                }else{
                    resultMap.put('isValid', false); //This customer’s already been helped, so we can’t remove them from the queue
                    resultMap.put('errorMessage', 'This customer’s already been helped, so we can’t remove them from the queue.');
                    
                    
                }
            }
            //Krishna End
        } else {
            resultMap.put('isValid', false);
            resultMap.put('errorMessage', System.Label.GenericError);
        }
        return resultMap;
    }

   /*
     * @description - This method swaps two check in records when managers manually move records in queues
     * @dependencies - 
     * 		Utilizes DCIConstants for string constants (DCIConstants.MOVE_UP), getStoreHandleTimeMap, and getHandleTime methods
     * Logic adapted from DCIUtil swapRecords method
    */
    @RemoteAction
    @AuraEnabled
    public static map<String, String> swapQueuePositions(String recordId, String action) {
        //Get Record Information
        RetailCheckinQueue__c recordInitiatingSwap = [SELECT Id, Status__c, Lead__c, Lead__r.Name,DCIChangeReason__c, Store__c, EstimatedWaitTime__c, QueuePosition__c, DCIMaximum_EWT__c, DCIMinimum_EWT__c,Lead__r.DCICheckinType__c,Lead__r.ReasonForLeaving__c FROM RetailCheckinQueue__c WHERE Id = :recordId WITH SECURITY_ENFORCED]; // Added Keyword SECURITY_ENFORCED(4440)
        
        if (recordInitiatingSwap.Status__c != DCIConstants.INSTORE) {
            map<String, String> resultMap = new map<String, String>();
            resultMap.put('status', System.Label.Error);
            resultMap.put('message', recordInitiatingSwap.Lead__r.Name + ' has not Arrived and cannot be moved up in the queue');
            resultMap.put('type', 'error');
            return resultMap;
        } else {
            RetailCheckinQueue__c recordBeingSwappedWith;
            //Get List of All Records in Queue for that store
            List<RetailCheckinQueue__c> checkInQueue = [SELECT id, Status__c, QueuePosition__c, EstimatedWaitTime__c, LastEWTUpdated__c, Store__c, Lead__c, Lead__r.ReasonForLeaving__c, DCIMaximum_EWT__c, DCIMinimum_EWT__c,Lead__r.DCICheckinType__c,DCIChangeReason__c
                                                    FROM RetailCheckinQueue__c
                                                    WHERE Store__c = :recordInitiatingSwap.Store__c AND 
                                                    //Status__c = :DCIConstants.INSTORE AND  tapaswini
                                                    QueuePosition__c  > 0
                                                    ORDER BY QueuePosition__c];
            
            //Find record in queue order, and find record being swapped with
            for (Integer i = 0; i < checkInQueue.size(); i++) {
                if (checkInQueue[i].Id == recordId) {
                    if (action == DCIConstants.MOVE_UP) {
                        if (i == 0) {
                            map<String, String> resultMap = new map<String, String>();
                            resultMap.put('status', System.Label.Error);
                            resultMap.put('message', recordInitiatingSwap.Lead__r.Name + ' is already at the front of the queue.');
                            resultMap.put('type', 'error');
                            return resultMap;
                        }
                        recordBeingSwappedWith = checkInQueue[i - 1];
                    }
                    
                    break;
                }
            }
            Store__c swapStore = [SELECT Id, DCIStoreRepActiveCapacity__c, LocationId__c FROM Store__c WHERE Id = :recordInitiatingSwap.Store__c WITH SECURITY_ENFORCED]; // Added Keyword SECURITY_ENFORCED(4440)
            
            //Below logic adapted from DCIUtil.swapRecords
            try {

                if (DCIConstants.EWTCalculationMethod == DCIConstants.TUF) { // DM Added TUF
                    Decimal queuePosition = recordBeingSwappedWith.QueuePosition__c;
                    recordBeingSwappedWith.QueuePosition__c = recordInitiatingSwap.QueuePosition__c;
                       //tapaswini
                    /*if (recordInitiatingSwap.QueuePosition__c > 0 && action == DCIConstants.MOVE_UP){
                        recordInitiatingSwap.DCIChangeReason__c= 'Move Up';           
                   }*/
                    recordInitiatingSwap.QueuePosition__c = queuePosition;
                    List<RetailCheckinQueue__c> recordsToUpdate = new List<RetailCheckinQueue__c>{recordInitiatingSwap,recordBeingSwappedWith};
                    if(Schema.sObjectType.RetailCheckinQueue__c.isUpdateable()){
						update recordsToUpdate;
					}
                    DCIUtil.updateQueueBulkifyMinutesUntilFree(new Set<Id>{recordInitiatingSwap.Store__c}, 0, false, false, 'Move Up');
                }else{
                    map<String, Decimal> typeToHandleTimeMap = DCIConstants.getStoreHandleTimeMap(new Set<Id>{recordInitiatingSwap.Store__c});
                    Decimal dciRecordTobeSwappedHandleTime = 0;
                    Decimal dciRecordTobeSwappedWithHandleTime = 0;
                    if (recordInitiatingSwap.Lead__c != null && recordInitiatingSwap.Lead__r.ReasonForLeaving__c != null) {
                        dciRecordTobeSwappedHandleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, recordInitiatingSwap.Lead__r.ReasonForLeaving__c, recordInitiatingSwap.Store__c);
                    }
                    if (recordBeingSwappedWith.Lead__c != null && recordBeingSwappedWith.Lead__r.ReasonForLeaving__c != null) {
                        dciRecordTobeSwappedWithHandleTime = DCIConstants.getHandleTime(typeToHandleTimeMap, recordBeingSwappedWith.Lead__r.ReasonForLeaving__c, recordBeingSwappedWith.Store__c);
                    }
                    
                    Decimal tempEWT = recordInitiatingSwap.EstimatedWaitTime__c;
                    Decimal tempQP = recordInitiatingSwap.QueuePosition__c; 
                    Decimal Difference = 0;
                    if (swapStore.DCIStoreRepActiveCapacity__c > 0) {            
                        Difference = (dciRecordTobeSwappedWithHandleTime - dciRecordTobeSwappedHandleTime)/swapStore.DCIStoreRepActiveCapacity__c;
                    } else {
                        Difference = dciRecordTobeSwappedWithHandleTime - dciRecordTobeSwappedHandleTime;
                    }
                    
                    recordInitiatingSwap.QueuePosition__c = recordBeingSwappedWith.QueuePosition__c;
                    recordBeingSwappedWith.QueuePosition__c = tempQP;
                    recordInitiatingSwap.EstimatedWaitTime__c = recordBeingSwappedWith.EstimatedWaitTime__c;
                    recordBeingSwappedWith.EstimatedWaitTime__c = tempEWT + Difference;
                    recordInitiatingSwap.DCIChangeReason__c = 'Move Up';
                    recordBeingSwappedWith.DCIChangeReason__c = 'Move Up';
                    
                    if (recordInitiatingSwap.DCIMaximum_EWT__c<recordInitiatingSwap.EstimatedWaitTime__c) {
                        recordInitiatingSwap.DCIMaximum_EWT__c = recordInitiatingSwap.EstimatedWaitTime__c;     
                    }
        
                    if (recordInitiatingSwap.DCIMinimum_EWT__c>recordInitiatingSwap.EstimatedWaitTime__c) {
                        recordInitiatingSwap.DCIMinimum_EWT__c = recordInitiatingSwap.EstimatedWaitTime__c;
                    }
                    
                    if (recordBeingSwappedWith.DCIMaximum_EWT__c<recordBeingSwappedWith.EstimatedWaitTime__c) {
                        recordBeingSwappedWith.DCIMaximum_EWT__c = recordBeingSwappedWith.EstimatedWaitTime__c;
                    }

                    if (recordBeingSwappedWith.DCIMinimum_EWT__c>recordBeingSwappedWith.EstimatedWaitTime__c) {
                        recordBeingSwappedWith.DCIMinimum_EWT__c = recordBeingSwappedWith.EstimatedWaitTime__c;
                    }

                    List<RetailCheckinQueue__c> recordsToUpdate = new List<RetailCheckinQueue__c>{recordInitiatingSwap,recordBeingSwappedWith};
                    	if(Schema.sObjectType.RetailCheckinQueue__c.isUpdateable()){
				        update recordsToUpdate;
					}
                }
               
                
                //US 2566
                try{
                    List<StoreQueueUpdateNotification__e> sueList = new List<StoreQueueUpdateNotification__e>();
                    sueList.add(new StoreQueueUpdateNotification__e(StoreId__c=swapStore.Id,StoreLocationId__c =swapStore.LocationId__c ));
                
                    if(!sueList.isEmpty()){
                        // Call method to publish events
                        List<Database.SaveResult> results = EventBus.publish(sueList);
                    }
                   
                } catch (Exception e){
                     System.Debug('Platform Event on StoreQueueUpdateNotification__e failed '+e.getMessage());
                }
                map<String, String> resultMap = new map<String, String>();
                resultMap.put('status', System.Label.Success);
                resultMap.put('message', recordInitiatingSwap.Lead__r.Name + ' was moved up in the queue.');
                resultMap.put('type', 'success');
                return resultMap;
            } catch (Exception e){
                map<String, String> resultMap = new map<String, String>();
                resultMap.put('status', System.Label.Error);
                resultMap.put('message', 'There was an error moving the customer up in the queue.');
                resultMap.put('type', 'error');
                return resultMap;
            }
        }
    }
@RemoteAction
    @AuraEnabled
    public static string updateLeadWithRep(String recordId, String selectedRep, String selectedRepName) {
        
        List<Lead> leadRecord = new List<Lead>();
        String updateStatus;
        try{
            RetailCheckinQueue__c checkInRec = [SELECT id,name,QueuePosition__c,EstimatedWaitTime__c,DCIEstimatedStartTime__c,Owner__c,DCIChangeReason__c, Status__c,Store__c,Lead__r.DCICheckinType__c,ArrivingTime__c,ArrivingTimeLocalTz__c, Store__r.Id,Lead__c,Lead__r.Name FROM RetailCheckinQueue__c WHERE Id =:recordId WITH SECURITY_ENFORCED]; // Added Keyword SECURITY_ENFORCED(4440)
            
            	if(Schema.sObjectType.Lead.fields.CustomerRequestedRep__c.isUpdateable()){
				leadRecord.add(new Lead(Id= checkInRec.Lead__c,CustomerRequestedRep__c=selectedRep));
				}
				if(leadRecord.size()>0 && Schema.sObjectType.Lead.isUpdateable()){
                update leadRecord;	
                updateStatus = 'Success! You assigned ' + checkInRec.Lead__r.name +' to '+ selectedRepName +'.' ;
            }
        
        //Added below if condition to call accept method to mark the Status Engaged when Assign button is clicked
        if(checkinRec.QueuePosition__c !=null){ 
            if(checkinRec.Status__c == DCIConstants.INSTORE){ 
                DCIUtil.repId = selectedRep;
                DCIUtil.accept(checkInRec);
            }
        }
    }

        catch(Exception e)  {
            updateStatus = 'error';
        }
        return updateStatus;
    }
}
/*
* This class has the logic for Lead related activities for Digital Checkin for Retail track 
* @Autthor: Reshma Jewrani, Alisha Mundaden
*/
public without sharing class DCILeadUtil {
  //6070
  public static string getDtTimeInTimeZone(string timezone,Datetime DtTime){
      Datetime dt = DtTime;
      String dtTimeZone = dt.format('yyyy-MM-dd HH:mm:ss',timezone);
      return dtTimeZone;
  }
  /**
   * This method creates the Digital Checkin Lead and RetailCheckinQueue__c records
   * @Parameter - Lead dciLeadApi - Lead record to be created
   *              RetailCheckinQueue__c newCheckinDci - RetailCheckinQueue__c record to be created
   *              Store__c leadStore -  Store record to get queue for assignment
   * @Return - RetailDTO.DCIResponseDTO - The detailed response to be send back from web service api
  */
  @AuraEnabled
  public static RetailDTO.DCIResponseDTO createDCILead(Lead dciLeadApi, RetailCheckinQueue__c newCheckinDci, Store__c leadStore){
    RetailDTO.DCIResponseDTO resp;
    Boolean isBopis = false;   
    Boolean isFuture = false;  
    leadStore = DCIUtil.fetchStore(leadStore.Id);
    List<RetailCheckinQueue__c> lstNewCheckins = new List<RetailCheckinQueue__c>();
    String dtTimeInTimeZone;//6070

      dciLeadApi.ownerid = RetailConstants.RETAILLEADOWNERQUEUE;    
      try{
          dciLeadApi.company = 'ATT';
          if(Schema.sObjectType.Lead.isCreateable() && Schema.sObjectType.Lead.fields.company.isCreateable() &&
             Schema.sObjectType.Lead.fields.ownerid.isCreateable()){
            insert dciLeadApi;
          }
          newCheckinDci.Name = dciLeadApi.firstname+' '+dciLeadApi.lastname;
          newCheckinDci.ownerid = RetailConstants.RETAILLEADOWNERQUEUE;
          if(leadStore.TimeZone__c !=null && leadStore.TimeZone__c !=''){
            dtTimeInTimeZone = String.valueof(getDtTimeInTimeZone(leadStore.TimeZone__c,system.now()));
            newCheckinDci.CreatedDateLocalTz__c = dtTimeInTimeZone;
           // newCheckinDci.ActualServiceStartTimeLocalTz__c = dtTimeInTimeZone;
            if(newCheckinDci.CheckInTime__c!=null){
                newCheckinDci.CheckInTimeLocalTz__c = String.valueof(getDtTimeInTimeZone(leadStore.TimeZone__c,newCheckinDci.CheckInTime__c));
            }else{
                newCheckinDci.CheckInTimeLocalTz__c = String.valueof(getDtTimeInTimeZone(leadStore.TimeZone__c,system.now()));
            }
            
        }
      }catch(Exception e){
        if(e.getMessage().contains(DCIConstants.VALIDATION_EXP)){
          throw new RetailError.ClientSideException('Error in Json request '+e.getMessage());
        }else{
          throw new RetailError.ServerSideException('Error in DCI Lead record creation '+e.getMessage());       
        }
      }

      List<RetailCheckinQueue__c> updatedCheckins = new List<RetailCheckinQueue__c>(); // DM Added TUF
       //6070
       if(newCheckinDci.Status__c==DCIConstants.INSTORE)
       {
           newCheckinDci.ArrivingTime__c=System.now();
            newCheckinDci.ArrivingTimeLocalTz__c = dtTimeInTimeZone!=null?dtTimeInTimeZone:null;
       }
     

      if(dciLeadApi.DCICheckinType__c == DCIConstants.FUTURE){
        isFuture = true;  
        newCheckinDci.EstimatedWaitTime__c = 0;
        //skip
        newCheckinDci.DCIMaximum_EWT__c = newCheckinDci.EstimatedWaitTime__c;
        newCheckinDci.DCITotalRepCount__c=leadStore.DCIStoreRepActiveCapacity__c;
        newCheckinDci.DCIAvailableRepCount__c=leadStore.DCIStoreRepCurrentCapacity__c;
        newCheckinDci.DCIMinimum_EWT__c = newCheckinDci.EstimatedWaitTime__c;
        newCheckinDci.Store__c = dciLeadApi.Store__c;
        newCheckinDci.Lead__c = dciLeadApi.Id;
      }else if(String.isNotBlank(dciLeadApi.dciBOPISOrder__c) || dciLeadApi.ReasonForLeaving__c == DCIConstants.BOPISREASON){
        isBopis = true; 
        newCheckinDci.EstimatedWaitTime__c = 0;
        newCheckinDci.DCIEstimatedStartTime__c = System.Now();
        newCheckinDci.QueuePosition__c = 1;
        newCheckinDci.DCIMaximum_EWT__c = newCheckinDci.EstimatedWaitTime__c;
        newCheckinDci.DCITotalRepCount__c=leadStore.DCIStoreRepActiveCapacity__c;
        newCheckinDci.DCIAvailableRepCount__c=leadStore.DCIStoreRepCurrentCapacity__c;
        newCheckinDci.DCIMinimum_EWT__c = newCheckinDci.EstimatedWaitTime__c;
        newCheckinDci.Store__c = dciLeadApi.Store__c;
        newCheckinDci.Lead__c = dciLeadApi.Id;
        System.Debug('LeadDCIQueue New Entry Bopis');
         //if isBopis and EWT calc is TUF, update queue positions of all future pending records
            if (DCIConstants.EWTCalculationMethod == DCIConstants.TUF) { // DM Added TUF
                for (RetailCheckinQueue__c dciRecord : [SELECT id, QueuePosition__c
                                                       FROM RetailCheckinQueue__c
                                                       WHERE Store__c = :newCheckinDci.Store__c AND 
                                                       Status__c IN :DCIConstants.ALL_PENDING AND  
                                                       QueuePosition__c  > 0
                                                       WITH SECURITY_ENFORCED ORDER BY Store__c,QueuePosition__c]) 
                {
                    dciRecord.QueuePosition__c = dciRecord.QueuePosition__c + 1;
                    updatedCheckins.add(dciRecord);
                }
            }
      }else{
          List<RetailCheckinQueue__c> dciLeadsList = [Select ID,Store__c,Status__c,QueuePosition__c,EstimatedWaitTime__c from RetailCheckinQueue__c where Store__c =:leadStore.Id and QueuePosition__c > 0 and Status__c IN :DCIConstants.ALL_PENDING WITH SECURITY_ENFORCED order by QueuePosition__c desc LIMIT 1]; 
          //Get handleTime map 
          Decimal leadHandleTime = DCIConstants.getHandleTime(leadStore.Id, dciLeadApi.ReasonForLeaving__c);
          if (newCheckinDci.Status__c == DCIConstants.ACTIVE) { //US#4280
            //Set values appropriately
           newCheckinDci.Store__c = dciLeadApi.Store__c;
           newCheckinDci.Lead__c = dciLeadApi.Id;
           newCheckinDci.QueuePosition__c = 0;
           newCheckinDci.LastEWTUpdated__c = system.now();
           newCheckinDCI.EstimatedWaitTime__c = 0; 
           newCheckinDCI.DCIEstimatedStartTime__c = newCheckinDCI.EstimatedWaitTime__c==0?System.Now():leadStore.DCIShortestTUF__c;
           newCheckinDci.DCIMaximum_EWT__c = newCheckinDci.EstimatedWaitTime__c;
           newCheckinDci.DCITotalRepCount__c=leadStore.DCIStoreRepActiveCapacity__c;
           newCheckinDci.DCIAvailableRepCount__c=leadStore.DCIStoreRepCurrentCapacity__c;
           newCheckinDci.DCIMinimum_EWT__c = newCheckinDci.EstimatedWaitTime__c;
           newCheckinDci.Owner__c = dciLeadApi.Owner__c;
       } else if(dciLeadsList.size()>0) {
              //over write the existing RetailCheckinQueue__c
              newCheckinDci.Store__c = dciLeadApi.Store__c;
              newCheckinDci.Lead__c = dciLeadApi.Id;
              newCheckinDci.QueuePosition__c = dciLeadsList[0].QueuePosition__c + 1;
              newCheckinDci.LastEWTUpdated__c = system.now();
              if (DCIConstants.EWTCalculationMethod == DCIConstants.TUF) { // DM Added TUF - EWT Calculation
                    newCheckinDCI.EstimatedWaitTime__c = (leadStore.DCIShortestTUF__c != null && ((leadStore.DCIShortestTUF__c.getTime() - System.now().getTime()) / 60000) > 0) ? ((leadStore.DCIShortestTUF__c.getTime() - System.now().getTime()) / 60000).intValue() : 0;
                    newCheckinDCI.DCIEstimatedStartTime__c =  newCheckinDCI.EstimatedWaitTime__c==0?System.Now():leadStore.DCIShortestTUF__c;
              }else {
                    newCheckinDci.EstimatedWaitTime__c = DCIUtil.calculateEstimatedWaitTime(dciLeadsList[0].EstimatedWaitTime__c,leadStore, leadHandleTime);
                    newCheckinDci.DCIEstimatedStartTime__c = System.now().addMinutes(Integer.valueOf(newCheckinDci.EstimatedWaitTime__c));
              }
              newCheckinDci.DCIMaximum_EWT__c = newCheckinDci.EstimatedWaitTime__c;
              newCheckinDci.DCITotalRepCount__c=leadStore.DCIStoreRepActiveCapacity__c;
              newCheckinDci.DCIAvailableRepCount__c=leadStore.DCIStoreRepCurrentCapacity__c;
              newCheckinDci.DCIMinimum_EWT__c = newCheckinDci.EstimatedWaitTime__c;
              System.Debug('LeadDCIQueue New Entry ');
          } else {
            //Create a new RetailCheckinQueue__c
              newCheckinDci.Store__c = dciLeadApi.Store__c;
              newCheckinDci.Lead__c = dciLeadApi.Id;
              newCheckinDci.LastEWTUpdated__c = system.now();
              //If there are no pending records, and there isn't any online reps, calculate shortest TUF
              if(!(leadStore.DCIStoreRepCurrentCapacity__c>0)){
                  newCheckinDci.QueuePosition__c = 1;
                  if (DCIConstants.EWTCalculationMethod == DCIConstants.TUF) { // DM Added TUF - EWT Calculation
                        newCheckinDCI.EstimatedWaitTime__c = (leadStore.DCIShortestTUF__c != null && ((leadStore.DCIShortestTUF__c.getTime() - System.now().getTime()) / 60000) > 0) ? ((leadStore.DCIShortestTUF__c.getTime() - System.now().getTime()) / 60000).intValue() : 0;
                        newCheckinDCI.DCIEstimatedStartTime__c =  newCheckinDCI.EstimatedWaitTime__c==0?System.Now():leadStore.DCIShortestTUF__c;                  
                      }else {
                        newCheckinDci.EstimatedWaitTime__c = DCIUtil.calculateEstimatedWaitTime(0,leadStore, leadHandleTime);
                        newCheckinDci.DCIEstimatedStartTime__c = System.now().addMinutes(Integer.valueOf(newCheckinDci.EstimatedWaitTime__c));
                  } 
                  newCheckinDci.DCIMaximum_EWT__c = newCheckinDci.EstimatedWaitTime__c;
                  newCheckinDci.DCITotalRepCount__c=leadStore.DCIStoreRepActiveCapacity__c;
                  newCheckinDci.DCIAvailableRepCount__c=leadStore.DCIStoreRepCurrentCapacity__c;
                  newCheckinDci.DCIMinimum_EWT__c = newCheckinDci.EstimatedWaitTime__c;
                  System.Debug('LeadDCIQueue First Entry - No Reps Available');  
              }else{
                  newCheckinDci.QueuePosition__c = 1;
                  newCheckinDci.EstimatedWaitTime__c = 0;
                  newCheckinDci.DCIEstimatedStartTime__c = System.Now();
                  newCheckinDci.DCIMaximum_EWT__c = newCheckinDci.EstimatedWaitTime__c;
                  newCheckinDci.DCITotalRepCount__c=leadStore.DCIStoreRepActiveCapacity__c;
                  newCheckinDci.DCIAvailableRepCount__c=leadStore.DCIStoreRepCurrentCapacity__c;
                  newCheckinDci.DCIMinimum_EWT__c = newCheckinDci.EstimatedWaitTime__c;
                  System.Debug('LeadDCIQueue New Entry - Reps Available');
              }
          }
    }
    
    if(isBopis&& DCIConstants.EWTCalculationMethod != DCIConstants.TUF){
      DCIUtil.updateQueue(newCheckinDci.Store__c, 0,  true, false, 'BOPIS');  
    }

    try{
        
        if (DCIConstants.EWTCalculationMethod == DCIConstants.TUF) {
          newCheckinDci.DCIEWTCalculationType__c = DCIConstants.TUF;
        }
      newCheckinDci.DCIChangeReason__c = 'New Check-In';
      if(Schema.sObjectType.RetailCheckinQueue__c.isCreateable() && 
         Schema.sObjectType.RetailCheckinQueue__c.fields.DCIEWTCalculationType__c.isCreateable() &&
         Schema.sObjectType.RetailCheckinQueue__c.fields.ArrivingTime__c.isCreateable() &&
         Schema.sObjectType.RetailCheckinQueue__c.fields.EstimatedWaitTime__c.isCreateable() &&
         Schema.sObjectType.RetailCheckinQueue__c.fields.DCIMaximum_EWT__c.isCreateable() &&
         Schema.sObjectType.RetailCheckinQueue__c.fields.Store__c.isCreateable() &&
         Schema.sObjectType.RetailCheckinQueue__c.fields.Lead__c.isCreateable() &&
         Schema.sObjectType.RetailCheckinQueue__c.fields.QueuePosition__c.isCreateable() &&
         Schema.sObjectType.RetailCheckinQueue__c.fields.LastEWTUpdated__c.isCreateable() &&
         Schema.sObjectType.RetailCheckinQueue__c.fields.DCIEstimatedStartTime__c.isCreateable() &&
         Schema.sObjectType.RetailCheckinQueue__c.fields.DCITotalRepCount__c.isCreateable() &&
         Schema.sObjectType.RetailCheckinQueue__c.fields.DCIAvailableRepCount__c.isCreateable() &&
         Schema.sObjectType.RetailCheckinQueue__c.fields.DCIMinimum_EWT__c.isCreateable() &&
         Schema.sObjectType.RetailCheckinQueue__c.fields.Owner__c.isCreateable()){
        insert newCheckinDci;
      }
      if(updatedCheckins.size() > 0 && // Needed for TUF
      Schema.sObjectType.RetailCheckinQueue__c.fields.QueuePosition__c.isUpdateable()) { 
        update updatedCheckins;
      }
      //Prepare response
      RetailCheckinQueue__c objNewCheckinDci = [SELECT ID,Status__c, QueuePosition__c, EstimatedWaitTime__c FROM RetailCheckinQueue__c where ID=:newCheckinDci.ID WITH SECURITY_ENFORCED];
      resp = new RetailDTO.DCIResponseDTO();
      resp.statuscode = '0';
      resp.queueposition = ''+objNewCheckinDci.QueuePosition__c;
      resp.leadwaittime = ''+objNewCheckinDci.EstimatedWaitTime__c;
      resp.checkinid = objNewCheckinDci.Id;
      resp.leadid = dciLeadApi.Id;
      resp.leadName =dciLeadApi.firstname+' '+dciLeadApi.lastname;
      resp.status = 'initial';
      System.debug('LEADS IN QUEUE:::::: '+objNewCheckinDci.QueuePosition__c);
      
      if(!isBopis && DCIConstants.EWTCalculationMethod == DCIConstants.TUF && newCheckinDCI.Status__c != DCIConstants.ACTIVE) { // DM Added TUF - EWT Calculation
        DCIUtil.recalculateStoreTUF(new Set<Id>{leadStore.Id});
      } else if (!isBopis && DCIConstants.EWTCalculationMethod == DCIConstants.TUF && newCheckinDCI.Status__c == DCIConstants.ACTIVE) {
        DCIUtil.updateQueueBulkifyMinutesUntilFree(new Set<Id>{newCheckinDci.Store__c}, 0, false, false);
      } else if (isBopis && DCIConstants.EWTCalculationMethod == DCIConstants.TUF) { // Anand - EWT TUF if BOPIS
        DCIUtil.updateQueueBulkifyMinutesUntilFree(new set<Id>{newCheckinDci.Store__c}, 0, false, false,'BOPIS');
        RetailCheckinQueue__c newDCIcheckIn = [SELECT Id, EstimatedWaitTime__c, DCIEstimatedStartTime__c
                                              FROM RetailCheckinQueue__c WHERE Id=: newCheckinDci.Id WITH SECURITY_ENFORCED]; 
        
        newCheckinDci.EstimatedWaitTime__c = newDCIcheckIn.EstimatedWaitTime__c;
      } else {
        if(!isBopis){
          if(!isFuture){
          //Update Store EWT
          Decimal storeHandleTime = DCIConstants.getHandleTime(leadStore.Id, null);   
          leadStore.DCILeadsinCheckinQueue__c = DCIUtil.getPendingQueue(leadStore.Id, 0).size();
          leadStore.DCIEstimatedWaitTime__c =  DCIUtil.calculateEstimatedWaitTime(objNewCheckinDci.EstimatedWaitTime__c, leadStore, storeHandleTime);
          if(Schema.sObjectType.Store__c.fields.DCILeadsinCheckinQueue__c.isUpdateable() &&
            Schema.sObjectType.Store__c.fields.DCIEstimatedWaitTime__c.isUpdateable()){
            update leadStore;
          }
        }
        }else if(isBopis){
          leadStore.DCILeadsinCheckinQueue__c = DCIUtil.getPendingQueue(leadStore.Id, 0).size();
          if(Schema.sObjectType.Store__c.fields.DCILeadsinCheckinQueue__c.isUpdateable()){
            update leadStore;
          }
        }
      }

      if(isBopis  && newCheckinDci.Status__c == DCIConstants.INSTORE)
      {
        if(String.isNotBlank(dciLeadApi.dciBOPISOrder__c)){
           //Send Notification
           String mgrNotificationTitle = System.Label.BOPISOrderCollection;
           String mgrNotificationBody = System.Label.BOPISOrderCollectionBody;
           mgrNotificationBody =mgrNotificationBody.replace('{0}',dciLeadApi.dciBOPISOrder__c);
           Set<String> mgrRecipientIds = new Set<String>();
           
           if(dciLeadApi.Store__c!=null)
           {
               Set<Id> storeIds=new Set<Id>{dciLeadApi.Store__c};
               Map<Id, Set<String>> storeToManagersUserIdMap = NotificationsHandler.fetchStoreToManagersMap(storeIds);
               
               if(storeToManagersUserIdMap.containsKey(dciLeadApi.Store__c))
               {
                   mgrRecipientIds=storeToManagersUserIdMap.get(dciLeadApi.Store__c);
                   Boolean validated = NotificationsHandler.validateNotificationRequestParams(mgrNotificationTitle, mgrNotificationBody , mgrRecipientIds, newCheckinDci.Id);
                   
                   if(validated)
                   {
                       NotificationsHandler.sendNotification(mgrNotificationTitle, mgrNotificationBody , mgrRecipientIds , newCheckinDci.Id);
                   }
               }
           }
        }
       }
      //Send Auto-Response SMS to Lead after Checkin   
      lstNewCheckins.add(newCheckinDci);
      String eventType = (dciLeadApi.DCICheckinType__c != null && dciLeadApi.DCICheckinType__c.equalsIgnoreCase(DCIConstants.FUTURE)) ? DCIConstants.FUTURE : DCIConstants.NEW_CHECKIN;
      sendAutoResponseSMS(lstNewCheckins, eventType);
      if(isBopis){
        sendAutoResponseSMS(lstNewCheckins, DCIConstants.SMSBOPIS); 
     }
      
    }catch(Exception e){
        throw new RetailError.ServerSideException('Error in creating a checkin record'+e.getMessage());
    }
    return resp;
  }

  /**
   * This method checks if a Digital Checkin Lead for the same phone number and storeId exists in the  system
   * @Parameter - Lead dciLeadApi - Lead record to bee checked for duplicates
   *              Store__c leadStore -  Store record to get storeId to check for duplicates
  */
  public static void checkIfDCILeadExists(Lead dciLeadApi,Store__c leadStore){
    List<Lead> dciLeadList = [Select ID from Lead where MobilePhone =:dciLeadApi.MobilePhone and store__c =:leadStore.id and recordtypeid=:dciLeadApi.recordtypeid and Status!='Closed' WITH SECURITY_ENFORCED Limit 1];
    if(dciLeadList.size()>0){
        dciLeadApi.id = dciLeadList[0].id;
    }
  }

  /**
   * This method checks if a RetailCheckinQueue__c for the same phone number and storeId for that day exists in the  system
   * @Parameter - Lead dciLeadApi - Lead record to bee checked for duplicates
   *              Store__c leadStore -  Store record to get storeId to check for duplicates
   * @Return - RetailCheckinQueue__c - The RetailCheckinQueue__c record if it existss, else null
  */
  public static RetailCheckinQueue__c checkifCustomerCheckedIn(Lead dciLeadApi, Store__c leadStore){
      if (dciLeadApi.mobilePhone != null) {
          List<RetailCheckinQueue__c> dciLeadsList = [Select ID,Store__c,Status__c,QueuePosition__c,EstimatedWaitTime__c,Lead__c from RetailCheckinQueue__c where lead__r.MobilePhone=:dciLeadApi.mobilephone and Status__c IN :DCIConstants.ALL_PENDING_ENGAGED WITH SECURITY_ENFORCED]; 
          if(dciLeadsList.size()>0){
              return dciLeadsList[0];
          }
      }

      return null;
  }

  /**
   * This method fetches the Store__c from the location id
   * @Parameters - String locationId - Location id for which store has to be fetched
   * @Return - Store__c - store record fetched, null if no store
   */
  public static Store__c getStorebyLocationID(String locationId){
    Store__c store;
    List<Store__c> leadStoreList = [Select ID,Name,DCIShortestTUF__c, DCIStoreRepCurrentCapacity__c,DCIStoreRepActiveCapacity__c from Store__c where LocationId__c=:locationId WITH SECURITY_ENFORCED];
    if(leadStoreList.size()>0)
        store = leadStoreList.get(0);
    return store;
  }

  /**
   * This method fetches the Queue for the store
   * In future we will modify this method to take Store's location id as parameter instead 
   * @Parameter - String storeId - Salesforce id of the  store
   *              String storeName - Name of the Store
   * @Return - Group - Queue record for the  store passed
   */
  public static Group getStoreQueue(String storeId, String storeName){
    Group storeQueue;
    List<Group> gList = [select Id from Group where Name =:storeName and Type = 'Queue'];
    if(gList.size()>0)
      storeQueue = gList.get(0);   
    return storeQueue;
  }

  /**
   * This method prepares/send auto-response SMS text after DCI is created
   * 
   */
  public static void sendAutoResponseSMS(List<RetailCheckinQueue__c> lstCheckins, String eventType){
    try{
      ProcessMessagingSessionHelper.InboundMessage inboundData = new ProcessMessagingSessionHelper.InboundMessage();
      String response ='';      
      for(RetailCheckinQueue__c checkinRecord : lstCheckins){
          /* Check if its a Future-dated DCI */
          if(eventType.equalsIgnoreCase(DCIConstants.FUTURE)) {
              response = 'F';               
          }
          else if(eventType.equalsIgnoreCase(DCIConstants.REMOVE)){
            response = 'Y';
          } 
             /*Check if its a Online or Store Checkin. Based on the Status */
          else { 
            if(checkinRecord.Status__c.equalsIgnoreCase(DCIConstants.PENDING)){
                if(eventType.equalsIgnoreCase(DCIConstants.NEW_CHECKIN))
                  response = 'DigitalCheckin';
                else if(eventType.equalsIgnoreCase(DCIConstants.NO_SHOW)){
                        if(checkinRecord.NoShowCount__c == 1)
                           response = 'NoShow1';
                        else  if(checkinRecord.NoShowCount__c == 2)
                          response = 'NoShow2';
                }                   
            }
            else if(checkinRecord.Status__c.equalsIgnoreCase(DCIConstants.INSTORE)) {
                if(eventType.equalsIgnoreCase(DCIConstants.NEW_CHECKIN))
                  response = 'StoreCheckin';
            } 
            else if(checkinRecord.Status__c.equalsIgnoreCase(DCIConstants.ACTIVE)) {
                 if(eventType.equalsIgnoreCase(DCIConstants.ACTIVE))
                    response = 'YT';
            }              
          }
          if(eventType.equalsIgnoreCase(DCIConstants.SMSBOPIS)) {
            response = 'BOPIS';               
        }
          inboundData.dciLeadToResponseMap.put(checkinRecord.Lead__c, response);
      }
      
      ProcessMessagingSessionHelper.processDCI(inboundData);
    }catch(Exception e){
      System.debug('Exception thrown in send autoresponse'+ e.getMessage());
    }
  }

  @AuraEnabled
  public static RetailDTO.DCIResponseDTO createDCILeadOnHelp(Lead dciLeadApi, RetailCheckinQueue__c newCheckinDci, Store__c leadStore){
      RetailDTO.DCIResponseDTO resp;
      dciLeadApi.ownerid = RetailConstants.RETAILLEADOWNERQUEUE;
      Store__c store  = DCIUtil.fetchStore(dciLeadApi.Store__c); 
      try{
          dciLeadApi.company = 'ATT';
          dciLeadApi.CustomerRequestedRep__c = null;
          if(dciLeadApi.MobilePhone != null){
            String phone = String.valueOf(dciLeadApi.MobilePhone);
            Boolean isAttCtn = DCIService.checkIsAttNumber(phone);
            dciLeadApi.IsAttCtn__c = isAttCtn;
          }
          if(Schema.sObjectType.Lead.isCreateable() && Schema.sObjectType.Lead.fields.IsAttCtn__c.isCreateable() && Schema.sObjectType.Lead.fields.OwnerId.isCreateable() && Schema.sObjectType.Lead.fields.Company.isCreateable() && Schema.sObjectType.Lead.fields.CustomerRequestedRep__c.isCreateable()){
            insert dciLeadApi;
          }
          newCheckinDci.Name = dciLeadApi.firstname+' '+dciLeadApi.lastname;
          newCheckinDci.ownerid = dciLeadApi.ownerid;
          newCheckinDci.lead__c = dciLeadApi.id;
          newCheckinDci.QueuePosition__c = 0;
          newCheckinDci.EstimatedWaitTime__c = 0;
          newCheckinDci.DCIEstimatedStartTime__c = System.Now();
          newCheckinDci.DCIMaximum_EWT__c = newCheckinDci.EstimatedWaitTime__c;
          newCheckinDci.DCITotalRepCount__c=leadStore.DCIStoreRepActiveCapacity__c;
          newCheckinDci.DCIAvailableRepCount__c=leadStore.DCIStoreRepCurrentCapacity__c;
          newCheckinDci.DCIMinimum_EWT__c =newCheckinDci.EstimatedWaitTime__c;
          newCheckinDci.Status__c = DCIConstants.ACTIVE;
          newCheckinDci.Store__c = dciLeadApi.Store__c;
          newCheckinDci.DCIChangeReason__c = 'New Check-In';
          if (DCIConstants.EWTCalculationMethod == DCIConstants.TUF) {
            newCheckinDci.DCIEWTCalculationType__c = DCIConstants.TUF;
        } 
          if(Schema.sObjectType.RetailCheckinQueue__c.isCreateable() && Schema.sObjectType.RetailCheckinQueue__c.fields.QueuePosition__c.isCreateable() && 
            Schema.sObjectType.RetailCheckinQueue__c.fields.ownerid.isCreateable() && 
            Schema.sObjectType.RetailCheckinQueue__c.fields.DCIChangeReason__c.isCreateable() &&
            Schema.sObjectType.RetailCheckinQueue__c.fields.DCIEWTCalculationType__c.isCreateable() &&
            Schema.sObjectType.RetailCheckinQueue__c.fields.Store__c.isCreateable() &&
            Schema.sObjectType.RetailCheckinQueue__c.fields.Status__c.isCreateable() &&
            Schema.sObjectType.RetailCheckinQueue__c.fields.DCIMinimum_EWT__c.isCreateable() &&
            Schema.sObjectType.RetailCheckinQueue__c.fields.DCIMaximum_EWT__c.isCreateable() &&
            Schema.sObjectType.RetailCheckinQueue__c.fields.DCIAvailableRepCount__c.isCreateable() &&
            Schema.sObjectType.RetailCheckinQueue__c.fields.DCITotalRepCount__c.isCreateable() &&
            Schema.sObjectType.RetailCheckinQueue__c.fields.DCIEstimatedStartTime__c.isCreateable() &&
            Schema.sObjectType.RetailCheckinQueue__c.fields.EstimatedWaitTime__c.isCreateable() &&
            Schema.sObjectType.RetailCheckinQueue__c.fields.lead__c.isCreateable() &&
            Schema.sObjectType.RetailCheckinQueue__c.fields.Name.isCreateable()){
            insert newCheckinDci;
          }
          DCIUtil.accept(newCheckinDci);
      } catch(Exception e){
          if(e.getMessage().contains(DCIConstants.VALIDATION_EXP)) {
              throw new RetailError.ClientSideException('Error in Json request '+e.getMessage());
          } else {
              throw new RetailError.ServerSideException('Error in DCI Lead record creation '+e.getMessage());       
          }
      }
      
     //US 2566
      if(store!=null){
        try{
            List<StoreQueueUpdateNotification__e> sueList = new List<StoreQueueUpdateNotification__e>();
            sueList.add(new StoreQueueUpdateNotification__e(StoreId__c=store.Id, StoreLocationId__c =store.LocationId__c ));
        
            if(!sueList.isEmpty()){
                // Call method to publish events
                List<Database.SaveResult> results = EventBus.publish(sueList);
            }
          
        } catch (Exception e){
            System.Debug('Platform Event on StoreQueueUpdateNotification__e failed '+e.getMessage());
        }
      }


      resp = new RetailDTO.DCIResponseDTO();
      resp.statuscode = '0';
      resp.queueposition = ''+newCheckinDci.QueuePosition__c;
      resp.leadwaittime = ''+newCheckinDci.EstimatedWaitTime__c;
      resp.checkinid = newCheckinDci.Id;
      resp.leadid = dciLeadApi.Id;
      resp.leadName =dciLeadApi.firstname+' '+dciLeadApi.lastname;
      resp.status = 'initial';
      resp.assignedRSC = [SELECT Id, DCIAssignedRSC__c FROM RetailCheckinQueue__c WHERE Id=:newCheckinDci.Id WITH SECURITY_ENFORCED][0].DCIAssignedRSC__c;
      return resp;
  }

}
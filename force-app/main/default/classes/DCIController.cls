public without sharing class DCIController { 
    @AuraEnabled(cacheable=true) 
    public static String getInactiveTime(){
        String inActivityTime;
        String DCI_INACTIVE_TIME = 'DCIRepAllowedIdleTime';
        inActivityTime = RetailUtil.getRetailCustomSettings(DCI_INACTIVE_TIME); 
        return inActivityTime;
    } 
    @AuraEnabled
    public static String changeRepStatus(String status){
        System.debug('status:: '+status);
        String strStoreId = StoreController.getStoreFromCache();
        List<EmployeeStoreRetail__c> empStoreList ;
        if(String.isBlank(strStoreId)){
            Store__c repsStore = LeadForm.getHomeStore('true'); 
            if(repsStore!=null){
                strStoreId = repsStore.Id; 
            }
        }
        System.debug('strStoreId:: '+strStoreId);
        if(String.isNotBlank(strStoreId)){
            empStoreList = [SELECT ID,Name,DCIPresenceStatus__c,Store__c,User__c FROM EmployeeStoreRetail__c  
            WHERE Employee__r.User__c =:UserInfo.getUserId() and Store__c=:strStoreId WITH SECURITY_ENFORCED];
        }else{
             empStoreList = [SELECT ID,Name,DCIPresenceStatus__c,Store__c,User__c FROM EmployeeStoreRetail__c  
            WHERE Employee__r.User__c =:UserInfo.getUserId() WITH SECURITY_ENFORCED];
        }
        
        if(empStoreList.size()>0){
            DCIRepUtil.updateRepStatus(empStoreList[0],status);    
        }
        return 'Status changed';
    }
   
    @AuraEnabled
    public static String cancelAllCheckins(String cancellationReason, String storeId){
        try{
            DCICancelChekinRecordsQueauable queueObj = new DCICancelChekinRecordsQueauable(cancellationReason,storeId);
            System.enqueueJob(queueObj);
            return 'All Checkins Cancelled';
        }
        catch(Exception e){
            return 'Error! '+e.getMessage();
        }
    }

    @AuraEnabled
    public static RetailDTO.DCIHomePageDataDTO getInitialData(){
       RetailDTO.DCIHomePageDataDTO initialData = new RetailDTO.DCIHomePageDataDTO();  
       String strStoreId = StoreController.getStoreFromCache();
        List<EmployeeStoreRetail__c> empStoreList ;
        if(String.isBlank(strStoreId)){
            Store__c repsStore = LeadForm.getHomeStore('true'); 
            if(repsStore!=null){
                strStoreId = repsStore.Id; 
            }
        }
        Boolean status;
        System.debug('strStoreId:: '+strStoreId);
        if(String.isNotBlank(strStoreId)){
            empStoreList = [SELECT ID,Name,DCIPresenceStatus__c,IsCurrentlyAvailable__c,Store__c,Store__r.Name,Store__r.DCIEstimatedWaitTime__c,Store__r.DCIStoreRepActiveCapacity__c,Store__r.DCIStoreRepCurrentCapacity__c,Store__r.DCILeadsinCheckinQueue__c,User__c,IsManagerOnDuty__c,SFProfileId__c FROM EmployeeStoreRetail__c  
            WHERE Employee__r.User__c =:UserInfo.getUserId() and Store__c=:strStoreId WITH SECURITY_ENFORCED];
            status = DCIUtil.checkIfBusywithCustomer(strStoreId);
        }else{
             empStoreList = [SELECT ID,Name,DCIPresenceStatus__c,IsCurrentlyAvailable__c,Store__c,Store__r.Name,Store__r.DCIEstimatedWaitTime__c,Store__r.DCIStoreRepActiveCapacity__c,Store__r.DCIStoreRepCurrentCapacity__c,Store__r.DCILeadsinCheckinQueue__c,User__c,IsManagerOnDuty__c,SFProfileId__c FROM EmployeeStoreRetail__c  
            WHERE Employee__r.User__c =:UserInfo.getUserId() WITH SECURITY_ENFORCED];
            status = DCIUtil.checkIfBusywithCustomer(empStoreList[0].Store__c);
        }
        EmployeeStoreRetail__c empStore;
        Boolean hasCustomersArrived = false;
        List<RetailCheckinQueue__c> dciCheckinList = new List<RetailCheckinQueue__c>();
        integer arrivedCustomersCount = 0;
        System.debug('empStoreList:: '+empStoreList.size());
        if(empStoreList.size()>0){
             empStore = empStoreList[0];
             dciCheckinList = DCIUtil.checkStoreHasArrivedCustomers(empStore);
             if(dciCheckinList!=null && dciCheckinList.size()>0){
                hasCustomersArrived = true;
                arrivedCustomersCount = dciCheckinList.size();
             }
        }
        initialData.massCancellationReason = new List<Map<String,String>>();
        Schema.DescribeFieldResult fieldResult = Lead.DCIReasonForCancellation__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry pickListVal : ple){
            Map < String, String > values = new Map < String, String > {
                'label' => pickListVal.getLabel(),
                'value' => pickListVal.getValue()
            };
            initialData.massCancellationReason.add(values);
        }
        initialData.hasCustomerEngaged = status;
        initialData.employeeDetails = empStore;
        initialData.hasCustomersArrived = hasCustomersArrived;
        initialData.customerArrivedCount = arrivedCustomersCount;
        initialData.pendingRecordsCount = [SELECT count() FROM RetailCheckinQueue__c WHERE Status__c IN('Pending', 'Arrived', 'No Show') AND Store__c=:empStore.Store__r.Id AND CheckInTime__c=TODAY WITH SECURITY_ENFORCED];
        return initialData;
    }
    @AuraEnabled
    public static List < RetailCheckinQueue__c > getArrivedCustomers() {
        RetailDTO.DCIHomePageDataDTO initialData = getInitialData();
        EmployeeStoreRetail__c empStore = initialData.employeeDetails;
        List < RetailCheckinQueue__c > arriveCustLst = new List < RetailCheckinQueue__c > ();
        arriveCustLst = [SELECT ID, Name, lead__c, lead__r.Name, DCICheckinType__c, NoShowCount__c, Store__c, Status__c, QueuePosition__c, EstimatedWaitTime__c, Store__r.Name
            FROM RetailCheckinQueue__c WHERE Store__c =: empStore.Store__c AND Status__c =: DCIConstants.INSTORE WITH SECURITY_ENFORCED order by QueuePosition__c
            ];
        return arriveCustLst;
    }

    @AuraEnabled
    public static RetailDTO.DCINextCustomerDTO getCustomer(EmployeeStoreRetail__c empStore, Store__c store){
        RetailDTO.DCINextCustomerDTO customerInfo = new RetailDTO.DCINextCustomerDTO();
        System.debug('empStore:: '+empStore);
        System.debug('store:: '+store);
        if(empStore!= null && store!= null){ 
            empStore = [SELECT ID,Name,DCIPresenceStatus__c,Store__c,Store__r.Name,Store__r.DCIEstimatedWaitTime__c,Store__r.DCIStoreRepActiveCapacity__c,Store__r.DCIStoreRepCurrentCapacity__c,Store__r.DCILeadsinCheckinQueue__c,User__c,SFProfileId__c FROM EmployeeStoreRetail__c  
            WHERE id = :empStore.Id];
            //if(empStore.SFProfileId__c == DCIConstants.EMPSTORE_SM_PROFILE || (empStore.SFProfileId__c == DCIConstants.EMPSTORE_REP_PROFILE && (empStore.DCIPresenceStatus__c =='Online' || empStore.DCIPresenceStatus__c =='Offline'))){   
            if(empStore.DCIPresenceStatus__c =='Online' || empStore.DCIPresenceStatus__c =='Offline'){       
                customerInfo = DCIRepUtil.assign(empStore); 
            }else{
                customerInfo.message = 'You are currently busy with a customer, a new customer cannot be assigned to you.';
            }     
        }else{
            customerInfo.message = 'No employee store Found';
        }
        
        return customerInfo;
    }    
    @AuraEnabled
    public static RetailCheckinQueue__c getCheckInStatus(String recordId){
        RetailCheckinQueue__c dciRecord = [SELECT Status__c, Store__c FROM RetailCheckinQueue__c WHERE Id =: recordId];
        system.debug('dciRecord Status---' + dciRecord);
        return dciRecord;
    }

    @AuraEnabled
    public static RetailDTO.DCICheckinDataDTO getCheckInInfo(String recordId){
        System.debug('getCheckInInfo');
        System.debug(recordId);
        Lead leadRecord;
        RetailCheckinQueue__c dciRecord = [SELECT id, Name, Status__c, Store__c, Lead__c  FROM RetailCheckinQueue__c WHERE Id =: recordId];
        if(dciRecord.Lead__c!=null)
            leadRecord = [SELECT id, Name , Store__c, recordTypeId, Status, FirstName, LastName, MobilePhone, OtherNotes__c FROM Lead WHERE Id =: dciRecord.Lead__c];
        RetailDTO.DCICheckinDataDTO checkinInfo = new RetailDTO.DCICheckinDataDTO();
        checkinInfo.checkinRecord = dciRecord;
        checkinInfo.leadRecord = leadRecord;
        return checkinInfo;
    }

    @AuraEnabled
    public static String finishCheckin(RetailDTO.DCICheckinDataDTO checkinInfo){
       System.Debug(checkinInfo);
       System.Debug('finishCheckin');
       return DCIUtil.updateFinishRecords(checkinInfo);  
    } 

    @AuraEnabled(cacheable=true)
    public static RetailDTO.OnLoadDCIDetails getonLoadDCIDetails() {
        RetailDTO.OnLoadDCIDetails onLoadDCIDetails = new RetailDTO.OnLoadDCIDetails();
        List<RetailDTO.DCICustomerRequestedRep> listCustReqRepInfo = new List<RetailDTO.DCICustomerRequestedRep>();
        String storeId = StoreController.getStoreFromCache();
        if(String.isBlank(storeId)){
            Store__c repsStore = LeadForm.getHomeStore('true'); 
            if(repsStore!=null){
                storeId = repsStore.Id; 
            }
        }
        if(String.isNotBlank(storeId)){
            onLoadDCIDetails.storeDetails = DCIUtil.fetchStore(storeId);
            onLoadDCIDetails.enableHelpNextButton = enableHelpNextButton(storeId);	
        }
        return onLoadDCIDetails;    
    }
	
	public static Boolean enableHelpNextButton(String storeId){
        Boolean decision = false;
        List<EmployeeStoreRetail__c> empStoreList; EmployeeStoreRetail__c empStore;

        if(String.isNotBlank(storeId)){
            empStoreList = [SELECT ID,Name,DCIPresenceStatus__c,Store__c,Store__r.Name,Store__r.DCIEstimatedWaitTime__c,Store__r.DCIStoreRepActiveCapacity__c,Store__r.DCIStoreRepCurrentCapacity__c,Store__r.DCILeadsinCheckinQueue__c,User__c,SFProfileId__c FROM EmployeeStoreRetail__c  
            WHERE Employee__r.User__c =:UserInfo.getUserId() and IsExpired__c = False and Employee__r.IsActive__c = true and Store__c=:storeId];
        }else{
             empStoreList = [SELECT ID,Name,DCIPresenceStatus__c,Store__c,Store__r.Name,Store__r.DCIEstimatedWaitTime__c,Store__r.DCIStoreRepActiveCapacity__c,Store__r.DCIStoreRepCurrentCapacity__c,Store__r.DCILeadsinCheckinQueue__c,User__c,SFProfileId__c FROM EmployeeStoreRetail__c  
            WHERE Employee__r.User__c =:UserInfo.getUserId()];
        }

        if(empStoreList.size()>0){
            empStore = empStoreList[0];
        }

		if(!DCIUtil.checkIfBusywithCustomer(storeId)){
            if(empStore!= null){
                if(empStore.SFProfileId__c == DCIConstants.EMPSTORE_REP_PROFILE){
                    List<RetailCheckinQueue__c> retailCheckIn = new List<RetailCheckinQueue__c>([SELECT id FROM RetailCheckinQueue__c WHERE Status__c = :DCIConstants.INSTORE AND Store__c=:storeId AND DAY_ONLY(CheckInTime__c )=:Date.today()]);
                    if(retailCheckIn.isEmpty())
                        decision = true;
                }else{
                    decision = true;
                }
            }
		}
		return decision;
    }
    @AuraEnabled
    public static Boolean DCIcheckIfBusywithCustomer(){

        String strStoreId = StoreController.getStoreFromCache();
        if(String.isBlank(strStoreId)){
            Store__c repsStore = LeadForm.getHomeStore('true'); 
            if(repsStore!=null){
                strStoreId = repsStore.Id; 
            }
        }
        List<RetailCheckinQueue__c> existingRetailCheckinQueue = new List<RetailCheckinQueue__c>([SELECT Id, Store__c, Store__r.Name FROM RetailCheckinQueue__c 
                                        WHERE Status__c=: DCIConstants.ACTIVE  AND Store__c=: strStoreId AND Lead__r.Owner__c=: UserInfo.getUserId()]);

        if(!existingRetailCheckinQueue.isEmpty())
            return true;  
        else
            return false;
        
    }
	
    //Krishna
    @AuraEnabled(cacheable=true)
    public static string getAllNotes(String RCQId){
        RetailCheckinQueue__c rck = [SELECT ID,Lead__r.OtherNotes__c FROM RetailCheckinQueue__c Where id =:RCQId];
        return  String.valueOF(rck.Lead__r.OtherNotes__c);
    }

    @AuraEnabled
    public static RetailDTO.DCIFormLwcHandleSubmit dciFormLwcHandleSubmit(Lead dciLeadApi, RetailCheckinQueue__c newCheckinDci, Store__c leadStore, String selectedRepId){
        RetailDTO.DCIFormLwcHandleSubmit dciFormHandleSubmitReturn = new RetailDTO.DCIFormLwcHandleSubmit();
        RetailDTO.DCIResponseDTO respDTO = new RetailDTO.DCIResponseDTO();
        if(dciLeadApi.MobilePhone != null){
            Boolean isAttCtn = DCIService.checkIsAttNumber(dciLeadApi.MobilePhone);
            dciLeadApi.IsAttCtn__c = isAttCtn;
        }
        respDTO = DCILeadUtil.createDCILead(dciLeadApi, newCheckinDci, leadStore);
        if(respDTO!=null){
            dciFormHandleSubmitReturn.dciResponseDTO = respDTO;
        }
        if(String.isNotBlank(selectedRepId)){
            User objUser = [Select ID, Name from User where Id =: selectedRepId ];
            dciFormHandleSubmitReturn.custReqRepName = objUser.Name;
        }
        return dciFormHandleSubmitReturn;
    }
    
    @AuraEnabled
    public static Boolean checkIfBusywithCustomer(String recordId){
        Boolean busyWithCustomer = DCIUtil.checkIfBusywithCustomer(recordId);
        return busyWithCustomer;
    }

	@AuraEnabled                                                                            
	public static RetailCheckinQueue__c getBusyCustomer(){
	String strStoreId = StoreController.getStoreFromCache();
	if(String.isBlank(strStoreId)){
		Store__c repsStore = LeadForm.getHomeStore('true'); 
		if(repsStore!=null){
			strStoreId = repsStore.Id; 
		}
	}
	System.debug('strStoreId:: '+strStoreId);
	if(String.isNotBlank(strStoreId)){
		RetailCheckinQueue__c cust = DCIUtil.getBusywithCustomerInfo(strStoreId);  
		return cust;
	}
	return null;
    }

    @AuraEnabled                                                                        
    public static String updateDCIPresenceOfEmployee(String recordId, String DCIStatus,String storeId){

        EmployeeStoreRetail__c esrObj = new EmployeeStoreRetail__c();
        String updateMsg;

        if(!String.isBlank(recordId) && !String.isBlank(DCIStatus)){
            try{
                esrObj.Id = recordId;
                esrObj.DCIPresenceStatus__c = DCIStatus;
                if(DCIStatus == DCIConstants.ONLINE){
                    esrObj.IsCurrentlyAvailable__c =true;  
                }else if(DCIStatus == DCIConstants.OFFLINE){
                    esrObj.IsCurrentlyAvailable__c =false; 
                }


                update esrObj;

                if(DCIStatus == DCIConstants.OFFLINE) {
                    if (DCIConstants.EWTCalculationMethod == DCIConstants.TUF) { // DM Added TUF - EWT Calculation
                        DCIUtil.updateQueueBulkifyMinutesUntilFree(new Set<Id>{storeId}, 0, false, false, 'Rep went offline');
                    } else {
                        DCIUtil.updateQueue(storeId, 0,  false, false, 'Rep went offline');
                    }
                } else if (DCIStatus == DCIConstants.ONLINE && DCIConstants.EWTCalculationMethod == DCIConstants.TUF) {
                    DCIUtil.updateQueueBulkifyMinutesUntilFree(new set<Id>{storeId}, 0, false, false, 'Rep went online');
                }
                updateMsg = 'Success';
            }
            catch(Exception e){
                System.debug(e);
                updateMsg = e.getMessage();
            }
        }
        return updateMsg;
    }
    @AuraEnabled                                                                        
    public static String updateMoDStatusOfRep(String recordId, Boolean ModStatus){

        EmployeeStoreRetail__c esrObj = new EmployeeStoreRetail__c();
        String updateMsg;

        if(!String.isBlank(recordId)){
            try{
                esrObj.Id = recordId;
                esrObj.IsManagerOnDuty__c = ModStatus;

                update esrObj;
                updateMsg = 'Success';
            }
            catch(Exception e){
                System.debug(e);
                updateMsg = e.getMessage();
            }
        }
        return updateMsg;
    }

    @AuraEnabled
    public static RetailDTO.DCICheckinDataDTO validateLeadInfo(String recordId, String firstName, String lastName){
        RetailDTO.DCICheckinDataDTO returnValidationInfo = new RetailDTO.DCICheckinDataDTO();
        List<RetailCheckinQueue__c> listRck = [SELECT ID,Lead__c,Lead__r.OtherNotes__c,Status__c, Lead__r.Name, Lead__r.FirstName, Lead__r.LastName, Store__c  FROM RetailCheckinQueue__c where id =:recordId];
        if(!listRck.isEmpty()){
            returnValidationInfo.checkinRecord = listRck[0];
            if(listRck[0].Lead__c!=null){
                Lead leadRecord = [Select ID, OtherNotes__c, Name, FirstName, LastName  from Lead where Id =:listRck[0].Lead__c];
                returnValidationInfo.leadRecord = leadRecord;
            }
        }
        return returnValidationInfo;
    }
    
    @AuraEnabled
    public static string BopisOrderCallout(string BOPISOrder, string OrderPhNumber){
        String response ='';
        String responseBody ='';
        Map<String,String>  calloutStatusMap = new Map<String,String>();
        calloutStatusMap = DCIService.BopisOrderCallouttoExternal(BOPISOrder,OrderPhNumber);
        
        for(string  responseCode : calloutStatusMap.Keyset()){
            
            if(responseCode=='200' || responseCode=='404'){
                 responseBody = calloutStatusMap.get(responseCode);
                 system.debug('**responseBody**'+responseBody);
                if(responseCode=='200'){
                    response = string.valueOf('200'+'-'+'Order Found');
                }else if(responseCode=='404'){
                     Map<String,Object> parseMessage = ( Map<String,Object>)JSON.deserializeUntyped(responseBody); 
                     string orderMessage= String.valueOf(parseMessage.get('message')).toLowerCase();
                     system.debug('**Order Message**'+orderMessage);
                     string responseORderID='';
                     if(orderMessage.Contains('order not found')){
                         response = string.valueOf('404'+'-'+'We can\'t locate that order. Choose another visit reason or enter another order number to check this customer in.');
                     }else{
                         responseORderID = orderMessage.substringAfter('order').substringBefore('found');
                         system.debug('**responseORderID**'+responseORderID);
                         if(orderMessage.Contains('found but fulfillment type is not c2s')){
                            response = string.valueOf('404'+'-'+'We found order '+responseORderID+', but it isn\'t an online pickup order. Choose another visit reason or enter another order number to check this customer in.');
                         }else if(orderMessage.Contains('found but ordering store and check-in store does not match')){
                             
                             response = string.valueOf('404'+'-'+'The customer selected a different pickup store when they placed order '+responseORderID+'. Choose another visit reason or enter another order number to check this customer in.');
                         }else if(orderMessage.Contains('found but line of business is not ws')){
                             response = string.valueOf('404'+'-'+'Order '+responseORderID+'isn’t a wireless order. Choose another visit reason or enter another order number to check this customer in.');
                         }else if(orderMessage.Contains('found but its cancelled')){ 
                             response = string.valueOf('404'+'-'+'Order '+responseORderID+'was canceled. Choose another visit reason or enter another order number to check this customer in.');
                         }else if(orderMessage.Contains('found but its not ready for pick up')){
                             response = string.valueOf('404'+'-'+'Order '+responseORderID+' isn\'t ready for pickup yet. Choose another visit reason or enter another order number to check this customer in.');
                         }else if(orderMessage.Contains('found but its already picked up')){
                             response = string.valueOf('404'+'-'+'Someone already picked up order '+responseORderID+'. Choose another visit reason or enter another order number to check this customer in.');
                         }
                    }

                }
             }else if(responseCode=='400'){
                    responseBody = calloutStatusMap.get(responseCode);
                    Map<String,Object> parseMessagefail = ( Map<String,Object>)JSON.deserializeUntyped(responseBody); 
                    system.debug('**Order description**'+parseMessagefail.get('description'));
                    response = string.valueOf('404'+'-'+string.valueOf(parseMessagefail.get('description')));
             }else{
                response = string.valueOf('250'+'-'+'Callout Failed, please checkback later.');
             }
        }
        
        return response;
    
    }

    @AuraEnabled
    public static void getEmployeeStoreRetail(String recordId, Boolean setUnsetManagerOnDuty){
        List<EmployeeStoreRetail__c>  empStore = [SELECT ID, IsManagerOnDuty__c, Store__r.Name, Store__r.LocationId__c,Employee__r.User__c FROM EmployeeStoreRetail__c  WHERE id =: recordId Limit 1]; 
        if(!empStore.isEmpty() && empStore[0].Store__r.LocationId__c!=null && empStore[0].Employee__r.User__c!=null){
        	try{
                String storeRetail = 'Retail_'+empStore[0].Store__r.LocationId__c;
                List<Group> listGrp = [SELECT Id, Name, DeveloperName, RelatedId, Type, Email FROM Group where DeveloperName=:storeRetail and Type='Regular' Limit 1];    
                if(!listGrp.isEmpty()){
                	List<GroupMember> listgM  = [SELECT Id, GroupID, UserOrGroupId FROM GroupMember where GroupID=:listGrp[0].Id and UserOrGroupId =:empStore[0].Employee__r.User__c Limit 1];
                    if(setUnsetManagerOnDuty){
                        GroupMember groupMember = new GroupMember();
                        groupMember.GroupId = listGrp[0].Id;
                        groupMember.UserOrGroupId = empStore[0].Employee__r.User__c;
                        insert groupMember; 
                    }else if(!setUnsetManagerOnDuty && !listgM.isEmpty()){
                        delete listgM;             
                    }    
                }        
            } catch (Exception e){
                throw new AuraHandledException(e.getMessage());
        	}
        }       
    }
    @AuraEnabled
    public static void updateRepStatus(){
        List<Profile> userProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId()];
        String profileName;
        if(userProfile.size()>0)
            profileName = userProfile[0].Name;
        
        if(profileName!=null && (profileName.contains('Retail SM') || profileName.contains('System Administrator'))){
            List<EmployeeStoreRetail__c> empStore = [Select Id from EmployeeStoreRetail__c where  
                                                     User__c=:userinfo.getUserId() and HomeStore__c = true];
        
            if(empStore!= null && !empStore.isEmpty()){
                empStore[0].IsCurrentlyAvailable__c = true;
                empStore[0].DCIPresenceStatus__c = 'Busy';
                update empStore[0];
            }
        }
    }
    @AuraEnabled
    public static boolean displayStoreManagementTab(){
        boolean result = true;
        user userrecord = [select id,profile.name from user where id=: userinfo.getUserId()];
        if(userrecord.profile.name == retailConstants.SM_PROFILE_NAME){
            result = false;
    }
        return result;
}
}
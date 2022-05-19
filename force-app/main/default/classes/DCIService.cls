/*
* This class is the service class for the DCI webservice. All processing on the incoming request should go here.
* @Author: Reshma Jewrani, Alisha Mundaden
*/
public with sharing class DCIService {
    /* 
    *This method is to process incoming Json payload on the DCI Checkin Creation web service.
    */
    public static RetailDTO.DCIResponseDTO processRequest(Map<String, Object> requestMap){
        RetailDTO.DCIResponseDTO response;
        Map<String, Object> leadRecordMap = (Map<String, Object>) requestMap.get('leadrecord');
        Map<String, Object> checkinRecordMap = (Map<String, Object>) requestMap.get('checkinrecord');
        Map<String, Object> repLeadMap = new Map<String, Object>();
        Store__c leadStore = DCILeadUtil.getStorebyLocationID(''+leadRecordMap.get('store__r.LocationId__c'));
        String profileName = [Select Id, Name FROM Profile WHERE Id=: userInfo.getProfileId()].Name;
        if(leadStore!=null && ((leadRecordMap.get('reasonForLeaving__c') == 'Get help from a rep in OPUS' && profileName == 'Integration Profile') || (leadRecordMap.get('reasonForLeaving__c') != 'Get help from a rep in OPUS'))){
            Lead dciLead = new Lead();
            for(String key: leadRecordMap.keyset()){
                if(key == 'store__r.LocationId__c'){
                    dciLead.store__c = leadStore.Id;
                } else if (key == 'owner__c') {
                    String repId = (String) leadRecordMap.get(key);
                    repLeadMap.put(repId, leadRecordMap);
                }else if(key.equalsIgnoreCase('isAttCtn__c')){
                    dciLead.put(key,leadRecordMap.get(key));
                }    
                else{
                    dciLead.put(key,''+leadRecordMap.get(key));
                }
            }
                    List<EmployeeStoreRetail__c>  employeeStoreRetail = [SELECT Id, SFProfileId__c, DCIPresenceStatus__c, Employee__r.EmployeeId__c, Employee__r.User__c  FROM EmployeeStoreRetail__c WHERE Employee__r.EmployeeId__c  IN :repLeadMap.keySet()  AND Store__c = :leadStore.Id];
                    //CDEX:90230
                    if (employeeStoreRetail != null && employeeStoreRetail.size() > 0 && repLeadMap.size() > 0) {
                        dciLead.owner__c = employeeStoreRetail[0].Employee__r.User__c;
                        dciLead.DCIActualServiceStartTime__c = System.now();
                        //CDEX:90230 Commented below IF statement
                        //if(employeeStoreRetail[0].DCIPresenceStatus__c == 'Busy' || employeeStoreRetail[0].SFProfileId__c == RetailConstants.RSC_MGR) {
                            //Get RetailCheckinQueue record
                            List<RetailCheckinQueue__c> retailQueue = [SELECT Id, Lead__c, Status__c, Store__c FROM RetailCheckinQueue__c  WHERE Owner__c =: employeeStoreRetail[0].Employee__r.User__c AND Status__c = :DCIConstants.ACTIVE AND Store__c = :leadStore.Id WITH SECURITY_ENFORCED];
                            //Only 1 record should return
                            if (retailQueue != null && retailQueue.size() > 0) {
                                retailQueue[0].Status__c = 'Completed';
                                
                                Lead leadToClose = [SELECT Id, Status, ClosedStatus__c, DCIActualServiceEndTime__c FROM Lead WHERE Id = :retailQueue[0].Lead__c WITH SECURITY_ENFORCED];
                                leadToClose.Status = RetailConstants.CLOSED;
                                leadToClose.ClosedStatus__c = DCIConstants.COMPLETED;
                                leadToClose.DCIActualServiceEndTime__c = System.now();
                                
                                update retailQueue;
                                update leadToClose;
                            }
                        
                        if (employeeStoreRetail[0].SFProfileId__c != RetailConstants.RSC_MGR) {
                            employeeStoreRetail[0].DCIPresenceStatus__c = 'Busy';
                            update employeeStoreRetail[0];
                        }
                    }
               
            RetailCheckinQueue__c newLeadDci = DCILeadUtil.checkifCustomerCheckedIn(dciLead, leadStore);
            if(newLeadDci!= null){
                RetailDTO.DCIResponseDTO resp = new RetailDTO.DCIResponseDTO();
                resp.statuscode = '0';
                resp.queueposition = ''+newLeadDci.QueuePosition__c;
                resp.leadwaittime = ''+newLeadDci.EstimatedWaitTime__c;
                resp.checkinid = newLeadDci.Id;
                resp.leadid = newLeadDci.Lead__c;
                resp.status = 'existing';
                response = resp;
             }else{
                newLeadDci= new RetailCheckinQueue__c();
                newLeadDci.Status__c = ''+checkinRecordMap.get('status__c');
                if(dciLead.dciCheckinType__c == DCIConstants.FUTURE){
                    String gmtDateTime = (string) checkinRecordMap.get('checkInTime__c');
                    if(String.isNotBlank(gmtDateTime)){  
                       DateTime checkinTime = DCIUtil.getGMTDateTime(gmtDateTime);
                       if(checkinTime == null)
                         throw new RetailError.ClientSideException('Invalid format of checkInTime__c. Expected Format Eg: 2021-01-31T04:00:00Z');     
                      newLeadDci.CheckinTime__c = checkinTime;     
                    }else{
                      throw new RetailError.ClientSideException('Json field checkInTime__c is a required field for Future Checkins');
                    }
                }else{
                    newLeadDci.CheckInTime__c = system.now();
                }

                if(newLeadDci.Status__c == DCIConstants.INSTORE || newLeadDci.Status__c == DCIConstants.ACTIVE) {
                    newLeadDci.ArrivingTime__c = system.now();
                }
                response = DCILeadUtil.createDCILead(dciLead, newLeadDci, leadStore); 
            }
             
        }else{
            throw new RetailError.ClientSideException('Invalid Location Id. No store available for location id');
        }
        return response;
    }

    
     /* 
    *This method is to process incoming Json payload on the DCI Reschedule web service.
    */
    public static RetailDTO.DCIRescheduleResponseDTO processDCIRescheduleRequest(Map<String, Object> requestMap){
        RetailDTO.DCIRescheduleResponseDTO response; 
        List<RetailCheckinQueue__c> lstNewCheckins = new List<RetailCheckinQueue__c>();  
            Id checkinID = (Id) requestMap.get('id');
            String visitReason = (string) requestMap.get('reasonForLeaving__c');
            String otherVisitReason = (string) requestMap.get('dciOtherVisitReason__c');
            String othernotes = (string) requestMap.get('othernotes__c');
            String checkinDateTime = (string) requestMap.get('checkInTime__c');

            if(checkinID!=null){
                RetailCheckinQueue__c rescheduledCheckin = DCIUtil.getCheckinRecordByID(checkinID);
                if(rescheduledCheckin!=null){
                    RetailCheckinQueue__c localCopyCheckin = new RetailCheckinQueue__c();
                    localCopyCheckin.QueuePosition__c = rescheduledCheckin.QueuePosition__c;
                        Lead dciLead = new Lead();
                        dciLead.Id = rescheduledCheckin.lead__c;
                        if(String.isNotBlank(visitReason))
                            dciLead.reasonForLeaving__c = visitReason;
                        if(String.isNotBlank(otherVisitReason))
                            dciLead.dciOtherVisitReason__c = otherVisitReason;
                        if(String.isNotBlank(othernotes))
                            dciLead.othernotes__c = othernotes;
                        if(String.isNotBlank(checkinDateTime)){  
                            DateTime checkinTime = DCIUtil.getGMTDateTime(checkinDateTime);
                            if(checkinTime == null)
                                throw new RetailError.ClientSideException('Invalid format of checkInTime__c. Expected Format Eg: 2021-01-31T04:00:00Z');     
                            rescheduledCheckin.CheckinTime__c = checkinTime;    
                        }

                        try{
                            update dciLead;
                        }catch(Exception e){
                            throw new RetailError.ServerSideException('Error in updating DCI lead'+e.getMessage()); 
                        }  

                        try{
                            rescheduledCheckin.Status__c = 'Pending';
                            rescheduledCheckin.QueuePosition__c = null;  
                            update rescheduledCheckin;
                        }catch(Exception e){
                            throw new RetailError.ServerSideException('Error in updating Checkin Record '+e.getMessage()); 
                        }  

                        if(localCopyCheckin.QueuePosition__c!=null){
                            Integer quePos = localCopyCheckin.QueuePosition__c.intValue();  

                            // US 4145 Added TUF - EWT Calculation
                            if (DCIConstants.EWTCalculationMethod == DCIConstants.TUF)
                                DCIUtil.updateQueueBulkifyMinutesUntilFree(new set<Id>{rescheduledCheckin.Store__c}, quePos, true, true,'Reschedule');
                            else 
                            DCIUtil.updateQueue(rescheduledCheckin.Store__c, quePos, true, true, 'Reschedule');
                        } 
                        
                        response = new RetailDTO.DCIRescheduleResponseDTO();
                        response.statuscode = '0';
                        lstNewCheckins.add(rescheduledCheckin);
                        String eventType = DCIConstants.FUTURE;
                        DCILeadUtil.sendAutoResponseSMS(lstNewCheckins, eventType);
                }else{
                    throw new RetailError.ClientSideException('Invalid Checkin Record'); 
                }
            }else{
                throw new RetailError.ClientSideException('Invalid Checkin Record Id');  
            }
        return response;
    }

     /**
     * This method validates the data coming to the DCI web service 
     * @Parameters - String requestString 
     *               String webServiceName
     * @Return Map<String, Object>
     */
    public static Map<String, Object> validateDCILeadRequest(String requestString, String webServiceName){
        Map<String, Object> requestMap = parseDCIJsontoMap(requestString);
        List<RetailWebService__mdt> webServiceDetailsList = new List<RetailWebService__mdt>();
        webServiceDetailsList = [Select FieldName__c, ParentName__c, Required__c, WebServiceName__c from RetailWebService__mdt where webservicename__c =:webServiceName WITH SECURITY_ENFORCED];
        Map<String, Object> leadRecordMap = (Map<String, Object>) requestMap.get('leadrecord');
        for(RetailWebService__mdt obj:webServiceDetailsList){
            if(requestMap.containsKey(obj.ParentName__c) && obj.Required__c){
                Map<String, Object> fieldMap = (Map<String, Object>) requestMap.get(obj.ParentName__c);
                if(!fieldMap.containsKey(obj.FieldName__c)) {
                    //Ignore missing required field when record coming from OPUS
                    if (obj.FieldName__c == 'mobilephone' && leadRecordMap.get('leadSource') != null && (String)leadRecordMap.get('leadSource') == 'OPUS') {
                        //ignore
                    } else {
                        throw new RetailError.ClientSideException(obj.FieldName__c+' is missing in Json');
                    }
                }
                
                if(fieldMap.containsKey(obj.FieldName__c)){
                    String fieldValue = (string) fieldMap.get(obj.FieldName__c);
                    if(String.isBlank(fieldValue)) {
                        //Ignore missing required field when record coming from OPUS
                        if (obj.FieldName__c == 'mobilephone' && leadRecordMap.get('leadSource') != null && (String)leadRecordMap.get('leadSource') == 'OPUS') {
                            //ignore
                        } else {
                            throw new RetailError.ClientSideException(obj.FieldName__c+' is a required field in Json');
                        }
                    }
                }
            }
        }
        return requestMap;
    }

     /**
     * This method validates the data coming to the DCI Reschedule web service 
     * @Parameters - String requestString 
     *               String webServiceName
     * @Return Map<String, Object>
     */
    public static Map<String, Object> validateDCIRescheduleRequest(String requestString, String webServiceName){
        Map<String, Object> requestMap = parseDCIRescheduleJsontoMap(requestString);
        List<RetailWebService__mdt> webServiceDetailsList = new List<RetailWebService__mdt>();
        webServiceDetailsList = [Select FieldName__c, ParentName__c, Required__c, WebServiceName__c from RetailWebService__mdt where webservicename__c =:webServiceName WITH SECURITY_ENFORCED];
        for(RetailWebService__mdt obj:webServiceDetailsList){  
            if(obj.Required__c){
                if(requestMap.containsKey(obj.FieldName__c)){
                    String fieldValue = (string) requestMap.get(obj.FieldName__c);
                    if(String.isBlank(fieldValue))
                        throw new RetailError.ClientSideException(obj.FieldName__c+' is a required field in Json');
                }

                if(!requestMap.containsKey(obj.FieldName__c)){
                    throw new RetailError.ClientSideException(obj.FieldName__c+' is missing in Json');
                }
            }
        }
        return requestMap;
    }


    /**
     * This method parses the Json Request recieved from the DCI web service to Objects 
     * @Parameters - String requestString 
     * @Return Map<String, Object>
     */
    public static Map<String, Object> parseDCIJsontoMap(String requestString){
        Map<String, Object> requestMap = new  Map<String, Object>();
        try{
            requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestString); 
            Map<String, Object> leadrecord = (Map<String, Object>) requestMap.get('leadrecord');
            requestMap.put('leadrecord',leadrecord);
            Map<String, Object> checkinrecord = (Map<String, Object>) requestMap.get('checkinrecord');
            requestMap.put('checkinrecord',checkinrecord);
        }catch(Exception e){
            throw new RetailError.ClientSideException('Incorrect Json Parsing Error');
        }
        return requestMap;
    }

     /**
     * This method parses the Json Request recieved from the DCI Reschedule web service to Objects 
     * @Parameters - String requestString 
     * @Return Map<String, Object>
     */
    public static Map<String, Object> parseDCIRescheduleJsontoMap(String requestString){
        Map<String, Object> requestMap = new  Map<String, Object>();
        try{
            requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestString); 
        }catch(Exception e){
            throw new RetailError.ClientSideException('Incorrect Json Parsing Error');
        }
        return requestMap;
    }

    //krishna
    /**
     * This method callouts to get Store pick up Status
     * @Parameters - 
     * @Return String
     */
    public static Map<String,String> BopisOrderCallouttoExternal(string BOPISOrder, string OrderPhNumber){
        
        Retail_Integration__mdt callDetail = [Select Client_Id__c,Client_Secret__c,Cert_Name__c,Endpoint__c from Retail_Integration__mdt where DeveloperName='BopisOrder' limit 1];
        string responseCode='';
        string responseBody='';
        Map<String,String> calloutstatusMap = new Map<String,String>();
        string Endpoint='';
        if(BOPISOrder!=null && BOPISOrder.length()>0){
            BOPISOrder  = BOPISOrder.replaceAll('\\s+','');
            }   
        system.debug('**Order BOPISOrder**'+BOPISOrder);
        system.debug('**Order OrderPhNumber**'+OrderPhNumber);
        
        String strStoreId = StoreController.getStoreFromCache();
            List<EmployeeStoreRetail__c> empStoreList ;
            if(String.isBlank(strStoreId)){
                Store__c repsStore = LeadForm.getHomeStore('true');
                if(repsStore!=null){
                    strStoreId = repsStore.Id;
                }
            }
            system.debug('******'+strStoreId);
            Store__c repsStore1  = DCIUtil.fetchStore(strStoreId);
            system.debug('******'+repsStore1);
            
        
        
       //List<Store__c> locationList = [elect id,LocationId__c from Store__c where id=];//.HomeStoreLocation__r.LocationId__c;
        //BOPISOrder = '23-262204616714318'; // for testing
        //string locationId='94890'; // for testing
        //system.debug('**loc id**'+repsStore1.LocationId__c);
        if(repsStore1 != null && repsStore1.LocationId__c != null && repsStore1.LocationId__c!=''){ //tapaswini
            string locationId  = repsStore1.LocationId__c;
            
            if(BOPISOrder!=null && BOPISOrder.length()>0){
               Endpoint = callDetail.Endpoint__c+'orderId?locationId='+locationId+'&orderId='+BOPISOrder;
            }else{
               Endpoint = callDetail.Endpoint__c+'mobile?locationId='+locationId+'&mobile='+OrderPhNumber;
            }     
            system.debug('**Endpoint**'+Endpoint);
            HttpRequest req = new HttpRequest();
            req.setEndpoint(Endpoint);
            req.setTimeout(120000);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('client_id',callDetail.Client_Id__c);
            req.setHeader('Client_secret',callDetail.Client_Secret__c);
            req.setClientCertificateName(callDetail.Cert_Name__c);
           Http http = new Http();
           HTTPResponse res = http.send(req);  
           system.debug('**res.getStatusCode()**'+res.getStatusCode());
           system.debug('**res.getStatus()**'+res.getStatus());
           responseCode=string.valueOf(res.getStatusCode());
           responseBody = string.valueOf(res.getBody());
            if(responseCode=='200' || responseCode=='404' || responseCode=='400' ){
                calloutstatusMap.put(responseCode,responseBody);
            }else{
                calloutstatusMap.put('250','Callout Failed, plese checkback later');
            }
            
        }else{
            calloutstatusMap.put('250','Callout Failed, Employee location is not available');
        }     
        return calloutstatusMap;
    }

    public static boolean checkIsAttNumber(String mobilePhone){
        if(String.isNotEmpty(mobilePhone)){
            List<Retail_Integration__mdt> callDetail = [Select Client_Id__c,Client_Secret__c,Cert_Name__c,Endpoint__c from Retail_Integration__mdt where DeveloperName='ATTPhoneNumberCheck' limit 1]; 
            HttpRequest req = new HttpRequest();
            if(!callDetail.isEmpty()){
                String EndPoint = callDetail[0].Endpoint__c+mobilePhone;
                req.setEndpoint(Endpoint);
                req.setTimeout(120000);
                req.setMethod('GET');
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('client_id',callDetail[0].Client_Id__c);
                req.setHeader('Client_secret',callDetail[0].Client_Secret__c);
                req.setClientCertificateName(callDetail[0].Cert_Name__c);
                Http http = new Http();
                HTTPResponse res = http.send(req);
                if(res.getStatusCode() == 200){
                    DCIService.ResIsATTNumber response = (DCIService.ResIsATTNumber)JSON.deserialize(res.getBody(), DCIService.ResIsATTNumber.class);
                    return response.isATTCTN;
                }   
            }
        }
        return false;
    }

    public class ResIsATTNumber{
        public boolean isATTCTN{get;set;}
    }
}
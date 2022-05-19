public without sharing class DCIRetailFutureAlertBatch implements Database.Batchable<sObject>, Database.Stateful {
    public Datetime currentTime;
    public map<String,map<String, String>> shortCodeResponseMap;
    public Set<String> dciRecordIds;
    
    public DCIRetailFutureAlertBatch(Datetime runTime, Set<String> recordIds) {
        currentTime = runTime;
        dciRecordIds = recordIds;
    }
    
	public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Lead__c,Lead__r.MobilePhone, Lead__r.IsAttCtn__c, Lead__r.DCIOtherVisitReason__c,Lead__r.PreferedLanguage__c, Store__c, Store__r.LocationId__c, Store__r.TimeZone__c,Store__r.Name,Store__r.Address1__c, Store__r.Address2__c, Status__c, CheckInTime__c, Store__r.City__c, ';
        query += ' DCICheckinType__c, Store__r.State__c, Store__r.Zip__c, Batch_SMS_Status__c, EstimatedWaitTime__c, QueuePosition__c FROM RetailCheckinQueue__c';
        query += ' WHERE Id IN :dciRecordIds';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<RetailCheckinQueue__c> scope){
        //List of Messages to be sent
        List<MessagingRequest> lstMessagingInputs = new List<MessagingRequest>();
        
        //Get list of shortcodes to their respective sms messages
        if (shortCodeResponseMap == null) {
            shortCodeResponseMap = ProcessMessagingSessionHelper.getDCIAutoResponses();
        }
        
        List<RetailCheckinQueue__c> dciUpdateList = new List<RetailCheckinQueue__c>();
     
        for (RetailCheckinQueue__c dciRecord : scope) {
            // checking other filters
            if (dciRecord.Store__c != NULL && dciRecord.Lead__c != null && dciRecord.Lead__r.MobilePhone != null) {
                String address;
                String autoResponse;
                List<String> dynamicValues;
                String tzId = DCIUtil.getRetailCustomSettings(dciRecord.Store__r.TimeZone__c);
                                        
                if (dciRecord.Store__r.Address2__c != null) {
                    address=dciRecord.Store__r.Name+', '+dciRecord.Store__r.Address1__c+', '+dciRecord.Store__r.Address2__c+ ', '+dciRecord.Store__r.City__c+', '+dciRecord.Store__r.State__c+', '+dciRecord.Store__r.Zip__c;
                } else {
                    address=dciRecord.Store__r.Name+', '+dciRecord.Store__r.Address1__c+', '+dciRecord.Store__r.City__c+', '+dciRecord.Store__r.State__c+', '+dciRecord.Store__r.Zip__c;
                }
                
                //Hour away record
                try {
                    if (dciRecord.CheckInTime__c > currentTime.addMinutes(30)) {
                        if (dciRecord.Batch_SMS_Status__c != '1HR' && dciRecord.Batch_SMS_Status__c != '15MIN') {
                            dciRecord.Batch_SMS_Status__c='1HR'; 
                            dciUpdateList.add(dciRecord);
                            //Autoresponse 2 was being sent before autoresponse 1, despite order of list being sent to Flow. Moving here 'Fixes' it, but order still not guaranteed.
                            String autoresponseTwo = ProcessMessagingSessionHelper.getResponseFormat('STOPINFO', dciRecord, shortCodeResponseMap);
                            lstMessagingInputs = MessagingRequestHandler.processOutboundMessaging(autoresponseTwo, dciRecord.Lead__c, dciRecord.Lead__r.MobilePhone, lstMessagingInputs, false, dciRecord.Lead__r.IsAttCtn__c);
                            autoResponse = ProcessMessagingSessionHelper.getResponseFormat('1HR', dciRecord, shortCodeResponseMap);
                            if (dciRecord.Store__r.TimeZone__c != null) {
                                dynamicValues = new List<String>{String.valueof(dciRecord.CheckInTime__c.format('hh:mm a', tzId))+' '+dciRecord.Store__r.TimeZone__c,address};
                            } else {
                                dynamicValues = new List<String>{String.valueof(dciRecord.CheckInTime__c.format('hh:mm a', 'GMT'))+' GMT',address};    
                            }
                            autoResponse = String.format(autoResponse, dynamicValues);
                            lstMessagingInputs = MessagingRequestHandler.processOutboundMessaging(autoResponse, dciRecord.Lead__c, dciRecord.Lead__r.MobilePhone, lstMessagingInputs, false, dciRecord.Lead__r.IsAttCtn__c);
                        }
                    } else {
                        if (dciRecord.Batch_SMS_Status__c != '15MIN') {
                            dciRecord.Batch_SMS_Status__c='15MIN'; 
                            //dciUpdateList.add(dciRecord);
                            
                            if (dciRecord.QueuePosition__c != 1) {
                                autoResponse = ProcessMessagingSessionHelper.getResponseFormat('15MINQNE', dciRecord, shortCodeResponseMap);
                                Integer displayNumber;
                                Integer displayNumber2;
                                if (dciRecord.EstimatedWaitTime__c != null) {
                                    displayNumber = dciRecord.EstimatedWaitTime__c.intValue();
                                    displayNumber2 = displayNumber+5;
                                    
                            }
                                
                                if (dciRecord.Store__r.TimeZone__c != null) {
                                    dynamicValues = new List<String>{String.valueOf(displayNumber), String.valueof(dciRecord.CheckInTime__c.format('hh:mm a', tzId))+' '+dciRecord.Store__r.TimeZone__c,String.valueOf(displayNumber2)};
                                } else {
                                    dynamicValues = new List<String>{String.valueOf(displayNumber), String.valueof(dciRecord.CheckInTime__c.format('hh:mm a', 'GMT'))+' GMT',String.valueOf(displayNumber2)};    
                                }
                                autoResponse = String.format(autoResponse, dynamicValues);
                                lstMessagingInputs =  MessagingRequestHandler.processOutboundMessaging(autoResponse, dciRecord.Lead__c, dciRecord.Lead__r.MobilePhone, lstMessagingInputs, false,dciRecord.Lead__r.IsAttCtn__c);
                            } else {
                                autoResponse = ProcessMessagingSessionHelper.getResponseFormat('15MINQE', dciRecord, shortCodeResponseMap);
                                if (dciRecord.Store__r.TimeZone__c != null) {
                                    dynamicValues = new List<String>{String.valueof(dciRecord.CheckInTime__c.format('hh:mm a', tzId))+' '+dciRecord.Store__r.TimeZone__c};
                                } else {
                                    dynamicValues = new List<String>{String.valueof(dciRecord.CheckInTime__c.format('hh:mm a', 'GMT'))+' GMT'};    
                                }
                                autoResponse = String.format(autoResponse, dynamicValues);
                                lstMessagingInputs =  MessagingRequestHandler.processOutboundMessaging(autoResponse, dciRecord.Lead__c, dciRecord.Lead__r.MobilePhone, lstMessagingInputs, false,dciRecord.Lead__r.IsAttCtn__c);                                
                            }
                            dciUpdateList.add(dciRecord);
                        }
                    }
                } catch (Exception e) {
                   // BWC_ExceptionUtils.handleException(e, true);
                }           
            }                      
        }
              
        //Send Auto-generated Outbound SMS reply to DCI Leads
        if(lstMessagingInputs != null && lstMessagingInputs.size() > 0){
            try {
                MessagingRequestHandler.sendOutboundSMS(lstMessagingInputs, 'MessageInput', DCIConstants.DCI_OUTBOUNDTEXT_FLOW);              
                update dciUpdateList;
            } catch (Exception e) {
                //BWC_ExceptionUtils.handleException(e, true);
            }
        }
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
}
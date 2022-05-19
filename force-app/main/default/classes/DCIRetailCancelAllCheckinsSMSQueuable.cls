public with sharing class DCIRetailCancelAllCheckinsSMSQueuable implements Queueable{
	/*
	* This  Class will be utilized for the following business scenario:
	* 		When Store Manager Cancels all checkins ,SMS will be notified to all cancelled records. 
	*/
		public Set<Id> checkinRecordId = new Set<Id>();
		
		public DCIRetailCancelAllCheckinsSMSQueuable(Set<Id> checkinRecords){
			checkinRecordId = checkinRecords;
		}
		public void execute(QueueableContext context){
			
			List<RetailCheckinQueue__c> scope = new List<RetailCheckinQueue__c>([SELECT id, Status__c,Store__c, ArrivingTime__c, Lead__c, Lead__r.IsAttCtn__c, Lead__r.MobilePhone, Lead__r.DCIReasonForCancellation__c, Lead__r.PreferedLanguage__c, Lead__r.Store__r.LocationId__c, Store__r.TimeZone__c, LastMessageReceived__c, QueuePosition__c, Store__r.LocationId__c, EstimatedWaitTime__c, LastEWTUpdated__c, CheckInTime__c, Lead__r.ReasonForLeaving__c, Lead__r.DCICheckinType__c, NoShowCount__c, DCIAssignedRSC__c, DCIMaximum_EWT__c,DCIMinimum_EWT__c FROM RetailCheckinQueue__c WHERE Id IN:checkinRecordId]);
		
		List<MessagingRequest> lstMessagingInputs = new List<MessagingRequest>();
		Map<String, Map<String,String>> shortCodeResponseMap = ProcessMessagingSessionHelper.getDCIAutoResponses();
		
		for(RetailCheckinQueue__c dciRecord : scope){
			String autoResponse = ProcessMessagingSessionHelper.getResponseFormat('CR', dciRecord, shortCodeResponseMap);  
			lstMessagingInputs =  MessagingRequestHandler.processOutboundMessaging(autoResponse, dciRecord.Lead__c, dciRecord.Lead__r.MobilePhone, lstMessagingInputs, false, dciRecord.Lead__r.IsAttCtn__c);
		}
			if(lstMessagingInputs != null && lstMessagingInputs.size() > 0)
				MessagingRequestHandler.sendOutboundSMS(lstMessagingInputs, 'MessageInput', DCIConstants.DCI_OUTBOUNDTEXT_FLOW);
		}
	}
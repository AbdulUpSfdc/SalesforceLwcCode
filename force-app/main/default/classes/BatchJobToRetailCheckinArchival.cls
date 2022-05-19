/**
 * @Author: Deepak Regatte
 * @Name: BatchJobToRetailCheckinArchival
 * @CreatedDate: 08/19/2021
 * @Description: This class is used to copy RetailCheckingQueue and History Records to RetailCheckingQueue and History Archival Objects.
 */

public class BatchJobToRetailCheckinArchival implements Database.Batchable<sObject>, Schedulable{

    public Database.QueryLocator start(Database.BatchableContext BC) {
        //Date todayDate = system.Today();
        Set<string> statusStringSet = new Set<string>{DCIConstants.COMPLETED,DCIConstants.CANCELLED};
        String query = 'SELECT Id, ArrivingTime__c,WaitTimeStatus__c, DCIVisitReason__c, DCITransactionTime__c, DCITimeWaiting__c,IsCurSessionStore__c, CustomerRequestedRep__c,DCICheckinType__c, DCICheckInStatus__c, DciApptSchedTime__c, DCIBOPISOrder__c, DCIOtherVisitReason__c,DCIAssignedRSC__c, AccrualEstimatedWaitTime__c, DCIAvailableRepCount__c, Batch_SMS_Status__c,CheckInTime__c,ElapsedWaitTime__c,EstimatedWaitTime__c,DCIChangeReason__c, DCIInitialEWT__c,LastEWTUpdated__c,LastMessageReceived__c, Lead__c, DCIMaximum_EWT__c, DCIMinimum_EWT__c, NoShowCount__c, Notification_1_sent__c, Notification_2_sent__c, QueuePosition__c, Name,Status__c, DCITotalRepCount__c, (SELECT Id, IsDeleted, ParentId, CreatedById, CreatedDate, Field, DataType, OldValue, NewValue FROM Histories) FROM RetailCheckinQueue__c where  Status__c=:statusStringSet';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<RetailCheckinQueue__c> scope) {
        List<RetailCheckinQueueArchival__c> listRetailCheckinQueueArchival = new List<RetailCheckinQueueArchival__c>();
        List<RetailCheckinQueueHistoryArchival__c> listRetailCheckinQueueHistoryArchival;

        Map<ID, List<RetailCheckinQueue__History>> mapRetailCheckiAndHistory = new Map<ID, List<RetailCheckinQueue__History>>();
        List<RetailCheckinQueue__History> listRetailCheckinQueueHistory = new List<RetailCheckinQueue__History>();
        Map<Id, RetailCheckinQueueArchival__c> mapRetailCheckinQueueandArchival = new Map<ID, RetailCheckinQueueArchival__c>();
        for(RetailCheckinQueue__c retailCheckinRecord: scope){

            mapRetailCheckiAndHistory.put(retailCheckinRecord.Id, retailCheckinRecord.Histories);
            RetailCheckinQueueArchival__c objRetailCheckinQueueArchival = new RetailCheckinQueueArchival__c();
            objRetailCheckinQueueArchival.DCIIDOriginal__c = retailCheckinRecord.Id;
            objRetailCheckinQueueArchival.ArrivingTime__c = retailCheckinRecord.ArrivingTime__c;
            objRetailCheckinQueueArchival.DCIAvailableRepCount__c = retailCheckinRecord.DCIAvailableRepCount__c ;
            objRetailCheckinQueueArchival.Batch_SMS_Status__c = retailCheckinRecord.Batch_SMS_Status__c;
            objRetailCheckinQueueArchival.CheckInTime__c = retailCheckinRecord.CheckInTime__c;
            objRetailCheckinQueueArchival.ElapsedWaitTime__c = retailCheckinRecord.ElapsedWaitTime__c;
            objRetailCheckinQueueArchival.EstimatedWaitTime__c = retailCheckinRecord.EstimatedWaitTime__c;
            objRetailCheckinQueueArchival.EventType__c = retailCheckinRecord.DCIChangeReason__c;
            objRetailCheckinQueueArchival.InitialEWT__C = retailCheckinRecord.DCIInitialEWT__c;
            objRetailCheckinQueueArchival.LastEWTUpdated__c = retailCheckinRecord.LastEWTUpdated__c;
            objRetailCheckinQueueArchival.LastMessageReceived__c = retailCheckinRecord.LastMessageReceived__c;
            objRetailCheckinQueueArchival.Lead__c = retailCheckinRecord.Lead__c;
            objRetailCheckinQueueArchival.DCIMaximum_EWT__c = retailCheckinRecord.DCIMaximum_EWT__c;
            objRetailCheckinQueueArchival.DCIMinimum_EWT__c = retailCheckinRecord.DCIMinimum_EWT__c;
            objRetailCheckinQueueArchival.NoShowCount__c = retailCheckinRecord.NoShowCount__c;
            objRetailCheckinQueueArchival.Notification_1_sent__c = retailCheckinRecord.Notification_1_sent__c;
            objRetailCheckinQueueArchival.Notification_2_sent__c = retailCheckinRecord.Notification_2_sent__c;
            objRetailCheckinQueueArchival.QueuePosition__c = retailCheckinRecord.QueuePosition__c;
            objRetailCheckinQueueArchival.Name = retailCheckinRecord.Name;
            objRetailCheckinQueueArchival.Status__c = retailCheckinRecord.Status__c;
            objRetailCheckinQueueArchival.DCITotalRepCount__c = retailCheckinRecord.DCITotalRepCount__c;
			objRetailCheckinQueueArchival.WaitTimeStatus__c = retailCheckinRecord.WaitTimeStatus__c;
            objRetailCheckinQueueArchival.DCIVisitReason__c = retailCheckinRecord.DCIVisitReason__c;
            objRetailCheckinQueueArchival.DCITransactionTime__c = retailCheckinRecord.DCITransactionTime__c;
            objRetailCheckinQueueArchival.DCITimeWaiting__c = retailCheckinRecord.DCITimeWaiting__c;
            objRetailCheckinQueueArchival.IsCurSessionStore__c = retailCheckinRecord.IsCurSessionStore__c;
            objRetailCheckinQueueArchival.CustomerRequestedRep__c = retailCheckinRecord.CustomerRequestedRep__c;
            objRetailCheckinQueueArchival.DCICheckinType__c = retailCheckinRecord.DCICheckinType__c;
            objRetailCheckinQueueArchival.DCICheckInStatus__c = retailCheckinRecord.DCICheckInStatus__c;
            objRetailCheckinQueueArchival.DciApptSchedTime__c = retailCheckinRecord.DciApptSchedTime__c;
            objRetailCheckinQueueArchival.DCIBOPISOrder__c = retailCheckinRecord.DCIBOPISOrder__c;
            objRetailCheckinQueueArchival.DCIOtherVisitReason__c = retailCheckinRecord.DCIOtherVisitReason__c;
            objRetailCheckinQueueArchival.DCIAssignedRSC__c = retailCheckinRecord.DCIAssignedRSC__c;
            objRetailCheckinQueueArchival.AccrualEstimatedWaitTime__c = retailCheckinRecord.AccrualEstimatedWaitTime__c;

            mapRetailCheckinQueueandArchival.put(retailCheckinRecord.Id, objRetailCheckinQueueArchival);

        }
        If(!mapRetailCheckinQueueandArchival.isEmpty()){
            
            system.debug('-----Before----'+mapRetailCheckinQueueandArchival.values());
            Database.SaveResult[] srList = Database.insert(mapRetailCheckinQueueandArchival.values(), false);
            system.debug('-----After----'+mapRetailCheckinQueueandArchival.values());
            listRetailCheckinQueueHistoryArchival = new List<RetailCheckinQueueHistoryArchival__c>();
            RetailCheckinQueueHistoryArchival__c objRetailCheckinQueueHistoryArchivalRecord;
                for(ID objRetailCheckinQueueArchivalRecord: mapRetailCheckinQueueandArchival.keySet()){
                    for(RetailCheckinQueue__History retailCheckinHistoryRecord: mapRetailCheckiAndHistory.get(objRetailCheckinQueueArchivalRecord))  {
                        objRetailCheckinQueueHistoryArchivalRecord = new   RetailCheckinQueueHistoryArchival__c();
                        objRetailCheckinQueueHistoryArchivalRecord.ParentId__c = mapRetailCheckinQueueandArchival.get(objRetailCheckinQueueArchivalRecord).Id; 
                        objRetailCheckinQueueHistoryArchivalRecord.CreatedByIdSource__c =  retailCheckinHistoryRecord.CreatedById;
                        objRetailCheckinQueueHistoryArchivalRecord.CreatedByDateSource__c = retailCheckinHistoryRecord.CreatedDate;
                        objRetailCheckinQueueHistoryArchivalRecord.DataType__c = retailCheckinHistoryRecord.DataType;
                        objRetailCheckinQueueHistoryArchivalRecord.Field__c = retailCheckinHistoryRecord.Field;
                        objRetailCheckinQueueHistoryArchivalRecord.IsDeleted__c = retailCheckinHistoryRecord.IsDeleted;
                        objRetailCheckinQueueHistoryArchivalRecord.NewValue__c = retailCheckinHistoryRecord.NewValue!=null?String.Valueof(retailCheckinHistoryRecord.NewValue):null;
                        objRetailCheckinQueueHistoryArchivalRecord.OldValue__c = retailCheckinHistoryRecord.OldValue!=null?String.valueof(retailCheckinHistoryRecord.OldValue):null;
                        listRetailCheckinQueueHistoryArchival.add(objRetailCheckinQueueHistoryArchivalRecord);
                    }
                    
                }
            If(listRetailCheckinQueueHistoryArchival.size()>0){
               Database.SaveResult[] srListHistory = Database.insert(listRetailCheckinQueueHistoryArchival, false);    
            }

        }
     }


   
    
    public void finish(Database.BatchableContext BC){
    
    
    }

    public void execute(SchedulableContext SC){

    }
}
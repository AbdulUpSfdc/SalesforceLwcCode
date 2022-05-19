public without sharing class RetailDTO {
  public RetailDTO() {

  }   
  
  public class LeadConsentDTO {
      @AuraEnabled
      public Boolean Accepted = false;
      @AuraEnabled
      public Boolean CustomerCanceled = false;
      @AuraEnabled
      public Boolean ConsentExpired = false;
    }
    public class LoggedInUserInfoDTO {
      @AuraEnabled
      public String profileName { get; set; }
      @AuraEnabled
      public String dueTodayListViewName { get; set; }
      @AuraEnabled
      public String channel{get;set;} //SPTSLSATT-1236
    }

    public class DCIRequestDTO {
      @AuraEnabled
      public DCILeadDTO leadrecord { get; set; }
      @AuraEnabled
      public DCICheckinDTO checkinrecord { get; set; }
    }

    public class DCILeadDTO {
      @AuraEnabled
      public String firstname { get; set; }
      @AuraEnabled
      public String lastname { get; set; }
      @AuraEnabled
      public String locationid { get; set; }
      @AuraEnabled
      public String mobilephone { get; set; }
      @AuraEnabled
      public String email { get; set; }
    }

    public class DCICheckinDTO {
      @AuraEnabled
      public String status { get; set; }
    }

    public class DCIResponseDTO {
      @AuraEnabled
      public String statuscode { get; set; }
      @AuraEnabled
      public String status { get; set; }
      @AuraEnabled
      public String queueposition { get; set; }
      @AuraEnabled
      public String leadwaittime { get; set; }
      @AuraEnabled
      public String leadid { get; set; }
      @AuraEnabled
      public String leadName { get; set; }
      @AuraEnabled
      public String checkinid { get; set; }
      @AuraEnabled
      public String assignedRSC { get; set; }
    }

    public class DCIFormLwcHandleSubmit{
      @AuraEnabled
      public DCIResponseDTO dciResponseDTO { get; set; } 
      @AuraEnabled
      public String custReqRepName { get; set; }  

    }

    public class DCIRescheduleReqDTO {
      @AuraEnabled
      public String id { get; set; }
      @AuraEnabled
      public String reasonForLeavin { get; set; }
      @AuraEnabled
      public String dciOtherVisitReason { get; set; }
      @AuraEnabled
      public String othernotes { get; set; }
      @AuraEnabled
      public String checkInTime { get; set; }
    }

    public class DCIRescheduleResponseDTO {
      @AuraEnabled
      public String statuscode { get; set; }
    }

    public class DCINextCustomerDTO {
      @AuraEnabled
      public String message { get; set; }
      @AuraEnabled
      public String checkinId { get; set; }
    }

    public class DCIHomePageDataDTO {
      @AuraEnabled
      public EmployeeStoreRetail__c employeeDetails { get; set; }
      @AuraEnabled
      public Store__c storeDetails { get; set; }
      @AuraEnabled
      public Boolean hasCustomersArrived { get; set; }
      @AuraEnabled	
      public integer customerArrivedCount{get;set;}
      @AuraEnabled 
      public Boolean hasCustomerEngaged{get;set;}
      @AuraEnabled	
      public List<Map<String,String>> massCancellationReason{get;set;}
      @AuraEnabled	
      public integer pendingRecordsCount{get;set;}
   }
    
    public class DCIUpdateRecordDTO {
      public List<RetailCheckinQueue__c> updateCheckinList { get; set; }
      public List<Store__c> updateStoreList { get; set; }

      public DCIUpdateRecordDTO() {
          updateCheckinList = new List<RetailCheckinQueue__c>();
          updateStoreList = new List<Store__c>();
      }
    }

    public class DCICheckinDataDTO {
      @AuraEnabled
      public RetailCheckinQueue__c checkinRecord { get; set; }
      @AuraEnabled
      public Lead leadRecord { get; set; }
    }

     public class DCIDataHelperDTO{
      public List<Store__c> updateStoreList { get; set; }
      public List<Lead> updateLeadList { get; set; }        
      public Set<Id> storeIdSet { get; set; }
      public Set<Id> storeIdSwapSet { get; set; }
      public Set<Id> storeIdNoShowSet { get; set; }
      public map<Id, RetailCheckinQueue__c> cancelledCheckinMap { get; set; }
      public map<Id, RetailCheckinQueue__c> noShowCheckinMap { get; set; }
      public map<Id, RetailCheckinQueue__c> swapCheckinMap { get; set; }
      public map<Id, RetailCheckinQueue__c> currentCheckinMap { get; set; }
      public map<Id, RetailCheckinQueue__c> swappedtoStoreMap { get; set; }   
      public map<Id, Decimal> lastEWTtoStoreMap { get; set; }
      public map<Id, Decimal> queuePostoStoreMap { get; set; }
      public map<Id, Boolean> cancelledtoStoreMap { get; set; }
      public map<Id, Boolean> noshowtoStoreMap { get; set; }
      public map<Id, Decimal> lastEWTtoStoreMapNS { get; set; }
      public map<Id, Decimal> queuePostoStoreMapNS { get; set; }
      public map<Id, Decimal> ewtDiffTrecords { get; set; } 

      public DCIDataHelperDTO(){
          updateStoreList = new List<Store__c>();
          updateLeadList = new List<Lead>();         
          storeIdSet = new Set<Id>();
          storeIdSwapSet = new Set<Id>();
          storeIdNoShowSet = new Set<Id>();
          noShowCheckinMap = new map<Id, RetailCheckinQueue__c>();
          cancelledCheckinMap = new map<Id, RetailCheckinQueue__c>();
          swapCheckinMap = new map<Id, RetailCheckinQueue__c>();
          currentCheckinMap = new map<Id, RetailCheckinQueue__c>();
          swappedtoStoreMap = new map<Id, RetailCheckinQueue__c>();   
          lastEWTtoStoreMap = new map<Id, Decimal>();
          queuePostoStoreMap = new map<Id, Decimal>();
          cancelledtoStoreMap = new map<Id, Boolean>();
          noshowtoStoreMap = new map<Id, Boolean>();
          lastEWTtoStoreMapNS = new map<Id, Decimal>();
          queuePostoStoreMapNS = new map<Id, Decimal>();
          ewtDiffTrecords = new map<Id, Decimal>();
      }
    }
    
    public class DCICustomerRequestedRep {
      @AuraEnabled
      public String employeName {get; set;}
      @AuraEnabled
      public String repNameuserId {get; set;}

    }

    public class OnLoadDCIDetails {
      @AuraEnabled  
      public List<DCICustomerRequestedRep> listDCICustomerRequestedRep{get; set;}
      @AuraEnabled
      public Store__c storeDetails { get; set; }
      @AuraEnabled
      public Boolean enableHelpNextButton { get; set; }
      
    }
}
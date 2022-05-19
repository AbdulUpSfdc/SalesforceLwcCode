@isTest
public class RetailDTOTest
{
    @istest
    public static void unitTest()
    {
        RetailDTO newRecord=new RetailDTO();
        RetailDTO.LeadConsentDTO objLeadConsentDTO =new RetailDTO.LeadConsentDTO();
        RetailDTO.LoggedInUserInfoDTO objLoggedInUserInfoDTO=new RetailDTO.LoggedInUserInfoDTO();
        RetailDTO.DCIRequestDTO objDCIRequestDTO=new RetailDTO.DCIRequestDTO();
        objDCIRequestDTO.leadrecord=new RetailDTO.DCILeadDTO();    
        objDCIRequestDTO.checkinrecord =new RetailDTO.DCICheckinDTO();
        
        RetailDTO.DCILeadDTO objDCILeadDTO=new RetailDTO.DCILeadDTO();
        objDCILeadDTO.firstname='';
        objDCILeadDTO.lastname='';
        objDCILeadDTO.locationid='';
        objDCILeadDTO.mobilephone='';
        objDCILeadDTO.email='';
        
        RetailDTO.DCICheckinDTO objDCICheckinDTO=new RetailDTO.DCICheckinDTO();
        objDCICheckinDTO.status='';
        
        RetailDTO.DCIResponseDTO objDCIResponseDTO=new RetailDTO.DCIResponseDTO();
        objDCIResponseDTO.statuscode='';
        objDCIResponseDTO.status='';
        objDCIResponseDTO.queueposition='';
        objDCIResponseDTO.leadwaittime='';
        objDCIResponseDTO.leadid='';
        objDCIResponseDTO.checkinid='';
        
        RetailDTO.DCINextCustomerDTO objDCINextCustomerDTO=new RetailDTO.DCINextCustomerDTO();
        objDCINextCustomerDTO.message='';
        objDCINextCustomerDTO.checkinId='';
        
        RetailDTO.DCIHomePageDataDTO objDCIHomePageDataDTO=new RetailDTO.DCIHomePageDataDTO();
        objDCIHomePageDataDTO.employeeDetails=new EmployeeStoreRetail__c();
        objDCIHomePageDataDTO.storeDetails=new Store__c();
        objDCIHomePageDataDTO.hasCustomersArrived=false;
        
        RetailDTO.DCIUpdateRecordDTO objDCIUpdateRecordDTO=new RetailDTO.DCIUpdateRecordDTO();
        RetailDTO.DCICheckinDataDTO objDCICheckinDataDTO=new RetailDTO.DCICheckinDataDTO();
        objDCICheckinDataDTO.checkinRecord=new RetailCheckinQueue__c();
        objDCICheckinDataDTO.leadRecord=new Lead();
        
        RetailDTO.DCIDataHelperDTO objDCIDataHelperDTO=new RetailDTO.DCIDataHelperDTO();
                
        
    }
}
public inherited sharing class BWC_LIC_WFE {
	public static final String LIC_WFE_MDT = 'WFE_ISSAC_Config';
    public static final String CALLING_APPLICATION_ID = 'SALESFORCE';
    public static final String PROJECT_ID = 'SFLICWFE';
    public static final String AUTH_LEVEL_L1 = 'L1';
    public static final String AUTH_LEVEL_BYPASS = 'BYPASS';
    public static final String CUST_AUTH_YES = 'yes';
    public static final String CUST_AUTH_NO = 'no';
    
    public BWC_LIC_WFE(){}
    
    public class LIC_WFEClientRequest{
        @AuraEnabled public LIC_WFERequest clientRequest;
    }
    public class LIC_WFERequest{
        @AuraEnabled public String CallingApplicationID; //SALESFORCE
        @AuraEnabled public String projectId; //SFLICWFE
        @AuraEnabled public List<CustomerInfo> sfCustomerInfo;
        @AuraEnabled public String repDetails;
    }
    public class CustomerInfo{
        @AuraEnabled public String subscriberId; 
        @AuraEnabled public String custAuth; //yes or no
    }
    public class LIC_WFEDataWrapper{
        @AuraEnabled public LIC_WFEClientRequest requestBody;
        @AuraEnabled public String endPoint;
    }
}
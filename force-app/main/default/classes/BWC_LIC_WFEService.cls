public inherited sharing class BWC_LIC_WFEService {
    
    public static BWC_LIC_WFE.LIC_WFEClientRequest getLICWFERequest(Boolean isAuthorized,String ban){
        
        BWC_LIC_WFE.LIC_WFEClientRequest requestData = new BWC_LIC_WFE.LIC_WFEClientRequest(); 
        requestData.clientRequest = new BWC_LIC_WFE.LIC_WFERequest();
        
        requestData.clientRequest.CallingApplicationID = BWC_LIC_WFE.CALLING_APPLICATION_ID;
        requestData.clientRequest.projectId = BWC_LIC_WFE.PROJECT_ID;
        requestData.clientRequest.repDetails = BWC_Utils.getCurrentUserAttId() + ' | '+String.valueOf(DateTime.now());
        
        requestData.clientRequest.sfCustomerInfo = new List<BWC_LIC_WFE.CustomerInfo>();
        
        BWC_LIC_WFE.CustomerInfo customerInfo = new BWC_LIC_WFE.CustomerInfo();
        customerInfo.subscriberId = ban;
        customerInfo.custAuth = isAuthorized ==true ? BWC_LIC_WFE.CUST_AUTH_YES : BWC_LIC_WFE.CUST_AUTH_NO;
        
        requestData.clientRequest.sfCustomerInfo.add(customerInfo);
        
        return requestData;
    }
}
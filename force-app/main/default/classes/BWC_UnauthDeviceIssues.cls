/* ================================================
* @class name: BWC_UnauthDeviceIssues
* @author: Salesforce Inc.
* @purpose: Aura TSRM solution
* @created date (mm/dd/yyyy) :  03/30/2021
================================================*/ 
public with sharing class BWC_UnauthDeviceIssues {
    /*returns the TSRM system endpoints and redirect url to client */
    @AuraEnabled
    public static string getTSRMMetaData(){
        return BWC_LIC_TSRMController.getTSRMMetaData();
    }
    /*returns tsrm request for the body of client side post call */    
    @AuraEnabled
    public static string getTSRMRequest(string ctn,string interactionId,string ban){
        
        return BWC_LIC_TSRMController.getTSRMRequest(ctn, interactionId, ban);
    }
    @AuraEnabled
    public static void createInteractionActivity(Id interactionId, String actionName, String detailRecord) {
        BWC_InteractionActivity.createInteractionActivity(interactionId, actionName, detailRecord);
    }
    //api logging solution
    @AuraEnabled
    public static string logAPICall(string request, string response, string recordId){
        return BWC_LIC_TSRMController.logAPICall(request, response, recordId);
    }


}
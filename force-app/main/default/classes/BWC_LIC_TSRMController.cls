/* ================================================
* @class name: BWC_LIC_TSRMController
* @author: Salesforce Inc.
* @purpose: Class supports TSRM client system integration
* @created date (mm/dd/yyyy) :  03/19/2021
================================================*/ 
public with sharing class BWC_LIC_TSRMController {
    //Name of the metadata record for TSRM
    private static final String META_DEV_NAME = 'TSRM_Configs';
    /*returns the TSRM system endpoints and redirect url to client */
    @AuraEnabled(cacheable=true)
    public static string getTSRMMetaData(){
        BWC_LIC_TSRM_Configurations__mdt metaRecord = BWC_LIC_TSRMController.getTSRMConfigs();
        BWC_LIC_TSRMController.TSRM_Configs returnValue = new BWC_LIC_TSRMController.TSRM_Configs();
        
        returnValue.endpoint = metaRecord?.TSRM_endpoint__c;
        returnValue.redirectUrl = metaRecord?.TSRM_URL__c;

        return JSON.serialize(returnValue);
    }
    public class TSRM_Configs{
        string endpoint;
        string redirectUrl;

    }
    /*returns tsrm request for the body of client side post call */    
    @AuraEnabled
    public static string getTSRMRequest(string ctn,string interactionId,string ban){
        
        BWC_LIC_TSRM_Request.TSRM_Request tsrmRequest = (ctn != 'Unauth')?new BWC_LIC_TSRM_Request.TSRM_Request(ctn,interactionId,ban,BWC_LIC_TSRMController.getATTUID()):new BWC_LIC_TSRM_Request.TSRM_Request(interactionId,BWC_LIC_TSRMController.getATTUID());

        return JSON.serialize(tsrmRequest);
    }
    /*returns user's att user id  ATTUID */
    public static string getATTUID(){
        string returnValue;
        string userid = UserInfo.getUserId();
        User user = [SELECT attuid__c 
                      FROM User
                      WHERE id =: userId ];
        returnValue = user?.attuid__c;
        return returnValue;
    }
    /*returns the TSRM system endpoints and redirect url */
    public static BWC_LIC_TSRM_Configurations__mdt getTSRMConfigs(){
        
        list<BWC_LIC_TSRM_Configurations__mdt> meta = [
                      SELECT TSRM_endpoint__c, TSRM_URL__c
                      FROM BWC_LIC_TSRM_Configurations__mdt
                      WHERE DeveloperName =: META_DEV_NAME
                      LIMIT 1 ];

       
        return (meta.IsEmpty())?null:meta[0];
    }
    @AuraEnabled
    public static string logAPICall(string request, string response, string recordId){
        
        String req = 'request=' + request;
        String resp = 'response=' + response;
        String delimiter = '|';
        
        String detail = req+delimiter+resp;

        try {
            List<Object> params = new List<Object>{'TSRM',  detail, null};
            LogMessage logMessage = new LogMessage(BWC_Constants.TSRM_NEBULA_MESSAGE_TEMPLATE, params);
            Logger.info(logMessage).setRecordId(recordId);
            Logger.saveLog();

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return 'true';
    }
      //not used but leaving for ref was fallback solution
  /* private static final String CLIENT_REQUEST = 'clientRequest';
    //visualForce Action to post data as url param
    public Pagereference initalizePostForRedirect(){
        String ctn = ApexPages.currentPage().getParameters().get('ctn');
        String intid = ApexPages.currentPage().getParameters().get('interactionId');
        String ban = ApexPages.currentPage().getParameters().get('ban');

        BWC_LIC_TSRM_Configurations__mdt metaRecord = BWC_LIC_TSRMController.getTSRMConfigs();
        BWC_LIC_TSRM_Request.TSRM_Request tsrmRequest = BWC_LIC_TSRMController.generateRequestObject(ctn,intid,ban);

        Pagereference pageRef = BWC_LIC_TSRMController.setUpPageRef(tsrmRequest,metaRecord);


        return pageRef;
    }
    public static BWC_LIC_TSRM_Request.TSRM_Request generateRequestObject(string ctn,string intid, string ban){
      
        BWC_LIC_TSRM_Request.TSRM_Request tsrmRequest = new BWC_LIC_TSRM_Request.TSRM_Request(ctn,intid,ban,BWC_LIC_TSRMController.getATTUID());
        return tsrmRequest;
        //return JSON.serialize(tsrmRequest);
    }
    public static Pagereference setUpPageRef(BWC_LIC_TSRM_Request.TSRM_Request tsrmRequest , BWC_LIC_TSRM_Configurations__mdt metaRecord){
        Pagereference pageRef = new Pagereference(metaRecord?.TSRM_endpoint__c);
        pageRef.getParameters().put(CLIENT_REQUEST, JSON.serialize(tsrmRequest)); // add the JSON to the POST data


        return pageRef;
    }  
    @AuraEnabled(cacheable=true)
    public static string getTSRMURL(){
        string returnValue;
        returnValue = URL.getSalesforceBaseUrl().toExternalForm() + Page.BWC_LIC_TSRM.getURL();
        return returnValue;
    }*/
}
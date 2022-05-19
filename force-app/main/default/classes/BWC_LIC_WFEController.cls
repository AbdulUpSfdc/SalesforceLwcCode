public with sharing class BWC_LIC_WFEController {
    
    @AuraEnabled
    public static BWC_LIC_WFE.LIC_WFEDataWrapper getLICWFERequestData(Boolean isAuthorized,String ban) {
        try{
            BWC_LIC_WFE_Configuration__mdt metaRecord = BWC_LIC_WFEController.getLICWFEConfig();
            
            BWC_LIC_WFE.LIC_WFEDataWrapper dataWrapper = new BWC_LIC_WFE.LIC_WFEDataWrapper();
            BWC_LIC_WFE.LIC_WFEClientRequest reqBody = BWC_LIC_WFEService.getLICWFERequest(isAuthorized,ban);
            
            dataWrapper.requestBody = reqBody;
            dataWrapper.endPoint = metaRecord.ISSAC_URL__c;
            return dataWrapper;
        }catch(Exception e){
            return null;
        }
    }
    
    public static BWC_LIC_WFE_Configuration__mdt getLICWFEConfig(){
        
        list<BWC_LIC_WFE_Configuration__mdt> meta = [
            SELECT ISSAC_URL__c
            FROM BWC_LIC_WFE_Configuration__mdt
            WHERE DeveloperName =: BWC_LIC_WFE.LIC_WFE_MDT
            LIMIT 1 ];
        
        
        return (meta.IsEmpty())?null:meta[0];
    }

    @AuraEnabled
    public static void logWFEResponse(String detail, String recordId, boolean isError){

        try {
            List<Object> params = new List<Object>{'WFE',  detail};
            LogMessage logMessage = new LogMessage(BWC_Constants.WFE_NEBULA_MESSAGE_TEMPLATE, params);

            if(isError){
                Logger.error(logMessage).setRecordId(recordId);
            }else{
                Logger.info(logMessage).setRecordId(recordId);
            }

            Logger.saveLog();

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
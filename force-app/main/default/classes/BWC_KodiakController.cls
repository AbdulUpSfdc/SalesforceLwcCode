public with sharing class BWC_KodiakController {
    public class KodiakSearchResponseWrapper extends BWC_ResponseWrapper {
        public BWC_Kodiak.KodiakSearchResponse response;
    }
    
    @AuraEnabled(continuation=true)
    public static Object KodiakSearchContinuation(String localTime){
        
        KodiakSearchResponseWrapper responseWrapper = new KodiakSearchResponseWrapper();
        try {
            BWC_KodiakService.GetKodiakSearch service = new BWC_KodiakService.GetKodiakSearch(localTime);
            Object response = service.callWithContinuation();
            if(response instanceof Continuation){
                ((Continuation)response).ContinuationMethod = 'getKodiakResp';
                return response;
            }
            BWC_Kodiak.KodiakSearchResponse kodiakResponse = (BWC_Kodiak.KodiakSearchResponse) response;
            system.debug('response....' + kodiakResponse);
            responseWrapper.response = kodiakResponse;
            responseWrapper.success=true;
            
        } catch (Exception e) {
            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, 'Kodiak Controller', null);
        }
        return responseWrapper.serialize();
    }
    
    @AuraEnabled
    public static String getKodiakResp(List<String> labels, Object state){
        try {
            
            BWC_KodiakService.GetKodiakSearch service =
                (BWC_KodiakService.GetKodiakSearch)state;
            
            BWC_Kodiak.kodiakSearchResponse KodiakResponse =
                (BWC_Kodiak.kodiakSearchResponse)service.processContinuationResponse();
            
            KodiakSearchResponseWrapper responseWrapper = new KodiakSearchResponseWrapper();
            responseWrapper.response = KodiakResponse;
            responseWrapper.success=true;
            
            return responseWrapper.serialize();
            
        } catch (Exception e) {
            
            throw BWC_Controller.handleException(e);
            
        }
    }
    @AuraEnabled
    public static boolean getKodiakAccess(){
        List<PermissionSetAssignment> lstcurrentUserPerSet =    [SELECT Id, PermissionSet.Name,AssigneeId
                                                                 FROM PermissionSetAssignment
                                                                 WHERE AssigneeId = :Userinfo.getUserId() ];
        Boolean user_has_permission = false;
        for ( PermissionSetAssignment psa : lstcurrentUserPerSet ) {
            if ( psa.PermissionSet.Name.equals( BWC_Kodiak.KM_BCSS_Advanced_Solutions_CS) ||
                 psa.PermissionSet.Name.equals(BWC_Kodiak.KM_BCSS_Adv_Tech_Support)|| 
                 psa.PermissionSet.Name.equals(BWC_Kodiak.KM_BCSS_FirstNet ) ){
                    user_has_permission = true;
                }
        }
        return user_has_permission;
    }
    
    @AuraEnabled
    public static Boolean hasRecordAccess(String title){
        String query = 'Select id,title,PublishStatus from Knowledge__kav where Title LIKE \'%' + title + '%\''+ 'and PublishStatus =' + '\''+ BWC_Constants.KM_PUBLISH_STATUS_ONLINE + '\'';
        List<Knowledge__kav> ka = Database.query(query);
        if(ka.size() > 0){
            UserRecordAccess access = [Select RecordId ,HasReadAccess,HasEditAccess from UserRecordAccess where RecordId = :ka[0].id and userId =:UserInfo.getUserId()];
            system.debug('access....' +access.HasReadAccess);
            return access.HasReadAccess;
        }else{
             return false;
        }
    }
}
public with sharing class BWC_IMEISearchController {
     @AuraEnabled
    public static string IMEISearch(String Imei){
        IMEISearchResponseWrapper responseWrapper = new IMEISearchResponseWrapper();
        try {
            responseWrapper.response = BWC_IMEISearchService.IMEISearch(Imei);
			responseWrapper.success=true;
            
        } catch (Exception e) {
            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, 'IMEI Search', null);
        }
        return responseWrapper.serialize();
    }
    
    public class IMEISearchResponseWrapper extends BWC_ResponseWrapper {
        public BWC_IMEISearch.IMEISearchResponse response;
    }

    @AuraEnabled
    public static Boolean hasRecordAccess(String title){
        
        String query = 'Select id,title,PublishStatus from Knowledge__kav where Title LIKE \'%' + title + '%\''+ 'and PublishStatus = \'Online\'';
        List<Knowledge__kav> ka = Database.query(query);
        system.debug('Knowledge__kav...' +ka);
        if(ka.size() > 0){
            UserRecordAccess access = [Select RecordId ,HasReadAccess,HasEditAccess from UserRecordAccess where RecordId = :ka[0].id and userId =:UserInfo.getUserId()];
            return access.HasReadAccess;
        }else{
            system.debug('--No Published Article found with title: ' + title);
            return false;
        }
    }
}
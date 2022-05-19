public with sharing class BWC_RSATokenController {
    @AuraEnabled @testvisible
    public static String getAuthCode(){
        DateTime timeNow = System.now();
        try {
            String tokenCache ='';   
            Cache.OrgPartition orgPart =  Cache.Org.getPartition('local.rsatoken');     
            tokenCache = (String)orgPart.get(String.valueOf(UserInfo.getUserId()));   
            system.debug('GET CACHE.....' + tokenCache);
            return tokenCache;
        } catch (Exception e) {
            system.debug('---' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
      
    @testVisible
    private static void CacheAuthCode(BWC_RSAToken.RSATokenResponse response){
        try{
            String tokenCache = response.token + '--' + response.serialnum + '--' + response.timestamp;
            Cache.OrgPartition orgPart =  Cache.Org.getPartition('local.rsatoken');
            orgPart.put(UserInfo.getUserId(), tokenCache, 3000);
            system.debug('inserted to cache.....' + tokenCache);                  
        }catch(Exception e){
            throw new BWC_Exception(e.getMessage());
        }
        
    }
    
    @AuraEnabled
    public static  string  getRSAToken(){
        
        RSATokenResponseWrapper responseWrapper = new RSATokenResponseWrapper();
        String attuid = BWC_Utils.getCurrentUserAttId();
        if(attuid == null || attuid == ''){
             throw new BWC_Exception('ATTUID is empty on user record');
        }
        String existingCode = getAuthCode();
        system.debug('---existingCode--' + existingCode);
        try {
            if(!generateNewToken(existingCode)){
                system.debug('---entering main if--' + existingCode);
                String token = existingCode.split('--')[0];
                String serialnum = existingCode.split('--')[1];
                String timestamp = existingCode.split('--')[2];
                BWC_RSAToken.RSATokenResponse response = new BWC_RSAToken.RSATokenResponse();
                response.token = token;
                response.serialnum = serialnum;
                response.timestamp = timestamp;
                response.attuid = attuid;
                responseWrapper.response = response;
                
            }else{
                system.debug('---entering main else--' + existingCode);
                responseWrapper.response = BWC_RSATokenService.getRSAToken();
                responseWrapper.response.timestamp = System.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'.000Z\'');
                //responseWrapper.response.token = String.valueOf(Math.round((Math.random() * (900000) + 100000)));//Remove this once actual Integration is setup
                //responseWrapper.response.serialnum = String.valueOf(Math.round((Math.random() * (90000000) + 10000000)));//Remove this once actual Integration is setup
                //responseWrapper.response.attuid = attuid;//Remove this once actual Integration is setup
                CacheAuthCode(responseWrapper.response);
            }
            
			responseWrapper.success=true;
            
        } catch (Exception e) {
            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, 'RSAToken', null);
        }
        return responseWrapper.serialize();
    }
    
    public class RSATokenResponseWrapper extends BWC_ResponseWrapper {
        public BWC_RSAToken.RSATokenResponse response;
    }
    
    public static Boolean generateNewToken(String existingCode){
        system.debug('---generateNewToken--'+ existingCode);
        if(existingCode == '' || existingCode == null){
            return true;
        }else{
            String timestamp = existingCode.split('--')[2];
            timeStamp = timeStamp?.replace('.000Z','').replace('T',' ');
            DateTime dt = Datetime.valueOfGMT(timeStamp);
            dt = dt.addMinutes(5);
            system.debug('---5 minutes --'+ dt);
            if(dt >= System.now()){
                system.debug('---5 minutes if--'+ dt);
                return false;
            }else{
                return true;
            }
        }
    }
    
    @AuraEnabled
    public static Boolean hasRecordAccess(String title){
        String query = 'Select id,title,PublishStatus from Knowledge__kav where Title LIKE \'%' + title + '%\''+ 'and PublishStatus = \'Online\'';
        
        List<Knowledge__kav> ka = Database.query(query);
        if(ka.size() > 0){
            UserRecordAccess access = [Select RecordId ,HasReadAccess,HasEditAccess from UserRecordAccess where RecordId = :ka[0].id and userId =:UserInfo.getUserId()];
            return access.HasReadAccess;
        }else{
            system.debug('--No Published Article found with title: ' + title);
            return false;
        }
    }
}
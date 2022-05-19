/* ================================================
* @author : Emmanuel Hernandez
* @date :   01/06/2021   
* @group : Auto Pay Profiles
* @description : Controller class for LWC bwcAutoPayProfilesServices
================================================*/
public with sharing class BWC_AutoPayProfilesController {
    
    @AuraEnabled
    public static String postAutoPayProfile(String autoPayProfileJson, String mode){
        return postAutoPayProfileRaisr(autoPayProfileJson, mode, null);
    }

    @AuraEnabled
    public static String postAutoPayProfileRaisr(String autoPayProfileJson, String mode, String spiDataJson){

        AutoPayProfilesResponseWrapper responseWrapper = new AutoPayProfilesResponseWrapper();

        try{

            BWC_AutoPayProfiles.AutoPayProfile autoPayProfile = (BWC_AutoPayProfiles.AutoPayProfile)JSON.deserialize(autoPayProfileJson, BWC_AutoPayProfiles.AutoPayProfile.class);
            
            BWC_MakePayment.SpiData spiData = new BWC_MakePayment.SpiData();
            if (spiDataJson != null) {
                spiData = (BWC_MakePayment.SpiData)JSON.deserialize(spiDataJson, BWC_MakePayment.SpiData.class);   
            }

            BWC_AutoPayProfiles.AutoPayProfilesPostResponse response = BWC_AutoPayProfilesService.postAutoPayProfile(autoPayProfile, mode, spiData);
            responseWrapper.success = true;
            responseWrapper.response = response;

        }
        catch(Exception e) {
            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, 'ban: ', null);
        }

        return responseWrapper.serialize();
    } 

    public class AutoPayProfilesResponseWrapper extends BWC_ResponseWrapper{
        public BWC_AutoPayProfiles.AutoPayProfilesPostResponse response;
    }

}
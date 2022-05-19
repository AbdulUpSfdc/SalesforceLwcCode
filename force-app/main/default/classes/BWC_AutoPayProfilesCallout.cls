/* ================================================
* @author : Emmanuel Hernandez
* @date :   01/06/2021   
* @group : Auto Pay Profiles
* @description : Callout class for BWC_AutoPayProfilesService
================================================*/
public with sharing class BWC_AutoPayProfilesCallout {
    
    public static BWC_AutoPayProfiles.AutoPayProfilesPostResponse postAutoPayProfile(BWC_AutoPayProfiles.AutoPayProfilesPostRequest request, String mode){

        String requestBody = JSON.serialize(request, true);

        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_AUTOPAY_PROFILES_POST, requestBody, null, 'mode='+mode);

        try{
            return (BWC_AutoPayProfiles.AutoPayProfilesPostResponse) JSON.deserialize(response.getBody(), BWC_AutoPayProfiles.AutoPayProfilesPostResponse.class);
        }catch(JSONException je){
            throw new BWC_Exception('Failed to deserialze HTTP response body',je);
        }

    }
}
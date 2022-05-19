/*
    Call Mulesoft to get users associated to a billing account.
*/
public with sharing class BWC_UserAssociationsCallout {
    public static final String USER_ASSOC_DETAILS = 'User_Associations';

    /*
        Callout to get user associations for requested accounts.
    */
    public static List<BWC_UserAssociations.UserAssociationsResponse> getUserAssociations(List<BWC_UserAssociations.UserAssociationsRequest> requests) {

        if (requests == null) {
            throw new BWC_Exception('Argument required: requests');
        }

        // Serialize
        String requestBody = JSON.serialize(requests, true);

        // Make the call
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_USER_ASSOCIATIONS, requestBody);

        // Attempt deserialize
        List<BWC_UserAssociations.UserAssociationsResponse> returnValue;
        try {
            returnValue = (List<BWC_UserAssociations.UserAssociationsResponse>)JSON.deserialize(response.getBody(), List<BWC_UserAssociations.UserAssociationsResponse>.class);
        }
        catch (System.JSONException e) {
            throw new BWC_Exception('Failed to deserialize HTTP response body.', e);
        }

        return returnValue;

    }

    
    public class GetUserAssociationsCallout extends BWC_Callout {
       
        // Request and Response state
        List<BWC_UserAssociations.UserAssociationsRequest> request;
        BWC_UserAssociations.UserAssociationsResponse response;

        /*
            Construct the callout object from request.
        */
        public GetUserAssociationsCallout(List<BWC_UserAssociations.UserAssociationsRequest> request) {

            this.setCallout(USER_ASSOC_DETAILS, request, null, null, null);

        }

        /*
            Returns BWC_UserAssociations.UserAssociationsResponse.
        */
        public override Object buildResponse() {

            // Response requires extra wrapper because API returns an array but we need root to be an object so it can extend BWC_Callout.Response
            this.response = new BWC_UserAssociations.UserAssociationsResponse();
            this.response.responses = (List<BWC_UserAssociations.UserAssociationsResponseListResponse>)this.deserialize(List<BWC_UserAssociations.UserAssociationsResponseListResponse>.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);
            return this.response;

        }

    } 

    /*
        Callout to add one or more authorized users to an account.
    */
    public static List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> addUserAssociations(List<BWC_UserAssociations.UserAssociation> userAssociations) {

        if (userAssociations == null) {
            throw new BWC_Exception('Argument required: userAssociations');
        }

        // Serialize
        String requestBody = JSON.serialize(userAssociations, true);

        // Make the call
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_USER_ASSOCIATIONS_ADD_DELETE, requestBody, null, null, 'POST');

        // Attempt deserialize
        List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> returnValue;
        try {
            returnValue = (List<BWC_UserAssociations.AddDeleteUserAssociationsResponse>)JSON.deserialize(response.getBody(), List<BWC_UserAssociations.AddDeleteUserAssociationsResponse>.class);
        }
        catch (System.JSONException e) {
            throw new BWC_Exception('Failed to deserialize HTTP response body.', e);
        }

        return returnValue;

    }

    /*
        Callout to remove one or more authorized users from an account.
    */    
    public static List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> deleteUserAssociations(List<BWC_UserAssociations.UserAssociation> userAssociations) {

        if (userAssociations == null) {
            throw new BWC_Exception('Argument required: userAssociations');
        }

        // Serialize
        String requestBody = JSON.serialize(userAssociations, true);

        // Make the call
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_USER_ASSOCIATIONS_ADD_DELETE, requestBody, null, null, 'DELETE');

        // Attempt deserialize
        List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> returnValue;
        try {
            returnValue = (List<BWC_UserAssociations.AddDeleteUserAssociationsResponse>)JSON.deserialize(response.getBody(), List<BWC_UserAssociations.AddDeleteUserAssociationsResponse>.class);
        }
        catch (System.JSONException e) {
            throw new BWC_Exception('Failed to deserialize HTTP response body.', e);
        }

        return returnValue;

    }

}
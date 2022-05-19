/*
    Exposes methods to allow LWC to call User Associations service.
*/
public with sharing class BWC_UserAssociationsController {

    /*
        Method for calling from LWC. Returns serialized JSON.
    */
    @AuraEnabled
    public static String getUserAssociations(Id recordId) {

        UserAssociationsResponseWrapper responseWrapper = new UserAssociationsResponseWrapper();

        try {

            List<BWC_UserAssociations.UserAssociationsResponse> responses = BWC_UserAssociationsService.getUserAssociations(recordId);
            responseWrapper.success = true;
            responseWrapper.responses = responses;

        }
        catch (System.Exception e) {

            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, 'recordId: ' + recordId, null);

        }

        // Return the JSON, LWC will parse it.
        return responseWrapper.serialize();

    }

    @AuraEnabled(continuation = true)
    public static Object getUserAssociationsForBillingAccountCont(Id recordId, Id InteractionId) {
        
        try {

            BWC_UserAssociationsService.GetUserAssociationsService service = new BWC_UserAssociationsService.GetUserAssociationsService(recordId,InteractionId);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'getUserAssociationResp';
                return response;
            }

            // No continuation needed, so return it directly
            BWC_UserAssociations.UserAssociationsResponse userAssociationResponse = (BWC_UserAssociations.UserAssociationsResponse)response;
            return userAssociationResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e, 'Record Id:' + recordId);
        }

    }
    @AuraEnabled
    public static String getUserAssociationResp(List<String> labels, Object state) {

        try {

            BWC_UserAssociationsService.GetUserAssociationsService service = ( BWC_UserAssociationsService.GetUserAssociationsService)state;
            BWC_UserAssociations.UserAssociationsResponse userAssociationResponse = (BWC_UserAssociations.UserAssociationsResponse)service.processContinuationResponse();
            return userAssociationResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }
    /*
        Method for calling from LWC. Returns serialized JSON.
    */
    @AuraEnabled
    public static String getUserAssociationsForBan(String ban, String accountType) {

        UserAssociationsResponseWrapper responseWrapper = new UserAssociationsResponseWrapper();

        try {

            List<BWC_UserAssociations.UserAssociationsResponse> responses = BWC_UserAssociationsService.getUserAssociationsForBan(ban, accountType);
            responseWrapper.success = true;
            responseWrapper.responses = responses;

        }
        catch (System.Exception e) {

            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, 'ban: ' + ban + ', accountType: ' + accountType, null);

        }

        // Return the JSON, LWC will parse it.
        return responseWrapper.serialize();

    }

    /*
        Wrapper for returning response along with error information.
    */
    public class UserAssociationsResponseWrapper extends BWC_ResponseWrapper {
        public List<BWC_UserAssociations.UserAssociationsResponse> responses;
    }

    /*
        Method for calling from LWC. Returns serialized JSON.
    */
    @AuraEnabled
    public static String addUserAssociations(String userAssociationsJson) {

        AddDeleteUserAssociationsResponseWrapper responseWrapper = new AddDeleteUserAssociationsResponseWrapper();

        try {

            // Deserialize the request sent by LWC
            List<BWC_UserAssociations.UserAssociation> userAssociations = 
                (List<BWC_UserAssociations.UserAssociation>)JSON.deserialize(userAssociationsJson, List<BWC_UserAssociations.UserAssociation>.class);

            List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> responses = BWC_UserAssociationsService.addUserAssociations(userAssociations);
            responseWrapper.success = true;
            responseWrapper.responses = responses;

        }
        catch (System.Exception e) {

            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, null, null);

        }

        // Return the JSON, LWC will parse it.
        return responseWrapper.serialize();

    }

    /*
        Method for calling from LWC. Returns serialized JSON.
    */
    @AuraEnabled
    public static String deleteUserAssociations(String userAssociationsJson) {

        AddDeleteUserAssociationsResponseWrapper responseWrapper = new AddDeleteUserAssociationsResponseWrapper();

        try {

            // Deserialize the request sent by LWC
            List<BWC_UserAssociations.UserAssociation> userAssociations = 
                (List<BWC_UserAssociations.UserAssociation>)JSON.deserialize(userAssociationsJson, List<BWC_UserAssociations.UserAssociation>.class);

            List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> responses = BWC_UserAssociationsService.deleteUserAssociations(userAssociations);
            responseWrapper.success = true;
            responseWrapper.responses = responses;

        }
        catch (System.Exception e) {

            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, null, null);

        }

        // Return the JSON, LWC will parse it.
        return responseWrapper.serialize();

    }

    /*
        Wrapper for returning response along with error information.
    */
    public class AddDeleteUserAssociationsResponseWrapper extends BWC_ResponseWrapper {
        public List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> responses;
    }

}
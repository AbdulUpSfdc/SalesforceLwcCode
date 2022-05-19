/**
 * Class used by bwcInteractionActivityServicw LWC.
 * Provides methods for interaction activity creations
*/
public with sharing class BWC_InteractionActivityController {

    /**
     * Method that process the parameters and calls the service class to create an interaction activity record.
     * @param activityJson JSON that contains the minimum needed parameters for interaction activity creation. It follows the format of BWC_InteractionActivityService.InteractionActivity
     * @param detailRecordJson JSON that contains additional information meant to be stored as a string in detail_record__c field.
    */
    @AuraEnabled
    public static void logActivity(String activityJson, String detailRecordJson){

        try{

            BWC_InteractionActivityService.InteractionActivity activity = (BWC_InteractionActivityService.InteractionActivity) JSON.deserialize(activityJson, BWC_InteractionActivityService.InteractionActivity.class);
            activity.setDetailRecord(detailRecordJson);
            BWC_InteractionActivityService.logActivity(activity);


        } catch(Exception e) {

            throw BWC_Controller.handleException(e);

        }

    }
}
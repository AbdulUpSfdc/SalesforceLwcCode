/**
 * Class used by BWC_InteractionActivityController class.
 * Contains a method and a class for interaction activity creation.
*/
public without sharing class BWC_InteractionActivityService {

    public static final String INTERACTION_COMPLETE_ACTION = 'Inquiry | Complete Interaction';

    /**
     * Method used to create interaction_activity__c records out of InteractionActivity instances.
     * It validates the minimum attributes are populated, otherwise an exception will be thrown
    */
    public static void logActivity(InteractionActivity activity){

        if(String.isBlank(activity.interactionId)){
            throw new BWC_InteractionActivityException('interactionId cannot be empty');
        }

        if(String.isBlank(activity.action)){
            throw new BWC_InteractionActivityException('action cannot be empty');
        }

        if(String.isBlank(activity.type)){
            throw new BWC_InteractionActivityException('type cannot be empty');
        }

        //FLS Not needed, results not returned to user
        Interaction__c interaction = [SELECT Customer__c, CompletedDate__c FROM Interaction__c WHERE Id = :activity.interactionId LIMIT 1];

        /**
         * Only log activities for interactions without a completed date or which action is Complete Interaction.
         * The last condition covers the scenario where we first complete the interaction (populate completedDate)
         * and if that operations success we log the Complete Interaction activity.
        */
        if(interaction.CompletedDate__c == null  || activity.action.equals(INTERACTION_COMPLETE_ACTION) ){

            Interaction_Activity__c intActivity = new Interaction_Activity__c();

            intActivity.Action__c = activity.action;
            intActivity.Interaction__c = activity.interactionId;
            intActivity.Type__c = activity.type;
            intActivity.Billing_Account__c = activity.billingAccountId;
            intActivity.Plan__c = activity.planId;
            intActivity.Equipment__c = activity.assetId;
            intActivity.Detail_Record__c = activity.detailRecord;
            intActivity.Customer__c = interaction.Customer__c;

            insert intActivity;

        }

    }

    /**
     * Class used to deserialize the JSON sent by bwcInteractionActivityService LWC
     * This class uses the builder pattern, so it can be used in Apex to only set the needed attributes.
     * @example
     * new InteractionActivity()
     *  .getAction('action')
     *  .setType('type')
     *  .setInteractionId('interactionId')
     *  .saveActivity();
    */
    public class InteractionActivity {
        private String action;
        private Id assetId;
        private Id billingAccountId;
        private String detailRecord;
        private Id interactionId;
        private Id planId;
        private String type;

        public InteractionActivity setAction(String action){
            this.action = action;
            return this;
        }

        public InteractionActivity setAssetId(Id assetId){
            this.assetId = assetId;
            return this;
        }

        public InteractionActivity setBillingAccountId(Id billingAccountId){
            this.billingAccountId = billingAccountId;
            return this;
        }

        public InteractionActivity setDetailRecord(String detailRecord){
            this.detailRecord = detailRecord;
            return this;
        }

        public InteractionActivity setInteractionId(Id interactionId){
            this.interactionId = interactionId;
            return this;
        }

        public InteractionActivity setPlanId(Id planId){
            this.planId = planId;
            return this;
        }

        public InteractionActivity setType(String type){
            this.type = type;
            return this;
        }

        public void saveActivity(){

            BWC_InteractionActivityService.logActivity(this);
        }

    }

    public class BWC_InteractionActivityException extends Exception{}

}
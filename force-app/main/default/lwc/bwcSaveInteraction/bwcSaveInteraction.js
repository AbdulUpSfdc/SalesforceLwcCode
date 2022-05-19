import { api, track, wire } from "lwc";
import BwcPageElementBase from "c/bwcPageElementBase";
import { updateRecord, getRecord, getFieldValue } from "lightning/uiRecordApi";
import getInteractionActivityTypes from "@salesforce/apex/BWC_InteractionActivity.getInteractionActivityTypes";
import getInteractionActivities from "@salesforce/apex/BWC_InteractionActivity.getInteractionActivities";
import getInteractionRecord from "@salesforce/apex/BWC_InteractionActivity.getInteractionRecord";
import publishEvent from "@salesforce/apex/BWC_InteractionCompleteEvent.publishEvent";
import * as BwcConstants from "c/bwcConstants";
import * as BwcUtils from "c/bwcUtils";
import * as BwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';
import { createOpusLog } from 'c/bwcLicServices';

import CASE_COUNT_FIELD from "@salesforce/schema/Interaction__c.Case_Count__c";
import CALL_STATUS_FIELD from "@salesforce/schema/Interaction__c.Call_Status__c";

// LMS Message channels
import MSG_TO_NEW_CUSTOMER_MC from "@salesforce/messageChannel/BWC_MsgToNewCustomer__c";
import MSG_TO_LIC_MC from "@salesforce/messageChannel/BWC_MsgToLIC__c";
import TRANSFER_REQUEST_MC from "@salesforce/messageChannel/BWC_TransferRequest__c";
import INTERACTION_COMPLETE_MC from "@salesforce/messageChannel/BWC_InteractionComplete__c";
import TRANSFER_COMPLETED_MC from "@salesforce/messageChannel/BWC_TransferCompleted__c"; // Leave this in - used if test code is uncommented
import MSG_WFE_WINDOW_CLOSE from "@salesforce/messageChannel/BWC_WFEWindowClose__c";

// Custom labels
import label_EscalationCasesMessage from "@salesforce/label/c.BWC_EscalationCases_Message";

const INTERACTION_COMPLETE = 'complete';
export default class TempSaveInteraction extends BwcPageElementBase {
    @api recordId;
    isBusy;
    @track activityTypes = [];

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [CASE_COUNT_FIELD, CALL_STATUS_FIELD]
    })
    interaction;

    get caseCount() {
        if (this.interaction) {
            return getFieldValue(this.interaction.data, CASE_COUNT_FIELD);
        }

        return -1;
    }

    get disableTransferCall() {
        if (this.interaction) {
            return this.isBusy || getFieldValue(this.interaction.data, CALL_STATUS_FIELD) !== "In Call";
        }

        return this.isBusy;
    }

    get caseCountGT0() {
        if (this.caseCount) {
            return this.caseCount > 0;
        }
        return false;
    }

    get caseEscalationMessage() {
        return label_EscalationCasesMessage.replace("##CaseCount##", this.caseCount);
    }

    async connectedCallback() {
        try {
            this.isBusy = true;

            // Get all picklist values
            const activityTypeMap = await getInteractionActivityTypes();

            // Build data to drive checkbox display, they all start unchecked
            const activityTypes = Object.keys(activityTypeMap).map((key, index) => ({
                value: key,
                label: activityTypeMap[key],
                key: index + "",
                checked: false
            }));

            // Get interaction's activities
            const interactionActivities = await getInteractionActivities({
                interactionId: this.recordId
            });

            // Set checkbox for all activities that are present
            interactionActivities.forEach((interactionActivity) => {
                const activityType = activityTypes.find((type) => type.value === interactionActivity.Type__c);
                if (activityType) {
                    activityType.checked = true;
                }
            });
            this.activityTypes = activityTypes;
        } catch (error) {
            super.handleError(error);
        } finally {
            this.isBusy = false;
        }
    }

    /*
        Save button.
    */
    async handleSave() {

        let success;
        try {
            this.isBusy = true;
            super.clearNotifications();

            await this.updateInteraction();

            // Publish all the LMS messages:
            this.publishMessage(MSG_TO_LIC_MC, { msg: "CLOSE" });
            this.publishMessage(INTERACTION_COMPLETE_MC, {
                recordId: this.recordId,
                objectName: "Interaction__c"
            });
            this.publishMessage(MSG_TO_NEW_CUSTOMER_MC, { show: "false" });

            success = true;

            this.publishMessage(MSG_WFE_WINDOW_CLOSE, { msg: "CLOSE" });

            this.dispatchCloseEvent();

        } catch (error) {
            success = false;
            super.handleError(error);
        } finally {
            this.isBusy = false;

            this.createInteractionActivity(success);

            createOpusLog(this.recordId, 'Closing OPUS', false);

        }
    }

    dispatchCloseEvent(){
        const event = new CustomEvent('closetab');
        this.dispatchEvent(event);
    }

    @api
    reportError(error){
        super.handleError(error);
    }

    createInteractionActivity(success){

        const action = BwcConstants.InteractionActivityValueMapping.CompleteInteraction.action;

        const intActPayload = {
            recordId: this.recordId,
            status: success ? 'success':'failed',
            action: INTERACTION_COMPLETE
        };

        const intActPayloadStr = JSON.stringify(intActPayload);

        BwcInteractActivityPublisher.publishMessage(this.recordId, action, intActPayloadStr);

    }

    /*
        Transfer button.
    */
    async handleTransfer() {
        try {
            this.isBusy = true;
            super.clearNotifications();

            await this.updateInteraction(true);

            this.publishMessage(TRANSFER_REQUEST_MC, {
                recordId: this.recordId,
                objectName: "Interaction__c"
            });
            // // Leave for unit testing when needed -- publish LMS messages for unit testing
            // console.log('publishing transfer complete')
            // this.publishMessage(TRANSFER_COMPLETED_MC, {recordId: this.recordId});

            this.closeQuickAction();
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isBusy = false;
        }
    }

    async updateInteraction(isTransfer) {
        // Retrieve current interaction
        const currentInteraction = await getInteractionRecord({ recordId: this.recordId });

        let notes = this.template.querySelector("lightning-textarea").value;
        /* Trim input, to prevent storing just tabs or spaces.
        if empty string or undefined, we set undefined as the final value
        so the notes field is not updated
        */
        notes = notes?.trim() || undefined;

        // Convert selected activity types into colon-separated list for multi-select-picklist
        const activitySummary = this.activityTypes
            .filter((activityType) => activityType.checked)
            .map((activityType) => activityType.value)
            .join(";");

        // Interaction__c fields
        const completedDate =
            currentInteraction && currentInteraction.Call_Status__c !== BwcConstants.callStatus.IN_CALL.value && !isTransfer
                ? new Date().toISOString()
                : undefined;
        const transferDate =  isTransfer ? new Date().toISOString() : undefined;
        const updatedFields = {
            Id: this.recordId,
            Notes__c: notes,
            CompletedDate__c: completedDate,
            Activity_Summary__c: activitySummary,
            Transfer_Date__c: transferDate
        };

        // Update the record
        await updateRecord({ fields: updatedFields });

        await this.callPublishEvent(isTransfer);
    }

    /*
        Close X icon or Cancel button.
    */
    closeQuickAction() {
        this.dispatchEvent(new CustomEvent("closequickaction"));
    }

    async callPublishEvent(isTransfer){

        try {
            await publishEvent({
                recordId: this.recordId,
                isTransfer
            });
        } catch (error) {
            BwcUtils.error(error);
        }
    }
}
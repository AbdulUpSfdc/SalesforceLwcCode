import { api } from "lwc";
import { updateRecord } from "lightning/uiRecordApi";

import * as BwcLabelServices from "c/bwcLabelServices";
import * as BwcAdjustmentCaseServices from "c/bwcAdjustmentCaseServices";
import BwcPageElementBase from "c/bwcPageElementBase";

export default class BwcTakeOwnership extends BwcPageElementBase {
    @api recordId;
    message;
    title;
    variant;

    // Labels
    labels = BwcLabelServices.labels;

    @api async invoke() {
        try {
            const result = await BwcAdjustmentCaseServices.takeOwnershipAdjustmentCase({ caseId: this.recordId });
            if (result == true) {
                this.message = this.labels.takeOwnershipSuccess;
                this.title = "Success";
                this.variant = "success";
                this.updateRecordView(this.recordId);
            } else {
                this.message = this.labels.takeOwnershipFailure;
                this.title = "Error";
                this.variant = "error";
            }
            this.showToast(this.title, this.message, this.variant, "");
            this.sendLmsRefresh(this.recordId, "refreshCaseDynamicEscalationDetail");
        } catch (error) {
            this.showToast("Error", error, "error", "");
        }
    }

    // Refresh the current record
    updateRecordView(recordId) {
        updateRecord({
            fields: {
                Id: recordId
            }
        });
    }
}
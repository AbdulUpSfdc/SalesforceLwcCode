import { api, track } from "lwc";

import * as BwcLabelServices from "c/bwcLabelServices";
import BwcPageElementBase from "c/bwcPageElementBase";
import * as BwcAdjustmentCaseServices from "c/bwcAdjustmentCaseServices";

export default class BwcReturnBackAdjustment extends BwcPageElementBase {
    @api recordId;
    @api fromParent;
    @api hasPermission;

    @track comment;
    @track isDisabled = true;

    // Labels
    labels = BwcLabelServices.labels;

    async handleSave() {
        var inp = this.template.querySelector("lightning-textarea");
        this.comment = inp.value;

        try {
            const result = await BwcAdjustmentCaseServices.returnBackAdjustment({
                workItemId: this.fromParent,
                comments: this.comment
            });

            if (result) {
                this.showToast("Success", result, "success", "");
                this.sendLmsRefresh(this.recordId, "refreshRelatedlist");
            }
        } catch (error) {
            this.showToast("Error", error, "error", "");
        }

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this.handleCancel();
        }, 5000);
    }

    changeHandler(event) {
        if (event.target.value.length > 0) {
            this.isDisabled = false;
        } else {
            this.isDisabled = true;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent("closemodal"));
    }
}
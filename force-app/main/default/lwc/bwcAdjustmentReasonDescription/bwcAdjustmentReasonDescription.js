import { api } from "lwc";

import hasCABackOfficeManagerPermission from "@salesforce/customPermission/Credit_Adjustments_Back_Office_Manager";
import BwcPageElementBase from "c/bwcPageElementBase";
import * as BwcAdjustmentCaseServices from "c/bwcAdjustmentCaseServices";

export default class BwcAdjustmentReasonDescription extends BwcPageElementBase {
    value = "";
    reasonDescriptions = [];
    reasonCodes = [];
    isViewMode = true;
    buttonLabel = "Edit";
    currentRecord;
    @api recordId;

    connectedCallback() {
        super.connectedCallback();
        this.getData();
    }

    async getData() {
        const data = await BwcAdjustmentCaseServices.getAdjustmentLineItem({ recordId: this.recordId });
        this.currentRecord = data;
        if (data) {
            this.getAdjReasonDescriptions();
        }
    }

    get hasCreditAdjustmentsPermission() {
        return !hasCABackOfficeManagerPermission;
    }

    async getAdjReasonDescriptions() {
        const adjReasonDesc = this.currentRecord.Adj_Reason_Description__c;
        const adjType = this.currentRecord.Adjustment_Type__c;
        const chargeCode = this.currentRecord.Charge_Code__c;
        const chargeType = this.currentRecord.Charge_Type__c;

        this.value = adjReasonDesc;

        const result = await BwcAdjustmentCaseServices.getReasonDescriptions({
            adjType: adjType,
            chargeCode: chargeCode,
            chargeType: chargeType
        });

        if (result) {
            this.reasonCodes = result;
            let ops = [];
            result.forEach((code) => {
                ops.push({ label: code.reasonDescription, value: code.reasonDescription });
            });
            this.reasonDescriptions = ops;
        }
    }

    handleChange(event) {
        this.value = event.detail.value;
    }

    async handleClick(event) {
        if (!this.isViewMode && this.value !== this.currentRecord.Adj_Reason_Description__c) {
            const selectedCode = this.reasonCodes.find((code) => code.reasonDescription === this.value);

            const adjLineItem = {
                Id: this.recordId,
                Adj_Reason_Explanation_Code__c: selectedCode.reasonExplanationCode,
                Adj_Reason_System_Code__c: selectedCode.reasonSystemCode,
                Adj_Reason_Description__c: selectedCode.reasonDescription
            };

            try {
                await BwcAdjustmentCaseServices.updateAdjustmentLineItem(adjLineItem);
                this.showToast("Success", "Description successfully updated!", "success", "");
            } catch (error) {
                this.showToast("Error", error.body.message, "error", "");
            }
        }

        this.isViewMode = !this.isViewMode;
        this.buttonLabel = this.isViewMode ? "Edit" : "Save";
    }
}
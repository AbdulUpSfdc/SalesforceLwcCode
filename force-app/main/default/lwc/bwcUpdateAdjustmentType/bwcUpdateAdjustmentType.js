import { api } from "lwc";

import * as BwcLabelServices from "c/bwcLabelServices";
import * as BwcAdjustmentCaseServices from "c/bwcAdjustmentCaseServices";
import BwcPageElementBase from "c/bwcPageElementBase";

export default class BwcUpdateAdjustmentType extends BwcPageElementBase {
    // Labels
    labels = BwcLabelServices.labels;

    @api recordId;
    @api async invoke() {
        try {
            const result = await BwcAdjustmentCaseServices.getEditableAdjustment({ recordId: this.recordId });
            const adj = result[0];

            const message = {
                pageReference: {
                    type: "standard__component",
                    attributes: {
                        componentName: "c__BWCBillViewerPage"
                    },
                    state: {
                        c__ban: adj.Case__r.Last_Interaction__r.Billing_Account_Number__c,
                        c__accountType: adj.Case__r.Last_Interaction__r.Billing_Account_Type__c,
                        c__interactionId: adj.Case__r.Last_Interaction__c,
                        c__caseId: adj.Case__r.Id,
                        c__defaultStatementId: adj.Statement_ID__c
                    }
                },
                label: `Bill: ${this.labels.account} ${adj.Case__r.Last_Interaction__r.Billing_Account_Number__c}`,
                icon: "custom:custom40"
            };
            this.openSubtab(message.pageReference, message.label, message.icon);
        } catch (error) {
            const errorMessage = error.body?.message ? JSON.parse(error.body.message).message : error.message;
            this.showToast("Error", errorMessage, "error", "");
        }
    }
}
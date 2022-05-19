import { api } from "lwc";
import { getAdjustmentApprovalHistory } from "c/bwcAdjustmentCaseServices";
import BwcPageElementBase from "c/bwcPageElementBase";

const columns = [
    { label: "Step Name", fieldName: "stepName", type: "text" },
    { label: "Date", fieldName: "appDate", type: "text" },
    { label: "Status", fieldName: "status", type: "text" },
    { label: "Assigned To", fieldName: "assignedTo", type: "text" },
    {
        label: "Actual Approver",
        fieldName: "actualApproverId",
        type: "url",
        typeAttributes: { label: { fieldName: "actualApprover" }, target: "_blank" }
    },
    { label: "Comments", fieldName: "comments", type: "text" }
];

export default class bwcApprovalHistoryRelatedList extends BwcPageElementBase {
    @api recordId;
    columns = columns;
    historyList;

    async getHistory() {
        const results = await getAdjustmentApprovalHistory({ recordId: this.recordId });
        this.historyList = results;
    }

    handleLmsRefresh(scope, recordId) {
        if (scope === "refreshRelatedlist") {
            this.getHistory();
        }
    }

    connectedCallback() {
        super.connectedCallback();
        this.getHistory();
    }

    handleRefreshClick(event) {
        this.getHistory();
    }
}
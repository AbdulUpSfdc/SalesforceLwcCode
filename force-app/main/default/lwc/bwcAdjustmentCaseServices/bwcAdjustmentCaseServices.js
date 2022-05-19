import * as BwcUtils from "c/bwcUtils";
import approveAdjustmentRequestApex from "@salesforce/apex/BWC_AdjustmentCasesController.approveAdjustmentRequest";
import fullRejectAdjustmentApex from "@salesforce/apex/BWC_AdjustmentCasesController.fullRejectAdjustment";
import getAdjustmentApprovalHistoryApex from "@salesforce/apex/BWC_AdjustmentCasesController.getHistory";
import getAdjustmentLineItemApex from "@salesforce/apex/BWC_AdjustmentCasesController.getAdjustmentLineItem";
import getEditableAdjustmentApex from "@salesforce/apex/BWC_AdjustmentCasesController.getEditableAdjustment";
import getReasonDescriptionsApex from "@salesforce/apex/BWC_AdjustmentCasesController.getReasonDescriptions";
import returnBackAdjustmentApex from "@salesforce/apex/BWC_AdjustmentCasesController.returnBackAdjustment";
import takeOwnershipAdjustmentCaseApex from "@salesforce/apex/BWC_AdjustmentCasesController.takeOwnershipAdjustmentCase";
import updateAdjustmentLineItemApex from "@salesforce/apex/BWC_AdjustmentCasesController.updateAdjustmentLineItem";

export const approveAdjustmentRequest = async (workItemId, comments) => {
    BwcUtils.log("Call approveAdjustmentRequest");

    const responseJson = await approveAdjustmentRequestApex(workItemId, comments);

    const response = JSON.parse(responseJson);

    BwcUtils.log("Response for approveAdjustmentRequest", response);

    return response;
};

export const fullRejectAdjustment = async (workItemId, comments) => {
    BwcUtils.log("Call fullRejectAdjustment");

    const responseJson = await fullRejectAdjustmentApex(workItemId, comments);

    const response = JSON.parse(responseJson);

    BwcUtils.log("Response for fullRejectAdjustment", response);

    return response;
};

export const getAdjustmentApprovalHistory = async (recordId) => {
    BwcUtils.log("Call getAdjustmentApprovalHistory", recordId);

    const responseJson = await getAdjustmentApprovalHistoryApex(recordId);

    const response = JSON.parse(responseJson);

    BwcUtils.log("Response for getAdjustmentApprovalHistory", response);

    return response;
};

export const getAdjustmentLineItem = async (recordId) => {
    BwcUtils.log("Call getAdjustmentLineItem", recordId);

    const response = await getAdjustmentLineItemApex(recordId);

    BwcUtils.log("Response for getAdjustmentLineItem", response);

    return response;
};

export const getEditableAdjustment = async (recordId) => {
    BwcUtils.log("Call getEditableAdjustment", recordId);

    const response = await getEditableAdjustmentApex(recordId);

    BwcUtils.log("Response for getEditableAdjustment", response);

    return response;
};

export const getReasonDescriptions = async (adjType, chargeCode, chargeType) => {
    BwcUtils.log("Call getReasonDescriptions");

    const responseJson = await getReasonDescriptionsApex(adjType, chargeCode, chargeType);

    const response = JSON.parse(responseJson);

    BwcUtils.log("Response for getReasonDescriptions", response);

    return response;
};

export const returnBackAdjustment = async (workItemId, comments) => {
    BwcUtils.log("Call returnBackAdjustment");

    const responseJson = await returnBackAdjustmentApex(workItemId, comments);

    const response = JSON.parse(responseJson);

    BwcUtils.log("Response for returnBackAdjustment", response);

    return response;
};

export const takeOwnershipAdjustmentCase = async (caseId) => {
    BwcUtils.log("Call takeOwnershipAdjustmentCase", caseId);

    const responseJson = await takeOwnershipAdjustmentCaseApex(caseId);

    const response = JSON.parse(responseJson);

    BwcUtils.log("Response for takeOwnershipAdjustmentCase", response);

    return response;
};

export const updateAdjustmentLineItem = async (request) => {
    BwcUtils.log("Call updateAdjustmentLineItem", request);

    const requestJson = JSON.stringify(request);

    await updateAdjustmentLineItemApex({ requestJson });
};
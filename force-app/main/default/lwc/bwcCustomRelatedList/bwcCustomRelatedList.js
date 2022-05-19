import { LightningElement, wire, api, track } from "lwc";
import removeFromRecord from "@salesforce/apex/BWC_CustomRelatedListController.removeFromRecord";
import getFilesList from "@salesforce/apex/BWC_CustomRelatedListController.getFilesList";
import deleteFile from "@salesforce/apex/BWC_CustomRelatedListController.deleteFile";
import { getRecordNotifyChange } from "lightning/uiRecordApi";
import { refreshApex } from "@salesforce/apex";
import * as BwcUtils from "c/bwcUtils";

const actions = [
  { label: "Remove from Record", name: "update_details" },
  { label: "Delete", name: "delete" }
];

const columns = [
  { label: "Title", fieldName: "title", type: "string" },
  { label: "Uploaded By", fieldName: "createdBy", type: "string" },
  { type: "action", typeAttributes: { rowActions: actions } }
];

export default class FileList extends LightningElement {
  manageFiles = "Manage Files";
  count = 0;
  @api recordId;
  filesList;
  files = [];
  columns = columns;
  currentDocId = null;
  isLoading = false;
  @api title;
  areDetailsVisible = false;


  connectedCallback() {
    BwcUtils.log("--Connected Callback Called--");
    this.getFilesList();
  }

  async getFilesList() {
    this.isLoading = true;
    try {
      BwcUtils.log("recid--" + this.recordId);
      const response = await getFilesList({
        recordId: this.recordId
      });
      BwcUtils.log("response--" + JSON.stringify(response));
      this.filesList = response;
      this.files = response;
      this.areDetailsVisible = response.length > 0 ? true : false;
      this.count = response.length;
    } catch (e) {
      BwcUtils.log("--error--" + JSON.stringify(e));
    } finally {
      this.isLoading = false;
    }
  }

  refresh() {
    this.getFilesList();
  }

  handleRowAction(event) {
    const action = event.detail.action.name;
    const row = event.detail.row;
    this.currentDocId = row.id;
    switch (action) {
      case "update_details":
        BwcUtils.log(this.currentDocId);
        this.updateFiles([this.currentDocId]);
        break;
      case "delete":
        this.deleteFiles([this.currentDocId]);
    }
  }

  updateFiles(recordIds) {
    if (recordIds.length > 0) {
      let decision = confirm(
        `Are you sure you want remove the file from the record, but not deleted?`
      );
      if (decision) {
        this.updateCaseRecord(recordIds);
      }
    }
  }

  async updateCaseRecord(recordIds1) {
    this.isLoading = true;
    try {
      const response = await removeFromRecord({
        fileId: recordIds1[0],
        CaseId: this.recordId
      });
      BwcUtils.log("response--updateCaseRecord" + JSON.stringify(response));
      refreshApex(this.filesList);
      getRecordNotifyChange({ recordId: "$recordId" });
      eval("$A.get('e.force:refreshView').fire();");
      this.refresh();
      const toastArgs = {
        title: "Sucess",
        message: "File removed successfully.",
        variant: "success"
      };
      BwcUtils.showToast(this, toastArgs);
      this.getFilesList();
    } catch (e) {
      const toastArgs = {
        title: "Error",
        message: "File update failed ",
        variant: "error"
      };
      BwcUtils.showToast(this, toastArgs);
      BwcUtils.log("--error--updateCaseRecord" + JSON.stringify(e));
    } finally {
      this.isLoading = false;
    }
  }

  deleteFiles(recordIds) {
    if (recordIds.length > 0) {
      let decision = confirm(`Are you sure you want to delete file?`);
      if (decision) {
        this.deleteFile(recordIds);
      }
    }
  }

  async deleteFile(recordIdFile) {
    this.isLoading = true;
    try {
      BwcUtils.log("recid--" + this.recordIdFile);
      const response = await deleteFile({
        contentDocId: recordIdFile[0]
      });
      refreshApex(this.filesList);
      getRecordNotifyChange({ recordId: "$recordId" });
      eval("$A.get('e.force:refreshView').fire();");
      const toastArgs = {
        title: "Sucess",
        message: "File deleted sucessfully ",
        variant: "success"
      };
      BwcUtils.showToast(this, toastArgs);
      BwcUtils.log("--error--" + JSON.stringify(response));
      this.getFilesList();
      this.areDetailsVisible = response.length > 0 ? true : false;
    } catch (e) {
      const toastArgs = {
        title: "Error",
        message: "File delete not successfull ",
        variant: "error"
      };
      BwcUtils.showToast(this, toastArgs);
      BwcUtils.log("--error--" + JSON.stringify(e));
    } finally {
      this.isLoading = false;
    }
  }
}
import { LightningElement, api, track, wire } from "lwc";
import * as BwcCustomLookupServices from 'c/bwcCustomLookupServices';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcLabelServices from 'c/bwcLabelServices';

export default class SearchComponent extends LightningElement {
labels = BwcLabelServices.labels;

@api objName = "";
@api iconName = "";
@api labelName;
@api readOnly = false;
@api currentRecordId;
@api placeholder = "";
@api fields;
@api displayFields = "";
@api recordId;
@api selectedRecord = '';
@track fieldLabeltoPopulate = "";
@track fieldIdtoPopulate = "";
@track error;

searchTerm;
delayTimeout;
searchRecords;
objectLabel;
isLoading = false;
fieldDisplay;

async connectedCallback() {
    if (this.objName === "" || this.fields === undefined) {
        return;
    }
    let fieldList;
    if (!Array.isArray(this.displayFields)) {
        fieldList = this.displayFields.split(",");
    } else {
        fieldList = this.displayFields;
    }
        this.fieldDisplay = fieldList[0].trim();
        this.fields=this.fields.split(",")[0].trim();
}
//This function will trigger when user enter search text on the component
async handleInputChange(event) {
    try{
    window.clearTimeout(this.delayTimeout);
    const searchKey = event.target.value;
        if (searchKey.length >= 2) {
            let response = await BwcCustomLookupServices.customLookupData(this.objName, this.fields, searchKey);
            BwcUtils.log(' response'+ response);
            if(response) {
                let stringResult = JSON.stringify(response);
                let allResult = JSON.parse(stringResult);
                    allResult.forEach((record) => {
                        record.showField = record[this.fieldDisplay];
                    });
                this.searchRecords = allResult;
            }
        }  
    }
    catch (e) {
        BwcUtils.error('problem searching', e);
        throw new Error(this.labels.unexpectedError);
    }
    finally {
        this.isLoading = false;
        }
}
//This Function handle the selecetd values from the drop down
handleSelect(event) {
    try{
        BwcUtils.log('In handle Select');
        let recordId = event.currentTarget.dataset.recordId;
        let selectRecord = this.searchRecords.find((item) => {
            return item.Id === recordId;
        });
        BwcUtils.log('selectRecord'+JSON.stringify(selectRecord));
        this.selectedRecord = selectRecord;
        this.dispatchEvent(new CustomEvent('lookup', {
            bubbles: true,
            composed: true,
            cancelable: true,
            detail: {
                data: {
                    record: selectRecord,
                    recordId: recordId,
                    currentRecordId: this.currentRecordId
                }
            }
        }));
    }
    catch (e) {
        BwcUtils.error('Exception Selecting', e);
        throw new Error(this.labels.unexpectedError);
    }
    finally {
        this.isLoading = false;
        }
}
//This Function handle the close icon functionality to remove the email template id and name from communication record
handleClose() {
    try{
        BwcUtils.log('In handle Close');
        this.selectedRecord = undefined;
        this.searchRecords = undefined;
        this.dispatchEvent(new CustomEvent('close', {
            bubbles: true,
            composed: true,
            cancelable: true,
            detail: {
                data: {
                    record: this.selectedRecord,
                    recordId: this.recordId,
                    currentRecordId: this.currentRecordId
                }
            }
        }));
    }
    catch (e) {
        BwcUtils.error('Exception Closing', e);
        throw new Error(this.labels.unexpectedError);
    }
    finally {
        this.isLoading = false;
        }
} 
}
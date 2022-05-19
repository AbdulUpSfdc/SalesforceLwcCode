import { api,  track } from 'lwc';
// Apex
import getEquipmentSummaryDetails from '@salesforce/apex/BWC_EquipmentDetailController.getEquipmentSummaryDetails';

//Other components
import BwcPageElementBase from 'c/bwcPageElementBase';
import * as BwcUtils from 'c/bwcUtils';

// Custom labels
import label_mulesoftErrorCode from '@salesforce/label/c.BWC_UnexpectedError_RefreshSection';
import label_NoDevices from '@salesforce/label/c.BWC_DeviceStatusSummary_NoData';
import label_title from '@salesforce/label/c.BWC_DeviceStatusSummary_Title';

const COLUMNS = [
    { label: 'Phone#', fieldName: 'Phone_Number__c', type:'text',hideDefaultActions: true, sortable: true },
    { label: 'Mobile Status', fieldName: 'Status' , type:'text',hideDefaultActions: true, sortable: true},
    { label: 'Mobile Created', fieldName: 'Mobile_Created_Date__c', type: 'date' ,hideDefaultActions: true,
        typeAttributes: {
            day: "numeric",
            month: "numeric",
            year: "numeric"
        }
    }
];

const COMPONENT_UI_NAME = 'Device Status Summary';

export default class BwcEquipmentSummaryComponent extends BwcPageElementBase {

    // 11-11-2020 fields to use for sorting daatable
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;

    columns = COLUMNS;

    @api recordId
    @track error;
    isLoading

    data = [];
    connectedCallback(){
        this.getSummary();
    }

    onRefresh(){
        this.getSummary();
    }

    getSummary(){
        this.isLoading = true;

        super.clearNotifications();

        getEquipmentSummaryDetails({recordId:this.recordId})
            .then(result => {

                if(!result){
                    this.data = [];
                    super.addInlineNotification(label_NoDevices, 'info');
                    return;

                }

                // Clone to allow changing of phone field
                this.data = BwcUtils.cloneObject(result);


                // Format phone field -- don't use datatable "phone" type because it forces it to be a telephone hyperlink
                if (this.data) {
                    this.data.forEach(record => {
                        record.Phone_Number__c = BwcUtils.formatPhone(record.Phone_Number__c);
                    });
                }

                this.sortData('Phone_Number__c', 'asc');

            })
            .catch(error => {
                this.data = [];
                super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
            }).finally(()=>{
                this.isLoading = false;
            });
    } 

    // 11-11-2020 returns function that compares two rows in the data array using the given field.
    sortBy(field, reverse, primer) {
        const key = primer
            ? function(x) {
                  return primer(x[field]);
              }
            : function(x) {
                  return x[field];
              };

        return function(a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortData(sortedBy, sortDirection);
    }

    // 11-11-2020 sort the data array
    sortData(sortedBy, sortDirection) {
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    get cardTitle(){
        return this.data?.length > 0 ? label_title : `${label_title} (0)`;
    }

    get hasData(){
        return this.data?.length > 0;
    }
}
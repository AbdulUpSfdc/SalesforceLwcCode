import {LightningElement, wire, api} from 'lwc';
import getAuxDetails from '@salesforce/apex/BWC_AuxDetailController.getAuxDetails';
import {refreshApex} from '@salesforce/apex';
import * as BwcUtils from 'c/bwcUtils';

const CARD_TITLE = 'Related Payment History';

export default class BwcRelatedPaymentHistory extends LightningElement {
	@api recordId;
	cardTitle = CARD_TITLE;
	data;
	pmtHistory;
	error;
	isLoading = true;
	pmtHstryGrpd;
	setLength = 9;

	@wire(getAuxDetails, { recordId: '$recordId' })
    wiredAuxDetails({ error, data }) {
        this.isLoading = true;
        if (data) {
			//BwcUtils.log('### DATA ', data);
			this.data = data;
			let dataFiltered = [];
			let dataGrouped = [];
			let item = {};
			let group = undefined;
			let groupAry = [];
			let obj;
			this.data.forEach(e =>{
				if(!group){
					group = e.OrderHint__c.substring(0, 4)
				}
				groupAry.push([e.Name__c, e.Value__c]);
				BwcUtils.log('### GROUP ARRAY LENGTH: ', groupAry.length);
				if(groupAry.length === this.setLength){
					BwcUtils.log('### GROUP ARRAY: ', groupAry);
					dataGrouped.push(Object.fromEntries(groupAry));
					groupAry = [];
				}
				if(group !== e.OrderHint__c.substring(0, 4)){
					BwcUtils.log('### STARTING A NEW GROUP');
					group = e.OrderHint__c.substring(0, 4);
				}
			});
			this.pmtHstryGrpd = dataGrouped;
            this.error = undefined;
			BwcUtils.log('### DATA GROUPED: ', this.pmtHstryGrpd);
        } else if (error) {
            this.error = error;
            this.contacts = undefined;
        }
        this.isLoading = false;
		//BwcUtils.log('### PAYMENT HISTORY ', this.pmtHistory);
    }

	handleRefresh(event){
		//this.isLoading = true;
		refreshApex(this.data);
	}
}
import { LightningElement,track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import UserProfileName from '@salesforce/schema/User.Profile.Name';
import getRetailQueues from '@salesforce/apex/customerUpNextController.getRetailQueues';



const columns = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'Est. wait time', fieldName: 'EstimatedWaitTimeWithMin__c' },
    { label: 'Waiting', fieldName: 'DCITimeWaiting__c' },
    { label: 'Assigned rep', fieldName: 'CustomerRequestedRep__c' },
    { label: 'Check-in type', fieldName: 'DCICheckinType__c' }
];

export default class customerUpNextTable extends LightningElement {
    userId=Id;
    userProfile;
    @track _data = [];
    columns = columns;
    isShowMore=false;
    initialSize=0;
    _userProfile;

    connectedCallback(){
        this.getQueues(this.params);
    }

    @wire(getRecord,{recordId:Id,fields:[UserProfileName]})
    userDetails({error,data}){
        if(error){
            console.log(error);
        }else if(data && data.fields.Profile.displayValue != null ){
            console.log(data.fields.Profile.displayValue);
            this._userProfile=data.fields.Profile.displayValue;
        }
    }

    get params(){
        return { limitVal : 499};
    }
    
    get data(){
        if(this._data.length <= 4 || this.isShowMore){
            this.initialSize=this._data.length;
            return this._data;
        }else{
            this.initialSize=4;
            return this._data.slice(0,4);
        }
    }

    getQueues(params){
        getRetailQueues(params)
        .then(result => {
           console.log(result); 
           //Start by MA SPTSLSATT-1464
           //this._data=result;
           result.forEach(element => {
                var insobj = new Object();
                insobj.Name = element.Name;
                insobj.EstimatedWaitTimeWithMin__c = element.EstimatedWaitTimeWithMin__c;
                insobj.DCITimeWaiting__c = element.DCITimeWaiting__c;
                insobj.CustomerRequestedRep__c = element.CustomerRequestedRep__c;
                insobj.DCICheckinType__c = element.DCICheckinType__c;
                if(element.Lead__r != undefined && element.Lead__r.PreferedLanguage__c != undefined && element.Lead__r.PreferedLanguage__c === 'Espanol') {
                    insobj.spanish = 'ES';
                    insobj.stylecls = 'background:#DBFFA1;color:#080707';             

                }
                this._data.push(insobj);
            });
            //End by MA SPTSLSATT-1464
        })
        .catch(error => {
            console.log(error); 
            // TODO Error handling
        });
    }

    handleclick(evt){
        this.isShowMore=!this.isShowMore;
    }

    get showMoreOrLessLabel(){
        return this.isShowMore ? 'View less': 'View more';
    }

    get showing(){
        return `Showing ${this.initialSize} of ${this._data.length}`;
    }

    get showComponent(){
        console.log('',((this._userProfile === 'Retail RSC Rep' || this._userProfile === 'Retail SM') && this._data.length === 0) ? false:true);
        return ((this._userProfile === 'Retail RSC Rep' || this._userProfile === 'Retail SM') && this._data.length === 0) ? false:true;
    }

    get showViewMore(){
        return (this._data.length > 4) ? true : false;
    }

    
}
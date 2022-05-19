import { LightningElement, api, track } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';

const COLUMNS = [
    { label: 'Line of Business', fieldName: 'lineOfBusiness', sortable:true,  hideDefaultActions: true},
    { label: 'Account', fieldName: 'accountNumber',  hideDefaultActions: true},
    { label: 'Status', fieldName: 'status',  hideDefaultActions: true},
    { label: 'Zip Code', fieldName: 'zipCode',  hideDefaultActions: true},
];

const CANCELED_STATUS = 'Canceled';
const CANCELLED_STATUS = 'Cancelled';
//const CLOSED_STATUS = 'Closed';

const CANCELED_STATUS_LIST = [
    CANCELED_STATUS,
    CANCELLED_STATUS

];

export default class BwcIndividualSelectionRow extends LightningElement {

    isExpanded = false;
    columns = COLUMNS;

    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;

    @track _subscribers = [];
    @track currentSubscribers = [];

    @api individual;

    set subscribers(value){
        const clonedValue = BwcUtils.cloneObject(value);
        this._subscribers = this.sortByDefault(clonedValue);
        this.showCanceledAccounts(false);
    }

    @api get subscribers(){
        return this._subscribers;
    }

    @api expand(value){

        this.isExpanded = value;
    }

    @api showCanceledAccounts(show){

        if(show){
            this.currentSubscribers = this._subscribers;
        }else{
            this.currentSubscribers = this._subscribers.filter( subscriber => !CANCELED_STATUS_LIST.includes(subscriber.status));
        }

    }

    @api get expandValue(){
        return this.isExpanded;
    }

    expandRow(){
        this.isExpanded = !this.isExpanded;

        this.dispatchEvent(new CustomEvent('expand'));
    }

    handleIndividualClick(){

        // TODO: show toast maybe?
        if(!this.currentSubscribers || this.currentSubscribers.length === 0){
            return;
        }

        this.dispatchEvent(new CustomEvent('selectedindividual',
            {
                detail:this.individual.globalId
            }
        ));

    }

    onHandleSort(event){
        const {fieldName: sortedBy, sortDirection} = event.detail;
        const cloneData = [...this.currentSubscribers];

        cloneData.sort( this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.currentSubscribers = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    sortBy(field, reverse, primer){
        const key = primer
            ? (x) => primer(x[field])
            : (x) => x[field] || '';

        return (a, b)=>{
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        }
    }
    /**
     * @param  {Array} subscribers
     * Sorts the subscriber in alphabetical order of Line of business, and in ascending order of Account number
     */
    sortByDefault(subscribers){

        if(!subscribers){
            return [];
        }

        return subscribers.sort((a,b)=>{

            if(a.lineOfBusiness === b.lineOfBusiness){
                return a.accountNumber > b.accountNumber ? 1 : -1;
            }

            return a.lineOfBusiness > b.lineOfBusiness ? 1 : -1;

        });
    }

    get iconName(){
        return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

}
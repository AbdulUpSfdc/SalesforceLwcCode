import { LightningElement, api } from 'lwc';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import * as BwcUtils from 'c/bwcUtils';
import { linkInteractionWithAccount, accountDetails } from 'c/bwcUnifiedSearchServices';

const UVERSE_LOB = 'Uverse';
export default class BwcIndividualSelection extends LightningElement {

    @api individuals;
    @api searchMode;
    @api searchTerm;
    @api recordId;

    isLoading=false;

    showCanceledAccounts = false;

    isExpanded = false;

    handleExpand(){

        const rows = this.template.querySelectorAll('c-bwc-individual-selection-row');

        let openRows = 0;
        rows.forEach(row=>{
            openRows = row.expandValue ? openRows+1 : openRows;
        });

        this.isExpanded = openRows>=1;

    }

    expandRows(){

        this.isExpanded = !this.isExpanded;

        const rows = this.template.querySelectorAll('c-bwc-individual-selection-row');

        rows.forEach(row=>{
            row.expand(this.isExpanded);
        });
    }

    
    /** This method will notify bwcUnifiedSearch to perform a new search using the individual Id of the selected entry
     * @param  {Object} event
     */
    async handleSelectedIndividual(event){

        BwcUtils.log('event received', event.detail);
        const individualId = event.detail;

        this.dispatchEvent(new CustomEvent('individualsearch',
            {
                detail: individualId
            }
        ));

    }

    async handleCanceledAccounts(event){

        this.showCanceledAccounts = event.detail.checked;

        const rows = this.template.querySelectorAll('c-bwc-individual-selection-row');

        rows.forEach(row=>{
            row.showCanceledAccounts(this.showCanceledAccounts);
        });
    }

    handleNewSearch(){
        this.dispatchEvent(new CustomEvent('newsearch', {
            detail:{
                clear: true
            }
        }));
    }

    get expandLabel(){
        return this.isExpanded ? 'Collapse All' : 'Expand All' ;
    }

    get results(){
        return `${this.individuals?.length} Results`;
    }

    get searchTermLabel(){
        return this.searchMode === 'phoneNumber' ? BwcUtils.formatPhone(this.searchTerm) : this.searchTerm;
    }
}
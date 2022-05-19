import { LightningElement, api, track } from 'lwc';
import search from '@salesforce/apex/ReusableComponentSearchBarController.search';
import { NavigationMixin } from 'lightning/navigation';

export default class ReusableComponentSearchBar extends NavigationMixin(LightningElement) {
    @api objName;
    @api iconName;
    @api labelName;
    @api placeholder = 'Search';
    @api useExternalSearch = false;

    @api 
    get results(){
        return this.searchRecords;
    }
    set results(value){
        this.searchRecords = JSON.parse(JSON.stringify(value));
        //this.setAttribute('externalResults', value);
    }

    //debounce delay in milliseconds
    @api delay = 300;
    //must be lists
    @api fields;
    @api displayFields; //max 3

    @track searchRecords;
    @track selectedRecord = {};
    @track isLoading = false;
    delayTimeout;
    field0;
    field1;
    field2;

    connectedCallback(){
        this.field0 = this.displayFields[0];
        if(this.displayFields.length > 1){
            this.field1 = this.displayFields[1];
        }
        if(this.displayFields.length > 2){
            this.field2 = this.displayFields[2];
        }
    }

    renderedCallback(){
        if(this.searchRecords){
            this.createFieldKeys();
            this.isLoading = false;
        }
    }

    handleChange(event){
        window.clearTimeout(this.delayTimeout);
        const searchTerm = this.template.querySelector('[data-source="searchInputField"]').value;
        this.delayTimeout = setTimeout(() => {
            if(searchTerm.length >= 2){
                this.isLoading = true;
                const dropdown = this.template.querySelector('.slds-dropdown_fluid');
                this.showElement(dropdown);
                if(this.useExternalSearch){
                    let searchKey = new CustomEvent('externalsearch', { detail: searchTerm });
                    this.dispatchEvent(searchKey);
                }
                else{
                    search({ 
                        objectName : this.objName,
                        fields     : this.fields,
                        searchTerm : searchTerm 
                    })
                    .then((result) => {
                        this.searchRecords = result;

                        this.createFieldKeys();

                        this.isLoading = false;
                    })
                    .catch((error) => {
                        console.log(error);
                        this.isLoading = false;
                    })
                }
            }
            else{
                const dropdown = this.template.querySelector('.slds-dropdown_fluid');
                this.hideElement(dropdown);
            }
        }, this.delay)    
    }

    handleSelect(event){    
        let recordId = event.currentTarget.getAttribute("data-record-id");
        let selectRecord = this.searchRecords.find((item) => {return item.Id == recordId});
        this.selectedRecord = JSON.parse(JSON.stringify(selectRecord));

        this.searchRecords = undefined;

        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        this.hideElement(searchBoxWrapper);

        const pillDiv = this.template.querySelector('.pillDiv');
        this.showElement(pillDiv);
    }

    handleRemove(){
        this.selectedRecord = {};
        this.dispatchEvent(new CustomEvent('clearselection'));
        const inputField = this.template.querySelector('[data-source="searchInputField"]');
        inputField.value = '';

        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        this.showElement(searchBoxWrapper);
   
        const pillDiv = this.template.querySelector('.pillDiv');
        this.hideElement(pillDiv);
    }

    recordNavigate(){
        if(!this.useExternalSearch){
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    actionName: 'view',
                    objectApiName: this.objName,
                    recordId: this.selectedRecord.Id
                }
            })
        }
        else{
            const selectedEvent = new CustomEvent('selectrecord', {
                bubbles    : true,
                composed   : true,
                cancelable : true,
                detail: {  
                    data : {
                        record : this.selectedRecord,
                        recordId : this.selectedRecord.Id,
                    }
                }
            });
            this.dispatchEvent(selectedEvent);
        }
    }

    createFieldKeys(){
        this.searchRecords.forEach(record => {
            record.field0 = record[this.field0];
            if(this.displayFields.length>1){
                record.field1 = record[this.field1];
            }
            if(this.displayFields.length>2){
                record.field2 = record[this.field2];
            }
        });
    }

    showElement(element){
        element.classList.remove('slds-hide');
        element.classList.add('slds-show');
    }

    hideElement(element){
        element.classList.add('slds-hide');
        element.classList.remove('slds-show');
    }
}
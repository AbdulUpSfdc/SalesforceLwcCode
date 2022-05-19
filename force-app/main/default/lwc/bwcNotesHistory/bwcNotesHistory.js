import { LightningElement, track, api } from 'lwc';
import * as BwcNoteSearchServices from 'c/bwcNotesSearchServices';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcInteractionServices from "c/bwcInteractionServices";
import * as BwcAuthorizationServices from 'c/bwcAuthorizationServices';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcLabelServices from 'c/bwcLabelServices';
import * as BwcUtils from 'c/bwcUtils';
// Labels
import label_onlyViewingAuth from '@salesforce/label/c.BWC_NotesHistory_OnlyViewingAuth';

const PAGE_SIZE = 50;
const SOURCE_OPTIONS = [
    {
        value: "OPUS",
        label: "OPUS"
    },
    {
        value: "TELEGENCE",
        label: "Mobility - Telegence"
    },
    {
        value: "ENABLER",
        label: "Video/Broadband - Enabler"
    },
    {
        value: "BIBA",
        label: "Video/BB Adjustments - BIBA"
    },
    {
        value: "CRM-CLARIFY",
        label: "Mobility - CRM – Clarify"
    },
    {
        value: "SALESFORCE",
        label: "AT&T Customer Connect"
    }
];

const ACCOUNT_TYPE_MAP = 
[
    BwcConstants.BillingAccountType.WIRELESS,
    BwcConstants.BillingAccountType.UVERSE,
    BwcConstants.BillingAccountType.DTVNOW,
    BwcConstants.BillingAccountType.DTVS,
    BwcConstants.BillingAccountType.WATCHTV,
    BwcConstants.BillingAccountType.DTV,
    BwcConstants.BillingAccountType.POTS
]


export default class BwcNotesHistory extends LightningElement {

    // Labels
    labels = BwcLabelServices.labels;

    @api recordId;

    interactionRecord;

    initialized;
    userTypeFilter = 'All';
    isBusy = true;
    isLoaded = false;
    isLoadingMore = false;
    totalCount = 0;
    currentPageNumber = 0;
    allExpanded = false;
    hasL0Bans;
    @track errors = [];
    @track allNotes = [];
    @track displayedNotes = [];
    get authMessageLeft() {return label_onlyViewingAuth.substring(0, label_onlyViewingAuth.indexOf('{0}'));}
    get authMessageRight() {return label_onlyViewingAuth.substring(label_onlyViewingAuth.indexOf('{0}') + 3);}
    get noResults() {return this.isLoaded && this.displayedNotes.length === 0;}
    get showResults() {return this.isLoaded && this.displayedNotes.length > 0;}
    get errorReports() {return this.template.querySelector('c-bwc-error-reports');}
    get isMoreNotes() {return this.allNotes.length < this.totalCount;}
    get showLoadMore() {return this.isMoreNotes && !this.isLoadingMore;}
    get expandCollapseText() {return this.allExpanded ? 'Collapse All' : 'Expand All';}
    boxClass= '';

    sourceOptions = SOURCE_OPTIONS;

    banOptions //= BAN_OPTIONS;

    interactions =[];

    copyOfInteractions = [];

    openfilter= false;

    banTypeMap = {};

    @track noteFilterParams = 
    {
        bans: [],
        appIds: [],
        createdTimeStart: null,
        createdTimeEnd: null
    }

    get startJsDate()
    {
        return this.getDate(this.noteFilterParams.createdTimeStart);
    }

    get endJsDate()
    {
        return this.getDate(this.noteFilterParams.createdTimeEnd);
    }

    onSourceSelected(event)
    {
        this.noteFilterParams.appIds = event.detail.selected;
    }

    onBanSelected(event)
    {
        this.noteFilterParams.bans = event.detail.selected;
    }

    hidefiltermodal() {
        this.openfilter = false;
    }

    displayfiltermodal(event) {
        this.openfilter = !this.openfilter;
        let left = event.clientX;
        let top=event.clientY;
        this.boxClass = `top:${top - 381}px; left:${left - 294}px`;
    }

    handleStepUp() {
 
        this.stepUp();
        
    }

    handleChange(event) {
        if (event.target.dataset.id === "startDate") {
            this.noteFilterParams.createdTimeStart = event.detail.value ? `${event.detail.value}T00:00:00 UTC` : '';
        }
        if (event.target.dataset.id === "endDate") {
            this.noteFilterParams.createdTimeEnd = event.detail.value ? `${event.detail.value}T23:59:59 UTC` : '';
        }
    }

        /**
     * clear filter button handler for clearing all the filters which are selected on UI.
     * @param {*} event 
     */
    clearFilters(event)
    {
        this.noteFilterParams.appIds = [];
        this.noteFilterParams.bans = [];
        this.noteFilterParams.createdTimeStart = '';
        this.noteFilterParams.createdTimeEnd = '';
        let children = this.template.querySelectorAll("c-bwc-checkbox-list");
        if(children != null && children.length > 0)
        {
            children.forEach(child => child && child.resetFilterOptions());
        }
        this.noteFilterParams = JSON.parse(JSON.stringify(this.noteFilterParams));
        //this.handleSearch(event, false);
    }

        /**
     * 
     */
    addBan(event)
    {
        let newBan = event.detail;
        this.banOptions.push(newBan);
    }

    /**
     * @return javascript date object
     * @param {String} dateString could be string of yyyy-mm-dd 
     */
    getDate(dateString)
    {
        if(dateString != null && dateString.length > 0)
        {
            let dateArr = dateString.substring(0,10).split('-').map(d=>parseInt(d));
            let d = new Date(dateArr[0], dateArr[1] - 1, dateArr[2]);
            return d;
        }
    }


    async renderedCallback() {

        if (!this.initialized) {

            this.initialized = true;

            try {

                this.errorReports.clearErrors();
                await this.refresh();
                await this.initializeBanList();
    
            }
            catch (error) {
                this.errorReports.addError(error);
            }

        }

    }

    /*
        Fill list of bans for filter.
    */
    async initializeBanList() {

        let bans =  await BwcAccountServices.getBillingAccounts(this.recordId, true);
        this.banOptions = bans.map(ban=>
        {
            let type = ACCOUNT_TYPE_MAP.find(accountType => accountType.value === ban.Account_Type__c);
            let option = {label: `${ban.Billing_Account_Number__c} ${ (type != null) ? '-' + type.label :''}`, value:ban.Billing_Account_Number__c};
            return option;
        });

    }

    /**
     * Method filters the data according to the selected filters
     * @param {*} event 
     */
    handleSearch(event,hideModel = true)
    {

        if(hideModel) this.hidefiltermodal();

        this.refresh(false);
    }

    /*
        Re-query the server for notes.
    */
    async refresh(loadMore) {

        try {

            if (!loadMore) {
                this.isLoaded = false;
                this.isBusy = true;
                this.currentPageNumber = 0;
                this.allExpanded = false;
            }
            else {
                this.isLoadingMore = true;
            }

            this.errorReports.clearErrors();

            // Get interaction record to determine L0/L1
            this.interactionRecord = await BwcInteractionServices.getInteraction(this.recordId);

            // Determine if any L0 bans
            this.hasL0Bans = BwcAuthorizationServices.hasL0Bans(this.interactionRecord.Authorization_Json__c ? JSON.parse(this.interactionRecord.Authorization_Json__c) : false);

            let filterParams = JSON.parse(JSON.stringify(this.noteFilterParams));
            filterParams.bans = this.noteFilterParams.bans.map(ban=>({accountType:this.banTypeMap[ban] != null?this.banTypeMap[ban].toLocaleLowerCase():'wireless',accountNumber:ban}));
            const notesSearchRequest = {

                notePaginationParams: {
                    pageSize: PAGE_SIZE,
                    pageNumber: this.currentPageNumber + 1
                },
                noteFilterParams: filterParams

            };

            // Do the search
          
           const responseWrapper = await BwcNoteSearchServices.getNotesSearch(this.recordId, notesSearchRequest);
            
            const response = responseWrapper;
            this.totalCount = response.totalCount;
            this.currentPageNumber++;

            // Check payload for errors
            if (response.additionalInfoArray) {
                response.additionalInfoArray.forEach(item => {
                    this.errorReports.addError(new Error('Search Error: ' + item.key), item.value);
                })
            }

            const retrievedNotes = responseWrapper.notes;

            // Enrich data rows
            retrievedNotes.forEach(note => {

                note.formattedDatetime = this.getFormattedDatetime(note.createdTime);
                note.title = note.noteBody ? note.noteBody.replaceAll('<br>', ' ') : '';    
                switch (note.createdByUserType) {

                    case 'System':
                        note.iconName = 'custom:custom27';
                        note.iconTitle = 'Created by System';
                        note.formattedUserDatetime = this.getFormattedDatetime(note.createdTime);
                        break;

                    case 'Agent':
                        note.iconName = 'standard:user';
                        note.iconTitle = 'Created by Agent';
                        note.formattedUserDatetime = `${note.createdByUserId ? note.createdByUserId + ' |' : ''} ${this.getFormattedDatetime(note.createdTime)}`;
                        break;

                    default:
                        console.error('Unexpected createdByUserType: ' + note.createdByUserType);
                        break;

                }

            });

            if (!loadMore) {
                // First load -- replace existing
                this.allNotes = retrievedNotes;
            }
            else {
                // Loading more -- append to existing
                this.allNotes = this.allNotes.concat(retrievedNotes);
            }

            // Filter to match the selected filter tab
            this.filterByUserType();

            this.isLoaded = true;

        }
        catch(error) {
            this.errorReports.addError(new Error('Error retrieving notes'), error);           
        }
        finally {
            this.isBusy = false;
            this.isLoadingMore = false;
        }

    }

    /*
        Refilter all notes by the selected type.
    */
    async filterByUserType() {

        if (this.userTypeFilter === 'All') {
            this.displayedNotes = this.allNotes;
        }
        else {
            this.displayedNotes = this.allNotes.filter(note => note.createdByUserType === this.userTypeFilter);
        }

        // var banOptionMap={};
        // this.displayedNotes.forEach(i=>
        //     {
        //         let type = i.accountType;
        //         banOptionMap[i.ban] = {value: i.ban, label: `${i.ban} - ${ (type != null && type.length > 0 )? type.charAt(0).toUpperCase() + type.slice(1):''}`}
        //         this.banTypeMap[i.ban] = type;//.toLocaleUpperCase();
        //     })
        


    }

    /*
        Format Date | Time for display in timeline.
    */
    getFormattedDatetime(noteTimeString) {

        const datetime = new Date(Date.parse(noteTimeString.replace(' UTC', 'Z')));

        const timeString = datetime.toLocaleTimeString([], {timeStyle: "short"});
        const dateString = datetime.toLocaleDateString();
        const today = (new Date()).toLocaleDateString();

        return `${timeString} | ${dateString === today ? 'Today' : dateString}`;

    }

    /*
        Refresh button.
    */
    handleRefresh() {

        this.refresh();

    }

    /*
        Tab switches filtering of the results (doesn't really display different tabs).
    */
    handleTabActive(event) {

        this.userTypeFilter = event.target.value;
        this.filterByUserType();

    }

    /*
        Expand or collapse one note.
    */
    handleSwitchClick(event) {

        // Get the div with slds-is-open class
        const div = this.template.querySelector(`div[data-note-index="${event.target.dataset.noteIndex}"]`);

        if (div.classList.contains('slds-is-open')) {
            div.classList.remove('slds-is-open');
            event.target.iconName = 'utility:chevronright';
        }
        else {
            div.classList.add('slds-is-open');
            event.target.iconName = 'utility:chevrondown';
        }

    }

    /*
        Load more notes.
    */
    handleLoadMore() {
        this.refresh(true);
    }

    /*
        Expand all or collapse all
    */
    handleExpandCollapseAll() {

        this.allExpanded = !this.allExpanded;

        Array.from(this.template.querySelectorAll(`div[data-note-index]`)).forEach(noteDiv => {

            if (this.allExpanded) {
                noteDiv.classList.add('slds-is-open');
            }
            else {
                noteDiv.classList.remove('slds-is-open');
            }

        });

        Array.from(this.template.querySelectorAll(`lightning-button-icon[data-note-index]`)).forEach(buttonIcon => {

            if (this.allExpanded) {
                buttonIcon.iconName = 'utility:chevrondown';
            }
            else {
                buttonIcon.iconName = 'utility:chevronright';
            }

        });

    }

    /*
        Initiate step-up authentication.
    */
    stepUp() {

        try {


            // Open the step-up modal
            // Even if there are no step-ups, we'll let the modal give that information
            this.template.querySelector('c-bwc-step-up').open(this.recordId, undefined, undefined, undefined, async steppedUpBans => {

                this.refresh();
                this.initializeBanList();

            });

        }
        catch(error) {

            throw new Error(error);

        }

    }

}
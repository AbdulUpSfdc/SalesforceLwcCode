import { api, track } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import * as bwcLICPublisher from 'c/bwcMsgToLICPublisher';
import * as BwcInteractionServices from 'c/bwcInteractionServices';
import * as BwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';
import * as BwcLabelServices from 'c/bwcLabelServices';
import accountSearch from '@salesforce/apexContinuation/BWC_CustomerSearchController.accountSearchCont';
import { cbrSearch } from 'c/bwcCustomerSearchServices';
import BwcError from 'c/bwcError';

// Custom labels
import label_zipAStMand from '@salesforce/label/c.BWC_CustomerSearchError_ZipAStMand';
import label_plsPopBan from '@salesforce/label/c.BWC_CustomerSearchError_PlsPopBan';
import label_plsSelAcctTyp from '@salesforce/label/c.BWC_CustomerSearchError_PlsSelAcctTyp';
import label_manualSearch from '@salesforce/label/c.BWC_Interaction_ManualSearchRequired';
import label_errWhilSear from '@salesforce/label/c.BWC_CustomerSearchError_ErrWhilSear';
import label_BanNotInOrder from '@salesforce/label/c.BWC_CustomerSearchError_BANNotInOrder';

const METHOD_AUTHENTICATION_MAPPING = {
    banWithAccountType: 'BAN',
    wirelessNumber: 'PHONE',
    phoneNumber: 'PHONE',
    userId: 'ATT_LOGIN_ID',
    address: 'ADDRESS',
    addressId: 'ADDRESS',
    orderId: 'ORDER_ID',
}

const BAN_WITH_ACCOUNT_TYPE_MODE = 'banWithAccountType';

export default class BwcCustomerSearch extends BwcPageElementBase {

    // Expose the labels to use in the template.
    labels = BwcLabelServices.labels;

    // Columns for multiple account results
    accountColumns = [
        {
            label: 'Account',
            fieldName: 'accountNumber', type: 'button', hideDefaultActions: true,
            typeAttributes: {
                variant: 'base',
                label: {fieldName: 'accountNumber'}
            },
            cellAttributes: {
                style : 'transform: scale(0.75);'
            }
        },
        { label: 'Line of Business', fieldName: 'lob', type: 'text' ,hideDefaultActions: true},
        { label: 'Status', fieldName: 'status', type: 'text' ,hideDefaultActions: true},
        { label: 'Zip Code', fieldName: 'zipCode', type: 'text',hideDefaultActions: true ,sortable: true},
        { label: 'Name', fieldName: 'name', type: 'text',hideDefaultActions: true },
        { label: 'Email', fieldName: 'email', type: 'text',hideDefaultActions: true },
        { label: 'Phone', fieldName: 'phoneNumber', type: 'text' ,hideDefaultActions: true},
    ];

    // Columns for multiple address results
    addressColumns = [
        {
            label: 'STREET ADDRESS', 
            fieldName: 'addressLine1', type: 'button', hideDefaultActions: true,
            typeAttributes: {
                variant: 'base',
                label: {fieldName: 'addressLine1'}
            },
            cellAttributes: {
                style : 'transform: scale(0.75);'
            }
        },
        { label: 'ADDRESS2', fieldName: 'addressLine2', type: 'text', hideDefaultActions: true},
        { label: 'CITY', fieldName: 'city', type: 'text' , hideDefaultActions: true},
        { label: 'STATE', fieldName: 'state', type: 'text', hideDefaultActions: true},
        { label: 'ZIP', fieldName: 'zip', type: 'text', hideDefaultActions: true },
        { label: 'COUNTRY', fieldName: 'country', type: 'text', hideDefaultActions: true },
    ];

    @api recordId           // This is the Interaction ID
    @api objectApiName;
    @api caseId;            // CaseId is set when this lwc is used on Case object

    isRendered = false;
    isLoading = false;

    // Display mode = search, accounts, addresses
    displayMode = 'search';
    get showSearch() {return this.displayMode === 'search';}
    get showAccounts() {return this.displayMode === 'accounts';}
    get showAddresses() {return this.displayMode === 'addresses';}

    // messages when too short or too long
    get messageWhenTooShort() {return `${this.labels.account} must be at least 7 characters.`;}
    get messageWhenTooLong() {return `${this.labels.account} can be no more than 15 characters.`;}

    // Account type combo box
    get acctTypeOptions() {
        return [
            { label: 'Select an Account Type', value: '' },
            BwcConstants.BillingAccountType.WIRELESS,
            BwcConstants.BillingAccountType.UVERSE,
            BwcConstants.BillingAccountType.DTVNOW,
            BwcConstants.BillingAccountType.DTV,
            BwcConstants.BillingAccountType.POTS,
            BwcConstants.BillingAccountType.WATCHTV
        ];
    }

    // State combo box
    get stateOptions() {return BwcConstants.StateOptions;}

    // Input values
    ban;
    accountType;
    wirelessNumber;
    phoneNumber;
    attLoginId;
    streetAddress;
    aptUnitNo;
    city;
    state;
    zipCode;
    addressId;          // Not shown as input, but used as search input for address search
    orderId;

    // Search mode: banWithAccountType, wirelessNumber, phoneNumber, userId, address
    get searchMode() {

        if (this.ban || this.accountType) {
            return 'banWithAccountType';
        }
        if (this.wirelessNumber) {
            return 'wirelessNumber';
        }
        if (this.phoneNumber) {
            return 'phoneNumber';
        }
        if (this.attLoginId) {
            return 'userId';
        }
        if (this.streetAddress || this.aptUnitNo || this.city || this.state || this.zipCode) {
            return 'address';
        }
        if (this.addressId) {
            return 'addressId';
        }
        if(this.orderId){
            return 'orderId'
        }
        return 'clear';

    }

    // Provides short label to describe the search in a message.
    get searchModeLabel() {

        switch (this.searchMode) {

            case 'banWithAccountType':
                return `${this.labels.account} ${this.ban} (${BwcConstants.BillingAccountType.getLabelForValue(this.accountType)})`;

            case 'address':
            case 'addressId':
                return 'the address';

            case 'userId':
                return this.attLoginId;

            default:
                // The other modes have the same name as the single value, so just return it.
                return this[this.searchMode];

        }

    }

    // Disable getters based on search mode
    get disableBan() {return this.searchMode !== 'clear' && this.searchMode !== 'banWithAccountType';}
    get disableWirelessNumber() {return this.searchMode !== 'clear' && this.searchMode !== 'wirelessNumber';}
    get disablePhoneNumber() {return this.searchMode !== 'clear' && this.searchMode !== 'phoneNumber';}
    get disableAttLoginId() {return this.searchMode !== 'clear' && this.searchMode !== 'userId';}
    get disableAddress() {return this.searchMode !== 'clear' && this.searchMode !== 'address';}
    get disableSearch() {return this.searchMode === 'clear';}
    get disableOrderId() {return this.searchMode!== 'clear' && this.searchMode !== 'orderId'; }

    @track accountData; // When search returns one or more accounts
    @track addressData; // When search returns multiple addresses for address search

    /*
        Initialize on first render.
    */
    async renderedCallback() {

        if (!this.isRendered) {

            this.isRendered = true;

            try {

                this.clear();

                if (this.recordId) {

                    const interactionRecord = await BwcInteractionServices.getInteraction(this.recordId);
                    if (!interactionRecord.Is_Manual_Search__c) {

                        if (interactionRecord.User_Order_Num__c && !interactionRecord.User_Account_Number__c) {

                            // IVR set an order number but not a BAN, show special notification
                            super.addScopedNotification(label_BanNotInOrder, 'info', 'alert');

                        }
                        else {

                            // Show message indicating manual search is required
                            super.addInlineNotification(label_manualSearch);

                        }

                    }
        
                }

            }
            catch (error) {
                super.handleError(error);
            }

        }

    }

    /*
        Clear all values and reset all errors and messages.
    */
    async clear() {

        // Clear all values
        this.ban = undefined;
        this.accountType = undefined;
        this.wirelessNumber = undefined;
        this.phoneNumber = undefined;
        this.attLoginId = undefined;
        this.streetAddress = undefined;
        this.aptUnitNo = undefined;
        this.city = undefined;
        this.state = undefined;
        this.zipCode = undefined;
        this.addressId = undefined;
        this.orderId = undefined;

        // Allow the reset values to render into the inputs
        await BwcUtils.nextTick();

        super.clearNotifications();

        // Reset all validity
        this.template.querySelectorAll('lightning-input, lightning-combobox').forEach(component => {
            component.value = undefined;
            component.setCustomValidity('');
            component.reportValidity();
        });

    }

    /*
        Validate that the current search mode is ready to search.
    */
    validate() {

        let isValid = true;

        // Run built-in validation on all enabled inputs
        this.template.querySelectorAll('lightning-input, lightning-combobox').forEach(component => {
            if (!component.disabled) {
                const i = component.reportValidity();
                isValid = isValid && i;
            }
        });

        switch (this.searchMode) {

            case 'banWithAccountType':
                if (!this.ban) {
                    this.setCustomValidity('ban', label_plsPopBan);
                    isValid = false;
                }
                if (!this.accountType) {
                    this.setCustomValidity('accountType', label_plsSelAcctTyp);
                    isValid = false;
                }
                break;

            case 'address':
                if (!this.streetAddress) {
                    this.setCustomValidity('streetAddress', label_zipAStMand);
                    isValid = false;
                }
                if (!this.zipCode) {
                    this.setCustomValidity('zipCode', label_zipAStMand);
                    isValid = false;
                }
                break;

            default:
                // Other search modes have only one field and no custom validation
                break;

        }

        return isValid;

    }

    /*
        Helper to set and display custom validity on a specified component.
    */
    setCustomValidity(componentId, message) {

        const component = this.template.querySelector(`[data-id="${componentId}"]`);
        if (component) {
            component.setCustomValidity(message);
            component.reportValidity();
        }
        else {
            throw new Error('Component not found: ' + componentId);
        }

    }

    /*
        Calls the server to perform the search.
    */
    async doSearch() {

        let banFound = '';
        let success = true;
        try {

            this.isLoading = true;

            if(this.searchMode === 'phoneNumber'){
                const searchResponse = await cbrSearch(this.recordId, BwcUtils.parsePhoneToDigits(this.phoneNumber));

                await this.processCBRResponse(searchResponse);
                return;
            }

            // Prepare search parameters
            const searchRequest = {
                ban: this.ban,
                phoneNumber: this.searchMode === 'wirelessNumber' ? BwcUtils.parsePhoneToDigits(this.wirelessNumber) : (this.searchMode === 'phoneNumber' ? BwcUtils.parsePhoneToDigits(this.phoneNumber) : undefined),
                accountType: this.accountType,
                userId: this.attLoginId,
                addressId: this.addressId,
                addressLine1: this.streetAddress,
                addressLine2: this.aptUnitNo,
                city: this.city,
                state: this.state,
                zip: this.zipCode,
                orderId: this.orderId,
            };

            // Searching with BAN after searching with phone
            if(this.searchMode === BAN_WITH_ACCOUNT_TYPE_MODE && this.phoneNumber){

                searchRequest.mode = BAN_WITH_ACCOUNT_TYPE_MODE;

                // Setting these to null so searchMode getter is now phoneNumber and phoneNumber field remains editable
                this.ban = null;
                this.accountType = null;

            }else{

                // Set searchmode as usual
                searchRequest.mode = this.searchMode === 'wirelessNumber' ? 'phoneNumber' : this.searchMode;
            }


            // Search
            const searchResponse = await this.accountSearch(searchRequest);

            if (searchResponse.accountResponses) {

                // Zero, one, or multiple accounts were returned

                this.accountData = searchResponse.accountResponses;

                if (searchResponse.accountResponseCount === 0) {

                    this.showEmptyResults();
                    success = false;

                }
                else if (searchResponse.accountResponseCount === 1) {

                    // Single account found

                    if (this.objectApiName === 'Interaction__c') {

                        // Customer should be set on the interaction -- reload
                        getRecordNotifyChange([{recordId: this.recordId}]);
                        bwcLICPublisher.publishMessage('INIT','','');
                        super.sendLmsRefresh(this.recordId, 'customerSearch');

                        banFound = searchResponse.rawResponse?.[0]?.accountHeader?.ban;

                    }
                    else if (this.caseId) {

                        // 10-02-2020 caseId is defined , so fire recordfound event
                        this.accountData[0].searchInputBAN = this.banFieldValue;
                        this.dispatchEvent(new CustomEvent('recordfound', {detail: { account: this.accountData[0]}}));

                    }

                }
                else {

                    // Multiple accounts found, show the accounts table
                    this.accountData.forEach(account => {
                        account.accountTypeLabel = BwcConstants.BillingAccountType.getLabelForValue(account.accountType);
                    });
                    this.displayMode = 'accounts';

                }
            }
            else if (searchResponse.addressesResponse) {

                this.addressData = searchResponse.addressesResponse.addresses;
                this.addressTitle = `Search Result for ${this.streetAddress || ''} ${this.aptUnitNo || ''} ${this.city || ''} ${this.state || ''} ${this.zipCode || ''}`;
                this.displayMode = 'addresses';

            }
            else {

                throw new Error('No accounts or address responses were returned.');

            }

        }
        catch (error) {

            BwcUtils.error(error instanceof Error ? error : JSON.stringify(error));

            super.addScopedNotification(label_errWhilSear);
            success = false;

        }
        finally {
            this.createInteractionActivity(success, banFound);
            this.isLoading = false;
        }

    }

    /*
        Make the API call to search.
    */
    async accountSearch(searchRequest) {
        
        const recordId = this.caseId ? this.caseId : this.recordId;
        const searchRequestJson = JSON.stringify(searchRequest);
        BwcUtils.log(`call accountSearch: recordId: ${recordId} requestJson: ${searchRequestJson}`);

        // Make the server call
        try {

            const searchResponseJson = await accountSearch({recordId: recordId, requestJson: searchRequestJson});
            BwcUtils.log('result accountSearch: ' + searchResponseJson);
            const searchResponse = JSON.parse(searchResponseJson);
            return searchResponse;

        }
        catch(error) {

            throw BwcError.convertError(error);

        }

    }

    /** Method that creates an interaction activity when a customer search is performed
     * @param  {} success. Boolean value that indicates the API call for the customer search was successful
     * @param  {} billingAccountNumber. BAN of the account that was found
     */
    createInteractionActivity(success, billingAccountNumber){

        const action = BwcConstants.InteractionActivityValueMapping.CustomerSearch.action;

        const intActPayload = {
            recordId: this.recordId,
            ban: billingAccountNumber,
            methodOfSearch: METHOD_AUTHENTICATION_MAPPING[this.searchMode],
            accountType: this.accountType,
            valueOfSearch: this.searchValue,
            status: success ? 'success':'failed'
        };

        const intActPayloadStr = JSON.stringify(intActPayload, BwcUtils.supressNullsJson);

        BwcInteractActivityPublisher.publishMessage(this.recordId, action, intActPayloadStr);
    }

    async processCBRResponse(response){

        // Only one person with associated accounts was found
        if(response.performSearch){

            // Sort accounts by type, wireless, uverse, etc..
            const sortedAccounts = response.accounts.sort((a,b) =>{

                let accTypeA = a.accountType.toLowerCase();
                let accTypeB = b.accountType.toLowerCase();
                if (accTypeA < accTypeB) {
                  return 1;
                }
                if (accTypeA > accTypeB) {
                  return -1;
                }

                return 0;
            });

            // Take first account. Will take wireless if any, otherwise uverse, else any other account
            const account = sortedAccounts[0];
            this.ban = account.ban;
            this.accountType = account.accountType;
            super.clearNotifications();
            await this.doSearch();
            return;
        }

        if(!response.accounts || response.accounts.length === 0){
            this.showEmptyResults();
            return;
        }

        this.displayMode = 'accounts';
        this.accountData = response.accounts;
    }

    showEmptyResults(){
        // Nothing found
        const label = `There were no results found for ${this.searchModeLabel}. <span class="slds-text-color_error">Please try your search again.</span>`;

        let errorMessage = this.orderId ? label_BanNotInOrder : label;
        super.addInlineNotification(errorMessage);
    }

    get searchValue(){

        let searchValue = '';
        switch (this.searchMode) {
            case 'banWithAccountType':
                searchValue = this.ban;
                break;
            case 'wirelessNumber':
                searchValue = BwcUtils.parsePhoneToDigits(this.wirelessNumber);
                break;
            case 'phoneNumber':
                searchValue = BwcUtils.parsePhoneToDigits(this.phoneNumber);
                break;
            case 'userId':
                searchValue = this.attLoginId;
                break;
            case 'address':
                searchValue = `${this.streetAddress || ''} ${this.aptUnitNo || ''} ${this.city || ''} ${this.state || ''} ${this.zipCode || ''}`;
                break;
            case 'orderId':
                searchValue = this.orderId;
                break;
            default:
                searchValue = 'Unknown search mode';
                break;
        }

        return searchValue;
    }

    /*
        Change to any input control.
    */
    handleInputChange(event) {

        // Property names match component ID, so set value
        this[event.target.dataset.id] = event.target.value.trim();
        
        // Reset any error
        event.target.setCustomValidity('');

        switch (event.target.dataset.id) {
            
            case 'ban':

                if (!this.ban && this.accountType) {
                    this.accountType = undefined;
                }
                else if (this.ban && !this.accountType) {
                    this.accountType = 'wireless';
                }

                this.template.querySelector('[data-id="accountType"]').value=this.accountType;
                break;
    
            default:
                break;

        }

    }

    /*
        Handle validation after tab-off field.
    */
    handleInputCommit(event) {

        switch (event.target.dataset.id) {

            case 'wirelessNumber':
            case 'phoneNumber':
            
                if (BwcUtils.validatePhone(event.target)) {
                    this[event.target.dataset.id] = BwcUtils.formatPhone(event.target.value);
                }
                else {
                    event.target.reportValidity();
                }
                break;
            case 'orderId':
                if(BwcUtils.validateOrderId(event.target)){
                    this[event.target.dataset.id] = event.target.value;
                }
                event.target.reportValidity();

                break;
            default:
                break;

        }

    }

    /*
        Clear button.
    */
    handleClear(){
        this.clear();
    }

    /*
        Search button.
    */
    handleSearch() {

        try {

            let isValidated = this.validate();
            if(isValidated){
                super.clearNotifications();
                this.doSearch();
            }

        }
        catch (error) {
            super.handleError(error);
        }

    }

    handleNewSearch(){
        this.clear();
        this.displayMode = 'search';
    }

    /*
        Clicked on Account. Search by its ban and accountType to get the single account.
    */
    handleAccountRowAction(event){

        const row = event.detail.row;

        // Clean all search inputs
        this.clear();

        // Search by ban and account type
        this.ban = row.ban;
        this.accountType = row.accountType;
        super.clearNotifications();
        this.doSearch();

    }

    /*
        Clicked on address. Search by its addressId to get the single account.
    */
    handleAddressRowAction(event){

        const row = event.detail.row;

        // Clean all search inputs
        this.clear();

        // Search by addressId
        this.addressId = row.addressId;
        super.clearNotifications();
        this.doSearch();

    }

    /*
        Pressing Enter key starts the search.
    */ 
    handleKeypress(event) {
        if (event.code === 'Enter') {
            this.handleSearch();
        }
    }

}
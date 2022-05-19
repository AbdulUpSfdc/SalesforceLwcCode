import { api, track } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import * as bwcLICPublisher from 'c/bwcMsgToLICPublisher';
import * as BwcInteractionServices from 'c/bwcInteractionServices';
import * as BwcLabelServices from 'c/bwcLabelServices';
import { customerSearch, labels } from 'c/bwcUnifiedSearchServices';
import { addressValidation, ID_NOT_FOUND } from 'c/bwcAddressValidationServices';
import { createActivity, InteractionActivityValueMapping } from 'c/bwcInteractionActivityService'
import BwcError from 'c/bwcError';

const METHOD_AUTHENTICATION_MAPPING = {
    banWithAccountType: 'BAN',
    wirelessNumber: 'PHONE',
    phoneNumber: 'PHONE',
    userId: 'ATT_LOGIN_ID',
    address: 'ADDRESS',
    addressId: 'ADDRESS',
    orderId: 'ORDER_ID',
}
const ACCOUNT_NUMBER_SEARCH_MODE = 'accountNumber';
const ADDRESS_SEARCH_MODE = 'address';
const ADDRESS_ID_SEARCH_MODE = 'addressId';
const DEFAULT_SEARCH_MODE = 'search';
const INDIVIDUAL_SELECTION_MODE ='individualSelection';
const INDIVIDUAL_ID_SEARCH_MODE = 'individualId';
const ADDRESS_SELECTION_MODE = 'addressSelection';
const SUCCESS_VALIDATION_RESULT = 'success';
const CLOSEMATCH_VALIDATION_RESULT = 'closematch';
const NO_MATCH_VALIDATION_RESULT = 'nomatch';
export default class BwcUnifiedSearch extends BwcPageElementBase {

    // Common Labels
    utilLabels = BwcLabelServices.labels;

    // Unified Search specific labels
    label = labels;

    @api recordId;           //This is the Interaction ID
    @api objectApiName;
    @api caseId;            // CaseId is set when this lwc is used on Case object

    isRendered = false;
    isLoading = false;

    // Display mode = search, accounts, addresses
    displayMode = DEFAULT_SEARCH_MODE;
    get showSearch() { return this.displayMode === DEFAULT_SEARCH_MODE; }
    get showIndividualSelection() { return this.displayMode === INDIVIDUAL_SELECTION_MODE; }
    get showAddressSelection() { return this.displayMode === ADDRESS_SELECTION_MODE; }

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
    individualId;          // Not shown as input, but used as search input for address search
    orderId;

    _currentSearchValue;
    _currentSearchMode;

    // Search mode: accountNumber, wirelessNumber, phoneNumber, userId, address
    get searchMode() {

        let searchMode;

        if (this.ban || this.accountType) {
            searchMode = 'accountNumber';
        }
        else if (this.wirelessNumber) {
            searchMode = 'wirelessNumber';
        }
        else if (this.phoneNumber) {
            searchMode = 'phoneNumber';
        }
        else if (this.attLoginId) {
            searchMode = 'userId';
        }
        else if (this.addressId) {
            searchMode = 'addressId';
        }
        else if (this.streetAddress || this.aptUnitNo || this.city || this.state || this.zipCode) {
            searchMode = 'address';
        }
        else if (this.emailAddress){
            searchMode = 'emailAddress';
        }
        else if (this.orderId){
            searchMode = 'orderId'
        }
        else if (this.individualId){
            searchMode = 'individualId';
        }

        // If searchMode does not have a value yet, default value will be "clear"
        searchMode = searchMode || 'clear';

        // Storing the last searchMode used. Agent does not need to know if it was an individualId search
        this._currentSearchMode = searchMode !== 'individualId' ? searchMode : this._currentSearchMode;

        return searchMode;

    }

    // Provides short label to describe the search in a message.
    get searchModeLabel() {

        switch (this.searchMode) {

            case 'accountNumber':
                return `${this.utilLabels.account} ${this.ban} (${BwcConstants.BillingAccountType.getLabelForValue(this.accountType)})`;

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
    get disableBan() {return this.searchMode !== 'clear' && this.searchMode !== 'accountNumber';}
    get disableWirelessNumber() {return this.searchMode !== 'clear' && this.searchMode !== 'wirelessNumber';}
    get disablePhoneNumber() {return this.searchMode !== 'clear' && this.searchMode !== 'phoneNumber';}
    get disableAttLoginId() {return this.searchMode !== 'clear' && this.searchMode !== 'userId';}
    get disableAddress() {return this.searchMode !== 'clear' && this.searchMode !== 'address';}
    get disableSearch() {return this.searchMode === 'clear';}
    get disableOrderId() {return this.searchMode!== 'clear' && this.searchMode !== 'orderId'; }
    get disableEmailAddress(){ return this.searchMode !== 'clear' && this.searchMode !== 'emailAddress' }

    get messageWhenTooShort() {return 'Account number must be at least 7 digits.';}
    get messageWhenTooLong() {return 'Account number can be no more than 15 digits.';}

    @track accountData; // When search returns one or more accounts
    @track individuals;
    @track addresses;
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
                            super.addScopedNotification(this.label.banNotInOrder, 'info', 'alert');

                        }
                        else {

                            // Show message indicating manual search is required
                            super.addInlineNotification(this.label.manualSearch);

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
        this.individualId = undefined;

        // Allow the reset values to render into the inputs
        await BwcUtils.nextTick();

        super.clearNotifications();

        // Reset all validity
        this.template.querySelectorAll('lightning-input, lightning-combobox').forEach(component => {
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

            case 'accountNumber':
                if (!this.ban) {
                    this.setCustomValidity('ban', this.label.plsPopBan);
                    isValid = false;
                }
                if (!this.accountType) {
                    this.setCustomValidity('accountType', this.label.selectAcctType);
                    isValid = false;
                }
                break;

            case 'address':
                if (!this.streetAddress) {
                    this.setCustomValidity('streetAddress', this.label.zipASTMand);
                    isValid = false;
                }
                if (!this.zipCode) {
                    this.setCustomValidity('zipCode', this.label.zipASTMand);
                    isValid = false;
                }
                if(!this.state){
                    this.setCustomValidity('state', this.label.selectValidState);
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
        super.clearNotifications();
        try {

            this.isLoading = true;

            // If search by address, use the address validation API.
            if(this.searchMode === ADDRESS_SEARCH_MODE){
                await this.callAddressValidation();
                return;
            }

            // Prepare search parameters
            const searchRequest = {
                accountNumber: this.ban,
                serviceType: this.accountType,
                phoneNumber: this.searchMode === 'wirelessNumber' ? BwcUtils.parsePhoneToDigits(this.wirelessNumber) : (this.searchMode === 'phoneNumber' ? BwcUtils.parsePhoneToDigits(this.phoneNumber) : undefined),
                userId: this.attLoginId,
                addressId: this.addressId,
                orderId: this.orderId,
                individualId: this.individualId
            };

            // Search
            const searchResponse = await this.accountSearch(searchRequest);


            if (searchResponse.accountResponseCount === 0) {

                // Nothing found
                const label = `There were no results found for ${this.searchModeLabel}. <span class="slds-text-color_error">Please try your search again.</span>`;

                let errorMessage = this.orderId ? this.label.banNotInOrder : label;
                super.addInlineNotification(errorMessage);
                success = false;
                this.isLoading = false;

            }
            else if (searchResponse.accountResponseCount === 1) {

                // Single account found

                if (this.objectApiName === 'Interaction__c') {

                    // Customer should be set on the interaction -- reload
                    getRecordNotifyChange([{recordId: this.recordId}]);
                    bwcLICPublisher.publishMessage('INIT','','');
                    super.sendLmsRefresh(this.recordId, 'customerSearch');

                    banFound = searchResponse.individuals?.[0]?.accounts?.[0]?.billingAccountId;

                }
                else if (this.caseId) {

                    this.dispatchEvent(new CustomEvent('recordfound', {
                        detail: {
                            account: {
                                searchInputBAN: this._currentSearchMode === ACCOUNT_NUMBER_SEARCH_MODE ? this.searchValue : '',
                                personAccountId: searchResponse.individualsFound?.[0]?.accountId,
                            }
                        }
                    }));

                }

            }
            else {

                BwcUtils.log('multiple accounts found');
                BwcUtils.log(searchResponse.individualsFound);

                let response = BwcUtils.cloneObject(searchResponse);

                this.individuals = response.individualsFound.sort((a,b)=>{

                    return a.fullName > b.fullName ? 1 : -1;
                });
                this.displayMode = INDIVIDUAL_SELECTION_MODE;
                this.isLoading = false;

            }

        }
        catch (error) {

            BwcUtils.error(error instanceof Error ? error : JSON.stringify(error));

            super.addScopedNotification(this.label.errorWhileSearch);
            success = false;
            this.isLoading = false;
        }
        finally {

            // Creating interaction activity when executed in Interaction context
            if(this.recordId){
                await this.createInteractionActivity(success, banFound);
            }

        }

    }

    /*
        Make the API call to search.
    */
    async accountSearch(searchRequest) {

        const recordId = this.caseId ? this.caseId : this.recordId;
        const searchRequestJson = JSON.stringify(searchRequest);
        BwcUtils.log(`call customerSearch: recordId: ${recordId} requestJson: ${searchRequestJson}`);

        // Make the server call
        try {

            const searchResponse = await customerSearch(recordId, searchRequestJson);
            BwcUtils.log('result customerSearch: ', searchResponse);
            return searchResponse;

        }
        catch(error) {

            throw BwcError.convertError(error);

        }

    }

    /**
     * Calls the Address validation API
     */
    async callAddressValidation(){
        try {
            const request = this.getAddressValidationRequestBody();
            const requestJson = JSON.stringify(request);
            const recordId = this.caseId ? this.caseId : this.recordId;

            const response = await addressValidation(recordId, requestJson);

            this.processAddressValidation(response);

        } catch (error) {

            BwcUtils.error(error);
            super.addScopedNotification(this.label.errorWhileSearch);
            this.isLoading = false;
        }
    }

    getAddressValidationRequestBody(){

        const requestBody = {
            city: this.city,
            postcode: this.zipCode,
            stateOrProvince: this.state,
            addressCharacteristic: []
        };

        if(this.streetAddress){
            requestBody.addressCharacteristic.push(
                {
                    name: "addressLine1",
                    value: this.streetAddress
                }
            );
        }

        if(this.aptUnitNo){
            requestBody.addressCharacteristic.push(
                {
                    name: "addressLine2",
                    value: this.aptUnitNo
                }
            );
        }

        return requestBody;
    }

    /**
     * @param  {Object} response from Address Validation API
     */
    processAddressValidation(response){
        const { validationResult } = response;

        BwcUtils.log({response});

        // Success, search individual using the address Id
        if(validationResult === SUCCESS_VALIDATION_RESULT){
            const { id } = response.validGeographicAddress;
            this.addressId = id;
            this.doSearch();
            return;
        }

        // Close match, get valid addresses (Id not null) and show them to the user
        if(validationResult === CLOSEMATCH_VALIDATION_RESULT ){

            const addresses = response.alternateGeographicAddress?.filter(address => address.id && address.id !== ID_NOT_FOUND );

            if(!Array.isArray(addresses)){
                return;
            }

            // No valid address, show notification
            if(addresses.length === 0){
                super.addInlineNotification(this.label.noServiceAddress);
                this.addresses = [];
                this.isLoading = false;
            } else {
                // Show address selection
                this.displayMode = ADDRESS_SELECTION_MODE;
                this.addresses=addresses;
                this.isLoading = false;
            }

            return;
        }

        // No match, show notification
        if(validationResult === NO_MATCH_VALIDATION_RESULT){
            super.addInlineNotification(this.label.noAddressFound);
            this.addresses = [];
            this.isLoading = false;
        }
    }

    /** Method that creates an interaction activity when a customer search is performed
     * @param  {Boolean} success. Boolean value that indicates the API call for the customer search was successful
     * @param  {String} billingAccountNumber. BAN of the account that was found
     */
    async createInteractionActivity(success, billingAccountNumber){

        const action = InteractionActivityValueMapping.CustomerSearch

        const intActPayload = {
            recordId: this.recordId,
            ban: billingAccountNumber,
            methodOfSearch: METHOD_AUTHENTICATION_MAPPING[this.searchMode],
            accountType: this.accountType,
            valueOfSearch: this.searchValue,
            status: success ? 'success':'failed'
        };

        await createActivity(this.recordId, action, intActPayload);
    }

    get searchValue(){

        let searchValue = '';
        switch (this.searchMode) {
            case 'accountNumber':
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
            case 'addressId':
                searchValue = this.getFormattedAddress();
                break;
            case 'orderId':
                searchValue = this.orderId;
                break;
            case 'individualId':
                // If search by individualId, show the same search value used prior selecting the individual
                searchValue = this._currentSearchValue;
                break;
            default:
                searchValue = 'Unknown search mode';
                break;
        }

        this._currentSearchValue = searchValue;

        return searchValue;
    }

    getFormattedAddress(){

        const stateName = BwcConstants.StateOptions.find(state => state.value === this.state)?.label;

        const aptUnitNo = this.aptUnitNo ? `, ${this.aptUnitNo}` : '';
        const city = this.city ? `, ${this.city}` : '';
        const state = stateName ? `, ${stateName}` : '';
        const zipCode = this.zipCode ? `- ${this.zipCode}` :'';

        return `${this.streetAddress || ''}${aptUnitNo }${city }${state}${zipCode }`;
    }

    /*
        Change to any input control.
    */
    handleInputChange(event) {

        // Property names match component ID, so set value
        const trimmedValue = event.target.value.trim();
        this[event.target.dataset.id] = trimmedValue || undefined;

        // Reset any error
        event.target.setCustomValidity('');

        switch (event.target.dataset.id) {

            case 'ban':
                if (!this.ban && this.accountType) {
                    this.accountType = undefined;
                }
                else if (this.ban && !this.accountType) {
                    this.accountType = BwcConstants.BillingAccountType.WIRELESS.value;
                }
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

    handleNewSearch(event){
        const clear = event.detail.clear;

        if(clear){
            this.clear();
        }

        if(this.searchMode === ADDRESS_ID_SEARCH_MODE){
            this.addressId = undefined;
        }

        if(this.searchMode === INDIVIDUAL_ID_SEARCH_MODE){
            this.individualId = undefined;
        }

        this.isLoading = false;
        this.displayMode = DEFAULT_SEARCH_MODE;
    }

    handleError(event){
        const error = event.detail;
        super.handleError(error);
    }

    handleAddressSelection(event){
        this.addressId  = event.detail;
        super.clearNotifications();
        this.doSearch();
    }

    handleNewAddress(event){
        const { streetAddress, aptUnitNo, city, state, zipCode } = event.detail;
        this.streetAddress = streetAddress;
        this.aptUnitNo = aptUnitNo;
        this.city = city;
        this.state = state;
        this.zipCode = zipCode;

        this.addressId = '';
        this.doSearch();
    }

    handleIndividualSearch(event){

        // Delete any search term that was used
        this.clear();

        this.individualId = event.detail;

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
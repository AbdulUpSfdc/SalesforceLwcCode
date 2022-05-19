import { track, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import SERVICE_AVAILABILITY_STYLE from '@salesforce/resourceUrl/serviceAvailability';
import * as BwcConstants from 'c/bwcConstants';

//Other components
import BwcPageElementBase from 'c/bwcPageElementBase';
import * as BwcUtils from 'c/bwcUtils';
import * as bwcLICPublisher from 'c/bwcMsgToLICPublisher';
import * as BwcInteractionServices from 'c/bwcInteractionServices';
import * as BwcServiceAvailabilityService from 'c/bwcServiceAvailabilityService';
import * as BwcAddressValidationService from 'c/bwcAddressValidationServices';

// Custom labels 
import label_mulesoftErrorCode from '@salesforce/label/c.BWC_UnexpectedError_RefreshSection';

const TREE_GRID_COLUMNS = [
    { type: 'text', fieldName: 'lob', label: 'LOB', hideDefaultActions: true, },
    { type: 'text', fieldName: 'additionalInfo', label: 'Add\'l Info', hideDefaultActions: true, },
    {
        type: 'text', fieldName: 'availability', label: 'Availability', hideDefaultActions: true,
        cellAttributes: {
            iconName: { fieldName: 'availabilityIcon' },
            iconVariant: { fieldName: 'availabilityIconVariant' },
            iconPosition: 'left',
            iconClass: 'slds-text-color_success'
        }
    }
];

//row attribute constants
const SUCCESS_CLASS = 'slds-text-color_success';
const ERROR_CLASS = 'slds-text-color_error';
const AVAILABLE_ICON = 'utility:check';
const UNAVAILABLE_ICON = 'action:close'

//Service Type constants
const WIRELESS_TYPE = 'Wireless';
const TV_TYPE = 'TV';
const DTVNOW = BwcConstants.BillingAccountType.DTVNOW.label;

//Children constants
const AVAILABLE_LABEL = 'Available';

const AVAILABILITY_STATUS = {
    EXISTINGSERVICES: { value: 'EXISTINGSERVICES' },
    MDU: { value: 'MDU' },
    CLOSEMATCH: { value: 'CLOSEMATCH' },
    RED: { value: 'RED' },
    GREEN: { value: 'GREEN' },
    NOMATCH: { value: 'NOMATCH' },
};

const COMPONENT_UI_NAME = 'Service Availability';

const SUCCESS = 'success';
const CLOSEMATCH = 'closematch';
const SIMILARMATCH = 'similar_match';
const NOT_FOUND = 'NOT FOUND';

export default class BwcServiceAvailability extends BwcPageElementBase {

    @api recordId;

    @track data = [];
    isLoading = true;
    isExpanded = false;
    hasData = false;
    @track error;
    showServiceAvailability = false;
    showMDUView = false;
    showAddressForm = false;
    isMDU = false;
    nomatch = false;


    isRendered = false;
    columns = TREE_GRID_COLUMNS;
    serviceAvailabilityMtd;
    entriesMap = new Map();
    mduAddresses = [];
    userInput;
    interaction;
    closematchAddresses = [];
    showInputAddress = false;
    showAddressIdWarning = false;
    @track internetExpand;

    async renderedCallback() {

        if (!this.isRendered) {

            this.isRendered = true;

            // Load styles
            loadStyle(this, SERVICE_AVAILABILITY_STYLE)
                .then(() => {
                    BwcUtils.log('style loaded');
                })
                .catch((error) => {
                    BwcUtils.error('Error loading style', error);
                })

            // Work around boxcarring by waiting so this component doesn't block product search from completion
            await BwcUtils.wait(BwcConstants.BOXCAR_WAIT);

            // load service availability data
            this.initialize();
        }

    }

    async initialize() {
        // Get Service Availability Metadata
        await this.loadServiceAvailabilityMtd();

        // Get interaction record
        this.interaction = await BwcInteractionServices.getInteraction(this.recordId);

        this.callGetServiceAvailability();
    }

    async loadServiceAvailabilityMtd() {
        // Get Service Availability Metadata
        try {
            this.serviceAvailabilityMtd = await BwcServiceAvailabilityService.getServiceAvailabilityMtd(this.recordId);
            for (let record of this.serviceAvailabilityMtd) {
                if (!this.entriesMap.has(record.Type__c)) {
                    this.entriesMap.set(record.Type__c, []);
                }

                this.entriesMap.get(record.Type__c).push(record);
            }
            BwcUtils.log('entriesMap: ' + this.entriesMap);
        } catch (error) {
            super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
        }
    }

    async callGetServiceAvailability() {

        try {
            let data = await BwcServiceAvailabilityService.getServiceAvailability(this.recordId);
            this.processServiceData(data);
        } catch (error) {
            this.hasData = false;
            super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
        } finally {
            this.isLoading = false;
        }
    }

    processServiceData(response) {

        const availabilityStatus = response.content.availabilityStatus;
        let isMDU = response?.content?.addressFeatures?.dwellingTypeDetails?.isMdu;
        this.userInput = response?.content?.userInput;

        this.isMDU = isMDU == "true";


        switch (availabilityStatus) {
            case AVAILABILITY_STATUS.GREEN.value:
            case AVAILABILITY_STATUS.RED.value:
            case AVAILABILITY_STATUS.EXISTINGSERVICES.value:
                let addressFeatures = response?.content?.addressFeatures;
                this.nomatch = false;
                this.showAddressFormComponent(addressFeatures, true);
                this.showInputAddress = addressFeatures !== undefined && addressFeatures !== null;
                this.buildServiceAvailabilityData(response);
                break;
            case AVAILABILITY_STATUS.MDU.value:
                let mduAddressList = response.content.mduAddress;
                this.isMDU = true;
                this.nomatch = false;
                this.showAddressFormComponent(this.userInput, false);
                this.showInputAddress = this.userInput !== undefined && this.userInput !== null;
                this.showMDUComponent(mduAddressList, null);
                break;
            case AVAILABILITY_STATUS.CLOSEMATCH.value:
                let closeMatchAddressList = response.content?.closeMatchAddress;
                this.isMDU = true;
                this.nomatch = false;
                this.showAddressFormComponent(this.userInput, false);
                this.showInputAddress = this.userInput !== undefined && this.userInput !== null;
                this.showMDUComponent(null, closeMatchAddressList);
                break;
            case AVAILABILITY_STATUS.NOMATCH.value:
            default:
                this.showAddressFormComponent(this.userInput, false);
                this.showInputAddress = this.userInput !== undefined && this.userInput !== null;
                this.nomatch = true;
                break;
        }
    }

    buildServiceAvailabilityData(response) {

        const availableServices = response?.content?.availableServices;
        const existingServices = response?.content?.existingServices || {};

        this.showAddressForm = false;
        this.showMDUView = false;

        if (availableServices == undefined) return;

        BwcUtils.log("%cit has available services", "color:green");
        let wirelessAvailability = availableServices.wirelessAvailable == 'true' ? 'Available' : 'Unavailable';
        let wirelessIcon = wirelessAvailability == 'Available' ? 'utility:success' : 'utility:error';
        let wirelessIconClass = wirelessAvailability == 'Available' ? 'slds-text-color_success' : 'slds-text-color_error';
        let wirelessIconVariant = wirelessAvailability == 'Available' ? 'success' : 'error';

        let tempData = [];
        let wirelessAvailable = false;
        let wirelessPrepaidAdded = false;
        let maxInternetSpeed;
        if (availableServices.maxInternetDownloadSpeedAvailableMBPS) {
            maxInternetSpeed = parseInt(availableServices.maxInternetDownloadSpeedAvailableMBPS);
        }

        let id = 0;
        let internetIdArr = [];
        //Loop for Type
        for (let type of this.entriesMap.keys()) {
            let serviceEntry = {
                id: ++id,
                lob: type,
                _children: []
            }
            if (type === 'Internet') {
                internetIdArr.push(id);
                this.internetExpand = internetIdArr;
            }
            //Loop for services
            for (let record of this.entriesMap.get(type)) {

                // let existingService = existingServices[record.Existing_Service_FieldName__c];
                let availability = availableServices[record.FieldName__c];
                BwcUtils.log(`${record.DisplayName__c} : ${availability}`)

                if (record.FieldName__c === 'wirelessAvailable'
                    // && !existingService
                    && availability) {
                    wirelessAvailable = true;
                }


                //IF wirelessAvailable, then Hardcode at&t tv available
                if (wirelessAvailable
                    && type === TV_TYPE) {
                    let serviceProduct = {
                        id: ++id,
                        lob: DTVNOW,
                        availability: AVAILABLE_LABEL,
                        availabilityIcon: AVAILABLE_ICON,
                        availabilityIconClass: SUCCESS_CLASS,
                    }
                    serviceEntry._children.push(serviceProduct);
                    wirelessAvailable = false;
                }

                //Don't add service if is unavailable OR user already has that service
                // if(availability=='false' || existingService) continue;
                if (availability == 'false') continue;
                // if(!availability) continue;

                //Adding wireless Prepaid
                if (type === WIRELESS_TYPE && !wirelessPrepaidAdded) {
                    let serviceProduct = {
                        id: ++id,
                        lob: 'Wireless Prepaid',
                        availability: AVAILABLE_LABEL,
                        availabilityIcon: AVAILABLE_ICON,
                        availabilityIconClass: SUCCESS_CLASS,
                    }
                    serviceEntry._children.push(serviceProduct);
                    wirelessPrepaidAdded = true;
                }

                let serviceProduct = {
                    id: ++id,
                    lob: record.DisplayName__c,
                    availability: AVAILABLE_LABEL,
                    availabilityIcon: AVAILABLE_ICON,
                    availabilityIconClass: SUCCESS_CLASS,
                }

                //For internet, show fiber based on the speed
                if (maxInternetSpeed && record.FieldName__c == 'hsiaAvailable') {
                    serviceProduct.lob = maxInternetSpeed >= 1000 ? 'AT&T Fiber' : serviceProduct.lob;
                    serviceProduct.additionalInfo = availableServices.maxInternetDisplayText;
                }

                serviceEntry._children.push(serviceProduct);
            }

            if (serviceEntry._children.length > 0) {
                tempData.push(serviceEntry);
            }
        }

        this.data = tempData;
        this.hasData = true;
        this.showServiceAvailability = true;
    }

    showMDUComponent(mduAddressList, closematchAddressList) {
        this.showServiceAvailability = false;
        this.showAddressForm = false;
        this.showMDUView = true;

        this.mduAddresses = mduAddressList;
        this.closematchAddresses = closematchAddressList;
    }

    showAddressFormComponent(inputAddress, isExactMatch) {

        BwcUtils.log('userInput: ', inputAddress);
        const { addressLine1, aptUnitNumber, addressLine2, zip, state, city } = inputAddress
        this.addressLine1 = addressLine1;
        this.aptUnitNumber = aptUnitNumber;
        this.addressLine2 = addressLine2;
        this.zip = zip;
        this.state = state;
        this.city = city;
        this.exactMatch = isExactMatch;
    }

    handleExpandAll() {
        if (this.isExpanded) {
            this.template.querySelector('lightning-tree-grid')?.collapseAll();
        } else {
            this.template.querySelector('lightning-tree-grid')?.expandAll();
        }

        this.isExpanded = !this.isExpanded;
    }

    handleToggle(event) {
        let expandedRows = this.template.querySelector('lightning-tree-grid').getCurrentExpandedRows();
        let numberExpandedRows = expandedRows.length;
        let numberTypeService = this.data?.length;

        //Means the user has expanded all the rows manually
        this.isExpanded = numberExpandedRows == numberTypeService;
    }

    handleSearchDiffAddress() {
        this.postToLIC();
    }

    handleOrderNewService() {
        this.postToLIC();
    }

    postToLIC() {
        const msg = 'PostToOpus';
        const licObj = {};
        licObj.launchPoint = 'Launch Point';
        licObj.JsonData = {};

        bwcLICPublisher.publishMessage(msg, licObj, this.billingAccountNumber);
    }

    handleRefresh() {
        this.isLoading = true;
        this.hasData = false;
        this.showAddressForm = false;
        this.showMDUView = false;
        this.showServiceAvailability = false;
        this.showInputAddress = false;
        super.clearNotifications();
        this.callGetServiceAvailability();
    }

    async handleUpdatedAddress(event) {
        try {
            this.isLoading = true;
            this.showInputAddress = false;
            this.showMDUView = false;
            this.showServiceAvailability = false;

            this.callGetAddressValidation(event.detail);
        } catch (error) {
            super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
            this.isLoading = false;
        }

    }

    async handleSelectedAddress(event) {
        this.showAddressIdWarning =false;
        this.isLoading = true;
        let addressdetails = JSON.parse(event.detail);
        let { addressLine1, addressId, zip, state, city } = addressdetails; 
        if(!addressId){
            this.showAddressIdWarning =true;
            this.isLoading = false;
            return;
        }
        this.showInputAddress = false;
        this.showMDUView = false;
        this.showServiceAvailability = false;
        BwcUtils.log('Selected Address ' + event.detail);
        let updatedAddress = {
            addressLine1,
            city,
            state,
            zip,
            addressId
        }
        BwcUtils.log({ updatedAddress });

        try {
            let response = await BwcServiceAvailabilityService.getServiceAvailabilityByAddress(this.recordId, updatedAddress);
            this.processServiceData(response)
        } catch (error) {
            super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
        } finally {
            this.isLoading = false;
        }

    }

    async callGetAddressValidation(addressDetail) {
        try {
            const requestJSON = {
                "city": addressDetail.city,
                "postcode": addressDetail.zip,
                "stateOrProvince": addressDetail.state,
                "addressCharacteristic": [
                    {
                        "name": "addressLine1",
                        "value": addressDetail.addressLine1
                    },
                    {
                        "name": "addressLine2",
                        "value": addressDetail.aptUnitNumber
                    }
                ]
            };
            BwcUtils.log("Updated Address request AV ====>", requestJSON);
            let response = await BwcAddressValidationService.addressValidation(this.recordId, JSON.stringify(requestJSON));
            BwcUtils.log("call callGetAddressValidation res ", response);
            this.processAddressValidationResponse(response, addressDetail);

        } catch (error) {
            super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
            this.isLoading = false;
        }
    }
    processAddressValidationResponse(response, addressDetail) {
        try {
            if (!response) {
                return;
            }

            const validationRes = response.validationResult ? response.validationResult.toLowerCase() : null;
            if (validationRes !== null && validationRes === SUCCESS) {
                const idVal = response.validGeographicAddress?.id;
                if(idVal !== NOT_FOUND){
                    this.callGetServiceAvailabilityByAddress(idVal, addressDetail);
                } else{
                    this.nomatch = true;
                    this.showAddressFormComponent(addressDetail, false);
                    this.showInputAddress = true;
                    this.isLoading = false;
                }
               

            } else if (validationRes !== null && (validationRes === CLOSEMATCH || validationRes === SIMILARMATCH)) {
                const multipleaddresses = response.alternateGeographicAddress?.filter(address => address.id && address.id !== 'NOT FOUND');

                if (multipleaddresses.length === 0) {
                    this.nomatch = true;
                    this.showAddressFormComponent(addressDetail, false);
                    this.showInputAddress = true;
                    this.isLoading = false;
                } else {
                    let closematchAddress = this.buildMultipleAddressList(multipleaddresses);
                    this.isMDU = true;
                    this.nomatch = false;
                    this.showAddressFormComponent(addressDetail, false);
                    this.showInputAddress = true;
                    this.showMDUComponent(null, closematchAddress);
                    this.isLoading = false;
                }


            } else {
                this.nomatch = true;
                this.showAddressFormComponent(addressDetail, false);
                this.showInputAddress = true;
                this.isLoading = false;
            }
        } catch (error) {
            super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
        }
    }

    async callGetServiceAvailabilityByAddress(addressIdVal, addressDetail) {
        try {
            let addressId = addressIdVal ? addressIdVal : '';
            let { addressLine1, aptUnitNumber, city, state, zip } = addressDetail;
        
            let updatedAddress = {
                addressLine1,
                aptUnitNumber,
                city,
                state,
                zip,
                addressId
            }
            BwcUtils.log("Updated Address request SA ====>", updatedAddress);
            let serviceAvailabilityResponse = await BwcServiceAvailabilityService.getServiceAvailabilityByAddress(this.recordId, updatedAddress);
            BwcUtils.log("Get service availability API res", serviceAvailabilityResponse);
            this.processServiceData(serviceAvailabilityResponse);

        } catch (error) {
            super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
        } finally {
            this.isLoading = false;
        }


    }

    buildMultipleAddressList(addressList) {
        let multipleAddressArr = [];

        if (addressList) {
            addressList.forEach(add => {
                let obj = {};
                obj.city = add.city || '';
                obj.state = add.stateOrProvince || '';
                obj.zip = add.postcode || '';
                obj.addressId = add.id || '';
                const addressLine1 = add.addressCharacteristic?.[0];
                const addressLine2 = add.addressCharacteristic?.[1];
                obj.addressLine1 = addressLine1?.value;
                obj.addressLine2 = addressLine2?.value;
                multipleAddressArr.push(obj);
            });
        }
        return multipleAddressArr;

    }

    get expandIcon() {
        return this.isExpanded ? 'utility:collapse_all' : 'utility:expand_all';
    }

    get expandButtonText() {
        return this.isExpanded ? 'Collapse All' : 'Expand All';
    }

    get showTable() {
        return !this.isLoading && this.hasData;
    }

    get showMDURestrictionMessage() {
        return this.isMDU;
    }


}
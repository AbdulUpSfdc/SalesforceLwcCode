import { api, track, wire } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import * as bwcLICPublisher from 'c/bwcMsgToLICPublisher';
import * as bwcTSRMLauncher from 'c/bwcTSRMLauncher';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcBillingAccount from 'c/bwcBillingAccount';
import { getSortedBillingAccounts } from 'c/bwcAccountServices';
import hasLICPermission from '@salesforce/customPermission/LIC_Permission';
import * as bwcOpenNewBrowserTabPublisher from 'c/bwcOpenNewBrowserTabPublisher';
import DeviceURL from '@salesforce/label/c.Device_Support_Index_URL';
import { createActivity, InteractionActivityValueMapping } from 'c/bwcInteractionActivityService';
import * as bwcDispatchEscalationCase from 'c/bwcDispatchEscalationCase';
import * as BwcProductServices from 'c/bwcProductServices';
import { isBroadbandTechCareAgentPermission } from 'c/bwcAppointmentsService';


//Lightning Message Service
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import COMPLETIONMC from '@salesforce/messageChannel/BWC_Completion__c';

// Import custom labels
import label_noItemsFound from '@salesforce/label/c.BWC_ProductList_NoItemsFound';
import label_unexpectedError from '@salesforce/label/c.BWC_UnexpectedError_RefreshSection';

const currencyFields = [
    'Monthly_Cost__c',
    'Installments_Amount__c'
];

const phoneFields = [
    'Phone_Number__c'
];

const HBO_MAX_BADGE_CLASS = 'hbo-max-badge';
const HBO_MAX_BADGE_LABEL = 'HBO Max'
const BROADBAND_AGENT_PERMISSION = 'Broadband_Agent';

export default class BwcProductList extends BwcPageElementBase {

    label = {
        noItemsFound: label_noItemsFound
    };

    // The Salesforce Interaction or Person Account Record Id
    @api recordId;

    // The Customer's services for this Person Account
    @track customerServices = [];

    // Used to show spiner as the products are being loaded.
    isLoadingMain = true;
    isLoading;
    error;

    // Used to refresh on first render
    isRendered;

    // Map of services by serviceName
    servicesByName = {};

    isExpanded = true;

    /*
        Refresh on first render.
    */
    renderedCallback() {

        if (!this.isRendered) {
            this.isRendered = true;
            this.refresh();
        }
    }

    /*
        Refresh the data.
    */
    async refresh(bans, forceRefresh) {

        super.clearNotifications();

        try {

            if (!bans) {

                // Refresh all
                this.isLoadingMain = true;
                this.isLoading = true;

                // First get just the billing accounts so we can populate the sections before the longer call to load plans and equipment
                const billingAccounts = await getSortedBillingAccounts(this.recordId, null, null, null, null, true, BROADBAND_AGENT_PERMISSION);
                // Build skeleton list of services
                this.customerServices = [];
                billingAccounts.forEach(billingAccount => {
                    const tempBillingAccount = BwcBillingAccount.BillingAccount.fromRecord(billingAccount);
                    const hboMaxFlag = billingAccount.HBO_Max_Entitlement__c;
                    // Check whether it's authenticated or not
                    const isMasked = billingAccount.Billing_Account_Number__c?.includes('*');

                    let service = {
                        ban: billingAccount.Billing_Account_Number__c,
                        accountType: billingAccount.Account_Type__c,
                        unifiedBan: billingAccount.Wireless_BAN__c,
                        serviceLabel: BwcBillingAccount.BillingAccount.fromRecord(billingAccount).serviceLabel,
                        serviceName: billingAccount.Service_Name__c,
                        noPlansOrEquipment: !billingAccount.Prepaid_Customer__c,
                        isLoading: !billingAccount.Prepaid_Customer__c,
                        isPrepaid: billingAccount.Prepaid_Customer__c,
                        hboMaxFlag,
                        serviceTypeName: tempBillingAccount.serviceTypeName,
                        maskedBan: billingAccount.Billing_Account_Number__c,
                        isUverse: billingAccount.Account_Type__c === BwcConstants.BillingAccountType.UVERSE.value ? true : false,
                        isMasked,
                        recordId: billingAccount.Id,
                        unifiedLabel: tempBillingAccount.unifiedLabel,
                    };

                    if (service.hboMaxFlag) {
                        this.setBadgeProperties(service);
                    }

                    this.customerServices.push(service);

                    this.servicesByName[service.serviceName] = service;

                });

                // Turn off main loading spinner because skeleton is loaded
                this.isLoadingMain = false;

            }

            // Call the Apex method to retrieve the products (Makes Mulesoft call, retrieved data for Plans &
            // and Equipement, Then UPSERTS into SF Objects, queries it back from Plan & Equipment and
            // Groups the records by formula field Service_Name__c on Plan & Equipment records,
            // sorts the record to display in sequence so WIRELESS shows on top).

            const result = await BwcProductServices.getProductsGroupedByService(this.recordId, bans, forceRefresh);

            // Loop through each Service inside the returned result object
            result.services.forEach(service => {
                service.isUverse = service.accountType === BwcConstants.BillingAccountType.UVERSE.value ? true : false;
                // Set authorization level flags
                service.isL0 = service.authorizationLevel === 'L0';
                service.isL1 = service.authorizationLevel === 'L1';
                service.isByPass = service.authorizationLevel === BwcConstants.AuthenticationMethod.BYPASS.value;

                if (service.planserror) {
                    service.errorMessage = label_unexpectedError;
                    BwcUtils.error('Services', `Error for ${service.serviceName}: Plans: ${service.planserror.code} ${service.planserror.message}`);
                }
                else if (service.isHidden) {

                    // This service is L0 authorized and no data at all should be shown
                    service.hasPlanPackages = false;
                    service.hasEquipment = false;

                }
                else if (service.hasPlanPackages) {

                    // If this billing account has Plan/Packages

                    // create the column definitions as needed by the LWC datatable
                    service.planColumns = this.createColumns(service.plans, 'plans');

                    // convert the data as field value pair so datatable can render it
                    service.planData = this.createData(service.plans, service, service);

                }

                if (service.equipmentserror) {
                    service.errorMessage = label_unexpectedError;
                    BwcUtils.error('Services', `Error for ${service.serviceName}: Equipment: ${service.equipmentserror.code} ${service.equipmentserror.message}`);
                }
                else if (service.hasEquipment) {

                    // If this billing account has Devices

                    // create the column definitions as needed by the LWC datatable
                    service.equipmentColumns = this.createColumns(service.equipments, 'equipment');

                    // convert the data as field value pair so datatable can render it
                    service.equipmentData = this.createData(service.equipments, service.ban, service);

                }
                if (!service.errorMessage && !service.hasPlanPackages && !service.hasEquipment && !service.isHidden) {
                    service.noPlansOrEquipment = true;
                }
                else if (service.hasPlanPackages && service.hasEquipment) {
                    service.bothPlansAndEquipment = true;
                }

            });

            // Now replace the customer's services with the results, but don't remove placeholders if there were no results
            result.services.forEach(service => {

                let placeholderIndex = this.customerServices.findIndex(placeholderService => placeholderService.serviceName === service.serviceName);
                if (placeholderIndex !== -1) {

                    const placeholderService = this.customerServices[placeholderIndex];

                    // Replace placeholder with results
                    service.isPrepaid = placeholderService.isPrepaid;
                    if (service.isPrepaid) {
                        // BAN is prepaid, we will just show notification and no other sections
                        service.hasEquipment = false;
                        service.hasPlanPackages = false;
                        service.bothPlansAndEquipment = false;
                        service.noPlansOrEquipment = false;
                        service.isHidden = false;
                        service.errorMessage = undefined;
                    }

                    service.isMasked = placeholderService.isMasked;
                    service.recordId = placeholderService.recordId;
                    service.unifiedLabel = placeholderService.unifiedLabel;

                    if (service.hboMaxFlag) {
                        this.setBadgeProperties(service);
                    }

                    this.customerServices[placeholderIndex] = service;

                }
                else {
                    // No placeholder, add to end
                    this.customerServices.push(service);
                }

                this.servicesByName[service.serviceName] = service;

            });

        }
        catch (error) {

            if (!bans) {
                this.customerServices = undefined;
                super.handleError(error, label_unexpectedError, 'Services', 'inline');
            }
            else {
                const customerService = this.customerServices.find(service => service.ban === bans[0]);
                BwcUtils.error('Services', `Error for ${customerService.serviceName}: ${error.message}`, error);
                customerService.errorMessage = label_unexpectedError;
                customerService.noPlansOrEquipment = false;
            }

        }
        finally {
            this.isLoadingMain = false;
            this.isLoading = false;
            this.customerServices.forEach(service => { service.isLoading = false; });
        }

    }

    //checks if user is having broadband techcare agent custom permission
    get isTechCareAgent() {
        return isBroadbandTechCareAgentPermission;
    }

    /*
        Refresh specified service.
    */
    async refreshSpecificServices(serviceName) {

        const service = this.customerServices.find(serv => serv.serviceName === serviceName);
        service.isLoading = true;
        service.errorMessage = undefined;
        await this.refresh([service.ban], true);

    }

    /**Method that adds additional attributes to display a badge component
     * @param  {} service
     */
    setBadgeProperties(service) {
        service.badgeClass = HBO_MAX_BADGE_CLASS;
        service.badgeLabel = HBO_MAX_BADGE_LABEL;
    }

    // This fuction converts the data returned by Apex method getServices in the format required by LWC datatable.
    // Data is retuned as array of object.
    // And each object has multiple field value pair as F0:<<value>>, F1:<<value>>, so on
    // F0 is rendered as column 1, F1 as column 2 etc.
    // If there is a field called Highlight,  create a field called RowClass with
    // value 'slds-text-color_success'  if Highlight is true else set RowClass to empty string.
    // Example: [{F0: '', F1: '', F2: ''},{F0: '', F1: '', F2: ''}]
    createData(records, service, serviceObject) {
        let data = [];
        for (let idxRow = 0; idxRow < records.length; idxRow++) {
            let record = records[idxRow];

            let row = {}
            row.RowClass = '';
            // 09-09-2020 Buttons always has the class slds-m-left_x-small
            //row['ButtonClass'] = 'slds-m-left_x-small';

            // First row is record id
            row.F0 = record.fields[0].fieldValue;

            for (let idx = 1; idx < record.fields.length; idx++) {
                let field = record.fields[idx];
                // 09-09-2020 Fields Is_Primary and Status is for UI settings
                if (field.fieldName !== 'Is_Primary' && field.fieldName !== 'Status') {
                    row['F' + idx] = phoneFields.includes(field.fieldName) ? BwcUtils.formatPhone(field.fieldValue) : field.fieldValue;
                }
                else {
                    if (field.fieldName === 'Is_Primary' && field.fieldValue) {
                        // if Is_Primary is true, hightlight the row with  color text
                        // row.RowClass = row.RowClass + ' slds-text-color_success';
                        row.iconName = 'utility:record';
                        row.iconAlternativeText = 'Primary';
                    }
                    if (field.fieldName === 'Status' && field.fieldValue === 'Reserved') {
                        // 09-09-2020 if Status is Tentative, the row background is greyed
                        row.RowClass = row.RowClass + ' slds-color__background_gray-7';
                    }
                }

            }

            // Clone a copy of the row to pass to the handleBillingAccountClick method via the bwcActionLink custom column control, so it has access to all row values
            row.record = record;
            row.record.ban = row.F1;

            if (!service.accountType) {
                row.record.ban = service;
            }
            row.record.service = this.handleServiceNameLogic(service);
            row.record.recordId = row.F0;
            row.record.serviceName = serviceObject.serviceName;
            row.record.isL1 = serviceObject.isL1;
            row.record.isByPass = serviceObject.isByPass;

            data.push(row);
        }
        return data;
    }

    handleServiceNameLogic(service) {

        if (service.accountType) {
            return service.accountType;
        }
        //ban for device
        return service;

    }

    createColumns(records, type) {

        let columns = [];
        let field = records[0].fields[1];

        columns.push(
            {
                label: field.fieldLabel,
                fieldName: 'record',
                type: 'actionLink',
                hideDefaultActions: true,
                fixedWidth: 125,
                typeAttributes: {
                    label: { fieldName: 'F1' },
                    onactionclick: this.handleBillingAccountClick.bind(this)
                }
            }
        );
        for (let idx = 2; idx < records[0].fields.length; idx++) {
            field = records[0].fields[idx];
            // 09-09-2020 Dont add column for fields Is_Primary and Status as they are used for UI settings
            // 01-08-2021 Dont show Id field  on UI that is now sent by controller
            if (field.fieldName === 'Is_Primary'
                || field.fieldName === 'Status'
                || field.fieldName === 'Id'
                || field.fieldName === 'Manufacturer__c'
                || field.fieldName === 'Make_And_Model__c'
                || field.fieldName === 'Product_Name_360__c') {
                continue;
            }
            if (typeof field.fieldValue === "boolean") {
                columns.push(
                    {
                        label: field.fieldLabel,
                        fieldName: 'F' + idx,
                        type: 'checkbox',
                        cellAttributes: {
                            class: field.isHidden ? 'slds-color__background_gray-5' : { fieldName: "RowClass" }
                        },
                        hideDefaultActions: true
                    }
                );
            }
            else {
                //Adding icon User Column
                if (field.fieldName === 'User__c') {
                    columns.push(
                        {
                            label: field.fieldLabel,
                            fieldName: 'F' + idx,
                            type: currencyFields.includes(field.fieldName) ? 'currency' : 'text',
                            cellAttributes: {
                                iconName: { fieldName: "iconName" },
                                iconAlternativeText: { fieldName: 'iconAlternativeText' }
                            },
                            hideDefaultActions: true,
                            fixedWidth: idx < 3 ? 150 : undefined
                        }
                    );
                } else {
                    columns.push(
                        {
                            label: field.fieldLabel,
                            fieldName: 'F' + idx,
                            type: currencyFields.includes(field.fieldName) ? 'currency' : 'text',
                            cellAttributes: {
                                class: field.isHidden ? 'slds-color__background_gray-5' : { fieldName: "RowClass" },
                                alignment: 'left',
                                wrapText: true
                            },
                            hideDefaultActions: true,
                            fixedWidth: idx < 3 ? 150 : undefined
                        }
                    );
                }

            }
        }
        if (hasLICPermission) {
            if (type === 'plans') {
                columns.push({ type: 'action', typeAttributes: { rowActions: this.getPlanRowActions } });
            }
            else {
                columns.push({ type: 'action', typeAttributes: { rowActions: this.getEquipmentRowActions } });
            }
        }

        return columns;
    }

    handleExpandCollapseClick(event) {

        event.stopPropagation();

        const div = this.template.querySelector(`[data-id="${event.target.dataset.item}"`);

        if (!div) {
            // Clicking on label span, ignore
            return;
        }

        if (div.classList.contains('slds-is-open')) {
            div.classList.remove('slds-is-open');
        }
        else {
            div.classList.add('slds-is-open');
        }

    }

    /*
        Refresh of one service.
    */
    async onItemRefreshClick(event) {

        const service = this.customerServices.find(serv => serv.serviceName === event.target.dataset.serviceName);
        service.isLoading = true;
        service.errorMessage = undefined;
        await this.refresh([service.ban], true);

    }

    /*
        StepUp authentication of an L0 ban.
    */
    onItemStepUpClick(event) {

        this.stepUp(event.target.dataset.serviceName);

    }

    /*
        Initiate step-up authentication.
    */
    stepUp(serviceName, callback) {

        try {

            const service = this.servicesByName[serviceName];

            // Open the step-up modal
            // Even if there are no step-ups, we'll let the modal give that information
            this.template.querySelector('c-bwc-step-up').open(this.recordId, service.ban, service.accountType, service.unifiedBan, async steppedUpBans => {

                // Refresh the services
                const servicesToRefresh = this.customerServices.filter(customerService => steppedUpBans.includes(customerService.ban));
                servicesToRefresh.forEach(serviceToRefresh => {
                    serviceToRefresh.isLoading = true;
                    serviceToRefresh.errorMessage = undefined;
                });

                await this.refresh(steppedUpBans, true);

                // Run any callback to do another step
                if (callback) {
                    callback();
                }

            });

        }
        catch (error) {
            super.handleError(error, label_unexpectedError, 'Services', 'inline');
        }

    }

    /*
        Retry button, only shows on error.
    */
    onRetryClick() {

        this.refresh(undefined, true);

    }

    /*
        User clicked on the Billing Account / Phone Number link
    */
    handleBillingAccountClick(event) {

        // Get the record from event detail
        const record = event.detail.value;

        // If L0, need to step up before opening
        const service = this.servicesByName[record.serviceName];
        if (service.isL0) {
            this.stepUp(record.serviceName, () => {
                this.openBillingAccount(record);
            });
            return;
        }

        // Not L0, can open
        this.openBillingAccount(record);

    }

    /*
        Open billing account detail pages.
    */
    openBillingAccount(record) {

        // Open the sub tab using Ban as tab label
        const openSubTabMessage = {
            pageReference: {
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: 'Billing_Account__c',
                    recordId: record.recordId,
                    actionName: "view"
                }
            },
            label: record.ban
        };
        BwcUtils.openSubTab(openSubTabMessage);

        // Log the interaction activity
        createActivity(this.recordId, InteractionActivityValueMapping.BanInquiry, record);

    }

    /*
        Get billing actions based upon row data.
    */
    getPlanRowActions(row, doneCallback) {
        //needed for diffrent actions on certain rows

        const isDisabled = !row.record.isL1 && !row.record.isByPass;
        let menuOption = [];

        switch (row.record.service) {
            case BwcConstants.BillingAccountType.WIRELESS.value:

                menuOption.push({ label: 'Add a Line', name: 'AddLine', ban: row.F1, disabled: isDisabled, iconName: 'utility:new_window' });
                if (row.planEscalateAddLine) {
                    menuOption.push({ label: 'Escalate For Device | Upgrade', name: 'PlanEscalateAddLine', ban: row.F1, disabled: isDisabled });
                }
                menuOption.push({ label: 'Change Plan', name: 'ChangePlanWireless', ban: row.F1, disabled: isDisabled, iconName: 'utility:new_window' });
                if (row.planEscalateChangePlan) {
                    menuOption.push({ label: 'Escalate For Rate Plan | Add Change Remove', name: 'PlanEscalateRatePlan', ban: row.F1, disabled: isDisabled });
                }
                break;

            case BwcConstants.BillingAccountType.UVERSE.value:

                menuOption.push({ label: 'Change Plan', name: 'ChangePlanUverse', ban: row.F1, disabled: isDisabled, iconName: 'utility:new_window' },
                    { label: 'Change Services(ie, equipment, premium add ons)', name: 'ChangeServices', ban: row.F1, disabled: isDisabled }
                );
                break;

            case BwcConstants.BillingAccountType.DTVNOW.value:

                menuOption.push({ label: 'Change Plan', name: 'ChangePlanDTVNow', ban: row.F1, disabled: isDisabled, iconName: 'utility:new_window' },
                    { label: 'Change Services(ie, equipment, premium add ons)', name: 'ChangeServices', ban: row.F1, disabled: isDisabled }
                );
                break;

            // for both DTV Legacy and DTV
            case BwcConstants.BillingAccountType.DTVS.value:
            case BwcConstants.BillingAccountType.DTV.value:


                menuOption.push({ label: 'Change Plan', name: 'ChangePlanDTV', ban: row.F1, disabled: isDisabled, iconName: 'utility:new_window' },
                    { label: 'Change Services(ie, equipment, premium add ons)', name: 'ChangeServices', ban: row.F1, disabled: isDisabled },
                    { label: 'Change Protection Plan', name: 'ChangeProtectionPlan', ban: row.F1, disabled: isDisabled }
                );
                break;

            default:

                menuOption.push({ label: 'Change Plan', name: 'ChangePlan', ban: row.F1, disabled: isDisabled, iconName: 'utility:new_window' },
                    { label: 'Change Services(ie, equipment, premium add ons)', name: 'ChangeServices', ban: row.F1, disabled: isDisabled, iconName: 'utility:new_window' }
                );
        }
        doneCallback(menuOption);
    }

    /*
        Get billing actions based upon row data.
    */
    getEquipmentRowActions(row, doneCallback) {
        //needed for diffrent actions on certain rows

        const isDisabled = !row.record.isL1 && !row.record.isByPass;
        let equipmentStatus = (row.record.fields.find(rowField => rowField.fieldName === 'Status')) ? row.record.fields.find(rowField => rowField.fieldName === 'Status').fieldValue : '';

        //first FilterValue
        let Product_Name_360__c = (row.record.fields.find(rowField => rowField.fieldName === 'Product_Name_360__c')) ? row.record.fields.find(rowField => rowField.fieldName === 'Product_Name_360__c').fieldValue : '';

        let menuOption = [];
        menuOption.push({ label: 'Upgrade Device', name: 'UpgradeDevice', ban: row.record.service, disabled: isDisabled, iconName: 'utility:new_window' });

        if (row.lineEscalateUpgradeDevice) {
            menuOption.push({ label: 'Escalate For Device | Upgrade', name: 'LineUpgradeDevice', ban: row.record.service, disabled: isDisabled });
        }

        if (equipmentStatus === 'Active' || equipmentStatus === 'Suspended') {
            menuOption.push({ label: 'Device Support', name: 'DeviceSupport', ban: row.record.service, disabled: isDisabled, iconName: 'utility:new_window' },
                { label: 'Device Issues', name: 'DeviceIssues', ban: row.record.service, disabled: isDisabled, iconName: 'utility:new_window' },
                { label: 'Service Issues', name: 'ServiceIssues', ban: row.record.service, disabled: isDisabled, iconName: 'utility:new_window' });
        }
        if (Product_Name_360__c === 'digitallife') {
            for (let i = 0; i < menuOption.length; i++) {
                if (menuOption[i].label === 'Device Support') { menuOption.splice(i, 1); }
            }
        }
        doneCallback(menuOption);
    }

    /*
        Handle action menu selection for the table row.
    */
    handleProductRowAction(event) {

        const row = event.detail.row;

        switch (event.detail.action.name) {
            case 'AddLine':
                this.createInteractionActivity(InteractionActivityValueMapping.ProductServiceAddaline, 'plan', row);
                row.planEscalateAddLine = true;
                this.LICToOpus(event);
                break;
            case 'ChangePlan':
                this.LICToOpus(event);
                row.planEscalateChangePlan = true;
                break;
            case 'ChangePlanWireless':
                this.createInteractionActivity(InteractionActivityValueMapping.ChangePlanWireless, 'plan', row);
                row.planEscalateChangePlan = true;
                this.LICToOpus(event);
                break;
            case 'ChangePlanUverse':
                this.createInteractionActivity(InteractionActivityValueMapping.ChangePlanUverse, 'plan', row);
                row.planEscalateChangePlan = true;
                this.LICToOpus(event);
                break;
            case 'ChangePlanDTVNow':
                this.createInteractionActivity(InteractionActivityValueMapping.ChangePlanDTVStream, 'plan', row);
                row.planEscalateChangePlan = true;
                this.LICToOpus(event);
                break;
            case 'ChangePlanDTV':
                this.createInteractionActivity(InteractionActivityValueMapping.ChangePlanDTV, 'plan', row);
                row.planEscalateChangePlan = true;
                this.LICToOpus(event);
                break;
            case 'ChangeServices':
                this.createInteractionActivity(InteractionActivityValueMapping.ProductServiceChangeServices, 'plan', row);
                this.LICToOpus(event);
                break;
            case 'ChangeProtectionPlan':
                // TODO: Interaction Activity Action to be defined for Change Protection Plan
                // this.createInteractionActivity(BwcConstants.InteractionActivityValueMapping.ProductServiceChangeServices.action, 'plan', row);
                this.LICToOpus(event);
                break;
            case 'UpgradeDevice':
                this.createInteractionActivity(InteractionActivityValueMapping.ProductServiceDeviceUpgrade, 'equipment', row);
                row.lineEscalateUpgradeDevice = true;
                this.LICToOpus(event);
                break;
            case 'DeviceSupport':
                this.handleDeviceSupport(row);
                this.createInteractionActivity(InteractionActivityValueMapping.TroubleshootResolveDeviceSupport, 'equipment', row);

                break;
            case 'ServiceIssues':
                // handles same functionality
                this.handleDeviceIssues(row);
                //need to add ServiceIssues to action picklist
                this.createInteractionActivity(InteractionActivityValueMapping.TroubleshootResolveServiceIssues, 'equipment', row);

                break;
            case 'DeviceIssues':
                this.handleDeviceIssues(row);
                this.createInteractionActivity(InteractionActivityValueMapping.TroubleshootResolveDeviceIssues, 'equipment', row);

                break;
            case 'PlanEscalateAddLine':
                this.handleEscalate(row, 'PlanEscalateAddLine');
                break;
            case 'PlanEscalateRatePlan':
                this.handleEscalate(row, 'PlanEscalateRatePlan');
                break;
            case 'LineUpgradeDevice':
                this.handleEscalate(row, 'LineUpgradeDevice');
                break;
            default:
                BwcUtils.error('Services', 'Unknown action: ' + event.detail.action.name);
                break;
        }


    }
    handleDeviceIssues(rowData) {
        let ctn = (rowData.record.fields.find(rowField => rowField.fieldName === 'Phone_Number__c')) ? rowData.record.fields.find(rowField => rowField.fieldName === 'Phone_Number__c').fieldValue : '';
        let ban = (rowData.record.ban) ? rowData.record.ban : '';

        //bwcTSRMLauncher.launchTSRMFromVF(this.recordId,ctn,ban);
        bwcTSRMLauncher.launchTSRM(this.recordId, ctn, ban);

    }
    handleDeviceSupport(rowData) {
        let urlParam = DeviceURL;
        let manufacturer = (rowData.record.fields.find(rowField => rowField.fieldName === 'Manufacturer__c')) ? rowData.record.fields.find(rowField => rowField.fieldName === 'Manufacturer__c').fieldValue : '';
        let makeAndModel = (rowData.record.fields.find(rowField => rowField.fieldName === 'Make_And_Model__c')) ? rowData.record.fields.find(rowField => rowField.fieldName === 'Make_And_Model__c').fieldValue : '';
        urlParam = (manufacturer) ? urlParam + manufacturer + '/' + makeAndModel : urlParam;

        bwcOpenNewBrowserTabPublisher.publishMessage(urlParam);


    }
    createInteractionActivity(action, planOrEquipment, row) {

        // Find ID field
        const planOrEquipmentId = row.record.fields.find(rowField => rowField.fieldName === 'Id')?.fieldValue;
        const billingAccountId = row.record.fields.find(rowField => rowField.fieldName === 'Billing_Account__c')?.fieldValue;
        const manufacturer = row.record.fields.find(rowField => rowField.fieldName === 'Manufacturer__c')?.fieldValue || '';
        const makeAndModel = row.record.fields.find(rowField => rowField.fieldName === 'Make_And_Model__c')?.fieldValue || '';
        const ctn = row.record.fields.find(rowField => rowField.fieldName === 'Phone_Number__c')?.fieldValue || '';

        // Create record detail for interaction activity
        const activityRecordDetail = {
            ban: row.record.ban,
            ctn: ctn,
            manufacturer: manufacturer,
            makeAndModel: makeAndModel,
            service: row.record.service,
            serviceName: row.record.serviceName,
            planId: planOrEquipment === 'plan' ? planOrEquipmentId : undefined,
            assetId: planOrEquipment === 'equipment' ? planOrEquipmentId : undefined
        };

        const additionalParams = {
            billingAccountId,
            planId: planOrEquipment === 'plan' ? planOrEquipmentId : undefined,
            assetId: planOrEquipment === 'equipment' ? planOrEquipmentId : undefined
        }


        createActivity(this.recordId, action, activityRecordDetail, additionalParams);

    }

    LICToOpus(event) {
        const msg = 'PostToOpus';
        const licObj = {};
        licObj.launchPoint = 'Launch Point';
        licObj.JsonData = {};
        if (event.detail.action.ban) {

            bwcLICPublisher.publishMessage(msg, licObj, event.detail.action.ban);

        }

    }

    handleLmsRefresh(scope, recordId) {
        if (!scope && recordId === this.recordId) {
            this.refresh();
        }
    }

    handleExpandEvent(event) {
        event.stopPropagation();

        const expandableSections = [...this.template.querySelectorAll("c-bwc-expandable-section")];
        const sectionsCounter = {
            expanded: 0,
            closed: 0
        };
        expandableSections.forEach((section) => {
            const key = section.isExpanded ? 'expanded' : 'closed';
            sectionsCounter[key]++;
        });

        this.isExpanded = sectionsCounter.expanded === expandableSections.length;
    }

    handleExpandClick() {
        this.isExpanded = !this.isExpanded;

        let expandableSections = [...this.template.querySelectorAll('c-bwc-expandable-section')];
        expandableSections.forEach(section => {
            section.expandCollapseSection(this.isExpanded);
        });
    }

    get expandCollapseLabel() {
        return this.isExpanded ? 'Collapse All' : 'Expand All';
    }

    completionSubscription;
    @wire(MessageContext)
    messageContext;

    handleEscalate(row, type) {
        const service = this.customerServices.find(serv => serv.serviceName === row.record.serviceName);
        service.isLoading = true;
        service.errorMessage = undefined;

        this.completionSubscription = subscribe(
            this.messageContext,
            COMPLETIONMC, (message) => {
                this.escalationComplete(message);
            }
        );

        let ecType;
        let ecFeature;

        if (type === 'PlanEscalateAddLine' || type === 'LineUpgradeDevice') {
            ecType = BwcConstants.HighLevelCaseType.Product_Service_Device_Upgrade.type;
            ecFeature = BwcConstants.HighLevelCaseType.Product_Service_Device_Upgrade.feature;
        } else {
            ecType = BwcConstants.HighLevelCaseType.Product_Service_Rate_Plan.type;
            ecFeature = BwcConstants.HighLevelCaseType.Product_Service_Rate_Plan.feature;
        }

        bwcDispatchEscalationCase.publishEscalationCaseMessage(
            this.recordId,
            ecType,
            ecFeature,
            JSON.stringify(
                {
                    ban: row.record.ban,
                    ctnInContext: type === 'LineUpgradeDevice' ? row.F1 : ''
                }
            )
        );

        this.template.querySelector('div').click();
    }

    escalationComplete(message) {
        unsubscribe(this.completionSubscription);
        this.completionSubscription = null;
        this.isLoadingMain = false;
        this.isLoading = false;
        this.customerServices.forEach(service => { service.isLoading = false; });
    }

    selectedBillingAccountId;
    handleWFEClick(event) {

        const ban = event.currentTarget.dataset.record;
        this.customerServices.forEach(service => {
            if (service.hasPlanPackages) {
                service.planData.forEach(plan => {
                    if (plan.record.ban === ban) {
                        this.selectedBillingAccountId = plan.record.recordId;
                    }
                });
            }
        });

        this.template.querySelector('c-bwc-launch-w-f-e').open(InteractionActivityValueMapping.WFEGeneralSupport,ban,this.selectedBillingAccountId,true,this.recordId);
    }
    handleHeaderBANClick(event){
        event.preventDefault();

        const recordId = event.target.dataset.id;
        const ban = event.target.dataset.ban;

        const record = {
            recordId,
            ban,
        };

        this.openBillingAccount(record);
    }
}
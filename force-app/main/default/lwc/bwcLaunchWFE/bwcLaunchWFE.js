import { api, track, wire } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcBillingAccount from 'c/bwcBillingAccount';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcLabelServices from 'c/bwcLabelServices';
import * as BwcLicWfeService from 'c/bwcLICWFEService';
import { createActivity } from 'c/bwcInteractionActivityService';

//import for LMS
import MSG_WFE_WINDOW_CLOSE from "@salesforce/messageChannel/BWC_WFEWindowClose__c";

export default class BwcLaunchWFE extends BwcPageElementBase {
    // Labels
    labels = BwcLabelServices.labels;
    title = 'Select Account'
    isOpen;
    isBusy;

    interactionId;
    billingAccounts;                            // All billing accounts for the interaction
    @track billingAccountOptions = [];          // Options for combo box
    selectedBillingAccountId;                   // Currently selected BAN
    selectedBillingAccount;                     // Corresponding billing account for the selected ban
    actionType;                                 // Action Type for Interaction Activity to be logged.
    isAuthorized = true;                          // Setting it to true for all authenticated flows

    winRefs = {};

    /*
        Start step-up authentication for the specific interaction and ban.
    */
    @api async open(actionType,ban,billingAccountId,isAuthorized,interactionId) {

        this.actionType = actionType;                           //Used in interaction activity creation
        this.interactionId = interactionId;
        if(isAuthorized !== undefined) {
            this.isAuthorized = isAuthorized;
        }
        //If there is only one uverse BAN
        if(ban){
            this.selectedBillingAccountId = billingAccountId;
            this.getWFEURLandLaunch(isAuthorized,ban);
        }else{                                  // IF there are multiple uverse BAN
            this.isBusy = true;
            try {
                this.interactionId = interactionId;
                const BILLING_ACCOUNT_TYPES = [
                    BwcConstants.BillingAccountType.UVERSE.value
                ];
                // Build selection list of billing accounts
                this.billingAccounts = await BwcAccountServices.getBillingAccounts(interactionId, true, false, BILLING_ACCOUNT_TYPES);
                BwcUtils.log('LaunchWFE >  billingAccounts ' + JSON.stringify(this.billingAccounts));
                // Build options
                this.billingAccountOptions = this.billingAccounts.map(billingAccount => {
                    return {
                        label: BwcBillingAccount.BillingAccount.fromRecord(billingAccount).serviceLabel,
                        value: billingAccount.Id,
                        accountType: billingAccount.Account_Type__c,
                        recordId: billingAccount.Id
                    };
                });
    
                // Default to first billing account
                if (!this.selectedBillingAccountId && this.billingAccountOptions.length > 0) {
                    this.selectedBillingAccountId = this.billingAccountOptions[0].value;
                }

                if(this.billingAccounts.length > 1) {
                    this.isOpen = true;
                } 
                else if (this.billingAccounts.length === 1) {
                    this.getWFEURLandLaunch(true,this.billingAccounts[0].Billing_Account_Number__c);
                }
            }
            catch (error) {
                super.handleError(error);
            }
            finally {
                this.isBusy = false;
            }
        }
    }
    /*
        BAN has been selected.
    */
    async handleBillingAccountSelected(event) {
        if (event) {
            this.selectedBillingAccountId = event.target.value;
        }
    }
    /*
        Capture tabbing so it cycles within the modal.
    */
    handleButtonKeydown(event) {

        //If tabbing forward and this is last button, override and circle back to X button
        if (event.target.dataset.name === 'launchWFE' && event.key === "Tab" && !event.shiftKey) {

            event.preventDefault();
            let closeButton = this.template.querySelector('lightning-button-icon[data-name="closeButton"');
            if (closeButton) {
                closeButton.focus();
            }
        }
        else if (event.target.dataset.name === 'closeButton' && event.key === "Tab" && event.shiftKey) {
            event.preventDefault();
            let rightButton = this.template.querySelector('lightning-button[data-name="launchWFE"');
            if (rightButton) {
                rightButton.focus();
            }
        }
    }

    handleClose() {
        this.close();
    }

    /*
        Close the modal.
    */
    close() {
        this.isOpen = false;
    }

    /*
        Handle Launch WFE
    */
    handleLaunchWFE (){
        let ban;
        this.billingAccounts.forEach(billingAccount => {
            if( billingAccount.Id === this.selectedBillingAccountId){
                ban = billingAccount.Billing_Account_Number__c;
            }
        });
        this.getWFEURLandLaunch(true,ban);       
    }

    async getWFEURLandLaunch (isAuthorized,ban){
        this.createInteractionActivity();
        BwcUtils.log(' getWFEURLandLaunch '+ban);

        const getRequestData = await BwcLicWfeService.getLICWFEUrl(isAuthorized, ban);
        BwcUtils.log(' getRequestData ' + JSON.stringify(getRequestData));

        let isaacURL = await BwcLicWfeService.handleFetch(getRequestData.requestBody, getRequestData.endPoint, this.interactionId);
        BwcUtils.log(' isaacURL '+isaacURL);
        const payload = { msg: "OPEN" , ban: ban , url: isaacURL };
        BwcUtils.log('payload '+JSON.stringify(payload));
        this.publishMessage(MSG_WFE_WINDOW_CLOSE, payload);
    }

    //Creates interaction activity on WFE Tech Support or Launch WFE button click
    async createInteractionActivity () {
        BwcUtils.log(' actionType ='+this.actionType);
        BwcUtils.log(' selectedBillingAccountId ='+this.selectedBillingAccountId);
        if(this.actionType) {
            if(this.selectedBillingAccountId){
                try{
                    this.isBusy = true;
                    // Create record detail for interaction activity
                    const activityRecordDetail = {
                        isAuthenticated: this.isAuthorized,                              
                        status: this.isAuthorized ? "success" : "failed"                                 
                    };
                    //Sets billing account Id on interaction activity
                    const additionalParams = { billingAccountId : this.selectedBillingAccountId };
                    BwcUtils.log(`InteractionActivity>activityRecordDetail:${activityRecordDetail}`);

                    createActivity(this.interactionId, this.actionType, activityRecordDetail, additionalParams);
                }catch(error){
                    super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
                }
                finally {
                    this.isBusy = false;
                }
            }
        }
    }
}
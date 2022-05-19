import { LightningElement, api, track } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcCpniConsentServices from 'c/bwcCpniConsentServices';
import * as BwcInteractionServices from 'c/bwcInteractionServices';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcConstants from 'c/bwcConstants';

import consentMessageEnglish from '@salesforce/label/c.BWC_CpniConsentMessage';
import consentMessageSpanish from '@salesforce/label/c.BWC_CpniConsentMessage_Spanish';
import permanentConsentMessageEnglish from '@salesforce/label/c.BWC_CpniPermanentConsentMessage';
import permanentConsentMessageSpanish from '@salesforce/label/c.BWC_CpniPermanentConsentMessage_Spanish';

export default class BwcCpniConsent extends LightningElement {

    @api recordId;
    interaction;
    billingAccount;

    languageOptions = [
        {label: 'English', value: 'English'},
        {label: 'Spanish', value: 'Spanish'}
    ];
    selectedLanguageOption = 'English';

    @track consentOptions = [
        {label: 'Yes, Consent will be GRANTED for this interaction only', value: 'Consent Granted'},
        {label: 'No, Consent will be DENIED for this interaction only', value: 'Consent Denied'}
    ];
    selectedConsentOption;
    get isSelectedPermanent() {return this.selectedConsentOption === 'Permanent';}

    permanentConsentOptions = [
        {label: 'Yes, approved permanent consent (CPNI opt-in)', value: 'Permanent/Yes'},
        {label: 'No, initiate permanent opt-out', value: 'No'}
    ]
    selectedPermanentConsentOption;

    get consentText() {return this.selectedLanguageOption === 'Spanish' ? consentMessageSpanish: consentMessageEnglish;}
    get permanentConsentText() {return this.selectedLanguageOption === 'Spanish' ? permanentConsentMessageSpanish: permanentConsentMessageEnglish;}

    isBusy;
    get errorReports() {return this.template.querySelector('c-bwc-error-reports');}

    isRendered = false;
    renderedCallback() {
        // Do on first render
        if (!this.isRendered) {
            this.isRendered = true;
            // Get interaction
            this.initialize();
        }
    }

    async initialize() {
        // Get interaction
        this.interaction = await BwcInteractionServices.getInteraction(this.recordId);
        // Get Billing Account
        this.billingAccount = await BwcAccountServices.getBillingAccountForBan(this.interaction.Billing_Account_Number__c);

        // Add permanent consent option only if account is not POTS
        if (this.billingAccount.Account_Type__c.toLowerCase() !== BwcConstants.BillingAccountType.POTS.value) {
            this.consentOptions.push({label: 'Permanent Consent', value: 'Permanent'});
        }
    }

    handleLanguageChange(event) {
        this.selectedLanguageOption = event.detail.value;
    }

    handleConsentOptionChange(event) {
        this.selectedConsentOption = event.detail.value;
    }

    handlePermanentConsentOptionChange(event) {
        this.selectedPermanentConsentOption = event.detail.value;
    }

    /*
        Submit button.
    */
    handleSubmit() {

        // Validate required
        if (!BwcUtils.reportValidity(this.template)) {
            return;
        }

        this.submitConsent();

    }

    resetAuthenticationMethod() {
        if (this.errorReports) {
            this.errorReports.clearErrors();
        }
    }

    async submitConsent() {

        this.resetAuthenticationMethod();

        // Build response value -- if permanent, use value of sub-radio button selection.
        const response = this.selectedConsentOption === 'Permanent' ? this.selectedPermanentConsentOption : this.selectedConsentOption;

        if (response == 'Permanent/Yes' || response == 'No') {

            this.isBusy = true;

            const preference = response == 'Permanent/Yes' ? 'Y' : 'N';

            try {
                // Build request to validate passcode
                const request = {
                    "consentPreferences" : [
                        {
                            "consentType" : "CPNI",
                            "preference" : preference,
                            "market" : this.billingAccount.Billing_Market__c
                        }
                    ]
                }

                // Update CPNI Consent Callout
                const result = await BwcCpniConsentServices.updateCpniConsent(request, this.interaction.Billing_Account_Number__c);

                if (result.status !== 'SUCCESS') {
                    BwcUtils.log(`Update CPNI Consent Preference Failed`, JSON.stringify(result));
                    this.notifySelection('');
                } else {
                    this.notifySelection(response);
                }

            }
            catch(error) {
                BwcUtils.log(`Update CPNI Consent Preference Failed: `, error);
                this.notifySelection('');
            } finally {
                this.isBusy = false;
            }

        } else {
            this.notifySelection(response);
        }
    }

    notifySelection(response) {
        // Fire cpnisubmitted event
        this.dispatchEvent(new CustomEvent('cpnisubmitted',  {detail: {response}}));
    }

}
import { LightningElement, api } from 'lwc';

// Labels
import prepaidAccountNotice from '@salesforce/label/c.BWC_PrepaidAccountNotice';
import loginLabel from '@salesforce/label/c.BWC_Login';
import kicCareUrl from '@salesforce/label/c.BWC_KICCare_Url';

/*
    Message used in a number of contexts to notify agent of a prepaid account and provide a login link.
*/
export default class BwcPrepaidNotification extends LightningElement {

    labels = {
        prepaidAccountNotice,
        loginLabel,
        kicCareUrl
    }

    // Pass thru 'inline' or 'scoped' notification
    @api type = 'scoped'
    
    get isTypeInline() {return this.type === 'inline';}
    get isTypeScoped() {return this.type === 'scoped';}

}
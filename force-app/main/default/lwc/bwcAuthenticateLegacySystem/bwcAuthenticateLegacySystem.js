import { LightningElement } from 'lwc';

// Labels
import authLegacySystemMessage from '@salesforce/label/c.BWC_Auth_LegacySystem_Message';

export default class BwcAuthenticateLegacySystem extends LightningElement {
    
    labels = {
        message : authLegacySystemMessage
    }   

    handleBack(event) {
        // Fire authenticated event 
        this.dispatchEvent(new CustomEvent('back'));
    }
}
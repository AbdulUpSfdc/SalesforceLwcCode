import { LightningElement } from 'lwc';
import changePasscodeLabel from '@salesforce/label/c.BWC_PasscodeAuthentication_Failed';

export default class BwcChangePasscodeNotification extends LightningElement {
    labels = {
        changePasscodeLabel
    }
}
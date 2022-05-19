import { LightningElement, track } from 'lwc';
import getUserData from '@salesforce/apex/SMSNotificationOptInOut.getUserData';
import setUserData from '@salesforce/apex/SMSNotificationOptInOut.setUserData';

export default class Lead_Enable_Disable_SMS_Notification extends LightningElement {
    @track isEnabled = false;

    handleChange(event) {
        this.isEnabled = event.target.checked;
        console.log('Enabled=1==>>>>'+ this.isEnabled );
        setUserData({isEnabled: this.isEnabled })
            .then((result) => {

            })
            .catch((error) => {
                this.error = error;
                
            });
    }
    connectedCallback() {
        getUserData()
            .then(result => {
                this.isEnabled = result;
                console.log('Enabled===>>>>'+ this.isEnabled );
            })
            .catch(error => {
                this.error = error;
            });
    }
}
import { LightningElement,api,wire,track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import DCIMobFlexiPage from '@salesforce/resourceUrl/DCIMoBFlexiPage';
import validateStatus from '@salesforce/apex/DCIChangeCustomerStatusController.validateStatus';
import errorTitle from '@salesforce/label/c.Error';
import displayComponent from '@salesforce/apex/dciModFlexipageDisplayController.displayComponent';
import {ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class DCIModFlexiPage extends LightningElement {
    renderedCallback() {
        Promise.all([
            loadStyle( this, DCIMobFlexiPage )
            ]).then(() => {
                console.log( 'Files loaded' );
            })
            .catch(error => {
                console.log( error.body.message );
        });
    }
@api recordId;
@api actionType;
@track openModal = false;
@track isValidStatus = false;
@track displayComp = false;
@track resultMap = [];
handleButtonClick(event) {
    this.actionType = event.target.dataset.name;       
    validateStatus({
            recordId: this.recordId,
            action: this.actionType
        })
        .then(data => {
            console.log(data);
            if (data.isValid) {
                this.openModal = true;
            } else {
                const toastEvent = new ShowToastEvent({
                    title: errorTitle,
                    message: data.errorMessage,
                    variant: 'error'
                });
                this.dispatchEvent(toastEvent);
            }
        }).catch(error => {
            const toastEvent = new ShowToastEvent({
                title: 'Error',
                message: 'Error! ' + JSON.stringify(error),
                variant: 'error'
            });
            this.dispatchEvent(toastEvent);
            console.log("Error thrown" + JSON.stringify(error));
        });
}

refreshViews() {
    setTimeout(location.reload.bind(location),2000);//tapaswini
}
closeAction() {
    this.openModal = false;
    this.refreshViews();
}
handleToast(result) {

    const toastEvent = new ShowToastEvent({
        title: result.status,
        message: result.message,
        variant: result.type,
        mode:'pester'//tapaswini
        
    });
    this.dispatchEvent(toastEvent);
}
handleSubmit(event) {
    var result = event.detail;
    this.handleToast(result);

    this.closeAction();
}
connectedCallback() {
this.displayComponent();
}
displayComponent(){
displayComponent()
    .then(result => {
        this.displayComp = result;
    })
    .catch(error => {
        this.error = error;
    });
}
}
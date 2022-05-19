import { LightningElement, api } from 'lwc';

export default class SetAsManagerOnDutyUtilModal extends LightningElement {
    @api showSetButton;
    @api showUnSetButton;
    @api showCancelButton;
    @api cancelButtonLabel = 'Cancel';
    @api showModal;
    @api headerFromParent;
    @api showButtonName;
    


    handleSet() {
        this.dispatchEvent(new CustomEvent('set'));
    }
    handleUnSet() {
        this.dispatchEvent(new CustomEvent('unset'));
    }
    
    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }



}
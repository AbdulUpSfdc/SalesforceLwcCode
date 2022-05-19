import { LightningElement, api } from 'lwc';

export default class BwcPaymentDetails extends LightningElement {

    // Payment details value.
    @api paymentDetails = {
        paymentMethod: {}
    };

    // Raisr values
    @api spiData = {
        spiDataList: []
    }

}
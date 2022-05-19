import { LightningElement, api } from 'lwc';

/*
    Simple custom card implementation to handle some issues with padding and borders that aren't possible with lightning-card.
*/
export default class BwcCard extends LightningElement {

    @api title;

}
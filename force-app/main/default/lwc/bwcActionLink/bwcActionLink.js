import { LightningElement, api } from 'lwc';

/*
    Implements a custom table cell for bwcDatatable.
    Allows specification of a link that can handle click event with any code.
*/
export default class BwcActionLink extends LightningElement {

    @api label; // The link text, i.e. the text inside <a></a>
    @api value; // The value passed to whatever code handles the click event

    handleClick() {

        // Fire event, client gets value and can handle.
        this.dispatchEvent(new CustomEvent('actionclick', {detail: {value: this.value}}));

    }

}
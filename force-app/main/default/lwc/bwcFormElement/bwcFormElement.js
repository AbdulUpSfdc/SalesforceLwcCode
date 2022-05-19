import { LightningElement, api } from 'lwc';

/*
    Provides basic structure of a form element which can be used for read-only or other content.
    (No equivalent out-of-box component provides this.)
*/
export default class BwcFormElement extends LightningElement {

    @api label;

}
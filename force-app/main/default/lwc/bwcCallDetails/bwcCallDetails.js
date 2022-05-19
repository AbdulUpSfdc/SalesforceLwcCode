import {  api, track } from 'lwc';
import * as BwcInteractionServices from 'c/bwcInteractionServices';
import BwcPageElementBase from 'c/bwcPageElementBase';

const ALLOWED_SCOPES = [
    'customerSearch'
];

export default class BwcCallDetails extends BwcPageElementBase {

    @api recordId;
    @track interaction = {};

    connectedCallback() {
        super.connectedCallback();
        this.getInteraction();
    }

    async getInteraction(){
        this.interaction = await BwcInteractionServices.getInteraction(this.recordId);
    }

    handleLmsRefresh(scope, recordId){

        if(ALLOWED_SCOPES.includes(scope) || !scope){
            super.handleLmsRefresh(scope, recordId);
            this.getInteraction();
        }

    }


}
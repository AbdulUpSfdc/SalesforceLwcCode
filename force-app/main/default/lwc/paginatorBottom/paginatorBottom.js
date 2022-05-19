import { LightningElement, track,api } from 'lwc';

export default class PaginatorBottom extends LightningElement {
     isPrevious = false;
     isNext = true;
    previousHandler() {
        this.dispatchEvent(new CustomEvent('previous'));
    }

    nextHandler() {
        this.dispatchEvent(new CustomEvent('next'));
    }

    @api
    disablePrevious(){
        this.isPrevious = false;
    }
    @api
    disableNext(){
        this.isNext = false;
    }
    @api
    enablePrevious(){
        this.isPrevious = true;
    }
    @api
    enableNext(){
        this.isNext = true;
    }
}
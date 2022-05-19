import { api, LightningElement } from 'lwc';

export default class reuseableMonthlybilling extends LightningElement {
    @api header;
    @api subHeader;
    @api infolist;
    temp = 1;
    disable = false;

    handleSelect(event) {
        if (this.temp === 1) {
            console.log('value2--->', this.temp);
            this.template.querySelector('.border').classList.add('borderStyle');
            this.disable = true;
            // this.dispatchEvent(new CustomEvent('genericDataSelection', { detail: this.eventKey } ));
            this.temp = 2;

        } else if (this.temp === 2) {
            this.template.querySelector('.border').classList.remove('borderStyle');
            this.disable = false;
            this.temp = 1;
        }
    }
}
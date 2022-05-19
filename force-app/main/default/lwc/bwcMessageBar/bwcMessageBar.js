import { LightningElement, api } from 'lwc';

export default class BwcMessageBar extends LightningElement {

    @api variant = 'warning';
    @api text;
    @api iconName;
    @api texture;

    get _texture() {
        if(this.texture) {
            return `slds-theme_${this.texture}-texture`;
        }
        return this.variant === 'warning' || this.variant === 'error' ? `slds-theme_alert-texture` : ''
    }

    get topClass() {return `slds-p-around_small slds-theme_shade ${this._texture} ${this.variant}`;}

    get _iconName() {
        if (this.iconName) {
            return this.iconName;
        }
        switch(this.variant) {

            case 'success-light':
            case 'success-blue':
                return 'utility:success';

            default:
                return `utility:${this.variant}`;
        }
    }

    get iconVariant() {
        switch(this.variant) {

            case 'error':
                return 'inverse';

            case 'success-light':
                return 'success';

            default:
                return undefined;

        }

    }

}
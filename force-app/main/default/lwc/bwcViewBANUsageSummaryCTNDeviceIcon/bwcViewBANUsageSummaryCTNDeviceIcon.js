import { LightningElement, api } from 'lwc';
import svgUsagePhone from '@salesforce/resourceUrl/BWC_usagePhone';
import svgUsageTablet from '@salesforce/resourceUrl/BWC_usageTablet';
import svgUsageWatch from '@salesforce/resourceUrl/BWC_usageWatch';

export default class BwcViewBANUsageSummaryCTNDeviceIcon extends LightningElement {
    @api deviceType;

    get svgUrl() {
        switch (this.deviceType) {
            case 'Phone':
                return `${svgUsagePhone}#icon`;
            case 'Tablet':
                return `${svgUsageTablet}#icon`;
            case 'Wearable':
                return `${svgUsageWatch}#icon`;
            default:
                return `${svgUsagePhone}#icon`;
        }
    }

}
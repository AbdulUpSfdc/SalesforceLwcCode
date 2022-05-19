import { LightningElement, api } from 'lwc';
import * as BwcConstants from 'c/bwcConstants';

// SVG References
import AMEX_LOGO from '@salesforce/resourceUrl/AmExLogo';
import DINERS_LOGO from '@salesforce/resourceUrl/DinersClubLogo';
import DISCOVER_LOGO from '@salesforce/resourceUrl/DiscoverLogo';
import MASTERCARD_LOGO from '@salesforce/resourceUrl/MastercardLogo';
import VISA_LOGO from '@salesforce/resourceUrl/VisaLogo';

export default class BwcCardLogo extends LightningElement {

    @api cardType;
    @api height = '22';

    get svgStyle() {return `height: ${this.height}px;`;}

    get svgURL() {

        switch (this.cardType) {

            case BwcConstants.CardType.AMEX.value:
                return `${AMEX_LOGO}#logo`;

            case BwcConstants.CardType.DINERS.value:
                return `${DINERS_LOGO}#logo`;

            case BwcConstants.CardType.DISCOVER.value:
                return `${DISCOVER_LOGO}#logo`;

            case BwcConstants.CardType.MASTERCARD.value:
                return `${MASTERCARD_LOGO}#logo`;

            case BwcConstants.CardType.VISA.value:
                return `${VISA_LOGO}#logo`;

            default:
                return undefined;

        }

    }

}
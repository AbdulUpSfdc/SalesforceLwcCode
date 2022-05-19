import LightningDatatable from 'lightning/datatable';
import typeCheckbox from './typeCheckbox.html';
import typeActionLink from './typeActionLink.html';
import typeIconText from './typeIconText.html';

/*
    Extends lightning-datatable to allow custom column types.
*/
export default class BwcDatatable extends LightningDatatable  {

    static customTypes = {
        checkbox: {
            template: typeCheckbox
        },
        actionLink: {
            template: typeActionLink,
            typeAttributes: [
                'label', 'onactionclick'
            ]
        },
        iconText: {
            template: typeIconText,
            typeAttributes: [
                'iconName', 'iconVariant', 'iconAlternativeText', 'iconPosition'
            ]
        }
    };

}
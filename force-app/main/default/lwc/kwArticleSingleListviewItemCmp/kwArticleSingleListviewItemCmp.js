import { LightningElement, api } from 'lwc';
import heart_Resource from '@salesforce/resourceUrl/heart_image';

export default class KwArticleSingleListviewItemCmp extends LightningElement {
    @api aticleData;
    hertlogoURL = heart_Resource;
}
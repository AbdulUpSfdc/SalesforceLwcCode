import { LightningElement, api } from 'lwc';
import { BillingAccountType } from 'c/bwcConstants';

export default class BwcMakeAdjustmentHeader extends LightningElement {
    
    @api isGoodwill;
    @api customerName;
    @api serviceType;
    @api creationDate;
    @api howToApply;
    @api accountNumber;
    @api billingPeriod;
    @api billPaymentStatus;

    get serviceTypeLabel() {
        return BillingAccountType.getLabelForValue(this.serviceType);
    }

}
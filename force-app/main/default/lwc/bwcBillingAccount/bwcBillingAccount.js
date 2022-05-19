/*
    Shared components for billing accounts functionality.
*/

export const AccountStatus = {
    ACTIVE: {value: 'Active'},
    SUSPENDED: {value: 'Suspended'},
    CANCELED: {value: 'Canceled'}
}

/*
    Represents one billing account.
*/
export class BillingAccount { 

    // Properties
    ban;
    accountType;
    accountStatus;
    serviceTypeName;
    productName360;
    isUnified;
    unifiedBan;

    /*
        Construct a new instance from Billing_Account__c record.
    */
    static fromRecord(billingAccountRecord) {

        const newObject = new BillingAccount();
        newObject.ban = billingAccountRecord.Billing_Account_Number__c;
        newObject.accountType = billingAccountRecord.Account_Type__c;
        newObject.accountStatus = billingAccountRecord.Account_Status__c;
        newObject.serviceTypeName = billingAccountRecord.Service_Type_Name__c;
        newObject.productName360 = billingAccountRecord.Product_Name_360__c;
        newObject.isUnified = billingAccountRecord.Is_Unified__c;
        newObject.unifiedBan = billingAccountRecord.Unified_BAN__c;

        return newObject;

    }

    /*
        Returns a billing status for this billing account, based upon its status and balance/collection status.
    */
    getBillingStatus(paymentDetails) {

        if (this.accountStatus === AccountStatus.ACTIVE.value) {
            if (paymentDetails?.accountBalanceSummary?.amountPastDue) {
                return 'PastDue';
            }
            return 'GoodStanding';
        }
        else if (this.accountStatus === AccountStatus.SUSPENDED.value) {
            return 'Suspended';
        }
        else if (this.accountStatus === AccountStatus.CANCELED.value) {
            if (paymentDetails?.paymentRecommendations?.billingCollectionDetails?.ocaName) {
                return 'OCA';
            }
            return 'Canceled';
        }
        throw new Error('Unexpected billing status.');

    }

    /*
        Returns label like '<Service Type> - <BAN>';
        This replaces Billing_Account__c.Service_Name__c field which will be deprecated since it's a formula which can't be masked or unmasked per context.
    */
    get serviceLabel() {

        if (this.isUnified && this.productName360 === 'wireless') {
            return `Wireless - ${this.ban} (Unified - ${this.unifiedBan})`;
        }

        return `${this.serviceTypeName} - ${this.ban}`;
    }


    get unifiedLabel(){

        return this.isUnified && this.productName360 === 'wireless' ? ` (Unified - ${this.unifiedBan})` : '';
    }

}
import { LightningElement, api } from 'lwc';

const INVOLUNTARY_SUSPENSION = 'involuntary';
const VOLUNTARY_SUSPENSION = 'voluntary';

// Badge classes
const GREY_BADGE = 'grey-badge';
const YELLOW_BADGE = 'yellow-badge';
const RED_BADGE = 'red-badge';
export default class BwcBillingAccountStatusBadge extends LightningElement {

    @api status;
    @api suspensionStatus;

    renderedCallback(){
        this.setBadgeClass(this.status);
    }

    setBadgeClass(status){

        const badge = this.template.querySelector("lightning-badge");
        let statusLower = status ? status.toLowerCase() : '';
        let colorClass = '';
        switch(statusLower){
            case "active":
            case "tentative":
            case "pending":
                colorClass=GREY_BADGE
                break;
            case "past due":
            case "suspended":

                colorClass = this.getSuspensionStatusColor() || YELLOW_BADGE;

                break;
            case "canceled":
            case "cancelled":
            case "oca":
            case "outside collection agency":
                colorClass = RED_BADGE;
                break;
            default:
                colorClass=GREY_BADGE
                break;
        }
        colorClass+=' slds-badge'

        badge.className = colorClass;


    }

    getSuspensionStatusColor(){

        if(this.suspensionStatus === INVOLUNTARY_SUSPENSION){
            return YELLOW_BADGE;
        }

        if(this.suspensionStatus === VOLUNTARY_SUSPENSION){
            return GREY_BADGE;
        }

        return;
    }
}
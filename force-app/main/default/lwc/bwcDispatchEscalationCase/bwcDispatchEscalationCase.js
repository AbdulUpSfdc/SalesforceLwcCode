import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext, createMessageContext,releaseMessageContext } from 'lightning/messageService';
import ESCALATION_MC from "@salesforce/messageChannel/BWC_EscalationCase__c";

export const publishEscalationCaseMessage = (recordId, type, feature, detailRecord) => {
    console.log('publish Escalation Case message');
    const payload = {
        interactionId: recordId,
        type: type,
        feature: feature,
        detailRecord: detailRecord 
    };
    const messageContext = createMessageContext();
    publish(messageContext, ESCALATION_MC, payload);
};  


export default class BwcDispatchEscalationCase extends LightningElement {
    @wire(MessageContext) context = createMessageContext();

    @api launchEscalationCase(recordId, type, feature, detailRecord) {
        console.log('publish Escalation Case message');
        const payload = { 
            interactionId: recordId, 
            type: type,
            feature: feature,
            detailRecord: detailRecord 
        };

        publish(this.context, ESCALATION_MC, payload);
    }


}
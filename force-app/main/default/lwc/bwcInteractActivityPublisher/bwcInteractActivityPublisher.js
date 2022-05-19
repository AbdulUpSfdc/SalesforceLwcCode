import { LightningElement, api, wire } from 'lwc';
import { InteractionActivityValueMapping } from "c/bwcConstants";
import {publish, MessageContext, createMessageContext } from 'lightning/messageService';
import InteractionActivityChannel from '@salesforce/messageChannel/BWC_InteractionActivity__c';
import getInteractionId from '@salesforce/apex/BWC_InteractionActivity.getInteractionId';
import getInteractionRecord from '@salesforce/apex/BWC_InteractionActivity.getInteractionRecord';
import hasByPassRights from '@salesforce/customPermission/Interaction_Activity_ByPass';

export const publishMessage = (interactionIdparam,serviceActionFeature,detail,serviceAction)=>{


    getInteractionId({recordId : interactionIdparam})
    .then(result => {


        return getInteractionRecord({recordId: result});

    })
    .then(interaction=>{

        console.log({interaction});
        if(!interaction.CompletedDate__c || serviceActionFeature === InteractionActivityValueMapping.CompleteInteraction.action ){

            console.log('%cCreate Interaction activity','color:green;');

            const message = {
                interactionId: interaction.Id,
                action: serviceActionFeature,
                detailRecord: detail,
                type: serviceAction
            };

            publish(createMessageContext(), InteractionActivityChannel, message);
        }
    })
    .catch(error => {
       console.log(error);
    });

};
export default class BwcInteractActivityPublisher extends LightningElement {
    @wire(MessageContext)
    messageContext;
    @api publish(interactionId,serviceActionFeature,detail,serviceAction){

        getInteractionId({recordId : interactionId})
        .then(result => {

            const message = {
            interactionId: result,
            action: serviceActionFeature,
            detailRecord: detail,
            type: serviceAction
        };

        publish(this.messageContext, InteractionActivityChannel, message);
        })
        .catch(error => {
           // this.error = error;
        });



    }

   // export{publish};
}
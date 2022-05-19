import { LightningElement, api, track, wire } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { publish, MessageContext } from 'lightning/messageService';
import MC_INTERACTION_COMPLETE from '@salesforce/messageChannel/BWC_InteractionComplete__c';

import { updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/Interaction__c.Id';
import COMPLETED_DATE from '@salesforce/schema/Interaction__c.CompletedDate__c';

export default class BwcInteractionMgrCmp extends LightningElement {

  tabIdToInfo = new Map();

  interactionId;
  @api 
  get recordId() {
    return this.interactionId;
  }
  set recordId( id ) {
    this.interactionId = id;
    this.completeInteraction();
  }

  showModal = false;

  @wire(MessageContext)
  messageContext;

  @api
  onTabClosedEvt( tabId, allTabsInfo ) {
    console.debug( '--->>> onTabClosedEvt', JSON.stringify( arguments ) );
    const tabInfo = this.tabIdToInfo.get( tabId );
    if ( tabInfo ) {
      const pgRef = tabInfo.pageReference;
      const attrs = ( pgRef && pgRef.attributes ) ? pgRef.attributes : undefined;
      if ( 
        pgRef &&
        pgRef.type === "standard__recordPage" &&
        attrs &&
        attrs.objectApiName === "Interaction__c"
      ) {
        this.recordId = attrs.recordId;
      }
      this.tabIdToInfo.delete( tabId );
    }
    return Promise.resolve({ tabId: tabId, tabsInfo: allTabsInfo });
  }

  @api
  onTabCreatedEvt( tabId, allTabsInfo ) {
    console.debug( '--->>> onTabCreatedEvt', JSON.stringify( arguments ) );
    this.tabIdToInfo.set(tabId, allTabsInfo.find(t=>t.tabId === tabId));
    return Promise.resolve({ tabId: tabId, tabsInfo: allTabsInfo });
  }

  closeModal() {
    console.debug( "--->>> closing Modal" );
    this.showModal = false;
  }

  saveNotes() {
    console.debug( "--->>> save Notes NOT Implemented in the original component BWCInteractionUtilityBar" );
  }

  sendMessage() {
    const payload = {
      recordId: this.recordId,
      objectName: "Interaction__c"
    };
    publish( this.messageContext, MC_INTERACTION_COMPLETE, payload );
    console.debug( '--->>> send Message to MC_INTERACTION_COMPLETE:', payload );
  }

  completeInteraction() {
    const fields = {};
    fields[ID_FIELD.fieldApiName] = this.recordId;
    fields[COMPLETED_DATE.fieldApiName] = (new Date()).toISOString();

    updateRecord({ fields })
      .then(()=>{
        this.sendMessage();
      })
      .catch(error=>{
        this.dispatchEvent(
          new ShowToastEvent({
              title: 'Error updating interaction',
              message: error.body.message,
              variant: 'error'
          })
        );  
      });
  }

}
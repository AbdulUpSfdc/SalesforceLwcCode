import { LightningElement, api, track } from 'lwc';

export default class Test extends LightningElement {


    @api keyId;
    @api specialStyling;
    @api allowSelection;
    @api isSelected;
    @api header;
    @api highlightPanelHeader;
    @api highlightPanelSubHeader;
    @api highlightPanelFeatures;
    @api highlightPanelLinks;
    @api linkList;
    @api rightColumnHeader;
    @api rightColumnFeatures;
    @track isrightColumn = true;
    @track isleftColumn = true;
    @track mainBlock = 'slds-size_6-of-12';
    @track leftChildBlock = 'slds-size_1-of-2 slds-p-right_xx-large';
    @track rightChildBlock = 'slds-size_1-of-2 slds-p-right_xx-large slds-p-left_xx-large slds-border_left';
    
    temp = 1;
    disable = false;

    connectedCallback(){
      if(this.rightColumnHeader == ''){
          this.isrightColumn = false;
          this.mainBlock = 'slds-size_4-of-12';
          this.leftChildBlock = 'slds-size_1-of-1 slds-p-right_xx-large';
          this.rightChildBlock = '';
      }

      if(this.header == ''){
          this.isleftColumn = false;
          this.mainBlock = 'slds-size_4-of-12';
          this.rightChildBlock = 'slds-size_1-of-1 slds-p-right_xx-large';
          this.leftChildBlock = '';
      }

      if(this.isSelected)
        this.template.querySelector('.hover').disabled = true;
    }

    handleSelect(){
      if (this.temp === 1) {
        console.log('value2--->', this.temp);
        this.template.querySelector('.border').classList.add('borderStyle');
        this.disable = true;
        // this.dispatchEvent(new CustomEvent('genericDataSelection', { detail: this.eventKey } ));
        this.temp = 2;

    } else if (this.temp === 2) {
        this.template.querySelector('.border').classList.remove('borderStyle');
        this.disable = false;
        this.temp = 1;
    }
     let params = {
			allowSelection: true,
			keyId: this.keyId
		}

		this.sendEvent(
			'genericplancardselectionevent',
			params
		);
    }

    /**
	 * @description send/fire an event when link selected.
	 */
    handleSelectedLink(event){
		let params = {
            Id: event.target.dataset.targetId
		}

		this.sendEvent(
			'genericplancardlinkselection',
			params
		);
    }

    /**
	 * @description send/fire an event when panel link selected.
	 */
    handleSelectedPanelLink(event){
		let params = {
            Id: event.target.dataset.targetId
		}

		this.sendEvent(
			'genericplancardpanellinkselection',
			params
		);
    }

    /**
	 * @description Generic function to send/fire an event. All the events will be sent to
	 * the immediate parent.
	 * @param {String} eventName Name of the event.
	 * @param {Object} parameters data to send to the parent.
	 */
	sendEvent(eventName, parameters) {
		let eventData = {
			detail: parameters
		};
		this.dispatchEvent(new CustomEvent(eventName, eventData));
	}
}
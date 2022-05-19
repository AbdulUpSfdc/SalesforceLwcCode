import { LightningElement, api } from 'lwc';

export default class SelectLineComponent extends LightningElement {

    /**
	 * @description key id.
	 */
    @api keyId;

    /**
	 * @description special style value.
	 */
    @api specialStyling;

    /**
	 * @description boolean value of allow selection.
	 */
    @api allowSelection;

    /**
	 * @description display label text.
	 */
    @api displayLabel;

    /**
	 * @description display description text.
	 */
    @api displayDescription;

    /**
	 * @description display sub label text.
	 */
    @api displaySubLabel;

    /**
	 * @description Boolean value of show details status.
	 */
    @api showDetails;

    /**
	 * @description highlight label text.
	 */
    @api highlightLabel;

    /**
	 * @description array of line items.
	 */
    @api lineItems;

    /**
	 * @description disclaimer text.
	 */
    @api disclaimers;

    /**
	 * @description array of links.
	 */
    @api linkList;

    /**
	 * @description highlight detail text.
	 */
    @api highlightDetails;

    /**
	 * @description toggle checkbox value.
	 */
    toggleIcon(){
        this.showDetails ? this.showDetails = false : this.showDetails = true;
    }

    /**
	 * @description send/fire an event when checkbox is changed.
	 */
    handleChange(event){
		let params = {
			checkBoxValue: event.detail.checked,
			keyId: this.keyId
		}

		this.sendEvent(
			'genericlinecardevent',
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
			'genericlinecardlinkevent',
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
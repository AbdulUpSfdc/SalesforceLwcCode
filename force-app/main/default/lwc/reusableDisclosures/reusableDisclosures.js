import { LightningElement, api } from 'lwc';

export default class reusableDisclosures extends LightningElement {
    @api keyId;
    @api disclosureMessage;
    @api header;
    @api announcement_header;
    @api announcements;
    @api announcement_link;
    checkboxVal = false;

    header ='DISCLOSURES';
	disclosureMessage ='I Have read this message to the customer';
	announcement_header ="READ TO THE CUSTOMER :";
    announcements =["Your address has only 1 speed option available.", "Here is a second announcement"];
    announcement_link =[
        {id:"1", name:'Find Out Why' , address:'www.google.com'}
    ]

    /**
	 * @description test
     * test
     * test
	 * @param {Object} event The Selection Line component's custom event.
	 */
	handleGenericLineCardLinkEvent(event) {
		let item = event.detail;
        let Id = item.Id;
        console.log('Id');
        console.log(Id);
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
			'genericdisclosureevent',
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
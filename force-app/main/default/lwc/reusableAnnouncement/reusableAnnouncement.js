import { LightningElement, api, track } from 'lwc';
import myPNG_icon from '@salesforce/resourceUrl/announcement';
//import myglobalPNG_icon from '@salesforce/resourceUrl/global';
export default class Announcement extends LightningElement {
    announcement_icon =myPNG_icon;
    //global_icon =myglobalPNG_icon;
    @api announcementheader;
    @api announcements;
    @api announcementlink;
    @api showLanguages = false;
    @api langSelected = false;
    @track selectedOption;

       announcementlink = [
           {id:'1', name:"", address:''}
       ];
    changeHandler(event) {
        const field = event.target.name;
        if (field === 'optionSelect') {
                this.selectedOption = event.target.value;
              //  alert("you have selected : "+this.selectedOption);
                if (this.selectedOption =="SP") {
                    this.langSelected =true;
                    this.announcementheader = "Leer a la cliente :";
                    this.announcements = ["Su dirección solo tiene 1 opción de velocidad disponible.", "Aquí hay un segundo anuncio"];
                    this.announcementlink = [{ name :"Descubra por qué>"}];
                }else if(this.selectedOption =="EN"){
                    this.langSelected =false;
                    this.announcementheader = "Read to the Customer :";
                    this.announcements = ["Your address has only 1 speed option available.", "Here is a second annoucement"];
                    this.announcementlink = [{ name :"Find Out Why"}];
                }
            } 
        }
    

    /**
	 * @description send/fire an event when link selected.
	 */
    handleSelectedLink(event){
		let params = {
            Id: event.target.dataset.targetId
		}

		this.sendEvent(
			'genericlinkevent',
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
import { LightningElement, api, wire, track } from 'lwc';
//import isGuestUser from '@salesforce/user/isGuest'; // Does not work in lightning out... :(
import vfOrigin from "@salesforce/apex/CustomLabelTranslatorController.visualforceOrigin";
import userType from "@salesforce/apex/CustomLabelTranslatorController.userType";

const MESSAGE_ID = "message";
export default class CustomLabelTranslatorCmp extends LightningElement {

  @wire(vfOrigin)
  pageOrigin;

  @track
  iframeSrc; 

  translatorMessageListener;

  constructor() {
    super();
    this.channel = new MessageChannel();
    this.isGuest();
  }

  // connectedCallback() {
  //   this.translatorMessageListener = window.addEventListener( 
  //     MESSAGE_ID, this.translationHandler.bind(this)
  //   );
  // }
  
  // disconnectedCallback() {
  //   window.removeEventListener( MESSAGE_ID, this.translatorMessageListener );
  // }

  async isGuest() {
    const ut = await userType();
    this.iframeSrc = (ut === "GUEST") ? 
      "/SecureInformationExchange/CustomLabelsTranslator" : "/apex/CustomLabelsTranslator";
  }
  
  @api
  async translateLabels( labelsArr, language ) {
    // console.debug( "--->>> starting translation to " + language + " of " + JSON.stringify( labelsArr ) );
    const trg = this.template.querySelector( "iframe" ).contentWindow;
    trg.postMessage(
      {
        action: "reload",
        lang: language,
        labels: (labelsArr) ? labelsArr.join( "," ) : ""
      }, 
      this.pageOrigin.data 
    );
    return new Promise((resolve)=>{
      const listener = (message) => {
        if (message.origin === this.pageOrigin.data) {
          const translatedLabels = message.data;
          // const dbg = JSON.stringify( translatedLabels );
          // console.debug( "GOT message", dbg );
          window.removeEventListener( MESSAGE_ID, listener );
          resolve( translatedLabels );
        }
      };
      window.addEventListener( MESSAGE_ID, listener );      
    });
  }
}
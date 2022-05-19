import { LightningElement, track, api } from 'lwc';

import { domElementHeight } from "c/bwcRaisrManagerFormCmp";

const DEFAULT_SiMULATOR =
  "https://sc-spi.test.att.com:8443/spisim/csp/fldspt/simulatorHome.html";
const NO_SIMULATOR_VALUE = "-1";

export default class BwcRaisrTesterCmp extends LightningElement {
  @track isSimulator = true;
  defaultSimulatorUrl = DEFAULT_SiMULATOR;
  doWeNeedCustomSimulatorUrl = false;
  simulatorUrl = "";
  isRecordSession;

  simulatorWindow;

  recordSessionState = false;
  playSessionState = false;

  simulatorSwitch(event) {
    this.isSimulator = event.target.checked;
    console.debug("isSimulator=" + this.isSimulator);

    // We need to get in line to obtain correct value 
    // after changed is rendered
    setTimeout(()=>{
      const payload = {
        height: this.ioFormHeight
      };
      const evt = new CustomEvent("dimensionchanged", {
        detail: payload
      });
      console.debug( "Sending dimensionchanged event: " + JSON.stringify( payload ) + ";" );
      this.dispatchEvent( evt );
    },0);
  }

  openSimulator(event) {
    let url;
    try {
      url = new URL( event.target.value );
    } 
    catch (_) {
      return;  
    }
  
    if ( url.protocol === "http:" || url.protocol === "https:" ) {
      this.openSimulatorWindow(event.target.value);
    }
  }

  openSimulatorWindow(url) {
    if ( this.simulatorWindow && this.simulatorWindow.closed ) {
      this.simulatorWindow = null;
    }
    if (!this.simulatorWindow ) {
      this.simulatorWindow = window.open(url);
    } else {
      this.simulatorWindow.focus();
    }
  }

  onSelectSimulator(event) {
    if (event.target.value === "") {
      this.doWeNeedCustomSimulatorUrl = true;
    } else {
      this.doWeNeedCustomSimulatorUrl = false;
    }

    if (/^https:\/\//.test(event.target.value)) {
      this.openSimulatorWindow(event.target.value);
    }
  }

  handleRecordSession( event ) {
    if ( this.playSessionState ) {
      this.playSessionState = this.recordSessionState;
    }
    this.recordSessionState = !this.recordSessionState;
  }

  handlePlaySession( event ) {
    if ( this.recordSessionState ) {
      this.recordSessionState = this.playSessionState;
    }
    this.playSessionState = !this.playSessionState;
  }

  startTest( event ) {
    const crn = this.template.querySelector( '.crn' );
    if ( !crn || !crn.reportValidity() ) {
      return;
    }
    const ban = this.template.querySelector( '.ban' );
    const msg = {
      crn: (crn) ? crn.value : undefined,
      ban: (ban) ? ban.value : undefined
    };
    this.dispatchEvent(new CustomEvent('teststart', { detail: msg } ));
  }

  @api get ioFormHeight() {
    let h = -1;
    const frm = this.template.querySelector( ".io-test-form" );
    if ( frm ) {
      h = domElementHeight( frm );
    }
    console.debug( "RAISR TEST FORM HEIGHT = " + h + ";" );
    return h;
  }
}
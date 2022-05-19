import * as FACTORY from "./webSocketFactory";

export const Factory = FACTORY.WebSocketFactory;

export const RAISR_FIELD_TYPE = Object.freeze({
  CREDIT_CARD_NUMBER: "creditCardNumber",
  CREDIT_CARD_EXP_DATE: "creditCardExpirationDate",
  CREDIT_CARD_CVV: "creditCardVerificationCode",
  CEDIT_CARD_ZIP: "zipCode",
  BANK_ACC_NUMBER: "checkingAccountNumber",
  BANK_ROUTING_NUMBER: "abaRoutingNumber"
});
export class RaisrAPI {

  _ws = undefined;
  _callCtxt = undefined;

  constructor( callContext ) {
    console.debug( "RaisrAPI constructor entering" );
    this._ws = callContext.ws;
    this._callCtxt = callContext;

    this._ws.onopen = this.onopen.bind( this );
    this._ws.onclose = this.onclose.bind( this );
    this._ws.onmessage = this.onmessage.bind( this );
    this._ws.onerror = this.onerror.bind( this );
  }

  init() {
    console.debug( "RaisrAPI::init() entered" );
  }

  onopen( event ) {
    console.debug( "RaisrAPI::onopen() entered", event );
    this.register();
  }

  onclose( event ) {
    console.debug( "RaisrAPI::onclose() entered", event );
  }
  
  onmessage( event ) {
    console.debug( "RaisrAPI::onmessage() entered", event );
  }
  
  onerror( event ) {
    console.debug( "RaisrAPI::onerror() entered", event );
  }
  
  close( code ) {
    console.debug( "RaisrAPI::close() entered", code );
    this._ws.close( code );
  }

  send( msg ) {
    console.debug( "RaisrAPI::send() entered", msg );
    if ( msg.name && /_INTERNAL$/.test( msg.name ) ) {
      return;
    }
    if ( typeof msg !== "string" ) {
      msg = JSON.stringify( msg );
    }
    this._ws.send( msg );
  }

  destroy() {
    console.debug( "RaisrAPI::destroy() entered" );
  }

  register() {
    const raisrFlds = Object.values( RAISR_FIELD_TYPE );
    const req = {
      name: 'REGISTER',
      callReferenceNumber: this._callCtxt.crn,
      ban: this._callCtxt.ban,
      spiFields: raisrFlds
    }
    console.debug( "Sending REGISTER event", JSON.stringify( req ) );
    this.send( req );
  }

  focus( fieldType ) {
    const req = {
      name: "FOCUS",
      fieldName: fieldType
    };
    console.debug( "Sending FOCUS event", JSON.stringify( req ) );
    this.send( req );
  }

  override( reason ) {
    const req = {
      name: "OVERRIDE",
      reason: reason
    };
    console.debug( "Sending OVERRIDE event", JSON.stringify( req ) );
    this.send( req );
  }
}
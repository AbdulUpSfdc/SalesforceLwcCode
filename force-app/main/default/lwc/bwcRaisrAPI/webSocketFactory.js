export const TEST_WS_LOCATE_URL =
  "https://sc-spi.test.att.com:8443/spiweb/scspi/rest/v1/wsLocatePost";

import * as OIDC from "./oidcFlow";

const oidcFlow = new OIDC.OidcFlow();
export class WebSocketFactory {
  // const callContext = {
  //   attuid: this.attuid,
  //   crn: "1111222233334444",
  //   ban: "177030379757",
  //   ws: undefined
  //   connection_error: undefined
  // }

  static async newWebSocketInstanceAsync(callContext, wsLocateUrl) {

    let connRes;
    try {
      connRes = await oidcFlow.connect( callContext );
    }
    catch( e ) {
      console.error( "Connection Failed", e );
      connRes = e;
    }

    return connRes;
  }
}
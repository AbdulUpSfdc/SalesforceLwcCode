import * as ORGTYPE from "./orgType";

const DEFAULT_REPORT_CONSOLE_METHOD = "error";
const REPORT_CONSOLE_METHODS = ["warn", DEFAULT_REPORT_CONSOLE_METHOD];
const SC_SPI_AUTHZ_WND_TITLE = "SC-SPI Authorization";

const OIDC_RESPONSE_TIMEOUT_IN_SECONDS = 1000 * 60 * 5;

const MAX_CONNECT_ATTEMPTS = 5;

export class OidcFlow {
  /**
   * Constructor
   *
   * @param {*} context context {
   *     attuid: this.attuid,
   *     crn: "1111222233334444",
   *     ban: "177030379757",
   *     ws: undefined
   *     connection_error: undefined
   *  }
   */
  constructor() {
    this.context;
    this.popupHandle;
    this.connectAttempts = 0;
    this.oidcMessageWaitingPromise;
  }

  /**
   * @returns promise wich will be resolved to the context:
   *  {
   *     attuid: this.attuid,
   *     crn: "1111222233334444",
   *     ban: "177030379757",
   *     ws: undefined
   *     connection_error: undefined
   *  }
   */
  async connect(context) {
    if ( this.popupHandle ) {
      this.popupHandle.close();
    }
    this.popupHandle = undefined;
    this.context = context;
    this.context.connection_error = undefined;
    if ( this?.connect?.ws?.readyState <= 1) {
      this.context.ws.close();
    }
    this.context.ws = undefined;
    this.connectAttempts = 0;
    console.debug( "--->>> Connecting to SC-SPI. Context: ", JSON.stringify( this.context ) );
    this.oidcMessageWaitingPromise = undefined;
    return this.wsLocate();
  }

  /**
   * Reports warning or error
   * @param {*} repMsgPrefix - prefix message
   * @param {*} repCtxtObj - NVPs with error related data
   * @param {*} consoleMethod - optional. @see REPORT_CONSOLE_METHODS
   */
  report(repMsgPrefix, repCtxtObj, consoleMethod) {
    let msg = repMsgPrefix;
    if ( typeof repCtxtObj === "string" ) {
      msg += repCtxtObj;
    } else {
      Object.keys(repCtxtObj).forEach(
        (k) => msg += k + ": " + repCtxtObj[k] + "; "
      );
    }
    let meth = REPORT_CONSOLE_METHODS.filter((m) => m === consoleMethod);
    console[meth && meth[0] ? meth[0] : DEFAULT_REPORT_CONSOLE_METHOD](msg);
    return msg;
  }

  async wsLocate() {
    this.connectAttempts++;
    if (this.connectAttempts > MAX_CONNECT_ATTEMPTS) {
      this.context.connection_error = "Connect Failed. Max Attempts reached.";
      return Promise.reject( this.context );  
    }

    let url;
    try {
      url = await ORGTYPE.getWSLocateUrl();
      console.debug( "WSLocate URL [" + url + "]" );
    }
    catch ( e ) {
      this.context.connection_error = "Can't obtain WSLocate url";
      return Promise.reject( this.context );
    }

    const data = {
      agentId: this.context.attuid,
      callReferenceNumber: this.context.crn,
      ban: this.context.ban
    };

    let response;
    try {
      response = await fetch(url, {
        method: "POST",
        mode: "cors",
        cache: "no-cache",
        credentials: "include",
        headers: {
          "Content-Type": "application/json"
        },
        redirect: "follow",
        referrerPolicy: "no-referrer",
        body: JSON.stringify(data)
      });

      if (response.status === 401) {
        console.info( "SC-SPI did not authorize WSLocate..." );
        const authzUrl = await ORGTYPE.getAuthzUrl();
        this.popupHandle = window.open(
          authzUrl,
          SC_SPI_AUTHZ_WND_TITLE,
          "popup"
        );
        if ( this.popupHandle ) {
          console.debug( "--->>> Focusing SC-SPI popup" );
          this.popupHandle.focus();
        }

        const originHost = new URL( authzUrl ).host;
        
        const self = this;

        console.debug( "--->>> Before returning promise waiting for OIDC response. originHost=[" + originHost + "]" );
        if ( !this.oidcMessageWaitingPromise ) {
          this.oidcMessageWaitingPromise = new Promise((resolve, reject) => {
            let timer;
  
            function listener(data) {
              if ( data.origin.includes( originHost ) ) {
                // { action: check; status: 200}
                if ( self.popupHandle ) {
                  self.popupHandle.close();
                }
                console.debug( "--->>> OIDC Got message from SC-SPI: " + JSON.stringify( data.data ) );
                if ( data.data.action === "check" && parseInt(data.data.status) === 200 ) {
                  clearTimeout(timer);
                  window.removeEventListener("message", listener, false);
                  resolve( self.wsLocate() );
                }
                else {
                  self.wsLocate();
                }
              }
            }
  
            window.addEventListener("message", listener, false);
            console.debug( "--->>> OIDC added event listener for xdomain" );
  
            timer = setTimeout(() => {
              console.debug( "--->>> OIDC setTimeout executing" );
              window.removeEventListener("message", listener, false);
              self.context.connection_error = "Connect Failed. Timeout waiting for message from OpenID Connect";
              console.debug( "--->>> OIDC setTimeout before calling reject" );
              reject( self.context );
            }, OIDC_RESPONSE_TIMEOUT_IN_SECONDS);
          });
        }

        return this.oidcMessageWaitingPromise;
      }

      const json = await response.json();
      if (
        json &&
        json.error &&
        typeof json.error === "string" &&
        json.error !== ""
      ) {
        this.context.connection_error = this.report(
          "WSLocate returned error: ",
          {
            url: url,
            error: json.error
          }
        );
      } else {
        this.context.ws = new WebSocket(json.wsUrl + "?" + this.context.attuid);
      }
    } catch (e) {
      this.context.connection_error = this.report("WSLocate failed: ", {
        url: url,
        error: e.body ? e.body.statusText : e.name,
        errorMessage: e.body ? e.body.message : e.message,
        response: JSON.stringify(response)
      });
    }

    return this.context;
  }
}
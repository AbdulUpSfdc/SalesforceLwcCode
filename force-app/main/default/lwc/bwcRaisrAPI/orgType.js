import isProdOrg from '@salesforce/apex/BWC_RAISRController.isProdOrg';

const URI_PATH_WSLOCATE = "/spiweb/scspi/rest/v1/wsLocatePostO";
const URI_PATH_WSLOCATE_NO_OIDC = "/spiweb/scspi/rest/v1/wsLocatePost";
const URI_PATH_OAUTH = "/spiweb/scspi/oauth/check";

const TEST_SC_SPI_FQDN = "sc-spi.test.att.com:8443";

const TEST_WS_LOCATE_URL = "https://" + TEST_SC_SPI_FQDN + URI_PATH_WSLOCATE;
const TEST_AUTHZ_URL = "https://" + TEST_SC_SPI_FQDN + URI_PATH_OAUTH;
 

const PROD_SC_SPI_FQDN = "sc-spi.it.att.com:8443";

const PROD_WS_LOCATE_URL = "https://" + PROD_SC_SPI_FQDN + URI_PATH_WSLOCATE;
const PROD_AUTHZ_URL = "https://" + PROD_SC_SPI_FQDN + URI_PATH_OAUTH;

let isProdRequested = false;
let isProd;
const getIsProd = async () => {
  if ( !isProdRequested) {
    isProd = await isProdOrg();
    isProdRequested = true;
  }
  return isProd;
}

export const getWSLocateUrl = async () => {
    const res = await getIsProd();
    return (res) ? PROD_WS_LOCATE_URL : TEST_WS_LOCATE_URL;
}

export const getAuthzUrl = async () => {
    const res = await getIsProd();
    return (res) ? PROD_AUTHZ_URL : TEST_AUTHZ_URL;
}
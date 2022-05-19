import * as BwcUtils from 'c/bwcUtils';
import getLICWFEUrlData from '@salesforce/apex/BWC_LIC_WFEController.getLICWFERequestData';
import logWFEResponse from '@salesforce/apex/BWC_LIC_WFEController.logWFEResponse';

export const getLICWFEUrl = async (isAuthorized, ban) => {

    BwcUtils.log(`call getLICWFERequestData: isAuthorized = ${isAuthorized} BAN = ${ban}`);

    const responseData = await getLICWFEUrlData({ isAuthorized: isAuthorized, ban: ban });

    BwcUtils.log('response WFE URL : ' + JSON.stringify(responseData));

    return responseData;

}

export const handleFetch = async (request, endPoint, interactionId) => {
    BwcUtils.log('handleFetch request: ' + JSON.stringify(request));
    BwcUtils.log('handleFetch endPoint: ' + JSON.stringify(endPoint));
    try {
        const response = await fetch(endPoint, {
            method: 'POST', // *GET, POST, PUT, DELETE, etc.
            mode: 'cors', // no-cors, *cors, same-origin
            credentials: "include",
            headers: {
                cache: 'no-cache', // *default, no-cache, reload, force-cache, only-if-cached
                credentials: 'include', // include, *same-origin, omit
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(request)
        });
        const repos = await response.text();
        BwcUtils.log(' repos ' + repos);

        const param = `uri=${JSON.stringify(endPoint)}
            |request=${JSON.stringify(request)}
            |response=${repos}`;

        const logResponse = logWFEResponse({
            detail: param,
            recordId: interactionId,
            isError: false
        });

        return repos;

    } catch (error) {
        BwcUtils.error(' handleFetch >> ' + error);
    }
};
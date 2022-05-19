import * as BwcUtils from 'c/bwcUtils';
import getBwcSettings from '@salesforce/apex/BWC_Settings.getBwcSettings';
import getProductsGroupedByServiceCont from '@salesforce/apexContinuation/BWC_ProductSearchController.getProductsGroupedByServiceCont';

export const getProductsGroupedByService = async (recordId, bans, forceRefresh) => {

    BwcUtils.log(`call getProductsGroupedByService: recordId: ${recordId}, bans: ${bans}, forceRefresh: ${forceRefresh} `);

    let result = await getProductsGroupedByServiceCont({recordId, bans, forceRefresh});

    BwcUtils.log('result getProductsGroupedByService: ' + JSON.stringify(result));

    if (result.prefetchStatus === 'In Process') {

        // Prefetch is ongoing. Fetch polling interval and timeout values
        const bwcSettings = await getBwcSettings();
        const pollingTimout = bwcSettings.Product_Prefetch_Polling_Timeout__c;
        const pollingInterval = bwcSettings.Product_Prefetch_Polling_Interval__c;
        const pollingMaxIterations = Math.ceil(pollingTimout / pollingInterval);
        let pollingIteration = 0;

        BwcUtils.log(`Product search prefetch is ongoing. Poll every ${pollingInterval} milliseconds for ${pollingTimout} milliseconds.`);

        // Poll for product search if needed
        while (result.prefetchStatus === 'In Process' && pollingIteration < pollingMaxIterations) {

            BwcUtils.log(`Product search polling ${pollingIteration + 1} of ${pollingMaxIterations}`)

            // eslint-disable-next-line no-await-in-loop
            await BwcUtils.wait(pollingInterval);
            // eslint-disable-next-line no-await-in-loop
            result = await getProductsGroupedByServiceCont({recordId, bans, forceRefresh});
            BwcUtils.log('Polling result: ' + JSON.stringify(result));

            pollingIteration++;

        }

    }

    if (result.prefetchStatus === 'In Process') {
        BwcUtils.warn('getProductsGroupedByService prefetch not finished by timeout. Making new request.');
        result = await getProductsGroupedByServiceCont({recordId, bans, forceRefresh: true});
    }

    if (!result.success) {
        throw new Error('Product search failed: ' + result.message);
    }

    return result;

};
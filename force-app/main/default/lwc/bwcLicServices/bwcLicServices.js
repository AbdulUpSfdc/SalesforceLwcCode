import * as BwcUtils from 'c/bwcUtils';
import logOpusResponse from "@salesforce/apex/BWC_LIC_OpusBgUtilController.logOpusResponse";

export const createOpusLog = async (recordId, detail, isError) => {

    try {

        detail = typeof detail === 'string' ? detail : JSON.stringify(detail);
        await logOpusResponse({recordId, detail, isError});

    } catch (error) {
        BwcUtils.error(error);
    }
}
import * as BwcUtils from 'c/bwcUtils';
import getCaseByIdApex from '@salesforce/apex/BWC_CaseServiceController.getCaseById';
import createEscalationCaseApex from '@salesforce/apex/BWC_CreateCase.createEscalationCase';

export const getCaseById = async caseId => {

    BwcUtils.log('call getCaseById caseId: ' + caseId);

    const caseResponseJson = await getCaseByIdApex({caseId: caseId});

    BwcUtils.log('response getCaseById: ' + caseResponseJson);

    const caseResponse = JSON.parse(caseResponseJson);
    if (!caseResponse.success) {
        throw BwcUtils.errorWithDetails('Call to getCaseById failed', caseResponse.message);
    }

    return caseResponse.caseRecord;

};

export const createEscalationCase = async (interactionId, type, feature, detailRecord) => {

    BwcUtils.log('call createEscalationCase');

    try {
        const response = await createEscalationCaseApex({
            interactionId: interactionId,
            ecType: type,
            ecFeature: feature,
            detailRecord: JSON.stringify(detailRecord)
        });

        if(response == null) {
            throw BwcUtils.errorWithDetails('call to createEscalationCase failed.', response);
        }

        return response;
    } catch(e) {
        throw BwcUtils.errorWithDetails('call to createEscalationCase failed.', e);
    }

}
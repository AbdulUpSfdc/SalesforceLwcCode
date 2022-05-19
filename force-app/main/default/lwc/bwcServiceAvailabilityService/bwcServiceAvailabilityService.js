import * as BwcUtils from 'c/bwcUtils';
import getServiceAvailabilityApex from '@salesforce/apexContinuation/BWC_ServiceAvailabilityController.getServiceAvailabilityCont';
import getServiceAvailabilityMtdApex from '@salesforce/apex/BWC_ServiceAvailabilityController.getServiceAvailabilityMtd';
import getServiceAvailabilityByAddressApex from '@salesforce/apexContinuation/BWC_ServiceAvailabilityController.getServiceAvailabilityByAddressCont';

export const getServiceAvailability = async (interactionId) => {

    BwcUtils.log('call getServiceAvailability: ' + interactionId);

    try {
        const getServiceAvailabilityJson = await getServiceAvailabilityApex({interactionId});
        BwcUtils.log('result getServiceAvailabilityJson: ' + getServiceAvailabilityJson);
        return JSON.parse(getServiceAvailabilityJson);
    } catch (error) {
        throw new Error('Failed to get Service Availability: ' + error);
    }

};

export const getServiceAvailabilityMtd = async (interactionId) => {

    BwcUtils.log('call getServiceAvailabilityMtd: ' + interactionId);
    try {
        const getServiceAvailabilityMtdResponse = await getServiceAvailabilityMtdApex({interactionId});
        BwcUtils.log('result getServiceAvailabilityMtdResponse: ' + getServiceAvailabilityMtdResponse);
        return JSON.parse(getServiceAvailabilityMtdResponse);
    } catch (error) {
        throw new Error('Failed to get Service Availability Metadata: ' + error);
    }

};

export const getServiceAvailabilityByAddress = async (interactionId, updatedAddress) => {

    BwcUtils.log('call getServiceAvailabilityByAddress: ' + interactionId);

    try {
        const getServiceAvailabilityByAddressJson = await getServiceAvailabilityByAddressApex({interactionId: interactionId, updatedAddress});
        BwcUtils.log('result getServiceAvailabilityByAddressJson: ' + getServiceAvailabilityByAddressJson);
        return JSON.parse(getServiceAvailabilityByAddressJson);
    } catch (error) {
        throw new Error('Failed to get Service Availability by Address: ' + error);
    }

};
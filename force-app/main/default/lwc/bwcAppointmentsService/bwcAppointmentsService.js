import * as BwcUtils from 'c/bwcUtils';
import getAppointmentsData from '@salesforce/apexContinuation/BWC_AppointmentsController.getAppointmentsCont';
export const AUTH_LEVEL_L1 = 'L1';
export const AUTH_LEVEL_BYPASS = 'BYPASS';
export const APPOINTMENT_TYPE_SERVICE = 'service';
export const APPOINTMENT_TYPE_INSTALL = 'install';
import * as BwcConstants from 'c/bwcConstants';
import isBroadbandTechCareAgent from '@salesforce/customPermission/LIC_to_WFE';

export const isBroadbandTechCareAgentPermission = isBroadbandTechCareAgent;

export const COLUMNS = [
        { label: 'Account', fieldName: 'ban', sortable: true, hideDefaultActions: true },
        { label: 'Status', fieldName: 'status', sortable: true, hideDefaultActions: true },
        { label: 'Number', fieldName: 'number', sortable: true, hideDefaultActions: true },
        { label: 'Date', fieldName: 'date', sortable: true, hideDefaultActions: true, type: 'date', typeAttributes: { month: "2-digit", day: "2-digit", year: "numeric" } },
        { label: 'Tech Arrival Window', fieldName: 'techArrivalWindow', sortable: true, hideDefaultActions: true },
        { label: 'Tech Status', fieldName: 'techStatus', sortable: true, hideDefaultActions: true },
        { label: 'Closed', fieldName: 'closedDate', sortable: true, hideDefaultActions: true, type: 'date', typeAttributes: { month: "2-digit", day: "2-digit", year: "numeric" } }
];

export const getByDefaultSortedAppointments = async (interactionId,authorizedBans, appointmentType, sortByFieldName, sortByDirection) => {
        BwcUtils.log(' bwcAppointments >> Authorized BANs : ' + authorizedBans);
        let appointmentsData = [];
        let appointments = [];
        let payload = [];
        if (authorizedBans.length > 0) {
                authorizedBans.forEach(eachBAN => {
                        BwcUtils.log(' callGetAppointmentsCont >> eachBAN : '+eachBAN);
                        let eachPayload = {
                                ban : eachBAN,
                                appointmentType : appointmentType,
                                accountType : BwcConstants.BillingAccountType.UVERSE.value
                        };
                        payload.push(eachPayload);
                });        
        }
        BwcUtils.log(`call getAppointments: interactionId = ${interactionId} payload = ${payload}`);

        appointments = await getAppointments(interactionId,payload);

        if(appointments !== undefined) {
                let unSortedAllData = getAppointmentsArray(appointments);
                let sortedData = getSortedAppointments(unSortedAllData, sortByFieldName, sortByDirection);
                appointmentsData = sortedData;
        }

        BwcUtils.log('Sorted Appointments : ' + appointmentsData);
        return appointmentsData;
}

export const getAppointments = async (interactionId, payload) => {

        BwcUtils.log(`call getAppointments: interactionId = ${interactionId} payload = ${payload}`);

        const responseWrapperJson = await getAppointmentsData({ payload: JSON.stringify(payload), interactionId: interactionId });

        const responseWrapper = JSON.parse(responseWrapperJson);

        BwcUtils.log('response Appointments : ' + responseWrapperJson);

        return responseWrapper.responses;

}
export const getSortedAppointments = (allAppointments, fieldName, sortDirection) => {

        let parser = (v) => v;
        if (fieldName == 'date' || fieldName == 'closedDate') {
                parser = (v) => (v && new Date(v));
        }
        if (fieldName == 'techArrivalWindow') {
                parser = (v) => {
                        if (v !== '' && v !== null && v !== undefined) {
                                v = v.toString().split('-')[0].toUpperCase().search('PM') !== -1 ?
                                        Number(
                                                v.toString()
                                                        .split('-')[0]
                                                        .toUpperCase()
                                                        .replaceAll('PM', '')
                                                        .replaceAll(':', '')
                                                        .trim()
                                        ) + 120000
                                        : Number(
                                                v.toString()
                                                        .split('-')[0]
                                                        .toUpperCase()
                                                        .replaceAll('AM', '')
                                                        .replaceAll(':', '')
                                                        .trim()
                                        );
                        }
                        else {
                                v = 0;
                        }
                        BwcUtils.log(`bwcServiceAppointments: v=${v}`);
                        return v;
                };
        }

        let sortMult = sortDirection === 'asc' ? 1 : -1;
        allAppointments.sort((a, b) => {
                let a1 = parser(a[fieldName]), b1 = parser(b[fieldName]);
                let r1 = a1 < b1, r2 = a1 === b1;
                return r2 ? 0 : r1 ? -sortMult : sortMult;
        });

        return allAppointments;
}

export const getAppointmentsArray = appointmentsData => {
        let allAppointments = [];
        appointmentsData.forEach(eachSA => {
                eachSA.appointments.forEach(appointment => {
                        let sa = {
                                ban: eachSA.ban,
                                number: appointment.appointmentNumber,
                                status: appointment.appointmentStatus,
                                date: appointment.scheduledDate,
                                techArrivalWindow: appointment.techArrivalWindow,
                                techStatus: appointment.techStatus,
                                closedDate: appointment.closedDate
                        };
                        allAppointments = [...allAppointments, sa];

                });
        });
        
        return allAppointments;
}
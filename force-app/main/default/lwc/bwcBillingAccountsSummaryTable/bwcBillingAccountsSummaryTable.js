import  LightningDatatable  from 'lightning/datatable';
import bwcBillingAccountStatusBadgeOutput from './bwcBillingAccountStatusBadgeOutput.html';

export default class BwcBillingAccountsSummaryTable extends LightningDatatable {
    static customTypes = {
        statusBadge:{
            template: bwcBillingAccountStatusBadgeOutput,
            standardCellLayout: true,
            typeAttributes: ['status', 'suspensionStatus'],
        }       
    }
}
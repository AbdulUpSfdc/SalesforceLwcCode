import { LightningElement, api } from 'lwc';

const ORDER_ITEMS_COLUMNS=[
    { label: 'Type', fieldName: 'type', type: 'text', hideDefaultActions: true,},
    { label: 'Plan/Package', fieldName: 'plan', type: 'text', hideDefaultActions: true, },
    { label: 'Make', fieldName: 'make', type: 'text', hideDefaultActions: true,},
    { label: 'Model', fieldName: 'model', type: 'text', hideDefaultActions: true,},
    { label: 'Serial #', fieldName: 'serialNumber', type: 'text', hideDefaultActions: true,},
    { label: 'Quantity', fieldName: 'quantity', type: 'number', hideDefaultActions: true, initialWidth:80,
        cellAttributes: { alignment: 'left' },
    },
];

export default class BwcOrderItems extends LightningElement {

    orderItemsColumns = ORDER_ITEMS_COLUMNS;

    @api items;
}
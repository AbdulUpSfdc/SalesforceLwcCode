import { LightningElement, api } from 'lwc';

export default class ComparePlan extends LightningElement {

@api header;

@api
keys = [];
      
@api
records = [];

}
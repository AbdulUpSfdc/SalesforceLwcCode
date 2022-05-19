import {LightningElement, api, track, wire} from 'lwc';

export default class EmployeeSelectionPicklist extends LightningElement {
@api scenario;
@api options;
@track selectedValue;
@track selectedRep;
  
    handleValueChange(event) {

        event.preventDefault();
        this.selectedValue = event.target.value;
        this.selectedRep = event.target.options.find(opt => opt.value === event.detail.value).label;
        const selectEvent = new CustomEvent('picklistcustomevent', {
            detail : {label: this.selectedRep, value: this.selectedValue}
        });
       this.dispatchEvent(selectEvent);
          
    }

    @api
    handleResetPicklist(event){
        this.selectedValue ='Select an Option';
    }
}
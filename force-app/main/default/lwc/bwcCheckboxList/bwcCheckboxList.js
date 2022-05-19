import { api, LightningElement, track } from 'lwc';

export default class BwcCheckboxList extends LightningElement 
{
    @api options = [];

    @api title = '';

    @api selected = [];

    @track filterOptions = [];

    filterOptionMap = {};

    connectedCallback()
    {
        this.initFilterOptions();
    }

    initFilterOptions()
    {
        this.filterOptions = this.options.map(op => 
            {
                let banId = Math.floor(Math.random()*1000) + '';
                let option = 
                {
                    id:banId, 
                    value: op.value, 
                    label:op.label, 
                    selected: this.selected.length > 0 && this.selected.includes(op.value)
                };
                this.filterOptionMap[banId] = option;
                return option;
            });
    }

    /**
     * Method handles the onchange event of checkbox on chip.
     * @param {*} event 
     */
    handleChange(event) 
    {
        let optionId = event.target.dataset.id;
        let optionValue = event.target.checked;
        this.filterOptionMap[optionId].selected = optionValue;
        this.fireChangeEvent(optionId);
    }

    fireChangeEvent(optionId)
    {
        let allSelectedValues = this.getSelectedValues();

        this.selected = allSelectedValues;

        let eventPayload = 
        {
            triggeredOption: this.filterOptionMap[optionId],
            selected: allSelectedValues
        }
        const selectedEvent = new CustomEvent('selected', { detail: eventPayload });
        this.dispatchEvent(selectedEvent);
    }

    /**
     * @description: method to help you get all the selected values from the filterOptionMap.
     */
    getSelectedValues()
    {
        let allSelectedValues = [];
        Object.keys(this.filterOptionMap).forEach(key => 
            {
                let option = this.filterOptionMap[key];
                if(option.selected)
                {
                    allSelectedValues.push(option.value);
                }
            });
        return allSelectedValues;
    }

        /**
     * 
     */
    @api
    resetFilterOptions()
    {
        this.selected = [];
        this.filterOptions.forEach(option=> option.selected = false);
        this.filterOptions = JSON.parse(JSON.stringify(this.filterOptions));
        
        Object.keys(this.filterOptionMap).forEach(op=>
            {
                this.filterOptionMap[op].selected = false;
                let checkbox = this.template.querySelector(`[data-id="${op}"]`)
                if(checkbox!=null) { checkbox.checked = false};
            });


        //this.initFilterOptions();
    }
    
}
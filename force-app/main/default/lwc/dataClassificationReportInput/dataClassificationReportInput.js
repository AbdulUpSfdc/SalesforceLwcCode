import { LightningElement,track } from 'lwc';
import getMetaDataForValues from '@salesforce/apex/DataClassificationReportController.getMetaDataForValues';
import getMetaDataForOptions from '@salesforce/apex/DataClassificationReportController.getEntitiesForInput';
import saveMetadata from '@salesforce/apex/DataClassificationReportController.saveMetaValues';
import getOmittedMtetadata from '@salesforce/apex/DataClassificationReportController.getMetaDataForOmittedValues';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const columns = [
    { label: 'Name', fieldName: 'name', type: 'text'},
 ];
export default class DataClassificationReportInput extends LightningElement {
columns = columns;
@track
omittedList=[];
@track
options;
@track
metadataStoredValues = [];
loading = false;

    connectedCallback() {
        this.loading= true;
        this.getData();
        this.getOptions()
        this.getOmittedData();
    }
    handleSectionClick() {
    }
    handleAdd(){
        let newVal = this.template.querySelector('[data-id=OmittedField]').value;
        this.template.querySelector('[data-id=OmittedField]').value='';
        
        if(newVal && newVal!= '' && this.checkList(newVal)){
            this.omittedList.push({name: newVal});
        }
        this.template.querySelector('[data-id=omittedTable]').data = this.omittedList;
    }
    handleRemove(){
        let dataTable = this.template.querySelector('[data-id=omittedTable]').getSelectedRows();
        let tempOmittedData = this.omittedList;
        let removeList=[];
        let newList = [];
       for(const prop in dataTable){
            removeList.push(dataTable[prop].name);
        }
        for(const prop in tempOmittedData){
            if(removeList.indexOf(tempOmittedData[prop].name) == -1){
                newList.push(tempOmittedData[prop]);
            }
        }
        this.template.querySelector('[data-id=omittedTable]').data = newList;
        this.omittedList = newList;

       console.log(removeList);
    }
    async save(fieldName , dataToSend){
        try{
        await saveMetadata({valueList: JSON.stringify(dataToSend),fieldName: fieldName});
        }catch(error){
            console.error(error);
        }finally{
            const event = new ShowToastEvent({
                title: 'Report Saved',
                message: 'Your report has been saved.',
                variant: 'success',

            });
            this.dispatchEvent(event);
        }


    }
    handleSave(event){
        let btn = event;
        console.log(btn);
        let db = this.template.querySelector(`[data-id="dualInput"]`).value;
        this.save('reportable_entity_json__c' , db);
        this.save('Omitted_Fields__c',this.handleOmittedList().sort());
    }
    handleOmittedList(){
        let returnList = [];
        for(const prop in this.omittedList){
                returnList.push(this.omittedList[prop].name);
        }
        return returnList;
    }
    handleSelect(event){
    let handle = event.target.label;
    if(handle== 'Select Standard Objects'){
        this.handleSelectFilter('__',false);
    }else if(handle== 'Select Custom Objects') {
        this.handleSelectFilter('__c',true);
    }
    }
    handleSelectFilter(filterVal,tof){
        let optionsForCombo = this.template.querySelector(`[data-id="dualInput"]`).options;;

        for(const prop in optionsForCombo){
            if(tof){
                if(optionsForCombo[prop].label.includes(filterVal)){
                    if(this.checkMetadataStoredValues(optionsForCombo[prop].label)){
                        this.metadataStoredValues.push(optionsForCombo[prop].label);
                    }
                }
            }else{
                if(!optionsForCombo[prop].label.includes(filterVal)){
                    if(this.checkMetadataStoredValues(optionsForCombo[prop].label)){
                        this.metadataStoredValues.push(optionsForCombo[prop].label);
                    }
                }
            }
        }
        this.metadataStoredValues.sort();
    }
    async getData() {
        try {
            let response1 = await getMetaDataForValues();
            let parsedRes = JSON.parse(response1.replaceAll('\\','').slice(1,-1));
            this.metadataStoredValues = parsedRes;

        } catch (error) {
                this.error = error;
        } finally {
        }
    }
    async getOptions() {
        try {
            let response1 = await getMetaDataForOptions();
            let parsedRes = JSON.parse(response1).sort();
             let tempOptionList = [];
            for(const prop in parsedRes){
                tempOptionList.push({
                    label: parsedRes[prop],
                    value: parsedRes[prop]
                })
            }
            this.options = tempOptionList;
        } catch (error) {
                this.error = error;
        } finally {
            this.loading = false;
        }
    }
    async getOmittedData() {
        try {
            let response1 = await getOmittedMtetadata();
            let parsedRes = JSON.parse(response1.replaceAll('\\','').slice(1,-1));
            let tempOptionList = [];
           for(const prop in parsedRes){
               tempOptionList.push({
                name: parsedRes[prop]
               })
           }
           this.omittedList = tempOptionList;
       } catch (error) {
               this.error = error;
       } finally {

    }
    }
    checkList(newVal){
        for(const prop in this.omittedList){
            if(this.omittedList[prop].name == newVal){
                return false;
            }
        }
        return true;
    }
    checkMetadataStoredValues(name){
        for(const prop in this.metadataStoredValues){
            if(this.metadataStoredValues[prop]== name){
                return false;
            }
        }
        return true;
    }
}
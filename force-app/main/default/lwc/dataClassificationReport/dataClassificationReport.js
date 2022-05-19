import { LightningElement,track } from 'lwc';
import getEntitiesName from '@salesforce/apex/DataClassificationReportController.getEntities';
import getEntityData from '@salesforce/apex/DataClassificationReportController.getEntityData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const actions = [
    { label: 'View Details', name: 'view' },
 ];
const columns = [
    { label: 'Metadata Name', fieldName: 'name', sortable: true,initialWidth: 195},
    { label: 'Total Fields', fieldName: 'fieldCount', sortable: true,initialWidth: 155},
    { label: 'Unclassified', fieldName: 'unclassified', sortable: true ,initialWidth: 155},
    { type: 'action', typeAttributes:
        {
            rowActions: actions,
            menuAlignment: 'right'
        }
    },

];
const findColumns=[
    { label: 'Metadata Name', fieldName: 'name', sortable: true, initialWidth: 220},
];
const columns1 = [
    { label: 'Field Name', fieldName: 'name',initialWidth: 250},
    { label: 'Data Classification', fieldName: 'classification',initialWidth: 250}
];
export default class DataClassificationReport extends LightningElement {
    columns = columns;
    objectList =[];
    findOptions =[];
    findData = [];
    findColumns= findColumns;
    columns1 = columns1;
    loading= false;
    finalLoadCount;
    currentLoadCount;
    comboBoxFilter;
    showFindTable = false;
    showExport= false;
    activeSections = []; //this controls which sections are expanded
    csvData=[];
    @track
    _data=[];
    get data(){
        return this._data;
    }
    set data(value){
        this._data = value;
    }
    renderedCallback(){

    }
    fireMessage(title,message,variant){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
    connectedCallback() {
        (async () => {
            try {
                this.currentLoadCount = 0;
                this.fireMessage('Please Be Patient With Me','This could take time.','warning');
                this.loading = true;
                let listOfNames = await this.getNames()
                for(const prop in listOfNames) {
                    this.getData(listOfNames[prop]);
                }
            } catch (error) {
                this.error = error;
            } finally {
            }
        })();
    }
    handleSectionClick() {
    }
    async getNames() {
        try {
            let response1 = await getEntitiesName();
            let parsedRes = JSON.parse(response1);
            this.finalLoadCount = parsedRes.length ;
            return parsedRes.sort();

        } catch (error) {
                this.error = error;
        } finally {

        }
    }
    async getData(name) {
        try {
            let tempObj, tempObj1 = {};
            let response1 = await getEntityData({entityName: name});
            let parsedRes = JSON.parse(response1);

            tempObj = {
                name: name ,
                fieldCount: parsedRes.length,
                unclassified: this.calcUnclassified(parsedRes),
                fieldData: this.handleFieldData(parsedRes)
            };
            tempObj1 ={
                name: name ,
                fieldCount: tempObj.fieldCount,
                unclassified: tempObj.unclassified,
            };
            this.objectList.push(tempObj);
            this.csvData.push(tempObj1);
            this.currentLoadCount++;
        } catch (error) {
                this.error = error;
        } finally {

            if(this.currentLoadCount == this.finalLoadCount){
                this.handleLoadCompleted();

            }

        }
    }
    calcUnclassified(dataObj){
        let count = 0;
        for(const prop in dataObj){
            if(!dataObj[prop].SecurityClassification){
                count++;
            }else{
                if(!this.findOptions.includes(dataObj[prop].SecurityClassification)){
                this.findOptions.push(dataObj[prop].SecurityClassification);
                }
            }
        }
        return count;
    }
    refresh(){
        eval("$A.get('e.force:refreshView').fire();");
    }
    handleFieldData(fieldData){

        let returnObjList =[];
        for(const prop in fieldData){
            returnObjList.push({
                name: fieldData[prop].QualifiedApiName,
                classification : fieldData[prop].SecurityClassification
            })
        }
        return returnObjList;
    }
    handleSectionName(){
    }
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const name = event.detail.row.name;
        switch (actionName) {
            case 'view':
           // this.handleSelectOfTab('sections');
            this.handleSelectOfSection(name);
                break;
            default:
        }
    }
    handleSelectOfTab(name){

    }
    handleLoadCompleted(){
        this._data = this.objectList;
        this.template.querySelector('[data-id=searchBox]').options = this.handleOptions();
        this.template.querySelector(`[data-id="reportTable"]`).data = this._data.sort((a, b) =>
           (a.name > b.name) ? 1 : (a.name === b.name) ? ((a.name > b.name) ? 1 : -1) : -1 );
        this.loading = false;
        this.showExport = true;

    }
    handleOptions(){
        let returnList = [];
        returnList.push({label:'',value:''},{label:'Unclassified',value:'unclass'});
        for(const prop in this.findOptions){
            returnList.push({label:this.findOptions[prop],value:this.findOptions[prop]});
        }
        return returnList;
    }
    handleFind(event){
        let filterValue = event.detail.value;
        this.showFindTable = (filterValue != '' )?true:false;
        this.comboBoxFilter = filterValue;
        this.handleFindTableUpdate(filterValue);
    }
    handleFindTableUpdate(filterValue){
        if(filterValue== 'unclass'){filterValue =  null;}
        let ourData = JSON.parse(JSON.stringify(this.data))
        let tempObj = [];
        for(const prop in ourData)
        {
            for(const prop1 in ourData[prop].fieldData){
                if(ourData[prop].fieldData[prop1].classification == filterValue){
                    tempObj.push({name:ourData[prop].name});
                    break;
                }
            }
        }
        this.findData = tempObj;
    }
    handleSelectOfSection(name){
        this.activeSections = [name];
       const element = this.template.querySelector('[data-id="' + name + '"]');
        element.scrollIntoView({behavior: "smooth", block: "center", inline: "nearest"});

    }
    handleCSVDownLoad(){
        this.downloadCSVFile(this.csvData,'Data Classification Report') ;
    }
    downloadCSVFile(dataobj,fileName) {
        let rowEnd = '\n';
        let csvString = '';
        // this set elminates the duplicates if have any duplicate keys
        let rowData = new Set();

        // getting keys from data
        dataobj.forEach(function (record) {
            Object.keys(record).forEach(function (key) {
                rowData.add(key);
            });
        });

        // Array.from() method returns an Array object from any object with a length property or an iterable object.
        rowData = Array.from(rowData);
        // splitting using ','
        csvString += rowData.join(',');
        csvString += rowEnd;

        // main for loop to get the data based on key value
        for(let i=0; i < dataobj.length; i++){
            let colValue = 0;

            // validating keys in data
            for(let key in rowData) {
                if(rowData.hasOwnProperty(key) && key) {
                    // Key value
                    // Ex: Id, Name
                    let rowKey = rowData[key];
                    // add , after every value except the first.
                    if(colValue > 0 ){
                        csvString += ',';
                    }
                    // If the column is undefined, it as blank in the CSV file.
                    let value = dataobj[i][rowKey] === undefined ? '' : dataobj[i][rowKey];
                    csvString += '"'+ value +'"';
                    colValue++;
                }
            }
            csvString += rowEnd;
        }

        // Creating anchor element to download
        let downloadElement = document.createElement('a');

        // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
        downloadElement.target = '_self';
        // CSV File Name
        downloadElement.download = fileName+Date.now()+'.csv';
        // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click();
    }
    downloadCSVFilterFile(){
        this.downloadCSVFile(this.findData,this.comboBoxFilter+' Report');
    }
}
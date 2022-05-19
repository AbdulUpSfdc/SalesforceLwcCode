import { LightningElement,track,api } from 'lwc';
import getInteractionList from '@salesforce/apex/BWC_InteractionsWithActivitiesController.getInteractionRecordList';
//import getFilterListsValues from '@salesforce/apex/BWC_InteractionsWithActivitiesController.getFilterListsValues';

export default class BwcInteractionsWithActivities extends LightningElement {
@api recordId;
@track isLoadingMain = false; 
@track InteractionList = null;
@track currentRecordSetTimeFrame = "3 months";
@track currentPage = 0;
@track displayPageNumber = 1;
@track displayList = null;
@track numberOfRecordsToDisplay = 10;
//@track featureFilterValue = { fieldName: 'Feature__c', objectName:'Interaction_Activity__c'};
//@track featureFilterList;
//@track caseTypeList=[{ label: 'caseType filter Placeholder', value: 'valuePlaceholder'},{label: 'caseType filter Placeholder 2', value: 'valuePlaceholder2'}];
//@track caesTypeFilterValue;
LWC_COMPONENT_NAME = 'c-bwc-interaction-row';
currentDateMilli = new Date();
//contains upto ten elements but no more
@track paginationList = [];
//full list of pages and record Lists
@track pageList = [];
@track moreThanOnePage = false;
@track showDots = false;
@track showPageNav = false;
nextButtonId = '[data-id="next"]';
prevButtonId = '[data-id="prev"]';

connectedCallback() {
  this.isLoadingMain = true;
this.handleInteractionList();


}
handleInteractionList(){

  getInteractionList({interactionId: this.recordId, SOQLTimeFrame: this.currentRecordSetTimeFrame, currentDateMilli : this.currentDateMilli.getTime() }).then(result => {
    let listFromServer =JSON.parse(result);
    this.InteractionList =listFromServer.sort((a, b) => 
    (a.CreatedDate < b.CreatedDate) ? 1 : (a.CreatedDate === b.CreatedDate) ? ((a.size < b.size) ? 1 : -1) : -1 );
    this.initializeDisplayList();
    this.cleanCreatedDate();
    this.initializePageList();
  }).catch(error => {
    
  }).finally(() => {
    this.handleNavButtonDisableLogic();
    this.isLoadingMain = false;

 });

  //this.handleFilterListOptions();
}
handleGetRecords(event){
this.isLoadingMain = true;

let timeFrame = event.currentTarget.dataset.id;
this.closeSections();
getInteractionList({interactionId: this.recordId, SOQLTimeFrame: timeFrame, currentDateMilli : this.currentDateMilli.getTime() }).then(result => {
  let listFromServer =JSON.parse(result);
  this.InteractionList =listFromServer.sort((a, b) => 
  (a.CreatedDate < b.CreatedDate) ? 1 : (a.CreatedDate === b.CreatedDate) ? ((a.size < b.size) ? 1 : -1) : -1 );


  this.initializeDisplayList();
  this.cleanCreatedDate();
  this.initializePageList();
  this.isLoadingMain = false;

}).catch(error => {
  this.isLoadingMain = false;

});

}
handleFilterListOptions(){
 /*  getFilterListsValues({objectName: this.featureFilterValue.objectName ,fieldName: this.featureFilterValue.fieldName}).then(result => {
    let listFromServer =JSON.parse(result);
console.log('helping');
  }).catch(error=>{
    
  });*/
}
cleanCreatedDate(){
  for(let i = 0; i < this.InteractionList.length; i++){
    this.InteractionList[i].CreatedDate = Date.parse(this.InteractionList[i].CreatedDate); 
  }

}
initializePaginationList(recordList){
  let returnList = [];
  for(let i = 0; i < recordList.length; i++){
    if(i<10){
      returnList.push(recordList[i]);
    }
  }
this.paginationList = returnList;
}
initializePageList(){ 
  let recordList = [];
  let returnList=[];
  for(let i = 0; i < this.InteractionList.length; i++){
    recordList.push(this.InteractionList[i]);
    if(recordList.length === this.numberOfRecordsToDisplay || i === (this.InteractionList.length -1)){
      let pageNumberParam = returnList.length + 1;    
      returnList.push({ pageNumber: pageNumberParam , objList : JSON.stringify(recordList)}); 
      recordList.length = 0;
    }
  }
  this.pageList = returnList;
  this.initializePaginationList(returnList);
  if(this.pageList.length > 1){
    this.moreThanOnePage = true;
    this.handleNavButtonDisableLogic();
  }
  if(this.pageList.length > 10){
    this.showDots = true;
  }
  
}
loadPageNumber(event){
  this.closeSections();
  let pagenumber = parseInt(event.currentTarget.dataset.id) -1;
    
  this.displayList = JSON.parse(this.pageList[pagenumber].objList);
  

  this.currentPage = pagenumber;
  this.displayPageNumber = pagenumber + 1;
  this.handleNavButtonDisableLogic();
}
initializeDisplayList(){
  let firstTenRecords=[];
  for(let i = 0; i < this.InteractionList.length; i++){
      if(i<this.numberOfRecordsToDisplay){
          firstTenRecords.push(this.InteractionList[i]);
      }
    }
  this.displayList = firstTenRecords;
  this.currentPage = 0;
  this.displayPageNumber = 1;
}
next(){
  this.closeSections();
  
  let currentpagenumber = this.currentPage+1;

  if(currentpagenumber < this.pageList.length){
      this.displayList = JSON.parse(this.pageList[currentpagenumber].objList);
      this.currentPage++;
      this.displayPageNumber++;
    }
    this.handleNavButtonDisableLogic();
}
refresh(){
  this.displayList = null;
  this.InteractionList = null;
  this.closeSections();
  this.connectedCallback();
  this.currentPage=0;
}
prev(){
  this.closeSections();
  
  let currentpagenumber = this.currentPage-1;

  if(this.currentPage !== 0){
      this.displayList = JSON.parse(this.pageList[currentpagenumber].objList);
      this.currentPage--;
      this.displayPageNumber--;

    }
    this.handleNavButtonDisableLogic();
}
closeSections(){

  let lwcList = this.template.querySelectorAll(this.LWC_COMPONENT_NAME);
  for(let i = 0; i < lwcList.length; i++){
    lwcList[i].closeSection();
  }
}
handleCaseTypeFilterChange(){


}
handleNavButtonDisableLogic(){
  
  if(this.currentPage === 0){
    this.disableNavigationButton(this.prevButtonId,true)
  }else{
    this.disableNavigationButton(this.prevButtonId,false);
  }

  if((this.currentPage+1) === this.pageList.length){
    this.disableNavigationButton(this.nextButtonId,true);
  }else{
    this.disableNavigationButton(this.nextButtonId,false);
  }
}
disableNavigationButton(buttonName,value){
  let button = this.template.querySelector(buttonName);
 //sometime we hide the buttons
  if(button){
    button.disabled = value;
 }
}
checkshowPageNav(){
  this.showPageNav = !this.showPageNav;


  console.log('helping');
}
}
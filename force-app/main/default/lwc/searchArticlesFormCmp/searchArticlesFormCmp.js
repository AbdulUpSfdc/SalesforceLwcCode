import { LightningElement, track, api, wire } from "lwc";
import getFilters from "@salesforce/apex/ArticleSearchDataService.getFilters";
import getViewAsFilters from "@salesforce/apex/ArticleSearchDataService.getViewAsFilters";

//import getViewAsFilters from "@salesforce/apex/ArticleFilterDataService.getViewAsFilters";
import formFactorPropertyName from '@salesforce/client/formFactor';
import UsedLicensesLastUpdated from "@salesforce/schema/UserLicense.UsedLicensesLastUpdated";
import hasKMViewAsPermission from "@salesforce/customPermission/KM_View_As";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import isSandbox from "@salesforce/apex/ArticleSearchDataService.isSandbox";
import getSearchExecutionType from "@salesforce/apex/ArticleSearchDataService.getSearchExecutionType";

// The delay used when debouncing event handlers before firing the event
const DELAY = 350;

export default class SearchArticlesFormCmp extends LightningElement {
  @api userId;

  IS_DESKTOP;
  
  isSandboxProperty = false;
  previous_isSandboxProperty = false;


  number_of_type_selected ='';
  number_of_market_selected="";
  number_of_category_selected="";
  number_of_status_selected="";
  date_range_set = "";

  get hasViewAsPermission() {
    console.log('User has view as permission: ' + hasKMViewAsPermission);
    return hasKMViewAsPermission;
  }

 
/* first div is to be the main container when one of the other divs is selected, toggle divs will turn off all other divs except for the first one */
filter_divs = 
[
  {
    divname: 'filter_div_container',
    show:    false
  },
  {
    divname: 'type_filter_div',
    show:    false
  },
  {
    divname: 'market_filter_div',
    show:    false
  },
  {
    divname: 'category_filter_div',
    show:    false
  },
  {
    divname: 'status_filter_div',
    show:    false
  },
  {
    divname: 'daterange_filter_div',
    show:    false
  },



];

  //viewas 
  userCanUseViewAs = hasKMViewAsPermission;
  @track userCanUseViewAs = true;
  ViewAsOpen = false;
  firsttime = true;

  searchText = "";
  startDate = "";
  endDate = "";
  dateValidationError = false;
  dateValidationMsg = "";
  sortBy;
  filterBy;
  filterLabels = [];
  @track typeFilters = [];
  typeFilterValue = [];
  @track marketFilters = [];
  @track allMarketFilters = [];
  @track allCategoryFilters = [];
  @track employeeRoleFilters = [];
  @track resourceTypeFilters = [];
  
  marketFilterValue = [];
  @track categoryFilters = [];
  categoryFilterValue = [];
  @track statusFilters = [];
  statusFilterValue = [];
  showFilters = false;
  filterDivHeight = 0;
  showSort = false;
  showGrid = false;
  iconGridCssClass = "unselected-icon";
  iconListCssClass = "selected-icon";
  @track error;
  firstLoadComplete;
  largeDevice = true;

  // show_quantity
//hide_quantity
  @track current_type_quantity_class = "show_quantity";
  current_market_quantity_class = "show_quantity";
  current_category_quantity_class = "show_quantity";
  current_status_quantity_class = "show_quantity";
  current_daterange_quantity_class  = "hide_quantity";

  current_searchTextInput = "slds-is-expanded";

  searchExecType = '';




  get searchTextInput()
  {
    return this.current_searchTextInput;
  }

  current_showsortby = "slds-is-expanded";
  get showsortby()
  {
    return this.current_showsortby;
  }

  //current_showViewAs = "slds-is-expanded";
  // viewas uses a span, need to use own show/hide not slds version
  // hide_this_button
  // show_this_button
  current_showViewAs = "show_this_button";


  get showViewAs()
  {
    return this.current_showViewAs;
  }

//  current_showFilterBy = "slds-is-expanded";
    // filterby  uses a span, need to use own show/hide not slds version
  // hide_this_button
  // show_this_button
  current_showFilterBy = "show_this_button";
  get showFilterBy()
  {
    return this.current_showFilterBy;
  }


  off_searchTextInput()
  {
   this.current_searchTextInput = "slds-is-collapsed";
  }
  on_searchTextInput()
  {
   this.current_searchTextInput = "slds-is-expanded";
  }
  
  off_showViewAs()
  {
   //this.current_showViewAs = "slds-is-collapsed";
   this.current_showViewAs = "hide_this_button";
   
  }
  on_showViewAs()
  {
//   this.current_showViewAs = "slds-is-expanded";
   this.current_showViewAs = "show_this_button";
  }
  
  off_showFilterBy()
  {
    this.current_showFilterBy = "hide_this_button";

  }
  on_showFilterBy()
  {
   this.current_showFilterBy = "show_this_button";
  }
  
  off_showsortby()
  {
   this.current_showsortby= "slds-is-collapsed";
  }
  on_showsortby()
  {
   this.current_showsortby= "slds-is-expanded";
  }
  

  get type_quantity_class(){
    return this.current_type_quantity_class;
  }

  get market_quantity_class(){
    return this.current_market_quantity_class;
  }
  get category_quantity_class(){
    return this.current_category_quantity_class;
  }
  get status_quantity_class(){
    return this.current_status_quantity_class;
  }

  get daterange_quantity_class(){
    return this.current_daterange_quantity_class;
  }


  get buttonApplyCss() {
    return "slds-button slds-p-horizontal_medium button-apply";
  }

  get buttonSmallCss() {
    return "slds-button slds-p-horizontal_small button-apply smallButton";
  }  

  get selectallbuttonSmallStyle() {
    return  "  color:#1E5876; width: 62px; font-size: 12px;cursor: pointer; position:relative; background: transparent;   border: none;  margin: 0px;  padding:0px; outline: none; color:white; top:-5px"
  }  


  get selectallbuttonSmallStyleviewas() {
    return  "  color:#1E5876; width: 62px; font-size: 12px;cursor: pointer; position:relative; background: transparent;   border: none;  margin: 0px;  padding:0px; outline: none; top:-5px; left:18px"
  }  


  get clearallbuttonSmallStyle() {
      return  "  color:#1E5876; width: 62px; font-size: 12px;cursor: pointer; position:relative; background: transparent;   border: none;  margin: 0px;  padding:0px; outline: none; color:white;top:-5px;float:right;"
    }  


  get clearbuttonSmallStyle() {

    return  "  color:#1E5876; width: 42px; font-size: 12px;cursor: pointer; position:relative; background: transparent;   border: none;  margin: 0px;  padding:0px; outline: none; color:white;top:-5px"
  }  

  get cleardatebuttonSmallStyle() {

    return  "  color:#1E5876; width: 80px; font-size: 12px;cursor: pointer; position:relative; background: transparent;   border: none;  margin: 0px;  padding:0px; outline: none; color:white;top:-5px;float:right;"
  }  


 @track current_type_class = "submenu_button_unselected";

  get type_class() {
    console.log("current_type_class="+this.current_type_class);
    return  this.current_type_class;

  }  
  
 current_market_class = "submenu_button_unselected";
  get market_class() {
    return  this.current_market_class;
  }  
  
  current_category_class = "submenu_button_unselected";
  get category_class() {
    return  this.current_category_class;
  }  

  current_status_class = "submenu_button_unselected";
  get status_class() {
    return  this.current_status_class;
  }    


  current_daterange_class = "submenu_button_unselected";
  get daterange_class() {
    return  this.current_daterange_class;
  }  
 
  //viewas 
  get buttonViewAsCss() {
    return !this.ViewAsOpen
      ? "slds-button slds-p-horizontal_x-small viewas-button-dropdown"
      : "slds-button slds-p-horizontal_x-small viewas-button-dropdown-clicked";
  }
  get buttonViewAsIconCss() {
    return !this.ViewAsOpen ? "selected-icon" : "selected-icon-clicked";
  }

  get buttonViewAsIconCssUpIcon() {
    return "buttonViewAsIconCssUpIcon"

  }

  currentviewasDivDontainerClass= "viewas_div_container slds-is-collapsed";


get viewasDivDontainerClass(){
  return this.currentviewasDivDontainerClass;
}


 

viewasProdStyleFix = "  ";
get viewasProdStyleFix(){
  return this.viewasProdStyleFix;
}




currentbuttonViewAsStyle = "";
get buttonViewAsStyle()
{
  return this.currentbuttonViewAsStyle;
}

  get buttonFilterCss() {
    return !this.showFilters
      ? "slds-button slds-p-horizontal_x-small button-dropdown"
      : "slds-button slds-p-horizontal_x-small button-dropdown-clicked";
  }


  get buttonFilterIconCss() {
    return !this.showFilters ? "selected-icon" : "selected-icon-clicked";
  }
  get buttonSortCss() {
    return !this.showSort
      ? "slds-button slds-p-horizontal_x-small button-dropdown"
      : "slds-button slds-p-horizontal_x-small button-dropdown-clicked";
  }
  get buttonSortIconCss() {
    return !this.showSort ? "selected-icon" : "selected-icon-clicked";
  }
  get iconGridCss() {
    return this.showGrid == true ? "selected-icon" : "unselected-icon";
  }
  get iconListCss() {
    return this.showGrid == false
      ? "slds-m-left_xx-small selected-icon"
      : "slds-m-left_xx-small unselected-icon";
  }
  
  get isExplicitSearchEnabled(){
    return this.searchExecType == "Explicit Search";
  }

  get isKeyPressSearchEnabled(){
    return this.searchExecType == "Key Press Search";
  }

  get searchBarWidth(){
    return this.searchExecType == "Key Press Search"
      ? "4"
      : "4";
  }

  connectedCallback(){
    if(formFactorPropertyName =='Medium'|| formFactorPropertyName =='Small'){
         this.largeDevice = false;
    }

    if(formFactorPropertyName=='Large') {
      this.IS_DESKTOP = true;
   }

   // uncomment the following line to test IPAD on desktop ( force  this.IS_DESKTOP=false)
  //this.IS_DESKTOP = false;

  }

  @wire(getSearchExecutionType)
  getSearchExecType({ error, data }){
    if(data){
      this.searchExecType = data;
    } else if(error){
      console.log("Error occurred in getSearchExecutionType:", error); 
    }
  }

  @wire(isSandbox)
  wiredIsSandbox({ error, data }) {

    if ( data===true) 
    {
      //this.isSandboxProperty = data;
      this.isSandboxProperty = true;
    }
    else if (data===false)
    {
      this.isSandboxProperty = false;
    }
    else if (error) 
    {
      this.isSandboxProperty = false;
    }

    //this.isSandboxProperty = false; // testing  prod
    //this.isSandboxProperty = true; // testing  sandbox

}


  renderedCallback() {

    console.log("renderdCallback searhArticlesFormCmp");

    if( this.firsttime)
    {
      //alert ("in rendered callback");
      //set_number_of_type_selected();
      this.set_number_of_type_selected();
      this.set_number_of_market_selected();
      this.set_number_of_category_selected();
      this.set_number_of_status_selected();

      //this.set_number_of_type_selected();

    }
    this.firsttime = false;

  }
  @api
  searchRendered() {
    
  }


  @wire(getViewAsFilters)
  
  wiredViewAsFilters(result) {
    console.log('Get View as Filters Users has view as permission ' + hasKMViewAsPermission);
    //throw new Error("Cannot divide by 0"); 
    const { data, error } = result;
    if (hasKMViewAsPermission) {
      if (data) {
        console.log('Data: ' + JSON.stringify(data));
        for (let filterName in data) {
          if (filterName === "employeetype"){
            for (let key in data[filterName]) {
              //console.log('in Market Loop');
              var newOption = {};
                newOption = {
                  label: data[filterName][key]["label"],
                  value: data[filterName][key]["value"]
                }; 
              //console.log('Adding market opton: ' + JSON.stringify(marketValueOption));
                this.resourceTypeFilters = [... this.resourceTypeFilters, newOption];
              }  
          }
          
          if (filterName === "market") {
              //console.log('Market: ' + JSON.stringify( data[filterName]));
            for (let key in data[filterName]) {
              //console.log('in Market Loop');
              var newOption = {};
                newOption = {
                  label: data[filterName][key]["label"],
                  value: data[filterName][key]["value"]
                }; 
              //console.log('Adding market opton: ' + JSON.stringify(marketValueOption));
                this.allMarketFilters = [... this.allMarketFilters, newOption];
              }  
          }
          
          if (filterName === "channel") {
            for (let key in data[filterName]) {
              //console.log('in Market Loop');
              var newOption = {};
                newOption = {
                  label: data[filterName][key]["label"],
                  value: data[filterName][key]["value"]
                }; 
              //console.log('Adding market opton: ' + JSON.stringify(marketValueOption));
                this.allCategoryFilters = [... this.allCategoryFilters , newOption];
              }  
          }
            
          if (filterName === "role") {
            for (let key in data[filterName]) {
              //console.log('in Market Loop');
              var newOption = {};
                newOption = {
                  label: data[filterName][key]["label"],
                  value: data[filterName][key]["value"]
                }; 
              //console.log('Adding market opton: ' + JSON.stringify(marketValueOption));
                this.employeeRoleFilters= [... this.employeeRoleFilters, newOption];
              }  
          }
            
          
        }
        console.log('Resource Type Filters: ' + JSON.stringify(this.resourceTypeFilters));
        console.log('Role Filters: ' + JSON.stringify(this.employeeRoleFilters));
        console.log('Market Filters: ' + JSON.stringify(this.allMarketFilters));
        
        console.log('Channel Filters: ' + JSON.stringify(this.allCategoryFilters));

      } else if (error) {
        this.error = "Unknown error loading View as filters";
        if (Array.isArray(error.body)) {
          this.error = error.body.map((e) => e.message).join(", ");
        } else if (typeof error.body.message === "string") {
          this.error = error.body.message;
        }
        this.employeeRoleFilters = undefined;
        this.allMarketFilters = undefined;
        this.allCategoryFilters = undefined;
        this.resourceTypeFilters = undefined;
      /*  this.RoleValue = 'Select Role';
        this.EmployeeTypeValue = 'Select Resource Type';
        this.PrimaryMarketValue = 'Select Primary Market';
        this.PrimaryChannelValue = 'Select Primary Channel'; */
      }
    }
  }


  @wire(getFilters)
  wiredFilters(result) {
    console.log('GetFilters Users has view as permission ' + hasKMViewAsPermission);

    //throw new Error("Cannot divide by 0"); 
    const { data, error } = result;
    if (data) {
      for (let filterName in data) {
        if (filterName === "type")
          this.populateFilters(filterName, data[filterName], this.typeFilters);
        if (filterName === "market")
          this.populateFilters(
            filterName,
            data[filterName],
            this.marketFilters
          );
        if (filterName === "category")
          this.populateFilters(
            filterName,
            data[filterName],
            this.categoryFilters
          );
        if (filterName === "status")
          this.populateFilters(
            filterName,
            data[filterName],
            this.statusFilters
          );
          if (filterName === "searchText") {
            for (let key in data[filterName]) {
              //let filterChecked = filterSrc[key]["label"].includes("(Primary)") ? true : false;
              //let filterChecked = filterSrc[key]["checked"].includes("true") ? true : false;
  
              this.searchText =  data[filterName][key]["value"];
              }
              console.log('End searchtext filter');
            } 
            if (filterName === "startDate") {
              for (let key in data[filterName]) {
                //let filterChecked = filterSrc[key]["label"].includes("(Primary)") ? true : false;
                //let filterChecked = filterSrc[key]["checked"].includes("true") ? true : false;
    
                this.startDate =  data[filterName][key]["value"];
                }
                console.log('End startDate filter');
              } 
              if (filterName === "endDate") {
                for (let key in data[filterName]) {
                  //let filterChecked = filterSrc[key]["label"].includes("(Primary)") ? true : false;
                  //let filterChecked = filterSrc[key]["checked"].includes("true") ? true : false;
      
                  this.endDate =  data[filterName][key]["value"];
                  }
                  console.log('End endtDate filter');
                } 



      }

      //alert("after initial load of  filters");

      this.set_number_of_type_selected();
      this.set_number_of_market_selected();
      this.set_number_of_category_selected();
      this.set_number_of_status_selected();

    } else if (error) {
      this.error = "Unknown error loading filters";
      if (Array.isArray(error.body)) {
        this.error = error.body.map((e) => e.message).join(", ");
      } else if (typeof error.body.message === "string") {
        this.error = error.body.message;
      }
      this.typeFilters = undefined;
      this.marketFilters = undefined;
      this.categoryFilters = undefined;
      this.statusFilters = undefined;
    }
  }


  populateDropDownFilters(filterName, filterSrc, filterTarget) {
      console.log('Adding filters for ' + filterName);
      tempArray = [];
      for (let key in filterSrc) {
        
        tempArray.push({
          label: filterSrc[key]["label"],
          value: filterSrc[key]["value"]
        });
      }
      return tempArray;
    /*  if (!this.firstLoadComplete) {
       this.delayTimeout = setTimeout(() => {
         this.fireFilterByChangeEventFirstLoad();
       }, 100);
       this.firstLoadComplete = true;
     }
 */  
  }

  populateFilters(filterName, filterSrc, filterTarget) {
    for (let key in filterSrc) {
      //let filterChecked = filterSrc[key]["label"].includes("(Primary)") ? true : false;
      //let filterChecked = filterSrc[key]["checked"].includes("true") ? true : false;
      //console.log('Fi;ter value' + filterSrc[key]["value"]  + filterSrc[key]["checked"]);
      filterTarget.push({
        group: filterName,
        label: filterSrc[key]["label"],
        value: filterSrc[key]["value"],
        checked: filterSrc[key]["checked"],
        //checked: filterChecked
      });
    }
     if (!this.firstLoadComplete) {
       this.delayTimeout = setTimeout(() => {
         this.fireFilterByChangeEventFirstLoad();
       }, 100);
       this.firstLoadComplete = true;
     }
  }
  toggleFilterDiv() {

   //var thebody = document.body;
   // var thehtml = document.html;

   
    if (this.showFilters === false)
     {
      this.template
        .querySelector(".filter-div")
        .classList.add("slds-is-expanded");
      this.template
        .querySelector(".filter-div")
        .classList.remove("slds-is-collapsed");
      this.showFilters = true;

      if(this.IS_DESKTOP && this.userCanUseViewAs)
      {
        this.off_showViewAs();
      }
 

    } 
    else
    {
      this.template
        .querySelector(".filter-div")
        .classList.remove("slds-is-expanded");
      this.template
        .querySelector(".filter-div")
        .classList.add("slds-is-collapsed");
      this.showFilters = false;

      if(this.IS_DESKTOP && this.userCanUseViewAs)
      {
        this.on_showViewAs();
      }
 

    }
    this.filterDivHeight = this.template.querySelector(".filter-div").offsetHeight;
    this.fireFilterDivVisible();
  }

  

  handleFilterCheckboxes() {
    this.filterLabels = [];
    this.typeFilterValue = [];
    this.marketFilterValue = [];
    this.categoryFilterValue = [];
    this.statusFilterValue = [];
    let i;
    let checkboxes = this.template.querySelectorAll(
      '[data-id="checkbox-filter"]'
    );
    for (i = 0; i < checkboxes.length; i++) 
    {
      if (checkboxes[i].checked) 
      {

        this.filterLabels.push({
          group: checkboxes[i].dataset.group,
          label:
            checkboxes[i].dataset.group + ": " + checkboxes[i].dataset.label,
          value: checkboxes[i].dataset.value
        });

        if (checkboxes[i].dataset.group == "Type") {
          this.typeFilterValue.push(checkboxes[i].dataset.value);
        }
        if (checkboxes[i].dataset.group == "Market") {
          this.marketFilterValue.push(checkboxes[i].dataset.value);
        }
        if (checkboxes[i].dataset.group == "Category") {
          this.categoryFilterValue.push(checkboxes[i].dataset.value);
        }
        if (checkboxes[i].dataset.group == "Status") {
          this.statusFilterValue.push(checkboxes[i].dataset.value);
        }
      }

       console.log(checkboxes[i].dataset.label+" "+checkboxes[i].checked);

      //checkboxes[i].checked = event.target.checked;
    }
  }

  rehydrateFiltersCheckboxes() {
    this.filters.forEach((filter) => {});

  }
  @api
  removeFilter(filterValue) {
    this.updateUIFilterCheckbox(filterValue, false);
   
    this.fireFilterByChangeEvent();
  }
  handleDateFilter(event) {
    let name = event.target.name;
    if(name === 'startDate'){
      this.startDate = event.target.value;
    }
    else{
      this.endDate = event.target.value;
    }
    if(this.dateValidationError === true){
      this.dateValidationError = false;
      this.dateValidationMsg = "";
    }

    if( !this.startDate || !this.endDate )
    {

      this.date_range_set = '';
      this.current_daterange_quantity_class = 'hide_quantity';
    }
    else
    {
      this.date_range_set = '1';
      this.current_daterange_quantity_class = 'show_quantity';
    }



  }
  handleFilterClick(event) {
    let checkboxValue = event.currentTarget.dataset.value;
    let checkboxChecked = event.target.checked;

//console.log(checkboxValue+" "+checkboxChecked);

    this.updateUIFilterCheckbox(checkboxValue, checkboxChecked);
  }
  updateUIFilterCheckbox(checkboxValue, checkboxChecked) {
    this.typeFilters.forEach((filter) => {
      if (filter.value === checkboxValue) {
        filter.checked = checkboxChecked;
        this.set_number_of_type_selected();
        return;
      }
    });
    this.marketFilters.forEach((filter) => {
      if (filter.value === checkboxValue) {
        filter.checked = checkboxChecked;
        this.set_number_of_market_selected();
        return;
      }
    });
    this.categoryFilters.forEach((filter) => {
      if (filter.value === checkboxValue) {
        filter.checked = checkboxChecked;
        this.set_number_of_category_selected();
        return;
      }
    });
    this.statusFilters.forEach((filter) => {
      if (filter.value === checkboxValue) {
        filter.checked = checkboxChecked;
        this.set_number_of_status_selected();
        return;
      }
    });
  }

  toggleSortDiv() {
    if (this.showSort === false) {
      this.template.querySelector(".sort-div").classList.add("slds-is-open");
      this.template
        .querySelector(".sort-div")
        .classList.remove("slds-is-closed");
      this.showSort = true;
    } else {
      this.template.querySelector(".sort-div").classList.remove("slds-is-open");
      this.template.querySelector(".sort-div").classList.add("slds-is-closed");
      this.showSort = false;
    }
  }





  desktop_clear_all()
  {
    //alert("in desktop_clear_all");
    this.filterLabels = [];
    this.typeFilterValue = [];
    this.marketFilterValue = [];
    this.categoryFilterValue = [];
    this.statusFilterValue = [];
    let i;
    let checkboxes = this.template.querySelectorAll(
      '[data-id="checkbox-filter"]'
    );
    for (i = 0; i < checkboxes.length; i++) 
    {
      
//      console.log(checkboxes[i].dataset.group);

      if (checkboxes[i].dataset.group == "type" ||
          checkboxes[i].dataset.group == "market" ||
          checkboxes[i].dataset.group == "category" ||
          checkboxes[i].dataset.group == "status"
      )
      {
        checkboxes[i].checked = false; 
//        console.log(checkboxes[i].value+" "+checkboxes[i].checked);
        this.updateUIFilterCheckbox(checkboxes[i].value, false);
      } 
      else
      {
//        console.log(checkboxes[i].dataset.group+" failed check...")
      }




    }

  }

  handleSearchOnKeyPress(event){
    if(event.which == 13) {
      this.searchText = event.target.value;
      this.handleFilterCheckboxes();
      this.delayedFireSearchTextChangeEvent();
    }
    
  }

  //event handlers
  handleSearchKeyChange(event) {
    // this.searchText = event.target.value;
    // also sending latest filters in case they are out of sync
   this.searchText =this.template.querySelector(`[data-id="searchInput"]`).value;
   

    this.handleFilterCheckboxes();
    this.delayedFireSearchTextChangeEvent();
  }
  handleSort(event) {
    this.sortBy = event.currentTarget.dataset.id;
    this.toggleSortDiv();
    this.fireSortByChangeEvent();
   
  }
  handleFilter(event) {

    //alert("before toggle filter "+this.IS_DESKTOP);
    if(!this.IS_DESKTOP){
      this.toggle_filter_div_container(event);
    }

    this.runDateValidations();
    if(this.dateValidationError === false)
    {
      this.toggleFilterDiv();
      this.fireFilterByChangeEvent();
    }
    else
    {

  //alert("Apply from Viewas based on settings");
    const evt = new ShowToastEvent({
      title: 'handleFilter error',
      message: 'rundDataValidates Error encountered.',
      variant: 'error',
      mode: 'dismissable'
    });
    this.dispatchEvent(evt);
 
    }
  
  }
  handleGridView(event) {
    this.showGrid = true;
    this.fireLayoutChangeEvent("grid");
   
  }
  handleListView(event) {
    this.showGrid = false;
    this.fireLayoutChangeEvent("list");

  }
  runDateValidations() {
    if(this.startDate && !this.endDate){
      this.dateValidationError = true;
      this.dateValidationMsg = "Enter the end date.";
    }
    else if(!this.startDate && this.endDate){
      this.dateValidationError = true;
      this.dateValidationMsg = "Enter the start date.";
    }
    else if(this.endDate < this.startDate){
      this.dateValidationError = true;
      this.dateValidationMsg = "End date should be greater than start date.";
    }

  }

  //event fires
  delayedFireSearchTextChangeEvent() {
    // Debouncing this method: Do not actually fire the event as long as this function is
    // being called within a delay of DELAY. This is to avoid a very large number of Apex
    // method calls in components listening to this event.
    window.clearTimeout(this.delayTimeout);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    let DELAY = 350;
    this.delayTimeout = setTimeout(() => {
      // Fire search event
      const searchEvent = new CustomEvent("search", {
        detail: {
          searchText: this.searchText,
          startDate: this.startDate,
          endDate: this.endDate,
          filterBy: {
            typeFilters: this.extractFilterValues(this.typeFilters),
            marketFilters: this.extractFilterValues(this.marketFilters),
            categoryFilters: this.extractFilterValues(this.categoryFilters),
            statusFilters: this.extractFilterValues(this.statusFilters)
          },
          filterLabels: this.extractFilterLabels()
        }
      });
      this.dispatchEvent(searchEvent);
    }, DELAY);
  }
  fireSortByChangeEvent() {
    const sortEvent = new CustomEvent("sort", {
      detail: { sortBy: this.sortBy }
    });
    this.dispatchEvent(sortEvent);
  }

  fireFilterByChangeEvent() {
    const filterEvent = new CustomEvent("filter", {
      detail: {
        searchText: this.searchText,
        startDate: this.startDate,
        endDate: this.endDate,
        filterBy: {
          typeFilters: this.extractFilterValues(this.typeFilters),
          marketFilters: this.extractFilterValues(this.marketFilters),
          categoryFilters: this.extractFilterValues(this.categoryFilters),
          statusFilters: this.extractFilterValues(this.statusFilters)
        },
        filterLabels: this.extractFilterLabels()
      }
    });
    this.dispatchEvent(filterEvent);
  }






  fireFilterByChangeEventFirstLoad() {
    const filterEvent = new CustomEvent("filterfirstload", {
      detail: {
        searchText: this.searchText,
        startDate: this.startDate,
        endDate: this.endDate,
        filterBy: {
          typeFilters: this.extractFilterValues(this.typeFilters),
          marketFilters: this.extractFilterValues(this.marketFilters),
          categoryFilters: this.extractFilterValues(this.categoryFilters),
          statusFilters: this.extractFilterValues(this.statusFilters)
        },
        filterLabels: this.extractFilterLabels()
      }
    });
    //this.dispatchEvent(filterEvent);
  }





  fireViewAs() {
    const viewas = new CustomEvent("viewas", {
      detail: {
        visible: this.ViewAsOpen
      }
    });
    this.dispatchEvent(viewas);
  }




  fireFilterDivVisible() {
    const filterVisible = new CustomEvent("filtervisible", {
      detail: {
        visible: this.showFilters,
        height: this.filterDivHeight
      }
    });
    this.dispatchEvent(filterVisible);
  }





  fireLayoutChangeEvent(layoutType) {
    const layoutEvent = new CustomEvent("layout", {
      detail: { layoutType: layoutType }
    });
    this.dispatchEvent(layoutEvent);
  }
 
  //Event helpers
  extractFilterValues(source) {
    let filterValues = [];
    filterValues = source
      .filter((filter) => filter.checked)
      .map((checkedFilter) => checkedFilter.value);
    return filterValues;
  }
  extractFilterLabels() {
    let filterLabels = [];
    filterLabels = filterLabels.concat(
      this.typeFilters.filter((filter) => filter.checked),
      this.marketFilters.filter((filter) => filter.checked),
      this.categoryFilters.filter((filter) => filter.checked),
      this.statusFilters.filter((filter) => filter.checked)
    );
    return filterLabels;
  }



//  toggleDiv(event) 
  toggleDiv(togglethisdivname) 
  {

// this method was created for the IPAD view
// this also calls the desktop toggle as sub logic relys on that div


   //console.log(event);
   //console.log(this.filter_divs);
   //let togglethisdivname = 'filter_div_container';

   // the div class name is in the data-id="type_filter_div"  key value pair 
  // let togglethisdivname = event.currentTarget.dataset.id;

   //console.log(" div name to toggle =>>"+togglethisdivname+"<<");

   // a '.' is needed before this name to add/remove the slds slds-is-expanded or slds-is-collapsed calss
   //let dot_togglethisdivname = '.'+ event.currentTarget.dataset.id;
   let dot_togglethisdivname = '.'+togglethisdivname;
   //console.log(togglethisdivname);

   let filter_div = this.filter_divs.find(filter_div => filter_div.divname === togglethisdivname);
  // console.log(filter_div);
   
   let thisindex = this.filter_divs.findIndex(filter_div => filter_div.divname === togglethisdivname);
  // console.log(thisindex);
  

   // turn off all divs except for first one (container div) and the div selected by this event
   let divindex;
   let num_filter_divs = this.filter_divs.length;
  // console.log(">>>>> num_filter_divs2 = " + num_filter_divs);
 
   if( thisindex !=0)
   {

    for( divindex=1; divindex <  num_filter_divs; ++divindex)
    {

      if( divindex != thisindex)
      {

      try 
      {
        this.filter_divs[divindex].show=false;
        const dot_divindex_name = '.'+ this.filter_divs[divindex].divname;
        this.template.querySelector(dot_divindex_name).classList.add("slds-is-collapsed"); 

        this.template.querySelector(dot_divindex_name).classList.remove("slds-is-expanded");
        
      }
      // firsttime in the menu divs do not exist
      catch(err) 
      {
       // console.log("collaps show failed");
      }        
      }
    }

  }
  else
  {
    this.toggleFilterDiv()
  }

//console.log ("after onoff loop thisindex="+thisindex);
 

   //  make it visable
    if (this.filter_divs[thisindex].show  === false) 
    {
 
      this.template.querySelector(dot_togglethisdivname).classList.add("slds-is-expanded");
      this.template.querySelector(dot_togglethisdivname).classList.remove("slds-is-collapsed");
      this.filter_divs[thisindex].show=true;

      
      //console.log("turn on "+thisindex);

    } 

   //  hide  it
   else 
    {
      this.template.querySelector(dot_togglethisdivname).classList.remove("slds-is-expanded");
      this.template.querySelector(dot_togglethisdivname).classList.add("slds-is-collapsed");
      this.filter_divs[thisindex].show=false;
      //console.log("turn off "+thisindex);

    } 
 

   }

  hide_filter_container_div()
  {
   this.filter_divs[0].show=false;
   this.template.querySelector(".filter_div_container").classList.add("slds-is-collapsed");   
   this.template.querySelector(".filter_div_container").classList.remove("slds-is-expanded");     
  }

  show_filter_div()
  {
   this.filter_divs[0].show=false;
   this.template.querySelector(".filter_div_container").classList.add("slds-is-collapsed");   
   this.template.querySelector(".filter_div_container").classList.remove("slds-is-expanded");     
  }
  hide_filter_div()
  {
   this.filter_divs[0].show=false;
   this.template.querySelector(".filter_div_container").classList.add("slds-is-collapsed");   
   this.template.querySelector(".filter_div_container").classList.remove("slds-is-expanded");     
  }



  set_number_of_type_selected()
  {

//alert("set_number_of_type_selected");

   let the_length = this.typeFilters.length;
   let num_checked=0;
   let an_index = 0;
   for (an_index = 0; an_index<the_length; ++an_index)
   {
     if(this.typeFilters[an_index].checked)
     {
       ++num_checked
     }
   }   

   let quantity_string="";
   if( num_checked > 0)
   {
//     quantity_string = "("+num_checked+")";
     quantity_string = num_checked;
     /*quantity_string = "<div class='numberCircle'>"+num_checked+"</div>";*/
     this.current_type_quantity_class = 'show_quantity';


   }
   else{
    this.current_type_quantity_class = 'hide_quantity';
   }

   this.number_of_type_selected = quantity_string;
   //alert ("updated number of selected types"+quantity_string);


  }



   
     
  set_number_of_market_selected()
  {

   let the_length = this.marketFilters.length;
   let num_checked=0;
   let an_index = 0;
   for (an_index = 0; an_index<the_length; ++an_index)
   {
     if(this.marketFilters[an_index].checked)
     {
       ++num_checked
     }
   }   

   let quantity_string="";
   if( num_checked > 0)
   {
     quantity_string = num_checked;
     this.current_market_quantity_class = 'show_quantity';
    }
   else{
    this.current_market_quantity_class = 'hide_quantity';
   }

   quantity_string = num_checked;

   this.number_of_market_selected = quantity_string;
   //alert ("updated number of selected markets >>"+quantity_string+" <<");


  }

  set_number_of_category_selected()
  {

   let the_length = this.categoryFilters.length;
   let num_checked=0;
   let an_index = 0;
   for (an_index = 0; an_index<the_length; ++an_index)
   {
     if(this.categoryFilters[an_index].checked)
     {
       ++num_checked
     }
   }   

   let quantity_string="";
   if( num_checked > 0)
   {
     quantity_string = num_checked;
     this.current_category_quantity_class = 'show_quantity';
   }
   else
   {
    this.current_category_quantity_class = 'hide_quantity';
   }

   this.number_of_category_selected = quantity_string;
   //alert ("updated number of selected types"+quantity_string);
  }
   
  set_number_of_status_selected()
  {

   let the_length = this.statusFilters.length;
   let num_checked=0;
   let an_index = 0;
   for (an_index = 0; an_index<the_length; ++an_index)
   {
     if(this.statusFilters[an_index].checked)
     {
       ++num_checked
     }
   }   

   let quantity_string="";
   if( num_checked > 0)
   {
     quantity_string = num_checked;
     this.current_status_quantity_class = 'show_quantity';
    }
   else
   {
    this.current_status_quantity_class = 'hide_quantity';
   }


   this.number_of_status_selected = quantity_string;
   //alert ("updated number of selected types"+quantity_string);
  }





   mkr_all_type(event)
   {
    let type_length = this.typeFilters.length;
    let type_index;
    for (type_index = 0; type_index<type_length; ++ type_index)
    {
      this.typeFilters[type_index].checked = true;
    }
    this.set_number_of_type_selected();    
   }

   unmkr_all_type(event)
   {
    let type_length = this.typeFilters.length;
    let type_index;
    for (type_index = 0; type_index<type_length; ++ type_index)
    {
      this.typeFilters[type_index].checked = false;
    }
    this.set_number_of_type_selected();    
   }

   
   clear_daterange(event)
   {


    if(this.dateValidationError)
    {
    //  this.clear_daterange();
      this.dateValidationMsg = "";
      this.dateValidationError = false;
    }

    this.startDate = "";
    this.endDate = "";
    this.current_daterange_quantity_class='hide_quantity';

   }




   mkr_all_market(event)
   {
    let the_length = this.marketFilters.length;
    let the_index;
    for (the_index = 0; the_index < the_length; ++ the_index)
    {
      this.marketFilters[the_index].checked = true;
    }
    this.set_number_of_market_selected();    
   }

   unmkr_all_market(event)
   {
    let the_length = this.marketFilters.length;
    let the_index;
    for (the_index = 0; the_index < the_length; ++ the_index)
    {
      this.marketFilters[the_index].checked = false;
    }
    this.set_number_of_market_selected();    
   }


   mkr_all_category(event)
   {                      
    let the_length = this.categoryFilters.length;
    let the_index;
    for (the_index = 0; the_index < the_length; ++ the_index)
    {
      this.categoryFilters[the_index].checked = true;
    }
    this.set_number_of_category_selected();    
   }

   unmkr_all_category(event)
   {
    let the_length = this.categoryFilters.length;
    let the_index;
    for (the_index = 0; the_index < the_length; ++ the_index)
    {
      this.categoryFilters[the_index].checked = false;
    }
    this.set_number_of_category_selected();    
   }

   mkr_all_status(event)
   {
    let the_length = this.statusFilters.length;
    let the_index;
    for (the_index = 0; the_index < the_length; ++ the_index)
    {
      this.statusFilters[the_index].checked = true;
    }
    this.set_number_of_status_selected();    
   }

   unmkr_all_status(event)
   {
    let the_length = this.statusFilters.length;
    let the_index;
    for (the_index = 0; the_index < the_length; ++ the_index)
    {
      this.statusFilters[the_index].checked = false;
    }
    this.set_number_of_status_selected();    
   }




   // clears all filter by selections
   clearall(event)
   {
    
    console.log("clearall");

      this.unmkr_all_type(event);
      this.unmkr_all_market(event);
      this.unmkr_all_category(event);
      this.unmkr_all_status(event);

      // the menu updates must follow the un-mark of items
      this.set_number_of_type_selected();
      this.set_number_of_market_selected();
      this.set_number_of_category_selected();
      this.set_number_of_status_selected();


//      this.template.querySelector('[data-id="startDate"]').reset();
//      this.template.querySelectorAll('[data-id="checkbox-filter"]');

      this.startDate = "";
      this.endDate = "";
      this.current_daterange_quantity_class='hide_quantity';

   }

   
   clear_select()
   {

//alert("inclear");

    this.current_type_class = "submenu_button_unselected";
    this.current_market_class= "submenu_button_unselected";
    this.current_category_class= "submenu_button_unselected";
    this.current_status_class= "submenu_button_unselected";
    this.current_daterange_class= "submenu_button_unselected";
//    this.current_main_clear_class= "submenu_button_unselected";
  }
 

  toggle_filter_div_container(event)
  {

    this.toggleDiv("filter_div_container"); 

  }

//viewas 
toggle_viewas_div_container(event)
  {

    if(this.ViewAsOpen)
    {
 
          this.ViewAsOpen=false; 
          this.currentviewasDivDontainerClass= "viewas_div_container slds-is-collapsed";
          this.currentviewasTabStyle = "";
          this.currentbuttonViewAsStyle = "";

    
          this.on_showFilterBy();
          this.on_searchTextInput();
          this.on_showsortby();

    }	
    else
    {  



        this.currentviewasDivDontainerClass= "viewas_div_container slds-is-expanded";
        this.ViewAsOpen=true;

        this.currentviewasTabStyle = "height:80px;width:100px;background-color:#fbb765;";

//        this.currentbuttonViewAsStyle = " background-color: Transparent;background-repeat:no-repeat;border: none;cursor:pointer;overflow: hidden;outline:none;";
        this.currentbuttonViewAsStyle = " background-color: Transparent;background-repeat:no-repeat;border: none;cursor:pointer;overflow: hidden;outline:none;display:none;";
//        this.currentbuttonViewAsStyle = " background-color: Transparent;background-repeat:no-repeat;border: none;cursor:pointer;overflow: hidden;outline:none;";
        
        this.off_showFilterBy();
        this.off_searchTextInput();
        this.off_showsortby();


    }

    this.fireViewAs(); 


  }


// viewas
valuetlu = 'inProgress';
@track RoleValue = null;;
@track EmployeeTypeValue =null;
@track PrimaryMarketValue = null;
@track PrimaryChannelValue = null;

currentviewasTabStyle = "";
get viewasTabStyle()
{
  return this.currentviewasTabStyle;
}

get optionstlu() {
    return [
        { label: 'New', value: 'new' },
        { label: 'In Progress', value: 'inProgress' },
        { label: 'Finished', value: 'finished' },
    ];

}

get RoleValueoptions() {
  return this.employeeRoleFilters;
}

get EmployeeTypeoptions() {
  /* return [
      { label: 'New', value: 'new' },
      { label: 'Old', value: 'old' },
      { label: 'Good', value: 'good' },
      { label: 'Bad', value: 'bad' },
  ]; */
  return this.resourceTypeFilters;

}

get PrimaryMarketoptions() {
  /* return [
      { label: 'East', value: 'east' },
      { label: 'West', value: 'west' },
      { label: 'North', value: 'north' },
      { label: 'South', value: 'south' },
  ]; */
  return this.allMarketFilters;

}

get PrimaryChanneloptions() {
  /* return [
      { label: 'Red', value: 'red' },
      { label: 'Blue', value: 'blue' },
      { label: 'Green', value: 'green' },
      { label: 'Cyan', value: 'cyan' },
      { label: 'Yellow', value: 'yellow' },
      { label: 'Magenta', value: 'magenta' },
  ]; */
  return this.allCategoryFilters;
}


 



handleChangetlu(event) {
    this.valuetlu = event.detail.value;
}

handleChangeRoleValue(event) {
  this.RoleValue = event.detail.value;
}

handleChangeEmployeeTypeValue(event) {
  this.EmployeeTypeValue = event.detail.value;
}

handleChangePrimaryMarket(event) {
  this.PrimaryMarketValue = event.detail.value;
}

handleChangePrimaryChannel(event) {
    this.PrimaryChannelValue = event.detail.value;
}












closeViewas(){
  //alert("close viewas - same as clicking on viewas again");
}

applyViewas(triggerevt){
  

console.log("in applyViewas");


  //alert("Apply from Viewas based on settings");
  if (!(this.PrimaryChannelValue && this.PrimaryMarketValue && this.RoleValue &&  this.EmployeeTypeValue)) 
  {
    const evt = new ShowToastEvent({
      title: 'Missing Filter Values',
      message: 'You must set a value for every filter.',
      variant: 'error',
      mode: 'dismissable'
    });
    this.dispatchEvent(evt);

    //  this.toggle_viewas_div_container(triggerevt);

    return; 
  }

  //this.toggle_viewas_div_container(triggerevt);

  var viewAsParams = {};
  viewAsParams = { 
      channel: this.PrimaryChannelValue + '__c',
      market: this.PrimaryMarketValue,
      employeeRole: this.RoleValue,
      resourceType: this.EmployeeTypeValue
  }

  console.log(this.PrimaryChannelValue+' '+this.PrimaryMarketValue+' '+this.RoleValue+' '+this.EmployeeTypeValue);
  
 const viewAsFilterAppliedEvent = new CustomEvent("viewasfilterapplied", {
    detail: viewAsParams
  });

  // Dispatches the event.
  this.dispatchEvent(viewAsFilterAppliedEvent );
  console.log('view as event applied');

}



select_this_action(event)
{


 
  this.clear_daterange();

  /*
  if(this.dateValidationError)
  {
    this.clear_daterange();
    this.dateValidationMsg = "";
    this.dateValidationError = false;
  }
*/

   let selected_action = event.currentTarget.dataset.id;

//alert("in select selected_action>>"+selected_action+"<<" );

  switch(selected_action)
  {
    case "type":

      this.clear_select();
     
      this.current_type_class = "submenu_button_selected";

      this.toggleDiv("type_filter_div") 
 

      break;

    case "market":
      this.clear_select();
      this.current_market_class= "submenu_button_selected";

      this.toggleDiv("market_filter_div") 

      break;

    case "category":
      this.clear_select();
      this.current_category_class= "submenu_button_selected";

      this.toggleDiv("category_filter_div") 

      break;

    case "status":
      this.clear_select();
      this.current_status_class= "submenu_button_selected";

      this.toggleDiv("status_filter_div") 

     break;    

     case "daterange":
      this.clear_select();
      this.current_daterange_class= "submenu_button_selected";

      this.toggleDiv("daterange_filter_div") 
      break;

    case "mainclearall":
//      this.clear_select();
//      this.current_main_clear_class= "submenu_button_selected";  
      this.clearall();
    break;

    default:
      alter ("indefault select");
      break;

  }


}


 




}
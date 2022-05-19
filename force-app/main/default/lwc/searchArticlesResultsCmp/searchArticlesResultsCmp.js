import { LightningElement, api, wire, track } from "lwc";
import searchArticles from "@salesforce/apex/ArticleSearchDataService.searchArticles";
import markArticleRead from "@salesforce/apex/ArticleSearchDataService.markArticleRead";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {
  refreshApex
} from '@salesforce/apex';


export default class SearchArticlesResultsCmp extends LightningElement {
  searchText;
  startDate="";
  endDate="";
  previousSearchText;
  sortBy;
  filterBy;
  previousFilterBy;
  @track filterPills = [];
  articles = [];
  wiredArticles = [];
  isLoading = false;
  currentPage = 1;
  @track hasMoreArticles = true;
  wiredSearchResults;
  @track error;
  @track isGridView = false;
  @track showBackToTopButtonProperty = false;

  renderedCallback() {
  }

  connectedCallback() {
    if (this.searchText == null) {
      this.searchText = "";
      this.sortBy = "";
      this.filterBy = "";
      this.currentPage = 1;
    }
  }
 

  @wire(searchArticles, {
    searchText: "$searchText",
    sortBy: "$sortBy",
    filterBy: "$filterBy",
    currentPage: "$currentPage",
    startDate: "$startDate",
    endDate: "$endDate"
  })
  wiredSearchArticles(result) {
    this.wiredArticles = result;
    const { data, error } = result;
    
    let previousResultSize;
    if (this.previousSearchText != this.searchText) {
      previousResultSize = 0;
      this.previousSearchText = this.searchText;
      this.articles = [];
    } else {
      previousResultSize = this.articles.length;
    }

    this.articles = [];
    if (data) {
      this.articles = data;
    } else if (error) {
      this.notifyLoading(false);
      this.error = "Unknown error loading articles";
      this.error =  error.body.message;
      //var errors = result.getError();
                /* if (errors) {
                    if (errors[0] && errors[0].message) {
                        // log the error passed in to AuraHandledException
                         */
                          const event = new ShowToastEvent({
                              title: 'Error Searching',
                              message:  this.error ,
                              variant: 'error',
                              mode: 'dismissable'
                          });
                          this.dispatchEvent(event);
                /*       }
                }   */
                               

      if (Array.isArray(error.body)) {
        this.error = error.body.map((e) => e.message).join(", ");
      } else if (typeof error.body.message === "string") {
        this.error = error.body.message;
      }
      console.error(this.error);
    }
    this.hasMoreArticles =
      previousResultSize + 12 > this.articles.length ? false : true;
    this.initialArticlesOnly = false;
    this.notifyLoading(false);
    /* if(!this.articles.length && this.template.querySelector('.blinker')!== null) {
            this.template.querySelector('.blinker').classList.remove("blink-no-results-css");
            setTimeout(function() {this.template.querySelector('.blinker').classList.add("blink-no-results-css");}, 500);
        } */
  }

  @api
  searchArticles(searchObj) {
    let searchText = searchObj.searchText;
    let filterBy = JSON.stringify(searchObj.filterBy);
    let filterLabels = searchObj.filterLabels;
    let startDate = searchObj.startDate;
    let endDate = searchObj.endDate;
    if (
      this.previousSearchText != searchText || this.previousFilterBy != filterBy || this.startDate != startDate || this.endDate != endDate
      ) {
      this.currentPage = 1;
      this.startDate = startDate;
      this.endDate = endDate;
      this.searchText = searchText;
      this.filterBy = filterBy;
      this.populateFilterPills(filterLabels);
      this.notifyLoading(true);
    }
    this.previousFilterBy = filterBy;
  }

  @api
  sortArticles(sortBy) {
    this.notifyLoading(true);
    switch (sortBy) {
      case "recommended":
        this.sortData("viewCount", "desc");
        break;
      case "latest":
        this.sortData("lastPublishedDateString", "desc");
        break;
      case "az":
        this.sortData("title", "asc");
        break;
      case "za":
        this.sortData("title", "desc");
        break;
      default:
        this.sortData("viewCount", "desc");
    }
    this.notifyLoading(false);
  }

  @api
  filterArticles(filterObj) {
    let filterBy = JSON.stringify(filterObj.filterBy);
    this.populateFilterPills(filterObj.filterLabels);
    let searchText = filterObj.searchText;
    let startDate = filterObj.startDate;
    let endDate = filterObj.endDate;
    if (this.previousFilterBy != filterBy || this.searchText != searchText || this.startDate != startDate || this.endDate != endDate) {
      this.articles = [];
      this.currentPage = 1;
      this.filterBy = filterBy;
      this.searchText = searchText;
      this.startDate = startDate;
      this.endDate = endDate;
      this.notifyLoading(true);
    }
    this.previousFilterBy = filterBy;
  }
  populateFilterPills(filterLabels) {
    this.filterPills = [];
    filterLabels.map((filterItem) => {
      let groupName =
        filterItem.group.charAt(0).toUpperCase() + filterItem.group.slice(1);
      this.filterPills.push({
        group: groupName,
        label: groupName + ": " + filterItem.label,
        value: filterItem.value
      });
    });
  }
  handleFilterRemoval(event) {
    event.preventDefault();
    this.fireRemoveFilterEvent(event.currentTarget.dataset.value);
  }

  @api
  layoutArticles(layoutType) {
    this.isGridView = layoutType == "grid" ? true : false;
  }

  @api
  showBackToTopButton() {
    this.showBackToTopButtonProperty = true;
  }
  handleBackToTop() {
    const backtotop = new CustomEvent("backtotop");
    this.dispatchEvent(backtotop);
    this.showBackToTopButtonProperty = false;

  }

  get viewMoreLabel() {
    return this.hasMoreArticles ? "View More" : "No Additional Search Results";
  }
  get hasArticlesLoaded() {
    return this.articles.length > 0;
  }

  handleMore() {
    this.notifyLoading(true);
    this.currentPage++;
  }
  get resultsMsg() {
    let msg = "";
    if (this.articles.length == 0)
      msg = "No Results Found. Please change search term or filters (minimum 3 characters needed for search).";
    else if (!this.initialArticlesOnly) {
      msg = "No Additional Articles";
    }
    return msg;
  }

  // Check the current value of isLoading before dispatching the doneloading or loading custom event
  notifyLoading(isLoading) {
    if (isLoading) {
      const loadingEvent = new CustomEvent("loading");
      this.dispatchEvent(loadingEvent);
    } else {
      const doneLoadingEvent = new CustomEvent("doneloading");
      this.dispatchEvent(doneLoadingEvent);
    }
  }

  fireRemoveFilterEvent(filterValue) {
    const removeFilterEvent = new CustomEvent("removefilter", {
      detail: { filterValue: filterValue }
    });
    this.dispatchEvent(removeFilterEvent);
  }

  async handleArticleRead(event) {
    console.log('in article read handler');
    await markArticleRead({
      kavId: event.detail.kavid
    })
      .then((result) => {
        console.log("markArticleRead", result);
       
          refreshApex(this.wiredArticles);
      })
      .catch((error) => {
        console.log("markArticleRead", error);
        this.error = error;
      });

  }

  sortData(fieldname, direction) {
    // serialize the data before calling sort function
    let parseData = JSON.parse(JSON.stringify(this.articles));
    // Return the value stored in the field
    let keyValue = (a) => {
      return a[fieldname];
    };
    // cheking reverse direction
    let isReverse = direction === "asc" ? 1 : -1;
    // sorting data
    parseData.sort((x, y) => {
      x = keyValue(x) ? keyValue(x) : ""; // handling null values
      y = keyValue(y) ? keyValue(y) : "";
      // sorting values based on direction
      return isReverse * ((x > y) - (y > x));
    });
    // set the sorted data to data table data
    this.articles = parseData;
  }
}
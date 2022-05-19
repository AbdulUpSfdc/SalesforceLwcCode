import { LightningElement, api, track, wire } from "lwc";
import formFactorPropertyName from "@salesforce/client/formFactor";
import isSandbox from "@salesforce/apex/ArticleSearchDataService.isSandbox";
   
export default class LandingPageCmp extends LightningElement {


  viewasopen = false;
  @track currentsearchFormPosition ="";

  isSandboxProperty = false;

doScrollTo = false;

  isLoading = false;
  searchFormOffset;
  screenWidth;
  isfilterVisible = false;
  filterDivHeight = 0;
  FRONTLINE_OFFSET = 69;
  @api flexipageRegionWidth;
  formFactor;
  error;
  stack;
  hasDoneInitialFilter = false;
  @track showResults = false;
  friendlyErrorMessage =
    " Please contact the system administrator and provide error text in the details below. Please refresh the page.";
  viewDetails = false;

  @wire(isSandbox)
  wiredIsSandbox({ error, data }) {

    if ( data===true) 
    {
      //this.isSandboxProperty = data;
      console.log('true successfully returned  in wire call for issandbox');
      this.isSandboxProperty = true;
    }
    else if (data===false)
    {
      console.log('false successfully returned  in wire call for issandbox');
      this.isSandboxProperty = false;
    }
    else if (error) 
    {
      console.log('error in wire call for issandbox');
      this.isSandboxProperty = false;
    }

    //this.isSandboxProperty = false; // testing  prod
    //this.isSandboxProperty = true; // testing  sandbox

  }

  renderedCallback() {
    

    this.formFactor = formFactorPropertyName;
    if (this.template.querySelector(".main-container") !== null) {
      this.screenWidth = this.template.querySelector(
        ".main-container"
      ).offsetWidth;
    }
    if (this.template.querySelector("c-trending-articles-cmp") !== null) {
      this.template.querySelector(
        "c-trending-articles-cmp"
      ).screenWidth = this.screenWidth;
    }

  // tlu testing
  if (this.doScrollTo)
  {
    
    const topDiv = this.template.querySelector('[data-id="searchresults2"]');
    //      topDiv.scrollIntoView({behavior: "smooth", block: "start", inline: "start"});
     topDiv.scrollIntoView();
     //topDiv.scrollIntoView();
    //alert("doing a scrollto=>"+topDiv.scrollTop);

  }
  this.doScrollTo = false;

  }

  errorCallback(error, stack) {
    this.error = error.message;
    this.stack = error.stack;
    console.error("e.name => " + error.name);
    console.error("e.message => " + error.message);
    console.error("e.stack => " + error.stack);
  }
  handleShowErrorDetailsClick() {
    this.viewDetails = !this.viewDetails;
  }

  handleViewAsFilterApplied(event) {



    //this.viewasopen = true;

    console.log('View as event caught by landing page: ' + JSON.stringify(event.detail));
 
    this.template.querySelector("c-frontline-article-component").handleViewAsQuery(event.detail.channel, event.detail.market, event.detail.employeeRole, event.detail.resourceType);
    //this.template.querySelector("c-trending-articles-cmp").handleViewAsQuery(event.detail.channel, event.detail.market, event.detail.employeeRole, event.detail.resourceType);
    this.template.querySelector("c-assigned-articles-component").handleViewAsQuery(event.detail.channel, event.detail.market, event.detail.employeeRole, event.detail.resourceType);

  
  }

  // Handles loading event
  handleLoading() {
    this.isLoading = true;
  }

  // Handles done loading event
  handleDoneLoading() {
    this.isLoading = false;
  }

  searchArticles(event) {
    this.template
      .querySelector("c-search-articles-results-cmp")
      .searchArticles(event.detail);

    this.scrollUpSearchResults();
  }

  sortArticles(event) {
    this.template
      .querySelector("c-search-articles-results-cmp")
      .sortArticles(event.detail.sortBy);
    this.scrollUpSearchResults();
  }

  filterArticles(event) {
    this.template
      .querySelector("c-search-articles-results-cmp")
      .filterArticles(event.detail);
    this.scrollUpSearchResults();
  }



  filterVisible(event) {
    this.isfilterVisible = event.detail.visible;
    this.filterDivHeight = event.detail.height;
  }


  setviewaslayout(event)
  {



    //this.isfilterVisible = event.detail.visible;
 
    this.viewasopen = event.detail.visible;

    console.log("viewasopen=",this.viewasopen)
//    this.viewasopen =  true;
    console.log("setviewaslayout event in landingpagecmp");
//    console.log("viewasopen=",this.viewasopen)



    // viewas only used on desktop
    let offsetTop = 123;
    const SANDBOX_HEADER = 33;
 //      offsetTop = !this.isSandboxProperty  ? offsetTop - SANDBOX_HEADER : offsetTop;
 
 // prod fix - note the isSandboxProperty is set to false but never to true
    if( this.isSandboxProperty )
    {
      offsetTop = 123; // for production
      console.log("set to 123 isSandboxPropertyA="+this.isSandboxProperty );
    }
    else
    {

      offsetTop = 90; // for sandbox
      console.log("set to 90 isSandboxProperty="+this.isSandboxProperty );

    }

    console.log("isSandboxProperty="+this.isSandboxProperty + " offsetTop="+offsetTop );



    this.currentsearchFormPosition =  "position:fixed; top: " + offsetTop +  "px; width: 100%; height: 0px; z-index: 4; left: 0; background-color:red;" ;

    this.template.querySelector("c-frontline-article-component").handleViewAsToggleResults(event.detail.visible);
    // this.template.querySelector("c-trending-articles-cmp").handleViewAsToggleResults(event.detail.visible);
    this.template.querySelector("c-assigned-articles-component").handleViewAsToggleResults(event.detail.visible);
    


  }



  filterFirstLoad(event) {
    this.template
      .querySelector("c-search-articles-results-cmp")
      .filterArticles(event.detail);
  }
  layoutArticles(event) {
    this.template
      .querySelector("c-search-articles-results-cmp")
      .layoutArticles(event.detail.layoutType);
    this.scrollUpSearchResults();
  }
  handleRemoveFilter(event) {
    this.template
      .querySelector("c-search-articles-form-cmp")
      .removeFilter(event.detail.filterValue);
    this.scrollUpSearchResults();
  }
  searchRendered(event) {
    this.template.querySelector("c-search-articles-form-cmp").searchRendered();
  }
  closeResults(event) {
    this.showResults = false;
  }

  scrollUpSearchResults() 
  {

    const RESULTS_OFFSET = this.template.querySelector(".search-results")
      .offsetTop;
    const ACTIVE_FILTERS_PADDING = 5;
    let finalOffset = RESULTS_OFFSET;
    if (this.isfilterVisible) {
      // some calc
      finalOffset -= this.filterDivHeight;
    }
    // calling assigned articles to collapse it's view port

 
    if (this.formFactor == "Large") 
    {

      //alert('scrollUpSearchResults large');

      this.doScrollTo = true;

      const topDiv = this.template.querySelector('[data-id="searchresults2"]');
      console.log("TLU topDiv="+topDiv );

//      topDiv.scrollIntoView({behavior: "smooth", block: "start", inline: "start"});
      topDiv.scrollIntoView();
//      topDiv.scrollTop = 500;
//      let scrollloc = topDiv.scrollTop;

      /*   
      var scrollOptions = {
        left: 0,
        top: 500,
        behavior: "smooth"
      };
      window.scrollTo(scrollOptions);
*/
//      alert('scrollupsearchresults LARGE b4 finalOffset=' + finalOffset);
//      finalOffset += 500;
//      alert('scrollupsearchresults LARGE after finalOffset=' + finalOffset);


      // We might need to use scrollIntoView for better support across browser and device.
      // We will need to add some padding above and below active filters for it to position correctly.
//alert("tada");

//let toploc = this.template.querySelector(".scroll-container").scrollTop;
//     this.template.querySelector(".scroll-container").scrollTop() += 100; 

/*
      this.template.querySelector(".search-results").scrollIntoView({
        behavior: "smooth",
        block: "start"
      }); 
//     this.template.querySelector(".scroll-container").scrollTop() += 700; 

      this.template.querySelector(".search-results").scrollIntoView(true); 

*/

/*
      finalOffset += 500;
      var scrollOptions = {
        left: 0,
        top: finalOffset + ACTIVE_FILTERS_PADDING,
        behavior: "smooth"
      };
      window.scrollTo(scrollOptions);


      const topDiv = this.template.querySelector('[data-id="searchresults"]');
      topDiv.scrollIntoView({behavior: "smooth", block: "start", inline: "nearest"});

*/
      //window.scrollTo(0, finalOffset + ACTIVE_FILTERS_PADDING);

/*
      this.template
        .querySelector("c-assigned-articles-component")
        .collapseArticle();




        topDiv.scrollIntoView({behavior: "smooth", block: "start", inline: "start"});
*/


    } 
    else 
    {

      //alert('scrollUpSearchResults other');

      this.showResults = true;
      this.template
        .querySelector("c-search-articles-results-cmp")
        .showBackToTopButton();
    }
  }

  get searchFormPosition() 
  {

//alert("in get searchFormPosition this.viewasopen="+this.viewasopen);

console.log("searchFormPosition");

    let offsetTop = 123;
    const SANDBOX_HEADER = 33;



    //offsetTop = !this.isSandboxProperty  ? offsetTop - SANDBOX_HEADER : offsetTop;

    
    if(this.isSandboxProperty )
    {
      offsetTop = 123; // for production
      console.log("set to 123 45 isSandboxProperty2="+this.isSandboxProperty );
    }
    else
    {
      offsetTop = 90; // for production
      console.log("set to 90 isSandboxProperty="+this.isSandboxProperty );
    }


    console.log("isSandboxProperty="+this.isSandboxProperty + " offsetTop="+offsetTop );




    this.currentsearchFormPosition ="";


    console.log("viewasopen=",this.viewasopen);


    if( this.viewasopen )
    {
  
      // fix for viewas in prod, make top 8  
      if(this.isSandboxProperty)
      {
        // this will need tweeking in prod
        this.currentsearchFormPosition =  "position:fixed; top:45px; width: 100%; height: 0px; z-index: 4; left: 0;" ;
        // for testing
        //this.currentsearchFormPosition =  "position:fixed; top:8px; width: 100%; height: 0px; z-index: 4; left: 0;" ;

      }
      else
      {
        // this will need tweeking in prod (new 45 should go to 8)
        this.currentsearchFormPosition =  "position:fixed; top:8px; width: 100%; height: 0px; z-index: 4; left: 0;" ;
      }
     
    }
    else
    {
      
      if (this.formFactor == "Large") 
      {
        this.currentsearchFormPosition =  "position:fixed; top: " + offsetTop +  "px; width: 100%; height: 48px; z-index: 4; left: 0;" ;
      } 
      else if (this.formFactor == "Medium" || this.formFactor == "Small") 
      {
        this.currentsearchFormPosition =  "position:top; width: 100%;  top:0; left:0;";
      }

   }


console.log("currentsearchFormPosition=",this.currentsearchFormPosition);

   return this.currentsearchFormPosition;


  }
  get frontlinePosition() {
    if (this.formFactor == "Large") {
      return "position: relative; top: " + this.FRONTLINE_OFFSET + "px;";
    } else if (this.formFactor == "Small" || this.formFactor == "Medium") {
      return "position: relative; ";
    }
  }
  displayit() {
    var hostname = window.location.hostname;
    var pathtoapp = "https://" + hostname + "/lightning/n/tlu_calculator";

    //alert("pathtoapp="+pathtoapp);
    window.location = pathtoapp;
  }
}
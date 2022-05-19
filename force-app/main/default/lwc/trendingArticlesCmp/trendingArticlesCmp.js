import { LightningElement, api, wire, track } from "lwc";
import getTrendingArticles from "@salesforce/apex/KnowledgeLandingPageDispatcher.getTrendingArticles";
import getViewAsTrendingArticles from "@salesforce/apex/KnowledgeLandingPageDispatcher.getViewAsTrendingArticles";
import { NavigationMixin } from "lightning/navigation";
import formFactor from '@salesforce/client/formFactor';
import hasKMViewAsPermission from "@salesforce/customPermission/KM_View_As";


export default class TrendingArticlesCmp extends NavigationMixin(LightningElement) {
  @track articles = [];
  @track articlesAll;
  @track viewAsArticles = [];
  @track viewAsArticlesAll = [];
  @track trendingArticles = [];
  @track trendingArticlesAll = [];
 

  comming_soon = true;

  displayArticles = false;
  article0;
  articles1;
  articles2;
  articles3;
  articles4;
  @track error;
  @track largedevice = true;
  @api screenWidth;
  IS_DESKTOP;
  DESKTOP_OFFSET = 4;
  IS_IPAD;
  IPAD_OFFSET = 3;
  currentIndex = 0;
  offset;
  @api flexipageRegionWidth;
  @track formFactorProperty ='';
  @track viewAsArticlesFound = false;

  renderedCallback() {
  
  }
  connectedCallback() {
    this.formFactorProperty = formFactor;
    if(formFactor == 'Medium'){
       this.largedevice = false;
    }
  }

  @api handleViewAsQuery(channel, market, employeeRole, resourceType) {
    //alert('View as query submitted trending artilces' + channel + '; market: ' + market + '; employeeRole: ' + employeeRole + '; resourcetype: ' +  resourceType);
    console.log('Handle View As called for trending articles');
    this.callGetViewAsTrendingArticles(channel,  market,  employeeRole, resourceType);
  }


  callGetViewAsTrendingArticles(channel,  market,  employeeRole, resourceType) {
     console.log('get Viewas Called trending articles');
     getViewAsTrendingArticles({ 
      channel : channel, 
      market: market, 
      employeeRole: employeeRole,
      resourceType: resourceType,
      requestSource: 'ViewAs'
    })  
      .then((value) => {
        console.log(
        " getViewAsAssignedKnowledgeArticles",
          JSON.stringify(value)
        );
  
        //this.wiredArticles = value;
        // Destructure the provisioned value
        const { data, error } = value;
          console.log('Trending view as data: ' + data);
          console.log('Trending view as value ' + value);
          console.log('Number of trending view as articles:' + value.length);
          if (value.length > 0 ) {
            viewAsArticlesFound = true;
          }
        try {
          if (this.formFactorProperty === "Large") {
            this.IS_DESKTOP = true;
            this.offset = this.DESKTOP_OFFSET;
          } else {
            this.IS_IPAD = true;
            this.offset = this.IPAD_OFFSET;
          }
  
          this.articlesAll = value;
          console.log('Tranding view as articles: ' + this.articlesAll);
          
          this.sliceArticles(this.articlesAll);
        } catch(e) {
          console.log('Error in callget view as trending: ' + JSON.stringify(e));
  
        }
    
      })
      .catch((error) => {
        console.log("Error caught");
      });
  }

 

  @api handleViewAsToggleResults(viewAsVisible) {
    console.log('Trending  view as has been selected: ' + viewAsVisible);
    if (hasKMViewAsPermission==true) {
      if (viewAsVisible == true) {
        this.trendingArticles = this.articles;
        this.trendingArticlesAll = this.allArticles;
        this.articles = this.viewAsArticles;
        this.allArticles = this.viewAsArticlesAll; 
        this.sliceArticles(this.allArticles);

        console.log('Set to view as trending rticles');
      } else {
        this.viewAsArticles = this.articles;
        this.viewAsArticlesAll = this.allArticles;
        this.articles = this.trendingArticles;
        this.allArticles = this.trendingArticlesAll; 
        this.sliceArticles(this.allArticles);
        
          console.log('Set to trending Articles');
      }
    }
  }



  @wire(getTrendingArticles)
  wiredArticles({ error, data }) {
    //const { data, error } = result;
    if (data) {
      try {
        if(Array.isArray(data) && data.length > 0) {
          this.displayArticles = true;
        }
        if (this.formFactorProperty === "Large") {
          this.IS_DESKTOP = true;
          this.offset = this.DESKTOP_OFFSET;
        } else {
          this.IS_IPAD = true;
          this.offset = this.IPAD_OFFSET;
        }

        this.articlesAll = data;
        this.sliceArticles(data);
      } catch(e) {
        console.error(e);

      }
    } else if (error) {
     
      this.error = "Unknown error loading trending articles";
      if (Array.isArray(error.body)) {
        this.error = error.body.map((e) => e.message).join(", ");
      } else if (typeof error.body.message === "string") {
        this.error = error.body.message;
      }
      console.error(this.error);
      this.articles = undefined;
    }
  }

  sliceArticles(data) {
    if (data) {
      if (this.IS_DESKTOP) {
        this.articles = data.slice(0, 4);
      } else {
        this.articles = data.slice(0, 3);
      }
    }
  }

  navigateToArticle(event) {
    event.preventDefault();
    event.stopPropagation();
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: event.target.dataset.id,
        actionName: "view"
      }
    });
  }


  forwardNew() {
    let newSliceStart = this.currentIndex + this.offset;
    if (newSliceStart < 12 && newSliceStart < this.articlesAll.length) {
      this.currentIndex = newSliceStart
    } else {
      this.currentIndex = 0;
    }
    this.articles = this.articlesAll.slice(
      this.currentIndex,
      this.currentIndex + this.offset
    );
  }
  backwardNew() {
     let newSliceStart = this.currentIndex - this.offset; 
     if (newSliceStart < 0) {
       if(this.articlesAll.length <= this.offset) this.currentIndex = 0;
       if(this.articlesAll.length > this.offset && this.articlesAll.length <= this.offset*2) this.currentIndex = this.offset;
       if(this.articlesAll.length > this.offset*2 && this.articlesAll.length <= this.offset*3) this.currentIndex = this.offset*2;
       // iPad
       if (this.articlesAll.length > this.offset*3 && this.articlesAll.length <= this.offset * 4) this.currentIndex = this.offset * 3;
     } else {
       this.currentIndex = newSliceStart;
     }
    this.articles = this.articlesAll.slice(
      this.currentIndex,
      this.currentIndex + this.offset
    );
  }

  
}
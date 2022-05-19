import {
    LightningElement,
    api
} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getKnowledgeArticle from "@salesforce/apex/KnowledgeAgentController.getKnowledgeArticle";
import getPublicLink from "@salesforce/apex/KnowledgeAgentController.getPublicLink";
import getPersistentLink from "@salesforce/apex/KnowledgeAgentController.getPersistentLink";
import getCommunityURL from "@salesforce/apex/KnowledgeAgentController.getCommunityURL";
import getLast_N_DaysViewCount from "@salesforce/apex/KnowledgeAgentController.getArticleViewCountForLast_N_Days";
import getDesktopImageWidth from "@salesforce/apex/KnowledgeAgentController.getDesktopImageWidth";

import getFavoriteslinksharingURL from "@salesforce/apex/KnowledgeAgentController.getFavoriteslinksharingURL";
 

import {
    NavigationMixin
} from 'lightning/navigation';
import formFactorPropertyName from "@salesforce/client/formFactor";
// import community_url from '@salesforce/label/c.Community_URL';

export default class KnowledgeArticleTitle extends NavigationMixin(LightningElement) {
    @api recordId;
    IS_DESKTOP;
    HAS_PREVIEWIMAGE = false;
    thecommunity_url = "";  
    ShareValue=null;
    last_N_Days_ViewCount = '';
    showRelatedLink = false;
    tabName = 'Knowledge_Search';
    showShareModal = false;
    smartURL = '';
    onlinepublishstatus = false;
    archivedpublishstatus = false;
     latestArticleVersion = "";
    previewImagePath = '';
    previewImageDivStyle = '';
    
    testsrc = 'src="https://attone--kmdev--c.documentforce.com/servlet/rtaImage?eid=ka00n0000004yik&feoid=00N6g00000UM7LH&refid=0EM0n0000009pCq"';

    article = {
        isRead: false,
        isUrgent: false,
        isPinnable: false,
        title: 'Loading...',
        cspId: 'Loading...',
        updateddate: 'Loading...',
        validity: 'Loading...',
        totalViewCount: 'Loading...'
    };

    articleispublic=false;
    UrlName="undefined";

    knowledgeArticleId="undefined";

    connectedCallback() {    
        getDesktopImageWidth()
        .then(result => {
    
            this.DesktopImageWidth = result;

            this.previewImageDivStyle = 'width:'+this.DesktopImageWidth+'px;';
    
        })
        .catch(error => {
    
            this.showToast("Desktop Image Width Custom Meta Data not found",error,'error'); 
    
        });

        getCommunityURL()
        .then(result => {
    
            this.thecommunity_url = result;
    
        })
        .catch(error => {
    
            this.showToast("Community_URL Custom Meta Data not found",error,'error'); 
    
        });

          getFavoriteslinksharingURL()
        .then(result => {
    
            this.theFavoriteslinksharingURL = result;
    
        })
        .catch(error => {
    
            this.showToast("FavoriteslinksharingURL Custom Meta Data not found",error,'error'); 
    
        });
        if (formFactorPropertyName == 'Large') {
            this.IS_DESKTOP = true;
        }

        console.log('recordId', this.recordId);
        console.log('this', this);

        getKnowledgeArticle({
                kwId: this.recordId
            })
            .then(result => {
                console.log("KnowledgeForAgent", result);

                if (result.isSuccess) {
                    this.article = result.frontLineKnwList[0];
                    //getSRCAttributeValue(this.article.previewImageFull) 
                    //console.log("previewImagePath=",this.previewImagePath);
                    // start of get preview image src
                    // start of get preview image src
                    // start of get preview image src
                    // start of get preview image src

                    var str =' ';

                    //console.log("before check", this.article);

                    try 
                    {
                        if( this.article.previewImageFull )
                        {

                          str = this.article.previewImageFull;
                          //console.log(str);

                          var locofimg = str.indexOf("<img");

                          //console.log("locofimg=",locofimg);

                          if(locofimg >= 0)
                          {
                             this.HAS_PREVIEWIMAGE = true;
                             console.log("has preview image");
                          }
                          else
                          {
                            console.log("no preview image");
                          }
                           
                        }
                        else
                        {
                            console.log("No previewimage defined");
                        }
                    }
                    catch(err) 
                    {
                        //console.log("error in previewimage type check ");
                        console.log("Error No previewimage defined");
                    }


                    //console.log("after ");


                    str = str.replaceAll("&amp;", "&");
                    str = str.replaceAll("&Amp;", "&");
                    str = str.replaceAll("&AMP;", "&");

                    console.log("str = ",str);

                    var length = str.length;
  
                    var startloc = str.indexOf("src=");
                  
                    var src = str.substr(startloc+4,length);
                  
                  
                    length = src.length
                  
                    // indexOf returns -1 if not found
                    var dqloc1 = src.indexOf('"');
                    var sqloc1 = src.indexOf("'");
                    var dqloc2 = src.indexOf('"');
                    var sqloc2 = src.indexOf("'");
                  
                  
                    if( dqloc1 >= 0 )
                    {
                  
                  
                  
                      if (sqloc1 >= 0 )
                      {
                  
                        src = src.substr(sqloc1+1,length);
                  
                          // found both " and ', use first one found as delimiter (rarley occuring with ing src attribute value)
                          if (dqloc1 > sqloc1 )
                          {
                              // this should not happen
                  
                               src = src.substr(sqloc1,length);
                               sqloc2 = src.indexOf("'");
                               src = src.substr(0,sqloc2);
                          }
                          else
                          {
                  
                               src = src.substr(dqloc1,length);
                               dqloc2 = src.indexOf('"');
                               src = src.substr(0,dqloc2);
                          }
                        }
                       else
                       {
                  
                           src = src.substr(dqloc1+1,length);
                  
                  
                           dqloc2 = src.indexOf('"');
                           src = src.substr(0,dqloc2);
                  
                       }
                  
                    }
                    else if (sqloc1 >= 0 )
                    {
                  
                  
                  
                  //  	if (dqloc > 0 )
                  //  	{
                  //  		// this code can never be reached due to the first if check
                  //	}
                  //	else
                  //	{
                  
                           src = src.substr(sqloc1+1,length);
                  
                  
                           sqloc2 = src.indexOf("'");
                           src = src.substr(0,sqloc2);
                  
                  
                  //	}
                    }
                  
                   // return (src);

                   console.log("after str = ",str);

                    this.previewImagePath = src;
                    console.log("output path",src);

                
                    // end of get preview image src
                    
                    console.log("after");

										 if (this.article.publishstatus == 'Online')
												 this.onlinepublishstatus = true;

										else if (this.article.publishstatus == 'Archived')
												this.archivedpublishstatus = true;
										
                    console.log("publishstatus=",this.article.publishstatus);
  
                    console.log("onlinepublishstatus=",this.onlinepublishstatus);
                    console.log("archivedpublishstatus=",this.archivedpublishstatus);
                    

                    this.articleispublic = this.article.isPublicalyAvailable;
                    this.totalViewCount = this.article.totalViewCount;
                    this.UrlName = this.article.UrlName;
                    this.knowledgeArticleId=this.article.knowledgeArticleId;
					
                    this.smartURL = this.article.shareURL;
                    if (this.article.externalLink) {
                        this.showRelatedLink = true;
                    }
                    if (this.article.extrnalURL) {
                        this.showRelatedLink = true;
                    }
                } else {
                    this.error = result.errorMessage;
                }
            })
            .catch(error => {
                this.error = error;
            });
            
        getLast_N_DaysViewCount({ articleId: this.recordId })
            .then((result) => {
                if(result > 0){
                    this.last_N_Days_ViewCount = result;
                }
                else {
                    this.last_N_Days_ViewCount = 'Unavailable';
                }
                this.error = undefined;
            })
            .catch((error) => {
                this.error = error;
                this.last_N_Days_ViewCount = undefined;
            });
 
    }

    /*
        handleback(e) {
            this[NavigationMixin.Navigate]({
                type: 'standard__navItemPage',
                attributes: {
                    apiName: this.tabName,
                },
            });
        }
        */
        getlatestArticleVersion(){
           
            let newurl = location.protocol + "//"+ location.hostname+'/lightning/articles/Knowledge/' + this.UrlName + '?name=' + this.UrlName;
			console.log('new ul'+newurl);
       this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: newurl
            }
        });
       			
			}		
       get ShareValueoptions() 
       {
       
           if(this.articleispublic)
           {
             return [
                 { label: 'Public', value: 'public' },
                 { label: 'Internal', value: 'internal' },
             ];
           }
           else
           {
             return [
                 { label: 'Internal', value: 'internal' },
             ];
           }
       
       }
              
       handleChangeShareValue(event) {

 
        switch( event.detail.value )
        {
            case 'public':

                //alert(" do public code here");
 
                let publicURL = this.thecommunity_url + '/knowledgebase/s/article/' + this.UrlName + '?name=' + this.UrlName;

                var copyText = document.createElement('input');
                copyText.setAttribute("value",publicURL);
                document.body.appendChild(copyText);
                copyText.select();
                copyText.setSelectionRange(0, 99999)
                document.execCommand("copy"); 

                var message =" \r\nThis URL has been copied to the clipboard: \r\n \r\n" + publicURL;

                //alert(message);
                this.showToast("URL Copied",message,'success'); 



            break;
            
            case 'internal':
                //alert(" do public code here");

                //let internalURL = this.thecommunity_url + '/knowledgebase/s/article/' + '?name=' + this.UrlName;

                //knowledgeArticleId
                // https://attone--ctpoc.lightning.force.com/lightning/r/Knowledge__kav/ka03K0000004okuQAA/view
                //let internalURL = this.thecommunity_url + '/lightning/r/Knowledge__kav/' + this.knowledgeArticleId +'/view';
                let internalURL =  location.protocol + "//"+ location.hostname+"/articles/Knowledge/"+this.UrlName;

                var copyText = document.createElement('input');
                copyText.setAttribute("value",internalURL);
                document.body.appendChild(copyText);
                copyText.select();
                copyText.setSelectionRange(0, 99999)
                document.execCommand("copy"); 

                var message =" \r\nThis URL has been copied to the clipboard: \r\n \r\n" + internalURL;

                //alert(message);
                this.showToast("URL Copied",message,'success'); 

            break;
        }

        // resets the selection value to null
        this.template.querySelectorAll('lightning-combobox').forEach(each => {
            each.value = null;
        });


      }

    shareArticle(e) {
        this.showShareModal = true;
    }

    hideModal(e) {
        this.showShareModal = false;
    }

    URL2Clipboard() {
        var copyText = document.createElement('input');
        copyText.setAttribute("value", this.smartURL);
        document.body.appendChild(copyText);
        copyText.select();
        copyText.setSelectionRange(0, 99999)
        document.execCommand("copy");
  //      alert(" \r\nThis URL has been copied to the clipboard: \r\n  \r\n" + this.smartURL );
        var message = " \r\nThis URL has been copied to the clipboard: \r\n  \r\n" + this.smartURL;
        this.showToast("URL Copied",message,'success'); 

        // alert("This URL has been copied to the clipboard: \r\n" + this.smartURL);

    }


  

    get isPublicArticle()
    {
        console.log('tlu --recordId--'+this.recordId);

	    let ispublic = false;
	
        getPublicLink({ ArticleId: this.recordId })
        .then(result => {
		
 

            var message = "";
            var n = result.search("http");                
            if( n < 0 )
            {
		        this.ispublic = false;    
	
            }
            else
            {
		        this.ispublic = true;

            }

        })
        .catch(error => {
            this.ispublic = false;      

        });
       
       return  this.ispublic;
       
   } 



    getTheUrl()
    {
        console.log('--recordId--'+this.recordId);

        getPublicLink({ ArticleId: this.recordId })
        .then(result => {

            var message = "";
            var n = result.search("http");                
            if( n < 0 )
            {

                message ="\r\n" + result;
            }
            else
            {

                var copyText = document.createElement('input');
                copyText.setAttribute("value",result);
                document.body.appendChild(copyText);
                copyText.select();
                copyText.setSelectionRange(0, 99999)
                document.execCommand("copy"); 
                
                message =" \r\n 2 This URL has been copied to the clipboard: \r\n \r\n" + result;
            }



            //alert(message);
            this.showToast("URL Copied",message,'success'); 
        })
        .catch(error => {
            this.resultsum = undefined;
            //alert("Error occured: " + error);

            this.showToast("Could not capture URL",error,'error'); 

            //this.error = error;
        });
        
   } 
  
   getPersistentUrl(){
        getPersistentLink({
            articleId: this.recordId
        })
        .then(result => {
            let persistentURL = result; 
            let copyText = document.createElement('input');

            copyText.setAttribute("value", persistentURL);
            document.body.appendChild(copyText);
            copyText.select();
            copyText.setSelectionRange(0, 99999)
            document.execCommand("copy");
            //alert(" \r\n1 This URL has been copied to the clipboard: \r\n  \r\n" + persistentURL);
            let message = " \r\n 1 This URL has been copied to the clipboard: \r\n  \r\n" + persistentURL;
            this.showToast("URL Copied",message,'success'); 

        })
        .catch(error => {
        this.error = error;
        });
    }
  


   showToast(title,msg,type) {
    const event = new ShowToastEvent({
        title: title,
        message: msg,
        variant: type,
        mode: 'dismissable'
    });
    this.dispatchEvent(event);
}



getSRCAttributeValue(str) {

    // standard "
    //var str='<img alt="01.jpg" src="https://attone--kmdev--c.documentforce.com/servlet/rtaImage?eid=ka00n0000004yik&amp;feoid=00N6g00000UM7LH&amp;refid=0EM0n0000009pCq"></img>';
    // " with an embedded '
    //var str='<img alt="01.jpg" src="'+"'"+'https://attone--kmdev--c.documentforce.com/servlet/rtaImage?eid=ka00n0000004yik&amp;feoid=00N6g00000UM7LH&amp;refid=0EM0n0000009pCq"></img>';
    // standard '
    //var str="<img alt='01.jpg' src='https://attone--kmdev--c.documentforce.com/servlet/rtaImage?eid=ka00n0000004yik&amp;feoid=00N6g00000UM7LH&amp;refid=0EM0n0000009pCq'></img>";
    // 'with an embedded "I thou
    //var str="<img alt='01.jpg' src='"+'"'+"https://attone--kmdev--c.documentforce.com/servlet/rtaImage?eid=ka00n0000004yik&amp;feoid=00N6g00000UM7LH&amp;refid=0EM0n0000009pCq'></img>";
  
    var length = str.length;
  
    var startloc = str.indexOf("src=");
  
    var src = str.substr(startloc+4,length);
  
  
    length = src.length
  
    // indexOf returns -1 if not found
    var dqloc1 = src.indexOf('"');
    var sqloc1 = src.indexOf("'");
    var dqloc2 = src.indexOf('"');
    var sqloc2 = src.indexOf("'");
  
  
    if( dqloc1 >= 0 )
    {
  
  
  
      if (sqloc1 >= 0 )
      {
  
        src = src.substr(sqloc1+1,length);
  
          // found both " and ', use first one found as delimiter (rarley occuring with ing src attribute value)
          if (dqloc1 > sqloc1 )
          {
              // this should not happen
  
               src = src.substr(sqloc1,length);
               sqloc2 = src.indexOf("'");
               src = src.substr(0,sqloc2);
          }
          else
          {
  
               src = src.substr(dqloc1,length);
               dqloc2 = src.indexOf('"');
               src = src.substr(0,dqloc2);
          }
        }
       else
       {
  
           src = src.substr(dqloc1+1,length);
  
  
           dqloc2 = src.indexOf('"');
           src = src.substr(0,dqloc2);
  
       }
  
    }
    else if (sqloc1 >= 0 )
    {
  
  
  
  //  	if (dqloc > 0 )
  //  	{
  //  		// this code can never be reached due to the first if check
  //	}
  //	else
  //	{
  
           src = src.substr(sqloc1+1,length);
  
  
           sqloc2 = src.indexOf("'");
           src = src.substr(0,sqloc2);
  
  
  //	}
    }
  
   // return (src);

    this.previewImagePath = src;

}




}
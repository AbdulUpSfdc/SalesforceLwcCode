import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getFeedbackThread from "@salesforce/apex/PublicFeedbackController.getFeedbackThread";
import ChkIfIModerator from "@salesforce/apex/PublicFeedbackController.ChkIfIModerator";
import checkFeedbackVisible from "@salesforce/apex/PublicFeedbackController.isFeedbackVisible";

import FeedbackThread_OBJECT from "@salesforce/schema/BWPublicFeedbackThread__c";
import FEEDBACKTHREAD_ID from "@salesforce/schema/BWPublicFeedbackThread__c.Id";
import IS_DELETED from "@salesforce/schema/BWPublicFeedbackThread__c.Is_Deleted__c";
import DELETED_DATE from "@salesforce/schema/BWPublicFeedbackThread__c.Deleted_Date__c";

import FeedbackThreadComment_OBJECT from "@salesforce/schema/BWFeedbackThreadComment__c";
import FEEDBACKTHREADCOMMENT_ID from "@salesforce/schema/BWFeedbackThreadComment__c.Id";
import IS_DELETED_COMMENT from "@salesforce/schema/BWFeedbackThreadComment__c.Is_Deleted__c";
import DELETED_DATE_COMMENT from "@salesforce/schema/BWFeedbackThreadComment__c.Deleted_Date__c";

import {getRecord} from 'lightning/uiRecordApi';
import { createRecord } from 'lightning/uiRecordApi';
import { updateRecord } from "lightning/uiRecordApi";

import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import {refreshApex} from '@salesforce/apex';

import { ShowToastEvent } from "lightning/platformShowToastEvent";

import userid from '@salesforce/user/Id';

export default class PublicFeedbackComponent extends LightningElement 
{

    @api usertype;
 
    @api recordId;
    havesearchkey = false;
    searchkey = '';
    theusertype = '';
    isAuthor = false;
    isAgent = false;
    isModerator = false;


    comment_div_css = "slds-show";
 
    showMatching = true;
    number_of_threads = 0;
    publicfeedback_title = 'Public Feedback'; 

    newfeedbackbutton_class = 'slds-float_right slds-show';

    numberthreads='';

    the_articleID;
    threads = [];
    workingthreads =[];
    comments = [];
    
    error;
    the_user_name;

 
    // default
    threaddivstyle="display:none";
    showthreaddiv = false;
    isFeedbackVisible =false;

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [NAME_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
           this.error = error ; 
        } else if (data) {
            console.log('isFeedbackVisible @78 data is '+data);
            this.the_user_name = data.fields.Name.value;
        }
    }



showMatchingComments(event) 
{
   this.showMatching = true;
   this.performSearch(event);
}

showAllComments(event) 
{
    this.showMatching = false;     
    this.performSearch(event);
}


deleteThread(event) 
{
    
    let threadId = event.target.dataset.id;;
//    alert ("delete threadid >>>"+threadId+"<<<<");
    const fields = {};

// Returns date in the format "June 08 2017, 01:45:49 PM"

//const now = new Date();
//console.log("date time is >>>>",now);
var d = new Date();
var DateTimeTFormat = d.toISOString();

    fields[FEEDBACKTHREAD_ID.fieldApiName] = threadId;
    fields[IS_DELETED.fieldApiName] = true;
    fields[DELETED_DATE.fieldApiName] = DateTimeTFormat;

    const recordInput = {
        fields: fields
      };

      
        // LDS method to create record.
        updateRecord(recordInput).then(response => {

//            alert('delete update successful  ');

setTimeout(() => {  console.log("waiting "); 
            this.performSearch(event);

        }, 1000); 



        }).catch(error => {
            //alert('Error: ' +JSON.stringify(error));

            this.showToast("Error:"," Could not delete thread", "error");
            console.log("Error",JSON.stringify(error));
    
            // toast message?
        });

/*
    //need a refresh here
    //console.log("leaving delete");
    // may need to get search term back in place
    //alert("searchkey="+this.searchkey);

    if(this.searchkey =='')
    {
        location.reload(); // quick dirty way to refresh data
    }
    else
    {
    // refreshApex(this.performSearch2());
    //    this.performSearch2();
          this.performSearch(event);
    }
*/

}


undeleteThread(event) 
{
 
    let buttonfuction = event.target.dataset.type;;
    //alert (" buttonfuction >>>"+buttonfuction+"<<<<");
 
    let threadId = event.target.dataset.id;;
 //   alert ("undelete threadid >>>"+threadId+"<<<<");
 
    const fields = {};

// Returns date in the format "June 08 2017, 01:45:49 PM"

//const now = new Date();
//console.log("date time is >>>>",now);
var d = new Date();
var DateTimeTFormat = d.toISOString();

    fields[FEEDBACKTHREAD_ID.fieldApiName] = threadId;
    fields[IS_DELETED.fieldApiName] = false;
    fields[DELETED_DATE.fieldApiName] = DateTimeTFormat;

    const recordInput = {
        fields: fields
      };

     //console.log("fields = ",fields);
      
        // LDS method to create record.
        updateRecord(recordInput).then(response => {

        // alert('undelete update successful  ');
        setTimeout(() => {  console.log("waiting "); 
        //need a refresh here
        //console.log("leaving delete");
        // may need to get search term back in place
        //alert("searchkey="+this.searchkey);
/*
        if(this.searchkey =='')
        {
            location.reload(); // quick dirty way to refresh data
        }
        else
        {
        // refreshApex(this.performSearch2());
        //    this.performSearch2();
            this.performSearch(event);
        }
*/
        this.performSearch(event);




    }, 1000); 

        }).catch(error => {
            //alert('Error: ' +JSON.stringify(error));
            this.showToast("Error:"," Could not un-delete thread record", "error");
            console.log("Error",JSON.stringify(error));
    
            // toast message?
        });


//need a refresh here
 //console.log("leaving delete");
// may need to get search term back in place
//    refreshApex(this.performSearch2());

    //this.performSearch2();

    //need a refresh here
    //console.log("leaving delete");
    // may need to get search term back in place
    //alert("searchkey="+this.searchkey);
/*
    if(this.searchkey =='')
    {
        location.reload(); // quick dirty way to refresh data
    }
    else
    {
//    refreshApex(this.performSearch2());
    //    this.performSearch2();
    this.performSearch(event);

    }
*/

}


showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
      mode: "dismissable"
    });
    this.dispatchEvent(event);
  }

deleteComment(event) 
{

    let deletecommentId = event.target.dataset.id;
//    alert (deletecommentId);

    const fields = {};

    var d = new Date();
    var DateTimeTFormat = d.toISOString();
    
    fields[FEEDBACKTHREADCOMMENT_ID.fieldApiName] = deletecommentId;
    fields[IS_DELETED_COMMENT.fieldApiName] = true;
    fields[DELETED_DATE_COMMENT.fieldApiName] = DateTimeTFormat;
   
    const recordInput = {
        fields: fields
      };
      
    // LDS method to create record.
    updateRecord(recordInput).then(response => {

    // need to wait for update to occur
    setTimeout(() => {  console.log("waiting "); 
            this.performSearch(event);
    }, 1000); 

    }).catch(error => {
        //alert('Error: ' +JSON.stringify(error));
        this.showToast("Error:"," Could not delete comment", "error");
        console.log("Error",JSON.stringify(error));

        // toast message?
    });

}


undeleteComment(event) 
{
 
    let deletecommentId = event.target.dataset.id;;
//    alert ("undelete commentId >>>"+deletecommentId+"<<<<");

	const fields = {};

	// Returns date in the format "June 08 2017, 01:45:49 PM"

	//const now = new Date();
	//console.log("date time is >>>>",now);
	var d = new Date();
	var DateTimeTFormat = d.toISOString();

	fields[FEEDBACKTHREADCOMMENT_ID.fieldApiName] = deletecommentId;
	fields[IS_DELETED_COMMENT.fieldApiName] = false;
	fields[DELETED_DATE_COMMENT.fieldApiName] = DateTimeTFormat;
	
	const recordInput = {
		fields: fields
	};

	//console.log("fields = ",fields);
      
	// LDS method to create record.
	updateRecord(recordInput).then(response => {

	// alert('undelete update successful  ');
	setTimeout(() => {  console.log("waiting "); 
		this.performSearch(event);

	    }, 1000); 

	}).catch(error => {
	    //alert('Error: ' +JSON.stringify(error));
        this.showToast("Error:"," Could not un-delete comment", "error");
        console.log("Error",JSON.stringify(error));

	    // toast message?
	});



}




togglereateNewThread(event) 
{


//alert("toggle new thread");

    if(this.showthreaddiv)
    {
        this.threaddivstyle="display:none";
        this.showthreaddiv = false;


        this.newfeedbackbutton_class = 'slds-float_right slds-show';



    }
    else
    {
        //style="border-style:solid;border-radius:20px; padding:10px;border-color: silver;margin-bottom: 20px;margin-top: 20px;"
        this.threaddivstyle="display:block;border-style:solid;border-radius:20px; padding:10px;border-color: silver;margin: 10px;";

        this.newfeedbackbutton_class = 'slds-float_right slds-hide';


        this.showthreaddiv = true;
    }






}


createNewThread(event) {

    
//alert("make a new thread");

//    this.closeModal();
    
    let articleID = this.recordId;

    var base_query_selector = "lightning-input";
    var inp=this.template.querySelectorAll(base_query_selector);

    let user_comment = 'default';

    //alert("make a new thread b4 loop");
    inp.forEach(function(element)
    {
        //console.log("TLU",element.name);
        if(element.name==articleID)
        {
            user_comment=element.value;
            element.value=''; // clears out the provided input
            return;
        }

    },this);

    //alert("make a new thread 2 after loop");

    if( user_comment.length < 1)
    {
        //alert("Please provide a feedback");
        this.showToast("Error: ", "Please provide a feedback","error");
        


    }

    else
    { 

        //alert("make a new thread 3");

        //alert("hmmmake new thread here articleID="+articleID +" comment="+user_comment + ' '+this.the_user_name);

        // make a thread
        // make a comment??

    //    var fields = {'DisplayName__c' : this.the_user_name, 'Feedback__c' :user_comment , 'Knowledge__c' : articleID};
        var fields = {'Feedback__c' :user_comment , 'Knowledge__c' : articleID};
        var objRecordInput = {'apiName' : 'BWPublicFeedbackThread__c', fields};

        // LDS method to create record.
        createRecord(objRecordInput).then(response => {

            this.searchkey=''; // ensure search key empty so new thread appears
            this.havesearchkey = false;

//            location.reload(); // quick dirty way to refresh data
            setTimeout(() => {  console.log("waiting "); 
                this.performSearch(event);
            }, 1000); 


        }).catch(error => {
            //alert('Error: ' +JSON.stringify(error));
            this.showToast("Error:"," Could not create new thread", "error");
            console.log("Error",JSON.stringify(error));
                // toast message?
        });

    }




}


addComment(event) 
{

//    alert("make a comment");


    //console.log('id => ' + event.target.dataset.id);
    let threadId = event.target.dataset.id;
//    console.log('id => ' + threadId);

    var base_query_selector = "lightning-input";
    var inp=this.template.querySelectorAll(base_query_selector);

    let user_comment = '';

    inp.forEach(function(element)
    {
        //console.log("tlu2",element.name);
        if(element.name==threadId)
        {
            user_comment=element.value;
            element.value=''; // clears out the provided input
            return;
        }

    },this);

//   alert("hmmmake new comment here threadId="+threadId +" coment="+user_comment + ' '+this.the_user_name);

/*
        object BWFeedbackThreadComment__c
            DisplayName__c
            FeedbackComment__c
            KMPublicFeedbackThread__c the theadid
*/  


    if( user_comment.length < 1)
    {
        //alert("Please provide a comment");
        this.showToast("Error:", " Please provide a comment", "error");
    }

    else
    { 

        var fields = {'DisplayName__c' : this.the_user_name, 'FeedbackComment__c' :user_comment , 'KMPublicFeedbackThread__c' : threadId};
        var objRecordInput = {'apiName' : 'BWFeedbackThreadComment__c', fields};

        // LDS method to create record.
        createRecord(objRecordInput).then(response => 
        {
//            console.log("success in creating thread record ");
//            location.reload(); // quick dirty way to refresh data
            setTimeout(() => {  console.log("waiting "); 
            this.performSearch(event);
            }, 1000); 

// did not work for comments         refreshApex(this.performSearch2());

            //this.connectedCallback();

        }).catch(error => {

             
            //alert('Error: ' +JSON.stringify(error));
            this.showToast("Error:"," Could not add comment", "error");
            console.log("Error",JSON.stringify(error));
                // toast message?
        });
    }
}

 
performSearch2() {

    if( this.searchkey.length)
    {
        this.havesearchkey = true;
    }
    else
    {
        this.havesearchkey = false;
    }            

    getFeedbackThread({
        searchKey: this.searchkey,
        articleID: this.recordId
    })
    .then(result => 
    {
        //console.log("getPublicFeedbackThreads what was obtained in ps2",this.searchkey,"   ", result);
       // console.log("getPublicFeedbackThreads what was obtained", result.feedbackArticleList);

       // this.threads = result.feedbackThreads;
      if (result){

//        setTimeout(function(){ }, 10000);


        //console.log("the result = ",result);
//        console.log('feedbackComment=',Object.keys(result[0].feedbackComments[0].feedbackComment));
//        console.log(Object.keys(result[0].feedbackComments));
//        console.log(Object.keys(result[0].feedbackComments[0]));

       // console.log("getPublicFeedbackThreads SUCCESS SUCCESS  SUCCESS");
            this.threads = result; /// these are the threads that get displayed.....

            this.number_of_threads = result.length;
            this.publicfeedback_title = 'Public Feedback (' + this.number_of_threads + ')';

        // do substitution here not on callback
        this.workingthreads = result;

        this.numberthreads = result.length;
        //console.log("number of threads = ",this.numberthreads);
        //console.log("start of thread feed back .................... ");

        let thread_feedback;
        let reg1; 
        let markedup_thread_feedback;
        
        let comment_feedback;
        let reg2; 
        let markedup_comment_feedback;
        
        for (let i = 0; i < this.numberthreads; i++) 
        {
            //console.log("start of loop");
            // process each thread
            thread_feedback = result[i].feedbackThreads.Feedback__c;
            reg1 = new RegExp(this.searchkey, 'gi');
            markedup_thread_feedback = thread_feedback.replace(reg1, function(str) {return '<mark>'+str+'</mark>'});
            result[i].feedbackThreads.Feedback__c = markedup_thread_feedback;


            // process comments if present
            if(result[i].feedbackComments === undefined)
            {

            }
            else
            {
                let number_comments = result[i].feedbackComments.length;        
                if( number_comments > 0)
                {
              //      console.log("start of this threads comments -------------------------number_comments=",number_comments);
                    for (let j = 0; j < number_comments; j++) 
                    {
                //        console.log(result[i].feedbackComments[j].feedbackComment.FeedbackComment__c);
                        comment_feedback = result[i].feedbackComments[j].feedbackComment.FeedbackComment__c;
                        reg2 = new RegExp(this.searchkey, 'gi');
                        markedup_comment_feedback = comment_feedback.replace(reg2, function(str) {return '<mark>'+str+'</mark>'});
                        result[i].feedbackComments[j].feedbackComment.FeedbackComment__c = markedup_comment_feedback;                       
                    }
                  //  console.log("end of this threads comments -------------------------");

                }
            }
    

        }

          //console.log("end of thread feed back .................... ");


        //console.log("getPublicFeedbackThreads SUCCESS SUCCESS  SUCCESS",this.threads);


        } 
        else 
        {
           // this.error = result.errorMessage;
        console.log("getPublicFeedbackThreads ERROR ",result.errorMessage);
        }
 

    })
     .catch(error => 
     {
        this.error = error;
        //console.log("getPublicFeedbackThreads ERROR 1",error);

    });


}
 

performSearch(event) {

let tmp = event.target.value;
//alert("eventvalue="+tmp);

    var base_query_selector = "lightning-input";
    var inp=this.template.querySelectorAll(base_query_selector);

    let search_term = 'undefined';

    inp.forEach(function(element)
    {
        //console.log("tlu3",element.name);
        if(element.name == 'search')
        {
            search_term=element.value;
            //element.value=''; // clears out the provided input
        }

    },this);

//    alert("perform Search for this term: "+ search_term);
/*
    if(search_term =='')
    {

        location.reload(); // quick dirty way to refresh data
       // alert("Search field can not be empty.. ");

    }
    else
    {

//        alert("before connected callback invocation");
        this.searchkey = search_term;

        //console.log("searchterm=",this.searchkey);

        refreshApex(this.performSearch2());


    }
*/

//        alert("before connected callback invocation");
this.searchkey = search_term.trim();

if( this.searchkey.length)
{
    this.havesearchkey = true;
}
else
{
    this.havesearchkey = false;
}            

//console.log("searchterm=",this.searchkey);

refreshApex(this.performSearch2());



}


connectedCallback() 
{
   

if( this.usertype == 'Author' )
{
    this.isAuthor = true;
    this.isAgent = false;
    this.comment_div_css = "slds-show";

//    this.isModerator = true;


}
else
{
    this.isAuthor = false;
    this.isAgent = true;
    this.comment_div_css = "slds-hide";


//    this.isModerator = false;

}


// check to see if is moderator
 
ChkIfIModerator({

    userid:userid

})
.then(result => 
{

    console.log("ChkIfIModerator",result);
    this.isModerator = result;

    if( this.isModerator)
    {
        this.isAuthor = true; // moderators will always be an author
        this.comment_div_css = "slds-show";
    }


})
.catch(error => 
{
    this.isModerator  = false;
    this.error = error;
    //console.log("ChkIfIModerator ERROR 1",error);

});

checkFeedbackVisible({
})
.then(result => 
{
    console.log("checkFeedbackVisible",result);
    this.isFeedbackVisible = result;
})
.catch(error => 
{
    this.isFeedbackVisible  = false;
    this.error = error;
    console.log("Public Feedback ERROR 1",error);

});


//console.log('usertype = ',this.usertype);
//console.log(this.theusertype);


    // needed to identify search filed
   this.the_articleID = this.recordId;
   
   // var searchkey='';
  //  console.log("articleID=",this.recordId);
  //  console.log("searchkey=",this.searchkey);


    if( this.searchkey.length)
    {
        this.havesearchkey = true;
    }
    else
    {
        this.havesearchkey = false;
    }            

    getFeedbackThread({
        searchKey: this.searchkey,
        articleID: this.recordId
    })
    .then(result => 
    {


       console.log("initial results = ",result);

      if (result){

            this.threads = result;
            this.number_of_threads = result.length;
            this.publicfeedback_title = 'Public Feedback (' + this.number_of_threads + ')';
                   
        } 
        else 
        {
        console.log("getPublicFeedbackThreads ERROR ",result.errorMessage);
        }
 

    })
     .catch(error => 
     {
        this.error = error;
        console.log("getPublicFeedbackThreads ERROR 3 ",error);

    });


}


showall(){


    //location.reload(); // quick dirty way to refresh data

    this.searchkey = '';
    if( this.searchkey.length)
    {
        this.havesearchkey = true;
    }    
    else
    {
        this.havesearchkey = false;
    }            

    //console.log("searchterm=",this.searchkey);
    
    refreshApex(this.performSearch2());

   
}

 

expandthis(event)
{
    
    let thisid = event.target.dataset.openid;
    //console.log("event ",thisid,event);

    let dot_querySelector = '[data-divid="'+thisid+'"]';
   
    // expand the thread  div
    this.template.querySelector(dot_querySelector).classList.remove("slds-hide");
    this.template.querySelector(dot_querySelector).classList.add("slds-show");

   // hide the open button 
   dot_querySelector = '[data-openid="'+thisid+'"]'; 
   this.template.querySelector(dot_querySelector).classList.remove("slds-show");
   this.template.querySelector(dot_querySelector).classList.add("slds-hide");

   // show the close button
   dot_querySelector = '[data-closeid="'+thisid+'"]';
   this.template.querySelector(dot_querySelector).classList.remove("slds-hide");
   this.template.querySelector(dot_querySelector).classList.add("slds-show");


}

closethis(event)
{
   // alert('close this '+event.target.dataset.closeid);
    let thisid = event.target.dataset.closeid;
    //console.log("event ",thisid,event);

    let dot_querySelector = '[data-divid="'+thisid+'"]';

    // collapsed  the thread  div
    this.template.querySelector(dot_querySelector).classList.remove("slds-show");
    this.template.querySelector(dot_querySelector).classList.add("slds-hide");


   // show the open button 
   dot_querySelector = '[data-openid="'+thisid+'"]'; 
   this.template.querySelector(dot_querySelector).classList.remove("slds-hide");
   this.template.querySelector(dot_querySelector).classList.add("slds-show");

   // hide the close button
   dot_querySelector = '[data-closeid="'+thisid+'"]';
   this.template.querySelector(dot_querySelector).classList.remove("slds-show");
   this.template.querySelector(dot_querySelector).classList.add("slds-hide");




}



performSearchnew(event) {
  

    let buttonfuction = event.target.dataset.type;;
    //alert (" buttonfuction >>>"+buttonfuction+"<<<<");
 
    let threadId = event.target.dataset.id;;
    //alert ("undelete threadid >>>"+threadId+"<<<<");
 
    const fields = {};

// Returns date in the format "June 08 2017, 01:45:49 PM"

//const now = new Date();
//console.log("date time is >>>>",now);
var d = new Date();
var DateTimeTFormat = d.toISOString();

    fields[FEEDBACKTHREAD_ID.fieldApiName] = threadId;
    fields[IS_DELETED.fieldApiName] = false;
    fields[DELETED_DATE.fieldApiName] = DateTimeTFormat;

    const recordInput = {
        fields: fields
      };

     //console.log("fields = ",fields);
      
        // LDS method to create record.
        updateRecord(recordInput).then(response => {

        // alert('undelete update successful  ');


        }).catch(error => {
            //alert('Error: ' +JSON.stringify(error));

            this.showToast("Error:"," Could perform search", "error");
            console.log("Error",JSON.stringify(error));
    
            // toast message?
        });


        setTimeout(() => {  console.log("waiting "); 
    
     
        //console.log( "after waiting");

//need a refresh here
 //console.log("leaving delete");
// may need to get search term back in place
//    refreshApex(this.performSearch2());

    //this.performSearch2();

    //need a refresh here
    //console.log("leaving delete");
    // may need to get search term back in place
    //alert("searchkey="+this.searchkey);


    if( this.searchkey.length)
    {
        this.havesearchkey = true;
    }
    else
    {
        this.havesearchkey = false;
    }            


    if(this.searchkey =='')
    {
        location.reload(); // quick dirty way to refresh data
    }
    else
    {
//    refreshApex(this.performSearch2());
    //    this.performSearch2();
//    this.performSearch(event);

    }


    let tmp = event.target.value;
    //alert("eventvalue="+tmp);
    
        var base_query_selector = "lightning-input";
        var inp=this.template.querySelectorAll(base_query_selector);
    
        let search_term = 'undefined';
    
        inp.forEach(function(element)
        {
            //console.log("tlu3",element.name);
            if(element.name == 'search')
            {
                search_term=element.value;
                //element.value=''; // clears out the provided input
            }
    
        },this);
    
    //    alert("perform Search for this term: "+ search_term);
    
        if(search_term =='')
        {
            //alert("Search field can not be empty.. ");
            this.showToast("Error:", " Search field can not be empty", "error");
        }
        else
        {
    
    //        alert("before connected callback invocation");
            this.searchkey = search_term;

            if( this.searchkey.length)
            {
                this.havesearchkey = true;
            }
            else
            {
               this.havesearchkey = false;
            }            
    
 //           console.log("searchterm=",this.searchkey);
    
            refreshApex(this.performSearch2());
    
    
        }
    
    }, 1000);        
    
    
    }



}
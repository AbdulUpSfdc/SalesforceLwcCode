import { LightningElement, track } from 'lwc';
import getListViewData from '@salesforce/apex/cLeadHomePageController.getListViewData';
import { NavigationMixin } from 'lightning/navigation';


export default class LeadLandingPageListView extends NavigationMixin(LightningElement) {

@track listviewArray = [];

connectedCallback() {
   getListViewData().then(data => {
    console.log(data);
   // this.listviewArray = data;
   
    let listviewsinorder = [];	
               data.forEach(key => {	
				if(key.viewLabel == "Due Today / Past Due"){	
                    listviewsinorder.push(key);	
				}	
				}); 	
				/*data.forEach(key => {	
				if(key.viewLabel == "Past Due"){	
                    listviewsinorder.push(key);	
				}	
				}); */	
				data.forEach(key => {	
				if(key.viewLabel == "Customer Interaction Leads"){	
                    listviewsinorder.push(key);	
				}	
               
				}); 
                data.forEach(key => {	
                    if(key.viewLabel == "Small Business Leads"){	
                        listviewsinorder.push(key);	
                    }	
                   
                    }); 
                    data.forEach(key => {	
                        if(key.viewLabel == "Marketing Campaign Leads"){	
                            listviewsinorder.push(key);	
                        }	
                       
                        }); 
                        data.forEach(key => {	
                            if(key.viewLabel == "Priority Leads"){	
                                listviewsinorder.push(key);	
                            }	
                           
                            }); 
                            data.forEach(key => {	
                                if(key.viewLabel == "All Leads"){	
                                    listviewsinorder.push(key);	
                                }	
                               
                                }); 
                this.listviewArray  =  listviewsinorder;		
				
    
   });
}


redirecttoListview(event) {
console.log(event.target.dataset.listview);
this[NavigationMixin.Navigate]({
    type: 'standard__objectPage',
    attributes: {
        objectApiName: 'Lead',
        actionName: 'list'
    },
    state: {
        // 'filterName' is a property on 'state'
        // and identifies the target list view.
        // It may also be an 18 character list view id.
        // or by 18 char '00BT0000002TONQMA4'
        filterName: event.target.dataset.listview
    }
});
}



}
/**********************************************************
Component Name : leadFormLWC
Created By : sj847r
Updated By : sj847r,nd7003
Description : This component is to display Reail Rep's currently check-in Store 
US#: SPTSLSATT-428 (RLM Deloitte Landing Page - Display Currently Check-in Store)
US#: SPTSLSATT-580 (Allow users to change store on RLM Landing page banner)
************************************************************/
import { LightningElement, track } from 'lwc';
import getStoreLocation from '@salesforce/apex/cLeadHomePageController.getStoreLocation';
import updateSelectedStore from '@salesforce/apex/cLeadHomePageController.SelectedStoreUpdate'; 
import Id from '@salesforce/user/Id';
const userId = Id;

export default class leadEmployeeSelectedStore extends LightningElement {

    @track isModalOpen = false;

    @track options = [];
    @track isStoreAssigned= false;
    @track storeName = [];
    @track initialStoreName;
    @track selectedStore;
    @track profileName;

    //Life cycle hooks
    connectedCallback() {

        let storeset = new Set();

        let storesFinalData = [];
 
        //Invoking Server Method(getStoreLocation) to get either List of Stores or Current Store
        getStoreLocation({userId: userId}).then(result => {
            console.log('result.StoreRetailStores==>'+result.StoreRetailStores);
		    //If Number of Associated Store Names are more than 1
            if (result.StoreRetailStores) {
                this.initialStoreName = result.CurrentLocationstorename;
                this.profileName = result.CurrentProfileName;
                console.log('this.profileName---===>'+this.profileName);
                this.isStoreAssigned = true;

                //For each loop for result.StoreRetailStores to prepare combobox options
                result.StoreRetailStores.forEach(store=>{
                    storeset.add(JSON.stringify({'value' : store, 'label' : store}))
                }) 

                //Seperating the string elements with Array.from()
                storesFinalData = Array.from(storeset);

                //Parsing the data
                storesFinalData = storesFinalData.map(store=>{
                    return JSON.parse(store);
                })

                this.options = storesFinalData;

            }
			//If Number of Associated Store Names are equal to 1
            else{              
              this.isStoreAssigned = true;
              this.initialStoreName = result.CurrentLocationstorename;
              this.profileName = result.CurrentProfileName;
            }
        });
    }

    //Showing the component if current profiile name is among below three.
    get validProfile(){
        return (this.profileName == 'Retail RSC Rep' || this.profileName == 'Retail ARSM' || this.profileName == 'Retail SM')? true : false;
    }

   
    //Saving the Selected Store Name in this function
    SaveChanges(){        
        this.isModalOpen = false;
        this.initialStoreName = this.selectedStore;

        //Updating selcted store name to custom settings
        updateSelectedStore({selectedStore : this.selectedStore})
            .then(result=>{
				window.location.reload();
                console.log('result-Store===>Success');
            })
    }

	//Onclick Function on Store Name to open Modal Popup  
    openPopUp(){
        console.log('this.options==-->.'+this.options)
        if(this.options.length > 0){
            this.isModalOpen = true;
        }else{
            this.isModalOpen = false;
        }      
    }

	//Getting the Selected Values in onChange event
    handleChange(event){
       this.selectedStore = event.target.value;
    }

	//Using this function to close Modal Popup when clicks on either Cancel button or Save button 
    closeModal(){
        this.isModalOpen = false;
    }
}
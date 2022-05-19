import { LightningElement, api, track} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';



export default class NavigationToPagesExample extends NavigationMixin(LightningElement) {
    @api recordId;
    @track article;
    @track error;
    @api previewImage;

    /* Use the below onclick logic to navigate to the 
    article record page. For this example it will direct to a test article in 
    */
    handleClick(e){
    //let artid = e.currentTarget.getAttribute("id").split('-')[0];
      //  console.log('artid', artid);
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName:'Knowledge_Landing'
            },
        });
        this[[NavigationMixin.Navigate](pagereferenceRecord, true)]
    }
}
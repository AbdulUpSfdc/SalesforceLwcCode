import { LightningElement,track,api} from 'lwc';
import compareDataCategories from "@salesforce/apex/BWLinkValidationHelper.compareDataCategories";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BwKMCategoryValidatorComponent extends LightningElement {
    @track linkedArticleId;
    @track comparisonResult;
    @track error;
    @api recordId;
    handleTextChange(event){
        this.linkedArticleId = event.target.value;
    }
    handleClick() {
        console.log('recordId',this.recordId);
        console.log('linkedArticleId',this.linkedArticleId);
        compareDataCategories({ parentArticleId: this.recordId,linkedArticleId:this.linkedArticleId})
            .then(result => {
                this.comparisonResult=result;
                console.log('comparisonResult',this.comparisonResult);
                })
            .catch(error => {
                this.error = error;
                console.log(this.recordId+':'+error);
                //alert(error);

                this.showToast("Error Validating Category",error,'error');                 

                this.comparisonResult= error;
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
}
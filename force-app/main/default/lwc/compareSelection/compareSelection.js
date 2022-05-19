import { LightningElement, api, track} from 'lwc';

export default class CompareSelection extends LightningElement {
    @api field;
    @api record;
    @api label;
    @track content;
    @track image = false;
    @track display;
    @track nullcheck = false;
     
    renderedCallback(){
        this.content = this.record[this.field];

        if(!this.content){
            this.nullcheck = true;
        }else{
            if(typeof(this.content) == 'string'){
                this.display = this.content;    
            }else{
                this.image = true;

            }
        }
    }
}
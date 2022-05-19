import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import deleteArticles from '@salesforce/apex/DeleteArchivedBat.DeleteArchivedArticles';

export default class KMComplianceArticleListView extends LightningElement {
numArticlesDeleted;
error;

handleDelete() {
    
    console.log('Button pressed');
    
    deleteArticles()
        .then(result => {
            this.numArticlesDeleted = result;
            console.log('Number of articles deleted: ' + this.numArticlesDeleted );

        })
        .catch(error => {
            this.error = error;
            console.log('Error: ' + JSON.stringify(error));

        });
        console.log('Button complete');
    }
}
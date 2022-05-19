import { LightningElement } from 'lwc';

export default class KnowledgeArticleBarCmp extends LightningElement {
    isGridArticleView = true; 
    get options() {
        return [
            { label: 'Option A', value: 'Option A' },
            { label: 'Option B', value: 'Option B' },
            { label: 'HBO Max App', value: 'HBO Max App' },
            { label: 'Option D', value: 'Option D' },
            { label: 'Option E', value: 'Option E' },
        ];
    }

    handleGridViewClick(){
        this.isGridArticleView = true;
    }

    handleListViewClick(){
        this.isGridArticleView = false;
    }
}
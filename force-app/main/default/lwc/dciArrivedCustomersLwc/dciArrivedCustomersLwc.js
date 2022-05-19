import {
    LightningElement,
    api,
    wire,
    track
  } from 'lwc';
  import getArrivedCustomers from "@salesforce/apex/DCIController.getArrivedCustomers";
  
  export default class dciArrivedCustomersLwc extends LightningElement {
    btn_label = "View More";
    ismorethanThreeRecords = true;
    hasRecordsLoaded = false;
    arrivedcustomers = [];
    allArrivedCustomers;
    NUMBER_RECORDS_TODISPLAY = 3;
    totalRecords;
  
    connectedCallback() {
        getArrivedCustomers()
            .then(data => {
                this.allArrivedCustomers = data;
                this.totalRecords = data.length;
                this.getFirstThreeRecords();
                if (this.allArrivedCustomers && this.allArrivedCustomers.length > 0) {
                    this.hasRecordsLoaded = true;
                }
            }).catch(error => {
                console.log('No articles returned ' + error);
                this.hasRecordsLoaded = false;
                this.ismorethanThreeRecords = false;
            });
    }
    getFirstThreeRecords() {
        if (this.allArrivedCustomers.length > this.NUMBER_RECORDS_TODISPLAY) {
            this.ismorethanThreeRecords = true;
            var tempRecs = new Array();
            for (let i = 0; i < this.NUMBER_RECORDS_TODISPLAY; i++) {
                tempRecs.push(this.allArrivedCustomers[i]);
            }
            this.arrivedcustomers = tempRecs;
        } else {
            this.ismorethanThreeRecords = false;
            this.arrivedcustomers = this.allArrivedCustomers;
        }
    }
    handleMore() {
        let assignedArticleContainer = this.template.querySelector(".assignedArticleContainer");
        if (this.btn_label === 'View More') {
            this.arrivedcustomers = this.allArrivedCustomers;
            this.btn_label = "View Less";
            if (assignedArticleContainer) {
                assignedArticleContainer.style = "overflow-y:scroll;overflow-x:hidden;height:200px;";
            }
        } else {
            this.getFirstThreeRecords();
            this.btn_label = "View More";
            if (assignedArticleContainer) {
                assignedArticleContainer.style = "";
            }
        }
    }
  }
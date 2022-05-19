import { LightningElement, wire, api, track } from 'lwc';
import pubsub from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import {ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInactiveTime from '@salesforce/apex/DCIController.getInactiveTime';
import changeRepStatus from '@salesforce/apex/DCIController.changeRepStatus';
import getInitialData from '@salesforce/apex/DCIController.getInitialData';

export default class CheckinQueue extends LightningElement {
@wire(CurrentPageReference) pageRef;  
@track currentlyAvailableRep = false;
@track logoutMinutes = 0;
@track isRepOnline=false;
@track isRepBusy=false;
@track EmployeeDetails = {};
@track StoreDetails = {};
@track iCanHelpCustomers = false;
userPresenceStatus = '';
timeoutInMiliseconds = 10000;
timeoutId; 

       
    connectedCallback(){
        getInitialData()
        .then(data => {
            this.EmployeeDetails = data.employeeDetails;
            if(this.EmployeeDetails){
                this.StoreDetails = this.EmployeeDetails['Store__r'];
                if(this.EmployeeDetails.DCIPresenceStatus__c === 'Online' || this.EmployeeDetails.DCIPresenceStatus__c === 'Busy'){
                    this.isRepOnline = true;
                    this.iCanHelpCustomers = true;
                }
                    
                if(this.EmployeeDetails.DCIPresenceStatus__c === 'Busy' || data.hasCustomerEngaged == true)
                    this.isRepBusy = true;
            }else{
                this.showHomePage = false;
                const toastEvent = new ShowToastEvent({
                    title: 'Error',
                    message: 'No store association data found for logged in user.',
                    variant: 'error',
                    mode:'sticky'
                });
                this.dispatchEvent(toastEvent);
            }
        }).catch(error => {   
            console.log("Error thrown in getInitialData" + JSON.stringify(error));
         });

          getInactiveTime()
                    .then(result => {
                            this.timeoutInMiliseconds = result*(-60000); 
                             this.setupTimers();          
            }).catch(error => {
                 console.log("Error thrown in getInactiveTime" + JSON.stringify(error));
            });   
                   
    }  

    register(){
        window.console.log('event registered ');
        pubsub.registerListener('simplevt', this.handleEvent.bind(this),this);
    }

    changeRepStatus(event){
        var Status = event.target.checked;
        if(Status){
            this.userPresenceStatus ='Online';
            this.iCanHelpCustomers = true;
            this.isRepOnline = true;
        }
        else{
            this.userPresenceStatus ='Offline';
             this.iCanHelpCustomers = false;
             this.isRepOnline = false;
        }

        changeRepStatus({
            status: this.userPresenceStatus,
            empStore: this.EmployeeDetails 
        })
        .then(data => {  
            if(Status){
                const toastEvent = new ShowToastEvent({
                       title: '',
                       message: 'You made yourself available to help customers.',
                       variant: 'success'
                   });
                   this.dispatchEvent(toastEvent);
               }   else{
                   const toastEvent = new ShowToastEvent({
                       title: '',
                       message: 'You made yourself unavailable to help customers.',
                       variant: 'info',
                       mode: 'dismissable',
                       
                   });
                   this.dispatchEvent(toastEvent);
               }
             
            //window.location.reload();
        }).catch(error => {   
            console.log("Error thrown in changeRepStatus" + JSON.stringify(error));
        });
    }
  
      
    startTimer() { 
        // window.setTimeout returns an Id that can be used to start and stop a timer
        this.timeoutId = setTimeout(()=>{
           changeRepStatus({
                        status: 'Offline',
                        empStore: this.EmployeeDetails
                    })
                    .then(data => {
                         this.userPresenceStatus = 'Offline';
                         this.iCanHelpCustomers = false;
                         this.isRepOnline = false;
                        
                    }).catch(error => {
                        console.log("Error thrown in changeRepStatus" + JSON.stringify(error));
                    });
            }, 
            this.timeoutInMiliseconds);
    }
     
    setupTimers () {
        document.addEventListener("mousemove",()=>this.resetTimer(), false);
        document.addEventListener("mousedown",()=> this.resetTimer(), false);
        document.addEventListener("keypress", ()=>this.resetTimer(), false);
        document.addEventListener("touchmove",()=> this.resetTimer(), false);
        document.addEventListener("touchstart",()=> this.resetTimer(), false);
        this.startTimer();
    } 
    resetTimer(){
        clearTimeout(this.timeoutId);
        this.startTimer();
    }
}
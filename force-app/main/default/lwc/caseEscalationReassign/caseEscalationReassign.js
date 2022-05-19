import { LightningElement, wire, track,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent  } from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import hasAdminPermission from '@salesforce/customPermission/Is_Admin';
import getGroupDetails from '@salesforce/apex/CaseEscalationReassign.getGroupDetails';
import caseLinktoInteraction from '@salesforce/apex/CaseEscalationReassign.caseLinktoInteraction';
import getUserDetails from '@salesforce/apex/CaseReassign_Escalation.getUserDetails';
import updateCaseOwner from '@salesforce/apex/CaseReassign_Escalation.updateCaseOwner';

export default class CaseEscalationReassign extends NavigationMixin(LightningElement) {

    _isAdmin = hasAdminPermission;
    @track isAdmin=false;
    @track selWorkgroup='';
    @track seluserId='';
    @track selectOptions = [];
    @track selectOptUsers = [{label: "--None--", value: ""}];
    @track isShowAll=false;
    @track isErrMsg=false;
    @track invalidSelection=true;
    @track cannotReassign=true;

    @track workgroupQueueId='';
    @track currentCaseOwnerId='';

    // The queue owner is considered the 'Admin' for the purpose of the 'Reassign to Admin' button
    @track queueOwnerId='';

    @api recordId;
    @api parentTabId;
    @track showLoadingSpinner=true;
    @track isErrLastInteraction=true;
    @track isShowReassignBtn=true;
    @wire(getRecord, {
        recordId:'$recordId',
        fields: ['Case.OwnerId','Case.Last_Interaction__c','Case.WorkGroup__c','Case.Status']
    }) wireuser({
        error,
        data
    }) {
        if (error) {
           console.log("####Erro",error);
        } else if (data) {
           console.log("###data.fieldsNew",data.fields);

           if(data.fields.Last_Interaction__c!=undefined && data.fields.Last_Interaction__c.value!=undefined
             && data.fields.Last_Interaction__c.value!=null){
                this.isErrLastInteraction=false;
           }
           this.currentCaseOwnerId=data.fields.OwnerId.value;

            if(data.fields.OwnerId.value!=undefined && data.fields.OwnerId.value.substr(0,3)!='005'){
               if(this._isAdmin){
                this.cannotReassign=false;   
               }else{
                this.cannotReassign=true;
               }
                
            } else{
                this.cannotReassign=false;   
            }
           console.log("##OldOwner",this.currentCaseOwnerId);

            //
            var workgroupVal=data.fields.WorkGroup__c.value;

            this.isShowAll=false;
            if(workgroupVal!=null && this._isAdmin){
                    const option = {label: workgroupVal+'',value: workgroupVal+''};
                    this.selectOptions = [ ...this.selectOptions, option ];

                    this.selWorkgroup =workgroupVal;
                    this.showLoadingSpinner = true;
                    this.isShowAll=true;
                    getUserDetails({ userOrGroupName : this.selWorkgroup })
                    .then(result => {
                        this.selectOptUsers=[];
                        this.isErrMsg=true;

                        console.log("@@@Size",result.length);
                        console.log({result});

                        //greater than 1 because apex returns a none option
                        if(result.length>1){
                            for(var i=0;i<result.length;i++){
                                this.selectOptUsers = [ ...this.selectOptUsers, result[i] ];
                            }
                        }
                        if(result.length>1){
                            this.isErrMsg=false;
                        }
                        this.showLoadingSpinner = false;
                    })
                    .catch(error => {
                        this.showLoadingSpinner = false;
                    });

            }
        }

        this.showLoadingSpinner=true;
        this.onrefreshGroupDetails();


    }

    onrefreshGroupDetails(){
        console.log("##OwnerDetailsNewFinalVal",this.workgroupQueueId);
        getGroupDetails({recordId: this.recordId}).then(result => {
            console.log("##resultnew",result);
             if(result.Id!=undefined){
                this.workgroupQueueId=result.Id;
                this.queueOwnerId = result.OwnerId;
             }
             this.showLoadingSpinner=false;

             console.log("##RefreshQueId",this.queueOwnerId);
         })
         .catch(error => {
            // this.error = error;
            this.showLoadingSpinner=false;
         });


    }
    connectedCallback() {
        //console.log("###connectedCallback");
        //this.showLoadingSpinner=true;
        //this.onrefreshGroupDetails();
        console.log('isAdmin: ' ,this.isAdmin);


    }

    onReassign(){
        if(hasAdminPermission){
            this.showAdminFields();
        }else{ 
            this.onChangeOwner();
        }
    }

    showAdminFields(){
        this.isAdmin = hasAdminPermission;
        console.log('this.isAdmin', this.isAdmin);
    }

    onChangeOwner(){
        // force the refresh of the group details to make sure we get the current details on the case
        this.onrefreshGroupDetails();

        if(this.currentCaseOwnerId!=undefined && this.workgroupQueueId!=undefined && this.currentCaseOwnerId== this.workgroupQueueId ){

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Updated record',
                    message: 'Case is already in related queue',
                    variant: 'error'
                })
            );

        }else{
            if( this.workgroupQueueId==undefined || this.workgroupQueueId==''){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Updated record',
                        message: 'No Queue exists. Please contact System Administrator.',
                        variant: 'error'
                    })
                );
            }else{
                this.showLoadingSpinner=true;
                console.log("###Owner",this.workgroupQueueId);
                // Create the recordInput object
                const fields = {};
                fields['Id'] = this.recordId;
                fields['OwnerId'] =this.workgroupQueueId;
                fields['Status'] = 'New';
                const recordInput = { fields };
                updateRecord(recordInput).then(() => {
                    this.showLoadingSpinner=false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Successfully updated',
                            variant: 'success'
                        })
                    );
                    // Display fresh data in the form
                    return refreshApex(this.recordId);
                }).catch(error => {
                    this.showLoadingSpinner=false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error Updated record',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
            }
        }
    }

    onReassignAdminOwner(event){
        console.log("##onReassignAdminOwner",this.queueOwnerId);
        this.onrefreshGroupDetails();
        if( this.queueOwnerId==undefined || this.queueOwnerId==''){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Updated record',
                    message: 'No Queue Owner exists. Please contact System Administrator.',
                    variant: 'error'
                })
            );
        }else{
            this.showLoadingSpinner=true;
            console.log("###Owner",this.queueOwnerId);
            // Create the recordInput object
            const fields = {};
            fields['Id'] = this.recordId;
            fields['OwnerId'] =this.queueOwnerId;
            const recordInput = { fields };
            updateRecord(recordInput).then(() => {
                this.showLoadingSpinner=false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Successfully updated',
                        variant: 'success'
                    })
                );
                // Display fresh data in the form
                return refreshApex(this.recordId);
            }).catch(error => {
                this.showLoadingSpinner=false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Updated record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
        }



    }
    onClickLinktoInteraction(event){
        console.log("### this.isErrLastInteraction", this.isErrLastInteraction);
        /*if(this.isErrLastInteraction){

            this.dispatchEvent(new ShowToastEvent({
                title: 'Error!!',
                message: 'No Last Interaction',
                variant: 'error'
            }));

        }else{*/

            this.showLoadingSpinner=true;
            console.log('parentTabId: ', this.parentTabId);
            caseLinktoInteraction({recordId: this.recordId,interactionId:this.parentTabId}).then(result => {
                console.log("##result",JSON.stringify(result));
                // Display fresh data in the form
               //window.location.reload();
                //console.log("###no catch");

                const fields = {};
                fields['Id'] = this.recordId;
                fields['Last_Interaction__c'] =this.parentTabId;
                const recordInput = { fields };
                getRecordNotifyChange([{recordId: this.recordId}]);
                //return updateRecord(recordInput);
            })
            .then((result)=>{

                this.showLoadingSpinner=false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        variant: 'success'
                    })
                );
                // Display fresh data in the form
                return refreshApex(this.recordId);
             })
             .catch(error => {
                // this.error = error;
                console.log("###In catch");
                console.log(JSON.stringify(error));
                this.showLoadingSpinner=false;

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error!!',
                    message: error.body.message,
                    variant: 'error'
                }));


             });

       // }
    }

    onhandleChangeUser(event){
        this.seluserId= event.detail.value;
        this.invalidSelection=true;
        if(this.seluserId!='' && this.seluserId!=this.currentCaseOwnerId){
            this.invalidSelection=false;
        }
        
    }    
    saveRecords(){   
        if(this.seluserId!='' && this.selWorkgroup !=''){
            this.showLoadingSpinner = true;
            updateCaseOwner({ caseId : this.recordId,userOrGroupId: this.seluserId}).then(result => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success!!',
                    message: 'Successfully Updated!!.',
                    variant: 'success'
                }));
                console.log("final New");
                this.showLoadingSpinner = false;
                this.resetPicklistValues();
                getRecordNotifyChange([{recordId: this.recordId}]);
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error!!',
                    message: errorPhase.body.message,
                    variant: 'error'
                }));

                this.showLoadingSpinner = false;
            });
        }else{
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error!!',
                message: 'Please Select WOrkGroup and User Records',
                variant: 'error'
            }));
        }

    }

    handleCancelReassign(){
        this.resetPicklistValues();
    }

    resetPicklistValues(){
        this.isAdmin = false;
        this.selWorkgroup='';
        this.seluserId='';
        this.invalidSelection = true;
    }

}
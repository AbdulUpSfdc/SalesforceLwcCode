import { LightningElement,track,wire,api } from 'lwc';
import * as bwcUtils from 'c/bwcUtils';
import createEscalationCase from '@salesforce/apex/BWC_CreateCase.createEscalationCase';
import * as BwcConstants from 'c/bwcConstants';
import { CurrentPageReference } from "lightning/navigation";

export default class CaseCreateBillingAdjustment extends LightningElement {
    @wire(CurrentPageReference)
    pageRef;

    @track action=BwcConstants.AdjustmentType;
    @track type = 'Billing';
    @track feature = 'Adjustment';


    //remove
    handleClick(){
        //Hard coded for testing only not for prod******************************************************
// ctdev ban id a2b7c000001h5xtAAA
// ctqa ban id a2b0U000000XUdvQAG
        this.createBillingAdjustmentCase(
            JSON.stringify({
                ban: '177057327797',
                caseAction: this.action,
                Type: this.type,
                adjustmentData:{
                    adjType:'Goodwill',
                    adjReasonExplanationCode:'Some Code',
                    adjReasonDescription:'deascriptionData',
                    adjReasonSystemCode:'magenta',
                    adjComments:'stuff about test data'
                },
                cdeData:{
                    overallCDEStatus:'something',
                    cdeApprovedAmount:'5.00',
                    cdeReasonForAgent:'something',
                    cdeReasonForCustomer:'reason data',
                    cdeRecommendationStatus:'Approved with Conditions',
                    isCustomerAccepted:'true',
                    overrideEscalate:'Override',
                    overrideEscalateBy:'Anshul',
                    cdeProductLevelId:'L5000'
                },
                billData:{
                    billDate:'something',
                    billSequenceNumber:'1234',
                    chargeCode:'chargeCodeData',
                    chargeType:'Goodwill',
                    chargeSequenceNumber:'241533',
                    chargeDescription:'chargeDescriptionData',
                    chargeAmount:'7500.00',
                    requestAmount:'8500.00',
                    agentAdjustedAmount:'3400',
                },
                lineItemDataList:[
                    {
                        billDate:'something',
                        billSequenceNumber:'1234',
                        chargeCode:'chargeCodeData',
                        chargeType:'Goodwill',
                        chargeDescription:'chargeDescriptionData',
                        chargeSequenceNumber:'241542',
                        chargeAmount:'7510.00',
                        requestAmount:'8200.00',
                        agentAdjustedAmount:'3800',
                    },
                    {
                        billDate:'somethingElse',
                        billSequenceNumber:'124534',
                        chargeCode:'chargeCodeDataNum2',
                        chargeType:'Goodwill',
                        chargeDescription:'chargeDescriptionDataNum2',
                        chargeSequenceNumber:'331533',
                        chargeAmount:'75090.00',
                        requestAmount:'24336.00',
                        agentAdjustedAmount:'33633',
                    }
                ]
            }));
    }
    @api
    createBillingAdjustmentCase(dataObj){
        //need caseAction var in dataObj
        createEscalationCase({interactionId: bwcUtils.getInteractionIdFromUrl(), ecType: this.type,ecFeature: this.feature, detailRecord: dataObj}).then(result => {
            console.log("result: ",result);

        }).catch(error => {

        }).then({

        });
    }

    //remove
    handleChange(event){
        this.action = event.detail.value.replaceAll('_',' ');
    }
}
import { LightningElement,track,api } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import getRSAToken from '@salesforce/apex/BWC_RSATokenController.getRSAToken';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import  checkUserAccess  from '@salesforce/apex/BWC_RSATokenController.hasRecordAccess';
import RSATitle from '@salesforce/label/c.BWC_RSA_Token_Title';
import RsaErrorMessage from '@salesforce/label/c.BWC_RSA_Access_Error_Message';

export default class BwcRequestAuthenticationCode extends LightningElement {

    disableGeneration = false;
    showToken = false;
    serialNum = '';
    tokenCode = '';
    isLoading = false;
    timeStamp;
    expiryTime;
    intervals = [];
    timer;
    showErrors = false;
    errorMessage = '';
    hasUserAccess;
    @track showRSAScreen = false;

    connectedCallback(){
        this.checkUserAccess();
    }

    async generateToken(){
        this.isLoading = true;
        try{
            const responseWrapperJson = await getRSAToken(); 
            BwcUtils.log(' RSA Token response: ' + responseWrapperJson);
            
            const responseWrapper = JSON.parse(responseWrapperJson);
            if (!responseWrapper.success) {
                this.addErrors(responseWrapper.message);
            }else{
                BwcUtils.log(' Showing Token');
                this.showToken = true;
                this.serialNum = responseWrapper.response.serialnum;
                this.tokenCode = responseWrapper.response.token;
                this.timeStamp = responseWrapper.response.timestamp;
                this.timeStamp = this.timeStamp.substr(0,this.timeStamp.lastIndexOf("."));
                BwcUtils.log('this.timeStam--' + this.timeStamp);
                let expDate = this.addMinutes(new Date(this.timeStamp),5);
                this.clearErrors();
                this.startTimer(expDate.getTime());
                this.disableGeneration = true;
            }
        }catch(error) {
            BwcUtils.log(JSON.stringify(error.body.message));
            this.addErrors(error.body.message);
        }
        finally {
            this.isLoading = false;
        }
    }

    checkUserAccess(){
        checkUserAccess({
            title : RSATitle
        }).then((result) => {
            
            BwcUtils.log(' Access response: ' + result);
            this.hasUserAccess = result;
            if(result === true) {
                this.showRSAScreen = true;
            } else {
                const event = new ShowToastEvent({
                    title: 'Access Error',
                    message: RsaErrorMessage,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            }
        })
    }

    startTimer(expTime){
        this.intervals.forEach(clearInterval);
        this.timer = "";
        let parent = this;
        let timerInterval = setInterval(function(){
            let now = new Date();
            let newNow = new Date(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(),now.getUTCHours(), now.getUTCMinutes(), now.getUTCSeconds());
            let timeLeft = expTime - newNow.getTime();
            let days = Math.floor(timeLeft / (1000 * 60 * 60 * 24));
            let hours = Math.floor((timeLeft % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
            let minutes = Math.floor((timeLeft % (1000 * 60 * 60)) / (1000 * 60));
            let seconds = Math.floor((timeLeft % (1000 * 60)) / 1000);
            minutes = minutes < 10 ? "0" + minutes : minutes;
            seconds = seconds < 10 ? "0" + seconds : seconds;
            parent.timer = minutes + ' : ' + seconds;
            if (timeLeft < 0) {
                clearInterval(timerInterval);
                parent.showToken = false;
                parent.timer = "";
                parent.showErrors = true;
                parent.addErrors('Token code has expired. Please generate a token again for a new serial number and token code.');
                parent.disableGeneration = false;
            }
            
        },1000);
        this.intervals.push(timerInterval);

    }

    addMinutes(date,minutes){
        return new Date(date.getTime() + minutes * 60000); 
    }

    clearErrors(){
        this.showErrors = false;
        this.errorMessage = '';
    }

    addErrors(msg){
        this.showErrors = true;
        this.errorMessage = msg;
    }
}
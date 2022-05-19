import { LightningElement, api } from "lwc";

import otpMessage from "@salesforce/label/c.PaymentRedactionCustomerOTPMessage";
import redactionTitle from "@salesforce/label/c.PaymentRedactionTitle";
import accNumber from "@salesforce/label/c.PaymentRedactionAccountNumber";
import nextDue from "@salesforce/label/c.PaymentRedactionNextDue";
import paymentMethodTitle from "@salesforce/label/c.PaymentRedactionPaymentMethodTitle";
import pmCC from "@salesforce/label/c.PaymentRedactionPaymentMethodCC";
import pmACH from "@salesforce/label/c.PaymentRedactionPaymentMethodBank";
import currentErrorMsg from "@salesforce/label/c.PaymentRedactionCurrentErrorMsg";
import cardPaymentMethod from "@salesforce/label/c.PaymentRedactionCardPaymentMethodMsg";
import cardholderName from "@salesforce/label/c.PaymentRedactionCardholderName";
import cardholderNameRequiredError from "@salesforce/label/c.PaymentRedactionCardholderNameRequiredError";
import cardNumber from "@salesforce/label/c.PaymentRedactionCardNumber";
import cardNumberPlaceHolder from "@salesforce/label/c.PaymentRedactionCardNoPlaceholder";
import cardNumberMissing from "@salesforce/label/c.PaymentRedactionCardNumberMissing";
import cardNumberInvalid from "@salesforce/label/c.PaymentRedactionCardNumberInvalid";
import cardNumberReenter from "@salesforce/label/c.PaymentRedactionCardNumberReenter";
import cardExpiration from "@salesforce/label/c.PaymentRedactionCardExpiration";
import cardExpirationPlaceholder from "@salesforce/label/c.PaymentRedactionCardExpirationPlaceHolder";
import cardExpirationRequiredError from "@salesforce/label/c.PaymentRedactionCardExpirationRequiredError";
import cardSecurityCode from "@salesforce/label/c.PaymentRedactionCardSecurityCode";
import cardSecurityCodePlaceholder from "@salesforce/label/c.PaymentRedactionCardSecurityCodePlaceholder";
import cardSecurityCodeError from "@salesforce/label/c.PaymentRedactionCardSecurityCodeError";
import cardSecurityCodeFormat from "@salesforce/label/c.PaymentRedactionCardSecurityCodeFormat";
import cardZip from "@salesforce/label/c.PaymentRedactionCreditCardCZip";
import cardZipCodeRequiredError from "@salesforce/label/c.PaymentRedactionCardZipCodeRequiredError";
import cardZipPlaceholder from "@salesforce/label/c.PaymentRedactionCreditCardCZipPlaceholder";
import cardSecurityCodeHelp from "@salesforce/label/c.PaymentRedactionCardSecurityCodeHelp";
import cardSubmitSuccessMsg from "@salesforce/label/c.PaymentRedactionCardSubmitSuccessMsg";
import cardSubmitErrorMsg from "@salesforce/label/c.PaymentRedactionCardSubmitErrorMsg";
import cardSubmitExceptionMsg from "@salesforce/label/c.PaymentRedactionCardSubmitExceptionMsg";
import bankNameOnAcc from "@salesforce/label/c.PaymentRedactionBankNameOnAccount";
import bankNameOnAccErrMsg from "@salesforce/label/c.PaymentRedactionBankNameOnAccountErrMsg";
import bankRoutingNumber from "@salesforce/label/c.PaymentRedactionBankRoutingNumber";
import bankRoutingNumberErrMsg from "@salesforce/label/c.PaymentRedactionBankRoutingNumberErrMsg";
import bankRoutingNumberMissingErrMsg from "@salesforce/label/c.PaymentRedactionBankRoutingNumberMissingErrMsg";
import bankAccNumber from "@salesforce/label/c.PaymentRedactionBankAccountNumber";
import bankAccNumberErrMsg from "@salesforce/label/c.PaymentRedactionBankAccountNumberErrMsg";
import bankAccNumberMissingErrMsg from "@salesforce/label/c.PaymentRedactionBankAccountNumberMissingErrMsg";
import bankCheckNumber from "@salesforce/label/c.PaymentRedactionBankCheckNumber";
import bankCheckNumberErrMsg from "@salesforce/label/c.PaymentRedactionBankCheckNumberErrMsg";
import submitPaymentBtn from "@salesforce/label/c.PaymentRedactionSubmitPaymentButton";
import paymentConfirmation from "@salesforce/label/c.PaymentRedactionPaymentConfirmation";
import paymentWaitingOnAgent from "@salesforce/label/c.PaymentRedactionWaitingForAgentMessage";
import hlinkLegalPolicyCenter from "@salesforce/label/c.PaymentRedactionFooterLegalPolicyCenter";
import hlinkPrivacyCenter from "@salesforce/label/c.PaymentRedactionFooterPrivacyCenter";
import hlinkTermsOfUse from "@salesforce/label/c.PaymentRedactionFooterTermsOfUse";
import hlinkAdvertChoices from "@salesforce/label/c.PaymentRedactionFooterAdvertisingChoices";
import hlinkBroadbandDetails from "@salesforce/label/c.PaymentRedactionFooterBroadbandDetails";
import hlinkAccessibility from "@salesforce/label/c.PaymentRedactionFooterAccessibility";
import hlinkDoNotSellPI from "@salesforce/label/c.PaymentRedactionFooterDoNotSellPI";
import hlinkSpanish from "@salesforce/label/c.PaymentRedactionFooterSpanish";
import hlinkEnglish from "@salesforce/label/c.PaymentRedactionFooterEnglish";
import refundTheSameMsg from "@salesforce/label/c.PaymentRedactionRefundTheSame";
import isRefundSameYES from "@salesforce/label/c.PaymentRedactionIsRefundTheSameYES";
import isRefundSameNO from "@salesforce/label/c.PaymentRedactionIsRefundTheSameNO";
import refundMethodTitle from "@salesforce/label/c.PaymentRedactionRefundMethodTitle";


//Expiration Error message for when pattern is not matched
import cardexpirationPatternmismatch from "@salesforce/label/c.PaymentRedactionCardExpirationPatternMismatch";

let labels = {
  otpMessage,
  redactionTitle,
  accNumber,
  nextDue,
  paymentMethodTitle,
  pmCC,
  pmACH,
  currentErrorMsg,
  cardPaymentMethod,
  cardholderName,
  cardholderNameRequiredError,
  cardNumber,
  cardNumberPlaceHolder,
  cardSecurityCodeError,
  cardSecurityCodeFormat,
  cardNumberMissing,
  cardNumberInvalid,
  cardNumberReenter,
  cardExpiration,
  cardExpirationPlaceholder,
  cardExpirationRequiredError,
  cardSecurityCode,
  cardZip,
  cardZipPlaceholder,
  cardZipCodeRequiredError,
  cardSecurityCodePlaceholder,
  cardSecurityCodeHelp,
  cardSubmitSuccessMsg,
  cardSubmitErrorMsg,
  cardSubmitExceptionMsg,
  bankNameOnAcc,
  bankNameOnAccErrMsg,
  bankRoutingNumber,
  bankRoutingNumberErrMsg,
  bankRoutingNumberMissingErrMsg,
  bankAccNumber,
  bankAccNumberErrMsg,
  bankAccNumberMissingErrMsg,
  bankCheckNumber,
  bankCheckNumberErrMsg,
  submitPaymentBtn,
  paymentConfirmation,
  paymentWaitingOnAgent,
  hlinkLegalPolicyCenter,
  hlinkPrivacyCenter,
  hlinkTermsOfUse,
  hlinkAdvertChoices,
  hlinkBroadbandDetails,
  hlinkAccessibility,
  hlinkDoNotSellPI,
  hlinkSpanish,
  hlinkEnglish,
  refundTheSameMsg,
  isRefundSameYES,
  isRefundSameNO,
  refundMethodTitle,
  cardexpirationPatternmismatch
};

const real2short = Object.freeze({
  "PaymentRedactionCustomerOTPMessage" : "otpMessage",
  "PaymentRedactionTitle" : "redactionTitle",
  "PaymentRedactionAccountNumber" : "accNumber" ,
  "PaymentRedactionNextDue" : "nextDue" ,
  "PaymentRedactionPaymentMethodTitle" : "paymentMethodTitle" ,
  "PaymentRedactionPaymentMethodCC" : "pmCC" ,
  "PaymentRedactionPaymentMethodBank" : "pmACH" ,
  "PaymentRedactionCurrentErrorMsg" : "currentErrorMsg" ,
  "PaymentRedactionCardPaymentMethodMsg" : "cardPaymentMethod",
  "PaymentRedactionCardholderName" : "cardholderName" ,
  "PaymentRedactionCardholderNameRequiredError" : "cardholderNameRequiredError" ,
  "PaymentRedactionCardNumber" : "cardNumber" ,
  "PaymentRedactionCardNoPlaceholder" : "cardNumberPlaceHolder" ,
  "PaymentRedactionCardNumberMissing" : "cardNumberMissing" ,
  "PaymentRedactionCardNumberInvalid" : "cardNumberInvalid" ,
  "PaymentRedactionCardNumberReenter" : "cardNumberReenter" ,
  "PaymentRedactionCardExpiration" : "cardExpiration" ,
  "PaymentRedactionCardExpirationPlaceHolder" : "cardExpirationPlaceholder" ,
  "PaymentRedactionCardExpirationRequiredError" : "cardExpirationRequiredError" ,
  "PaymentRedactionCardSecurityCode" : "cardSecurityCode" ,
  "PaymentRedactionCardSecurityCodePlaceholder" : "cardSecurityCodePlaceholder" ,
  "PaymentRedactionCardSecurityCodeError" : "cardSecurityCodeError" ,
  "PaymentRedactionCardSecurityCodeFormat" : "cardSecurityCodeFormat" ,
  "PaymentRedactionCreditCardCZip" : "cardZip" ,
  "PaymentRedactionCardZipCodeRequiredError" : "cardZipCodeRequiredError" ,
  "PaymentRedactionCreditCardCZipPlaceholder" : "cardZipPlaceholder" ,
  "PaymentRedactionCardSecurityCodeHelp" : "cardSecurityCodeHelp" ,
  "PaymentRedactionCardSubmitSuccessMsg" : "cardSubmitSuccessMsg" ,
  "PaymentRedactionCardSubmitErrorMsg" : "cardSubmitErrorMsg" ,
  "PaymentRedactionCardSubmitExceptionMsg" : "cardSubmitExceptionMsg" ,
  "PaymentRedactionBankNameOnAccount" : "bankNameOnAcc" ,
  "PaymentRedactionBankNameOnAccountErrMsg" : "bankNameOnAccErrMsg" ,
  "PaymentRedactionBankRoutingNumber" : "bankRoutingNumber" ,
  "PaymentRedactionBankRoutingNumberErrMsg" : "bankRoutingNumberErrMsg" ,
  "PaymentRedactionBankRoutingNumberMissingErrMsg" : "bankRoutingNumberMissingErrMsg",
  "PaymentRedactionBankAccountNumber" : "bankAccNumber" ,
  "PaymentRedactionBankAccountNumberErrMsg" : "bankAccNumberErrMsg" ,
  "PaymentRedactionBankAccountNumberMissingErrMsg" : "bankAccNumberMissingErrMsg",
  "PaymentRedactionBankCheckNumber" : "bankCheckNumber" ,
  "PaymentRedactionBankCheckNumberErrMsg" : "bankCheckNumberErrMsg" ,
  "PaymentRedactionSubmitPaymentButton" : "submitPaymentBtn" ,
  "PaymentRedactionPaymentConfirmation" : "paymentConfirmation" ,
  "PaymentRedactionFooterLegalPolicyCenter" : "hlinkLegalPolicyCenter" ,
  "PaymentRedactionFooterPrivacyCenter" : "hlinkPrivacyCenter" ,
  "PaymentRedactionFooterTermsOfUse" : "hlinkTermsOfUse" ,
  "PaymentRedactionFooterAdvertisingChoices" : "hlinkAdvertChoices" ,
  "PaymentRedactionFooterBroadbandDetails" : "hlinkBroadbandDetails" ,
  "PaymentRedactionFooterAccessibility" : "hlinkAccessibility" ,
  "PaymentRedactionFooterDoNotSellPI" : "hlinkDoNotSellPI" ,
  "PaymentRedactionFooterSpanish" : "hlinkSpanish" ,
  "PaymentRedactionFooterEnglish" : "hlinkEnglish" ,    
  "PaymentRedactionWaitingForAgentMessage" : "paymentWaitingOnAgent" ,
  "PaymentRedactionRefundTheSame" : "refundTheSameMsg" ,
  "PaymentRedactionIsRefundTheSameYES" : "isRefundSameYES" ,     
  "PaymentRedactionIsRefundTheSameNO" : "isRefundSameNO" ,   
  "PaymentRedactionRefundMethodTitle" : "refundMethodTitle" ,
  "PaymentRedactionCardExpirationPatternMismatch" : "cardexpirationPatternmismatch" ,

 });

export default class BwcRedactionLabels extends LightningElement {

  @api
  get labels() {
    return labels;
  }

  /**
   * Method to translate all "registered" labels to the target language
   * 
   * @param {String} lang (example en-US or es-MX)
   */
   @api
   async translateLabels( lang ) {
     const trn = this.template.querySelector( "c-custom-label-translator-cmp" );
     console.debug( "--->>> translator ", trn, JSON.stringify( trn ) );
 
     const lbls = Object.keys( real2short );
     if ( trn ) {
        const ls = await trn.translateLabels( lbls, lang );
        if ( ls ) {
          const translatedLabels = {};
          Object.entries( ls ).forEach(([key, value])=>{
            const short = real2short[ key ];
            if ( short ) {
              translatedLabels[ short ] = value;
            }
          });
          labels = translatedLabels;
        }
     }
     return labels;
   }    
 }
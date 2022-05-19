import { LightningElement, api } from 'lwc';

const INPUT_FIELDS = [
  "bankNameOnAcc",
  "bankRoutingNumber",
  "bankAccNumber",
  "bankCheckNumber"
];

export default class BwcPaymentBankingInfoCmp extends LightningElement {
  
  @api
  labels;

  @api showCheckNo = false;
  
  @api
  get formData() {
    const res = {};
    const areAllGood = INPUT_FIELDS.reduce((validFields, fnm) => {
      const inp = this.template.querySelector("." + fnm);
      if (inp) {
        inp.reportValidity();
		console.log('### checkValidity ', inp.checkValidity());
        //if ( validFields && inp.checkValidity()) {
        if ( inp.checkValidity()) {
          res[fnm] = inp.value;
		  console.log('### res[fnm] ', JSON.stringify(res[fnm]));
		  validFields++;
          //return true;
        }
        //return false;
      }
      //return true;
      return validFields;
    }, 0/*true*/);
	const inputFieldsLength = this.showCheckNo ? INPUT_FIELDS.length : INPUT_FIELDS.length - 1;
    //return areAllGood ? res : undefined;
    return areAllGood === inputFieldsLength ? res : undefined;
  }
}
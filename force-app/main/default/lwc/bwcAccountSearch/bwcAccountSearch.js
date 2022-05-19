import { LightningElement, api,wire,track } from 'lwc';

// SKHAN - 08-18-2020 import NavigationMixin
import { NavigationMixin } from 'lightning/navigation';

import getAccounts from '@salesforce/apex/BWC_CustomerSearchController.getAccounts';
const columnsSingleAccount = [
    { label: 'CUSTOMER NAME', fieldName: 'urlPath',type: 'url',hideDefaultActions: true ,
        typeAttributes: {
            label: { fieldName: 'custName' },
            value: {fieldName: 'custName'}, target: 'urlPath'}
    },
    { label: 'STREET ADDRESS', fieldName: 'street', type: 'text' ,hideDefaultActions: true},
    { label: 'CITY', fieldName: 'city', type: 'text' ,hideDefaultActions: true},
    { label: 'STATE', fieldName: 'state', type: 'text',hideDefaultActions: true ,sortable: true},
    { label: 'ACCOUNT#', fieldName: 'acctNum', type: 'text',hideDefaultActions: true },
    { label: 'ACCOUNT STATUS', fieldName: 'status', type: 'text',hideDefaultActions: true },
    { label: 'PRODUCT', fieldName: 'product', type: 'text' ,hideDefaultActions: true},
    { label: 'PRIMARY EMAIL', fieldName: 'email', type: 'text',hideDefaultActions: true },
];
const columnsMultipleAccount = [
    {
        label: 'CUSTOMER NAME', 
        fieldName: 'custName', type: 'button', hideDefaultActions: true,
        typeAttributes: {
            variant: 'base',
            label: {fieldName: 'custName'}
        },
        cellAttributes: {
            style : 'transform: scale(0.75);'
        }
    },
    { label: 'STREET ADDRESS', fieldName: 'street', type: 'text' ,hideDefaultActions: true},
    { label: 'CITY', fieldName: 'city', type: 'text' ,hideDefaultActions: true},
    { label: 'STATE', fieldName: 'state', type: 'text',hideDefaultActions: true ,sortable: true},
    { label: 'ACCOUNT#', fieldName: 'acctNum', type: 'text',hideDefaultActions: true },
    { label: 'ACCOUNT STATUS', fieldName: 'status', type: 'text',hideDefaultActions: true },
    { label: 'ACCOUNT TYPE', fieldName: 'accountType', type: 'text' ,hideDefaultActions: true},
    { label: 'PRIMARY EMAIL', fieldName: 'email', type: 'text',hideDefaultActions: true },
];


/*
When showing addresses table, first column is a link which wen clicked does a search on addressId.
 */
const columnsAddress = [
    {
        label: 'STREET ADDRESS', 
        fieldName: 'addressLine1', type: 'button', hideDefaultActions: true,
        typeAttributes: {
            variant: 'base',
            label: {fieldName: 'addressLine1'}
        },
        cellAttributes: {
            style : 'transform: scale(0.75);'
        }
    },
    { label: 'ADDRESS2', fieldName: 'addressLine2', type: 'text', hideDefaultActions: true},
    { label: 'CITY', fieldName: 'city', type: 'text' , hideDefaultActions: true},
    { label: 'STATE', fieldName: 'state', type: 'text', hideDefaultActions: true},
    { label: 'ZIP', fieldName: 'zip', type: 'text', hideDefaultActions: true },
    { label: 'COUNTRY', fieldName: 'country', type: 'text', hideDefaultActions: true },
];



// SKHAN - 08-18-2020 Use NavigationMixin to redirect to PersonAccount record
//export default class BwcAccountSearch extends LightningElement {
export default class BwcAccountSearch extends NavigationMixin(LightningElement) {
    search=true;
    showLoading=false;
    showAccounts = false;
    showAddresses = false;
    showNoResultAccount = false;
    showNoResultAddress = false;
    @track UIdata;
    @track AddressData;
    columns = columnsSingleAccount;
    columnsAddress = columnsAddress;
    banFieldValue;
    ctnFieldValue;
    acctTypeValue='wireless';
    addressTitle;

    userId;
    addr1;
    addr2;
    city;
    state;
    zip;
    addressId;

    value = '';

    get options() {
        return [
            { label: 'California', value: 'CA' },
            { label: 'Texas', value: 'TX' },
            { label: 'New York', value: 'NY' },
            { label: 'Wisconsin', value: 'WI' },
        ];
    }

    get acctType() {
        return [
            { label: 'Wireless', value: 'wireless' },
            { label: 'Uverse', value: 'uverse' },
            { label: 'AT&T TV', value: 'tv' },
            { label: 'Direct TV', value: 'dtv' },
        ];
    }

    handleBanChange(event){
        this.banFieldValue = event.target.value;
        //if(this.banFieldValue.length==15){
           // this.acctTypeValue = 'tv';
        //}
    }

    handleacctTypeChange(event){
        this.acctTypeValue = event.target.value;
    }

    handlectnChange(event){
        this.ctnFieldValue = event.target.value;
    }

        
    handleUserIdChange(event) {
        this.userId = event.target.value;
    }

    handleAddr1Change(event) {
        this.addr1 = event.target.value;
    }
    handleAddr2Change(event) {
        this.addr2 = event.target.value;
    }
    handleCityChange(event) {
        this.city = event.target.value;
    }
    handleStateChange(event) {
        this.state = event.target.value;
    }
    handleZipChange(event) {
        this.zip = event.target.value;
    }

    handleNewSearch(){
        this.reset();
        this.search=true;
        this.showAccounts = false;
        this.showAddresses = false;
        this.showLoading = false;
    }

    reset() {
        this.banFieldValue = null;
        this.ctnFieldValue = null;
        this.userId = null;
        this.addr1 = null;
        this.addr2 = null;
        this.city = null;
        this.state = null;
        this.zip = null;
        this.addressId = null;
    }

    handleSearch() {
        this.showLoading=true;
        //SKHAN - 08/17/2020 - Added CTN parameter
        getAccounts({ban:this.banFieldValue, ctn:this.ctnFieldValue,acctType:this.acctTypeValue,
        userId:this.userId,
        addressId:this.addressId,
        addr1:this.addr1,addr2:this.addr2,city:this.city,state:this.state,zip:this.zip})
        .then(result =>{

            if (!result.success) {
                console.log('return rejection')
                return Promise.reject(result.message);
            }
            console.log('no reject')

            this.showAccounts = false;
            this.showAddresses = false;

            //show the data table based on the resultType
            window.console.log('Data from Service :'+JSON.stringify(result));
            if (result.resultType == 'accounts') {
                let parsedResult = JSON.parse(result.resultJSON);

                // if result has more than one row, use the column definition in columnsMultipleAccount
                if (parsedResult != null && parsedResult.length > 1) {
                    this.columns = columnsMultipleAccount;
                }
                else {
                    this.columns = columnsSingleAccount;
                }

                this.UIdata = parsedResult;
                window.console.log('this.UIdata :'+this.UIdata);
                // 09-08-2020 : Make decision of hiding search form later
                //this.search=false;
                this.showLoading=false;
                //  09-08-2020 :  : Make decision of showing search result later
                //this.showAccounts = true;
                if(this.banFieldValue=='0'){
                    this.showNoResultAccount =true;
                }else{
                    this.showNoResultAccount=false;
                }

                // SKHAN - 08-18-2020 If result has only one record, redirect to PersonAccount record
                if (this.UIdata != null && this.UIdata.length == 1) {
                    this[NavigationMixin.Navigate]({
                        "type": "standard__webPage",
                        "attributes": {
                            "url": this.UIdata[0].urlPath
                        }
                    });
                }
                //  09-08-2020 :  : Search resulted in 0 or more than 1 record. So hide the search form and show
                // results table
                else {
                    //Show the results table
                    this.search=false;
                    this.showAccounts=true;
                }
            }
            else if (result.resultType == 'addresses') {

                console.log('In addresses:' + result.resultJSON);
                this.addressTitle = 'Search Result for ' + (this.addr1 != null?this.addr1:'') +  ' ' + (this.addr2 != null?this.addr2:'') + ' ' + (this.city != null?this.city:'') + ' ' + (this.state != null?this.state:'') + ' ' + (this.zip != null?this.zip:'');
                let addressResult = JSON.parse(result.resultJSON);
                console.log('after parse addresses');

                // resultJSON's addresses field hasthe list of addresses.
                this.AddressData = addressResult.addresses;
                window.console.log('this.AddressData :'+this.AddressData);
                this.search=false;
                this.showLoading=false;
                this.showAddresses = true;
                if(this.AddressData==null || this.AddressData.length == 0){
                    this.showNoResultAddress =true;
                }else{
                    this.showNoResultAddress=false;
                }
            }


        })
        .catch(error =>{
            window.console.log('This is error');
            this.UIdata=null;
            console.log(JSON.stringify(error,null,2));
            this.search=false;
            this.showLoading=false;
            this.showNoResultAccount = true;
            this.showAccounts = true;
        })
        window.console.log('banFieldValue :'+this.banFieldValue);
        window.console.log('ctnFieldValue :'+this.ctnFieldValue);
    }

    handleRowAction(event){
        console.log('row clicked');
        const row = event.detail.row;
        // clean allsearch variables
        this.reset();
        // search by addressId
        this.addressId = row.addressId;
        this.handleSearch();
    }

    handleRowActionAccount(event){
        console.log('row clicked');
        const row = event.detail.row;
        // clean allsearch variables
        this.reset();
        // search by ban
        this.banFieldValue = row.ban;
        this.acctTypeValue = row.accountType;
        this.handleSearch();
    }
}
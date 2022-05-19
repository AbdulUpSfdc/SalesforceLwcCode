/* ================================================
* @class name: BWC_CustomerSearchCalloutMockTest
* @author: Anshul Gupta
* @group: Customer Searccch
* @purpose: set Mock responses of the BWC_CustomerSearchCallout.
* @created date (mm/dd/yyyy) :  09/07/2020
================================================*/ 
@isTest
global with sharing class BWC_CustomerSearchMock implements HttpCalloutMock{
    
    //variable declaration    
    private Integer intStatusCode{get;set;}
    private String strNamedCredential{get; set;}
    private String searchType{get; set;}

    public BWC_CustomerSearchMock(){}
     /* ========================================================
    * @method name : BWC_CustomerSearchCalloutMockTest
    * @author : Anshul Gupta
    * @group : BWC
    * @purpose:  : Default Constructor.
    * @created date (mm/dd/yyyy) : 09/07/2020
    ============================================================*/  
    public BWC_CustomerSearchMock(Integer intStatusCode,String strNamedCredential,String searchType) {

        this.intStatusCode = intStatusCode;        
        this.strNamedCredential = strNamedCredential;
        this.searchType=searchType;

    }


     /* ========================================================
    * @method name : BWC_CustomerSearchCalloutMockTest
    * @author : Anshul Gupta
    * @group : BWC
    * @purpose:  : Default Constructor.
    * @created date (mm/dd/yyyy) : 09/07/2020
    ============================================================*/      
    global HTTPResponse respond(HTTPRequest objRequest){
        
        //variable Declaration
        HttpResponse objResponse;
        
        //Variable Initialization
        objResponse = new HttpResponse();
       
        // Create a mock response
        objResponse.setHeader('Content-Type', 'application/json');       
        
        //Creating mock for FDR Note call
        if (BWC_CONSTANTS.HTTP_STATUS_CODE_200 == intStatusCode && BWC_Constants.API_CUSTOMER_SEARCH == strNamedCredential){

            if (searchType==BWC_Constants.CS_BAN_WITH_ACCOUNT_TYPE) {
                objResponse.setBodyAsBlob([SELECT Body FROM StaticResource WHERE Name = 'BWC_CustomerSearchMock_Ban'].Body);
            }
            else if (searchType=='BanWithMultiple') {
                objResponse.setBodyAsBlob([SELECT Body FROM StaticResource WHERE Name = 'BWC_CustomerSearchMock_Ban2'].Body);
            }
            else if (searchType==BWC_Constants.CS_PHONE_NUMBER) {
                objResponse.setBody('[{"accountHeader":{"name":"ELVIS DIAZ MENDEZ","email":"qc_dummy@att.com","isEmployee":true,"primaryProduct":"WIRELESS"},"accountDetails":{"globalProfile":"ELVIS DIAZ MENDEZ","globalId":"534211605781","address":[{"type":"B","streetName1":"3900 GEORGE BUSBEE PKWY NW APT 407","locality":"KENNESAW","stateOrProvince":"GA","postcode":"30144-6677"}]},"accounts":[{"ban":"534211605781","accountType":"WIRELESS","address":[{"type":"B","streetName1":"3900 GEORGE BUSBEE PKWY NW APT 407","locality":"KENNESAW","stateOrProvince":"GA","postcode":"30144-6677"}],"accountStatus":"O","languagePreference":"EN","serviceStartDate":"07/22/2018","firstName":"ELVIS","lastName":"DIAZ MENDEZ","email":"qc_dummy@att.com","isEmployee":true,"customerId":"123","isPaperlessBill":false,"isPrepaidCustomer":false,"serviceDiscount":0,"securityLevel":"S","cpid":"534211605781"}]}]');  
            }
            else if (searchType==BWC_Constants.CS_USER_ID) {
                objResponse.setBody('[{"accountHeader":{"name":"ELVIS DIAZ MENDEZ","email":"qc_dummy@att.com","isEmployee":true,"primaryProduct":"WIRELESS"},"accountDetails":{"globalProfile":"ELVIS DIAZ MENDEZ","globalId":"534211605781","address":[{"type":"B","streetName1":"3900 GEORGE BUSBEE PKWY NW APT 407","locality":"KENNESAW","stateOrProvince":"GA","postcode":"30144-6677"}]},"accounts":[{"ban":"534211605781","accountType":"WIRELESS","address":[{"type":"B","streetName1":"3900 GEORGE BUSBEE PKWY NW APT 407","locality":"KENNESAW","stateOrProvince":"GA","postcode":"30144-6677"}],"accountStatus":"O","languagePreference":"EN","serviceStartDate":"07/22/2018","firstName":"ELVIS","lastName":"DIAZ MENDEZ","email":"qc_dummy@att.com","isEmployee":true,"customerId":"123","isPaperlessBill":false,"isPrepaidCustomer":false,"serviceDiscount":0,"securityLevel":"S","cpid":"534211605781"}]}]');  
            }
            else if(searchType==BWC_Constants.CS_ADDRESS_ID) {
                objResponse.setBody('[{"accountHeader":{"name":"ELVIS DIAZ MENDEZ","email":"qc_dummy@att.com","isEmployee":true,"primaryProduct":"WIRELESS"},"accountDetails":{"globalProfile":"ELVIS DIAZ MENDEZ","globalId":"534211605781","address":[{"type":"B","streetName1":"3900 GEORGE BUSBEE PKWY NW APT 407","locality":"KENNESAW","stateOrProvince":"GA","postcode":"30144-6677"}]},"accounts":[{"ban":"534211605781","accountType":"WIRELESS","address":[{"type":"B","streetName1":"3900 GEORGE BUSBEE PKWY NW APT 407","locality":"KENNESAW","stateOrProvince":"GA","postcode":"30144-6677"}],"accountStatus":"O","languagePreference":"EN","serviceStartDate":"07/22/2018","firstName":"ELVIS","lastName":"DIAZ MENDEZ","email":"qc_dummy@att.com","isEmployee":true,"customerId":"123","isPaperlessBill":false,"isPrepaidCustomer":false,"serviceDiscount":0,"securityLevel":"S","cpid":"534211605781"}]}]');  
            }
            else if(searchType==BWC_Constants.CS_ADDRESS_SEARCH) {
                objResponse.setBody('[{"accountHeader":{"name":"ELVIS DIAZ MENDEZ","email":"qc_dummy@att.com","isEmployee":true,"primaryProduct":"WIRELESS"},"accountDetails":{"globalProfile":"ELVIS DIAZ MENDEZ","globalId":"534211605781","address":[{"type":"B","streetName1":"3900 GEORGE BUSBEE PKWY NW APT 407","locality":"KENNESAW","stateOrProvince":"GA","postcode":"30144-6677"}]},"accounts":[{"ban":"534211605781","accountType":"WIRELESS","address":[{"type":"B","streetName1":"3900 GEORGE BUSBEE PKWY NW APT 407","locality":"KENNESAW","stateOrProvince":"GA","postcode":"30144-6677"}],"accountStatus":"O","languagePreference":"EN","serviceStartDate":"07/22/2018","firstName":"ELVIS","lastName":"DIAZ MENDEZ","email":"qc_dummy@att.com","isEmployee":true,"customerId":"123","isPaperlessBill":false,"isPrepaidCustomer":false,"serviceDiscount":0,"securityLevel":"S","cpid":"534211605781"}]}]');  
            }
        }
        else {
            objResponse.setStatusCode(BWC_CONSTANTS.HTTP_STATUS_CODE_404);
            objResponse.setBody(BWC_CONSTANTS.HTTP_ERROR_MESSAGE)    ;
        }
        
        objResponse.setStatusCode(intStatusCode);
        
        return objResponse;
    }

}
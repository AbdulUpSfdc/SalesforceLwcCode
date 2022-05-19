/*
    Class to Upsert in Account, Billing Account and Customer Account Relation using the following logic
        Create record in Billing Account Object
        Create Account - take the Account.ID field and pass it in Customer Account Relation Object (Customer__c)
        Create a Record in Customer Account Relation object (where Account ID = Customer __c)
*/
@RestResource(urlMapping='/CreateCustomerRecord')
global with sharing class BWCLM_CreateCustomerRecordCallIn {

    @HttpPost
    global static void doPost() {
        String responseJson;
        RestRequest req1 = RestContext.request;
        RestResponse res = RestContext.response;
        String reqJson = req1.requestBody.toString();
        Account account;
        Billing_Account__c ba;
        BWCLM_CreateCustomerRecord req;
        String personAcctId;
        try {
            if(String.isBlank(reqJson)){
                throw new BWCLM_Exception('Request JSON is empty ');
            }

            try {
                req = (BWCLM_CreateCustomerRecord)JSON.deserialize(reqJson, BWCLM_CreateCustomerRecord.class);
            }
            catch (System.JSONException e) {
                throw new BWCLM_Exception('Failed to deserialize requested Json.', e);
            }
//Updated check to lastName and BAN only. Removed firstName - 03/23/21
            if( String.isBlank(req.lastName)
            || String.isBlank(req.accountNumber_ban)){
                throw new BWCLM_Exception('Either BAN,LastName is empty ');
            }
// added conditons for CAR List
            list<Billing_Account__c> baLst;
            baLst = [SELECT id,First_Name__c,Last_Name__c
                            FROM Billing_Account__c
                            WHERE Billing_Account_Number__c=:req.accountNumber_ban
                            limit 1];

            List<Customer_Account_Relation__c> carLst;
            carLst =  [SELECT id, Billing_Account__r.Billing_Account_Number__c,
                        Billing_Account__r.Id,Customer__r.Id,Customer__r.FirstName,
                        Customer__r.LastName
                        FROM Customer_Account_Relation__c
                        WHERE Billing_Account__r.Billing_Account_Number__c=:req.accountNumber_ban
                        AND Customer__r.FirstName =: req.firstName
                        AND Customer__r.LastName =: req.lastName
                        limit 1];

            if(carLst.isEmpty() && baLst.isEmpty()){
                //everything need to create and insert
                account = createOrUpdatePersonAccount(req,null,true);
                ba = createOrUpdateBillingAccount(req,null,true);
                createOrUpdateRelationship(req,account.Id,ba.Id,null,true);
            }
            else if(carLst.isEmpty() && !baLst.isEmpty()){
                account = createOrUpdatePersonAccount(req,null,true);
                ba = createOrUpdateBillingAccount(req,baLst[0].Id,false);
                createOrUpdateRelationship(req,account.Id,ba.Id,null,true);
            }
            else {
                //Boolean isFound = false;
                //for(Customer_Account_Relation__c car :carLst){
                    //if(car.Customer__r.FirstName.equalsIgnoreCase(req.firstName)
                   //&& car.Customer__r.LastName.equalsIgnoreCase(req.lastName)){
                       // isFound = true;
                        //don't do anything just update and pass
                        account = createOrUpdatePersonAccount(req,carLst[0].Customer__r.Id,false);
                        ba = createOrUpdateBillingAccount(req,carLst[0].Billing_Account__r.Id,false);
                        createOrUpdateRelationship(req,account.Id,ba.Id,carLst[0].Id,false);
                    //}
                //}
                //if(!isFound){
                    //Need to create a new Person Account and link with existing Billing Account
                   // account = createOrUpdatePersonAccount(req,null,true);
                   // createOrUpdateRelationship(req,account.Id,carLst[0].Billing_Account__r.Id,null,true);
                //}
            }
            BWCLM_Exception.ResponseWrapper responseWrapper = new BWCLM_Exception.ResponseWrapper(true,account.Id,'');
            responseJson = JSON.serialize(responseWrapper);
            RestContext.response.responseBody = Blob.valueOf(responseJson);
            RestContext.response.statuscode = 200;
            //added line for JSON header response.03/23/21
            RestContext.response.addHeader('Content-Type','application/json');

        } catch (Exception e) {
            BWCLM_Exception.ResponseWrapper responseWrapper = new BWCLM_Exception.ResponseWrapper(false,'Exception',e.getMessage());
            responseJson = JSON.serialize(responseWrapper);
            RestContext.response.responseBody = Blob.valueOf(responseJson);
            //RestContext.response.statuscode = 404; */line commented out to provide correct error message to mulesoft */
            //added line for JSON header response.03/23/21
            RestContext.response.addHeader('Content-Type','application/json');
        }

    }

    /*
        InsertorUpdate for Insert=true for update=false (You have to pass the Id of record)
    */
    public static Account createOrUpdatePersonAccount(BWCLM_CreateCustomerRecord json,
                                        String acctId,Boolean InsertOrUpdate){
        Account acct;
        if(InsertOrUpdate){
            acct = new Account();
        } else {
            acct = new Account(Id=acctId);
        }
        acct.FirstName = json.firstName;
        acct.LastName = json.lastName;
        acct.MiddleName   = json.middleName;
        acct.PersonEmail = json.email;
        acct.AccessId__c = json.accessId; /*added new field*/
        acct.Primary_BAN__c = json.accountNumber_ban; /*added new field*/
        acct.External_Id__c = json.accountNumber_ban + 'WIRELESS'; //HARDCODING IT don't know
        acct.AccountSource = json.accountSource; /*added new field*/
        if(json.addresses !=null){
            for(BWCLM_CreateCustomerRecord.Addresses addr : json.addresses){
                if(addr.addressType == 'shipping'){
                    acct.ShippingStreet = BWC_Utils.appendString(addr.address1,addr.address2,', ');
                    acct.ShippingCity  = addr.city;
                    acct.ShippingPostalCode = BWC_Utils.appendString(addr.zip,addr.zipExtension,'-');
                    acct.ShippingStateCode = addr.state;
                    acct.ShippingCountryCode = addr.country;
                } else if(addr.addressType == 'billing'){
                    acct.BillingStreet = BWC_Utils.appendString(addr.address1,addr.address2,', ');
                    acct.BillingCity  = addr.city;
                    acct.BillingPostalCode = BWC_Utils.appendString(addr.zip,addr.zipExtension,'-');
                    acct.BillingStateCode = addr.state;
                    acct.BillingCountryCode = addr.country;
                } else if(addr.addressType == 'mailing'){
                    acct.PersonMailingStreet = BWC_Utils.appendString(addr.address1,addr.address2,', ');
                    acct.PersonMailingCity  = addr.city;
                    acct.PersonMailingPostalCode = BWC_Utils.appendString(addr.zip,addr.zipExtension,'-');
                    acct.PersonMailingStateCode = addr.state;
                    acct.PersonMailingCountryCode = addr.country;
                } else if(addr.addressType == 'other'){
                    acct.PersonOtherStreet = BWC_Utils.appendString(addr.address1,addr.address2,', ');
                    acct.PersonOtherCity  = addr.city;
                    acct.PersonOtherPostalCode = BWC_Utils.appendString(addr.zip,addr.zipExtension,'-');
                    acct.PersonOtherStateCode = addr.state;
                    acct.PersonOtherCountryCode = addr.country;
                }
            }
        }

        if(json.phonesNumbers !=null){
            for(BWCLM_CreateCustomerRecord.PhonesNumbers phone : json.phonesNumbers){
                if(phone.phoneType == 'home'){
                    acct.PersonHomePhone = phone.phoneNumber;
                } else if(phone.phoneType == 'cell'){
                    acct.Phone = phone.phoneNumber;
                } else if(phone.phoneType == 'mobile'){
                    acct.PersonMobilePhone = phone.phoneNumber;
                } else if(phone.phoneType == 'contact'){
                    acct.PersonOtherPhone = phone.phoneNumber;
                } else if(phone.phoneType == 'work'){
                    acct.PersonAssistantPhone = phone.phoneNumber;
                } else if(phone.phoneType == 'fax'){
                    acct.Fax = phone.phoneNumber;
                }
            }
        }

        if(InsertOrUpdate){
            Id paRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(BWC_Constants.PERSON_ACCOUNT).getRecordTypeId();
            acct.RecordTypeId = paRecordTypeId; // making account person account.
            insert acct;
        } else {
            update acct;
        }
        return acct;
    }

    /*
        InsertorUpdate for Insert=true for update=false (You have to pass the Id of record)
    */
    public Static Billing_Account__c createOrUpdateBillingAccount(BWCLM_CreateCustomerRecord json,
                                    String billAcctId,Boolean InsertOrUpdate){
        Billing_Account__c billAcct;
        if(InsertOrUpdate){
            billAcct = new Billing_Account__c();
        } else {
            billAcct = new Billing_Account__c(Id=billAcctId);
        }
        billAcct.Billing_Account_Number__c = json.accountNumber_ban;
        billAcct.Account_Status__c = json.accountStatus;
        billAcct.Billing_System__c = json.accountBillingSystem;
        billAcct.Account_Type__c = json.accountType;
        if(json.addresses !=null){
            for(BWCLM_CreateCustomerRecord.Addresses addr : json.addresses){
                if(addr.addressType == 'billing'){
                    billAcct.Billing_Address_Line_1__c = addr.address1;
                    billAcct.Billing_Address_Line_2__c  = addr.address2;
                    billAcct.Billing_City__c = addr.city;
                    billAcct.Billing_State__c = addr.state;
                    billAcct.Billing_Zipcode__c = addr.zip;
                    billAcct.Billing_Country__c = addr.country;
                }
            }
        }
        if(InsertOrUpdate){
            insert billAcct;
        } else {
            update billAcct;
        }

        return billAcct;
    }

    /*
        InsertorUpdate for Insert=true for update=false (You have to pass the Id of record)
    */
    public static String createOrUpdateRelationship(BWCLM_CreateCustomerRecord json,
            String acctId,String billAcctId,String relId,
            Boolean InsertOrUpdate){
        Customer_Account_Relation__c car;
        if(InsertOrUpdate){
            car = new Customer_Account_Relation__c();
        } else {
            car = new Customer_Account_Relation__c(Id=relId);
        }
        car.Billing_Account__c = billAcctId;
        car.Customer__c = acctId;
        if(json.firstName == json.accountFirstName
            && json.lastName == json.accountLastName){
            car.Role__c = 'Primary Account Owner';
        } else {
            car.Role__c = 'Subscriber';
        }
        if(InsertOrUpdate){
            insert car;
        } else {
            update car;
        }
        return car.Id;
    }
}
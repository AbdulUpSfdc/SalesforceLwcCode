/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-30-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   09-30-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public without sharing class SyncCaseWithAccount implements Queueable, Database.AllowsCallouts{ 
    //List<Case> casesToProcess;
     Set<ID> caseId_Set;
     List<ID> caseId_List;
     Map<String,String> productToCgProduct_Map{
        get{
            if(productToCgProduct_Map==null){
                cgMappingSelector();    
            }
            return productToCgProduct_Map;
        }
        set;
    }
    
    public SyncCaseWithAccount(){}
    public SyncCaseWithAccount(Set<ID> caseId_Set){
        //casesToProcess = new List<Case>();
        //this.caseId_Set = new Set<ID>();
        //this.caseId_Set = caseId_Set;
        this.caseId_List = new List<ID>();
        this.caseId_List.addAll(caseId_Set);
    }
    
    public void execute(QueueableContext context){
        if(caseId_List!=null && caseId_List.size()>0){
            Case currentCase = filterCase(caseId_List[0]);
            SearchParameters searchParameter;
            //for(Case currentCase : casesToProcess){
            // searchParameter = getParameters(currentCase);
            //callServiceHandler(searchParameter, currentCase);
            //}
            if(currentCase!=null){
                searchParameter = getParameters(currentCase);
                callServiceHandler(searchParameter, currentCase);
            }
            if(caseId_List.size()>1){
                caseId_List.remove(0);
                system.enqueueJob(new SyncCaseWithAccount(new Set<ID>(caseId_List)));    
            }
        }
    }
    /*public void test(){
SearchParameters searchParameter = new SearchParameters();
Case currentCase = new Case();
callServiceHandler(searchParameter, currentCase);

}*/
    
    //helper methods
    private Case filterCase(ID caseId){
        Case currentCase = [Select 
                            Billing_Account__c,
                            AccountIdentifier__c, 
                            RecordType.DeveloperName, 
                            Product__c, 
                            ServiceCustFirstName__c,
                            ServiceCustLastName__c,
                            StreetName__c,
                            City__c,
                            State__c,
                            Country__c,
                            ZipPostalCode__c,
                            BillingCustFirstName__c,
                            BillingCustLastName__c,
                            BillingState__c,
                            BillingStreet__c,
                            BillingCity__c,
                            BillingZip__c,
                            BillingCountry__c,
                            BillingEmail__c,
                            ServiceEmail__c,
                            BillingPhone__c,
                            ServicePhone__c,
                            FAN__c
                            From Case
                            Where ID = :caseId]; 
        if(currentCase.RecordType.DeveloperName == 'OOP'){
            return currentCase;
        } 
        return null;   
    }//filterCases
    
    private SearchParameters getParameters(Case currentCase){
        SearchParameters parameter = new SearchParameters();
        if(currentCase!=null && String.isNotBlank(currentCase.AccountIdentifier__c)){
            parameter.accountIdentifier = currentCase.AccountIdentifier__c;
            if(String.isNotBlank(currentCase.Product__c)){
                parameter.product = searchCgProduct(currentCase.Product__c);
            }else{
                parameter.product = getCgProduct(currentCase.AccountIdentifier__c);
            }
        }
        return parameter;
    }
    
    private String getCgProduct(String accountIdentifier){
        if(String.isNotBlank(accountIdentifier)){
            if(accountIdentifier.length()<=8){
                //return 'DTVS';
                return Label.ProductLength_8;
            }
            else if(accountIdentifier.length()==9){
                //return 'Uverse';
                return Label.ProductLength_9;
            }
            else if(accountIdentifier.length()==10 || accountIdentifier.length()==13){
                //return 'POTS';
                return Label.ProductLength_10;
            }
            else if(accountIdentifier.length()==12){
                //return 'WireLess';
                return Label.ProductLength_12;
            }
            else if(accountIdentifier.length()==15){
                //return 'HBOmax';
                return Label.ProductLength_15;
            }
        }
        return '--';
    }//getCgProduct
    
    public String getCgProductForRetry(String accountIdentifier){
        if(String.isNotBlank(accountIdentifier)){
            if(accountIdentifier.length()==9){
                //return 'Wireless';
                return Label.ProductLengthRetry_9;
            }
            else if(accountIdentifier.length()==15){
                //return 'DTVnow';
                return Label.ProductLengthRetry_15;
            }
        }
        return '--';
    }//getCgProductForRetry
    
    private String searchCgProduct(String product){
        List<String> productList = new List<String>();
        String cgProduct;
        if(String.isNotBlank(product) 
           && productToCgProduct_Map.size()>0){
               if(product.containsIgnoreCase(';')){
                   productList = product.split(';');
                   for(String currentProd : productList){
                       if(productToCgProduct_Map.containsKey(currentProd)){
                           cgProduct = productToCgProduct_Map.get(currentProd);
                           break;            
                       }                    
                   }//for ends..    
               }
               //else if(productToCgProduct_Map.containsKey(product.toLowerCase())){
               else if(productToCgProduct_Map.containsKey(product)){
                   cgProduct = productToCgProduct_Map.get(product);
               }
               if(String.isBlank(cgProduct)){
                   cgProduct='--';
               }
           }
        return cgProduct;
    }
    
    private void cgMappingSelector(){
        productToCgProduct_Map = new Map<String, String>();
        productToCgProduct_Map = MetadataSelector.customerToProduct_Map;
        system.debug('productToCgProduct_Map==>'+productToCgProduct_Map);
    }
    
    private void callServiceHandler(SearchParameters parameter, Case currentCase){
        system.debug('parameter==>'+parameter);
        system.debug('currentCase==>'+currentCase);

        // Do customer account search
        BWC_CustomerSearch.CustomerSearchRequest searchRequest = new BWC_CustomerSearch.CustomerSearchRequest();
        searchRequest.mode = 'banWithAccountType';
        searchRequest.ban = parameter.accountIdentifier;
        searchRequest.accountType = parameter.product;
        BWC_CustomerSearch.CustomerSearchResponse searchResponse = BWC_CustomerSearchService.accountSearch(currentCase.Id, searchRequest);
        System.debug('searchResponse: ' + JSON.serialize(searchResponse));

        if (searchResponse.accountResponses != null && !searchResponse.accountResponses.isEmpty()) {
            // One account found
            processCallout(searchResponse.accountResponses[0], currentCase, parameter);
        }
        else {
            // Retry with different product
            parameter.product = getCgProductForRetry(parameter.accountIdentifier);
            if(String.isNotBlank(parameter.product) && parameter.product!='--'){       
                searchRequest.ban = parameter.accountIdentifier;
                searchRequest.accountType = parameter.product;
                searchResponse = BWC_CustomerSearchService.accountSearch(currentCase.Id, searchRequest);
                if (searchResponse.accountResponses != null && !searchResponse.accountResponses.isEmpty()) {
                    processCallout(searchResponse.accountResponses[0], currentCase, parameter);
                }
            }
        }

    }//callServiceHandler

    private void processCallout(BWC_CustomerSearch.AccountResponse accountResponse, Case currentCase, SearchParameters parameter){

        String ban = accountResponse.accountHeader.ban;
        String accountId = accountResponse.accountId;

        if(ban!=null && accountId!=null){
            Customer_Account_Relation__c relationship = filterBillingAccount(ban, accountId);
            if(relationship!=null){
                currentCase.AccountId = accountId;
                populateCase(currentCase, relationship, parameter);
            }
            updateCase(currentCase,parameter, relationship);
        }
        
    }//ends processCallout

    public static 
    void updateCase(Case currentCase, SearchParameters parameter, Customer_Account_Relation__c relationship){
        try{
            update currentCase;
            if(parameter != NULL && parameter.product == 'uverse'){
                SyncCaseWithProducts sync = new SyncCaseWithProducts(currentCase.ID, relationship.Billing_Account__r.Billing_Account_Number__c);
                system.enqueueJob(sync);       
            }
        } catch(Exception ex) {
            BWC_ExceptionUtils.handleException(ex, true);
            System.debug('*** exception: ' + ex.getMessage());
            if(parameter.manualSearch) {
                String exceptionMessage = ex.getMessage();
                if(exceptionMessage.containsIgnoreCase('INSUFFICIENT_ACCESS_OR_READONLY')) {
                    // 'You cannot perform the specified action because you do not have sufficient permissions.'
                    throw new AuraHandledException(Label.Case_Insufficient_Access);   
                } else {
                    throw new AuraHandledException(ex.getMessage());
                }

            }
        }
    }
    
    public static 
    void populateCase(Case currentCase, Customer_Account_Relation__c relationship, SearchParameters parameter){
        if(!parameter.manualSearch) {
            if((relationship.Billing_Account__r.Last_Name__c!=currentCase.ServiceCustLastName__c) && (relationship.Billing_Account__r.Service_City__c != currentCase.City__c || relationship.Billing_Account__r.Service_Zipcode__c != currentCase.ZipPostalCode__c)){
                currentCase.AddressDifferent__c = true;
            } 
            
            //first name & last name...
            if(String.isBlank(currentCase.BillingCustFirstName__c)){
                currentCase.BillingCustFirstName__c = relationship.Billing_Account__r.First_Name__c;    
            }
            if(String.isBlank(currentCase.BillingCustLastName__c)){
                currentCase.BillingCustLastName__c = relationship.Billing_Account__r.Last_Name__c;    
            }
            if(String.isBlank(currentCase.ServiceCustFirstName__c)){
                currentCase.ServiceCustFirstName__c = relationship.Billing_Account__r.First_Name__c;    
            }
            if(String.isBlank(currentCase.ServiceCustLastName__c)){
                currentCase.ServiceCustLastName__c = relationship.Billing_Account__r.Last_Name__c;    
            }
            //first name & last name
    
            // address..
            if(String.isBlank(currentCase.BillingStreet__c)){
                String addressString = relationship.Billing_Account__r.Billing_Address_Line_1__c;
                if(String.isNotBlank(relationship.Billing_Account__r.Billing_Address_Line_2__c)) {
                    addressString += ' ' + relationship.Billing_Account__r.Billing_Address_Line_2__c;    
                }
                currentCase.BillingStreet__c = addressString;
            }
            if(String.isBlank(currentCase.BillingCity__c)){
                currentCase.BillingCity__c = relationship.Billing_Account__r.Billing_City__c;
            }
            if(String.isBlank(currentCase.BillingState__c)){
                currentCase.BillingState__c = MetadataSelector.stateCodeToName_Map.get(relationship.Billing_Account__r.Billing_State__c);        
            }
            if(String.isBlank(currentCase.BillingZip__c)){
                currentCase.BillingZip__c = relationship.Billing_Account__r.Billing_Zipcode__c;
            }
            if(String.isBlank(currentCase.BillingCountry__c)){
                currentCase.BillingCountry__c = 'United States';
            }
            if(String.isBlank(currentCase.StreetName__c)){
                String addressString = relationship.Billing_Account__r.Service_Address_Line_1__c;
                if(String.isNotBlank(relationship.Billing_Account__r.Service_Address_Line_2__c)) {
                    addressString += ' ' + relationship.Billing_Account__r.Service_Address_Line_2__c;    
                }
                currentCase.StreetName__c = addressString;
            }
            if(String.isBlank(currentCase.State__c)){
                currentCase.State__c = MetadataSelector.stateCodeToName_Map.get(relationship.Billing_Account__r.Service_State__c);
            }
            if(String.isBlank(currentCase.City__c)){
                currentCase.City__c = relationship.Billing_Account__r.Service_City__c;
            }
            
            if(String.isBlank(currentCase.State__c)){
                currentCase.State__c = MetadataSelector.stateCodeToName_Map.get(relationship.Billing_Account__r.Service_State__c);
            }
            if(String.isBlank(currentCase.ZipPostalCode__c)){
                currentCase.ZipPostalCode__c = relationship.Billing_Account__r.Service_Zipcode__c;
            }
            if(String.isBlank(currentCase.Country__c)){
                currentCase.Country__c = 'United States';
            }
            //address..
    
            //Emails..
            if(String.isBlank(currentCase.BillingEmail__c)){
                currentCase.BillingEmail__c= relationship.Billing_Account__r.Email__c;
            } 
            if(String.isBlank(currentCase.ServiceEmail__c)){
                currentCase.ServiceEmail__c = relationship.Billing_Account__r.Email__c; 
            }
            //Emails
    
            //Phone Details..
            if(currentCase.BillingPhone__c==null){
                currentCase.BillingPhone__c=relationship.Billing_Account__r.Contact_Number__c;
            }
            if(currentCase.ServicePhone__c==null){
                currentCase.ServicePhone__c=relationship.Billing_Account__r.Contact_Number__c;
            }
            //Phone Details...
            
            // FAN
            if(String.isBlank(currentCase.FAN__c)){
                currentCase.FAN__c = relationship.Billing_Account__r.FAN_Id__c;
            }
            system.debug('customer type==>'+relationship.Billing_Account__r.Customer_Type__c);
           /* if(String.isNotBlank(relationship.Billing_Account__r.Customer_Type__c) 
                && MetadataSelector.customerToCgCustomerMap!=null & MetadataSelector.customerToCgCustomerMap.containsKey(relationship.Billing_Account__r.Customer_Type__c)){
                //currentCase.CustomerType__c = MetadataSelector.customerToCgCustomerMap.get(relationship.Billing_Account__r.Customer_Type__c);
            }*/
            
        } else {
            // manual search
            currentCase.AddressDifferent__c = false;
            
            currentCase.BillingCustFirstName__c = relationship.Billing_Account__r.First_Name__c;    
            currentCase.BillingCustLastName__c = relationship.Billing_Account__r.Last_Name__c;    
            currentCase.ServiceCustFirstName__c = relationship.Billing_Account__r.First_Name__c;    
            currentCase.ServiceCustLastName__c = relationship.Billing_Account__r.Last_Name__c;
            
            String addressString = relationship.Billing_Account__r.Billing_Address_Line_1__c;
            if(String.isNotBlank(relationship.Billing_Account__r.Billing_Address_Line_2__c)) {
                addressString += ' ' + relationship.Billing_Account__r.Billing_Address_Line_2__c;    
            }
            currentCase.BillingStreet__c = addressString;
            currentCase.BillingCity__c = relationship.Billing_Account__r.Billing_City__c;
            currentCase.BillingState__c = MetadataSelector.stateCodeToName_Map.get(relationship.Billing_Account__r.Billing_State__c);        
            currentCase.BillingZip__c = relationship.Billing_Account__r.Billing_Zipcode__c;
            currentCase.BillingCountry__c = 'United States';

            addressString = relationship.Billing_Account__r.Service_Address_Line_1__c;
            if(String.isNotBlank(relationship.Billing_Account__r.Service_Address_Line_2__c)) {
                addressString += ' ' + relationship.Billing_Account__r.Service_Address_Line_2__c;    
            }
            currentCase.StreetName__c = addressString;
            currentCase.State__c = MetadataSelector.stateCodeToName_Map.get(relationship.Billing_Account__r.Service_State__c);
            currentCase.City__c = relationship.Billing_Account__r.Service_City__c;            
            currentCase.State__c = MetadataSelector.stateCodeToName_Map.get(relationship.Billing_Account__r.Service_State__c);
            currentCase.ZipPostalCode__c = relationship.Billing_Account__r.Service_Zipcode__c;
            currentCase.Country__c = 'United States';
            
            currentCase.BillingEmail__c= relationship.Billing_Account__r.Email__c;
            currentCase.ServiceEmail__c = relationship.Billing_Account__r.Email__c; 
            currentCase.BillingPhone__c=relationship.Billing_Account__r.Contact_Number__c;
            currentCase.ServicePhone__c=relationship.Billing_Account__r.Contact_Number__c;
            
            // FAN
            currentCase.FAN__c = relationship.Billing_Account__r.FAN_Id__c;
           /* if(String.isNotBlank(relationship.Billing_Account__r.Customer_Type__c) 
                && MetadataSelector.customerToCgCustomerMap!=null & MetadataSelector.customerToCgCustomerMap.containsKey(relationship.Billing_Account__r.Customer_Type__c)){
                //currentCase.CustomerType__c = MetadataSelector.customerToCgCustomerMap.get(relationship.Billing_Account__r.Customer_Type__c);
            }*/
        }
        
        //populate Billing account on Case # 3407
        currentCase.Billing_Account__c = relationship.Billing_Account__c;
        
        // for Wireless accounts only, copy Billing address to Service Address
        String theAccountType = relationship.Billing_Account__r.Account_Type__c;
        if(String.isNotBlank(theAccountType) && (theAccountType.equalsIgnoreCase('wireless') || theAccountType.equalsIgnoreCase('pots'))) {
            currentCase.ServiceCustFirstName__c = currentCase.BillingCustFirstName__c;
            currentCase.ServiceCustLastName__c = currentCase.BillingCustLastName__c;
            currentCase.StreetName__c = currentCase.BillingStreet__c;
            currentCase.State__c = currentCase.BillingState__c;
            currentCase.City__c = currentCase.BillingCity__c;           
            currentCase.State__c = currentCase.BillingState__c;
            currentCase.ZipPostalCode__c = currentCase.BillingZip__c;
            currentCase.Country__c = 'United States';
            currentCase.ServiceEmail__c = currentCase.BillingEmail__c; 
            currentCase.ServicePhone__c = currentCase.BillingPhone__c;
        }

        //system.debug('Product==> '+String.isBlank(currentCase.Product__c));
        //system.debug('Product Found==> '+!parameter.productFound);
        //system.debug('Billing Product==> '+relationship.Billing_Account__r.Product_Name_360__c);

        if(parameter!=null && parameter.product!='uverse'){
            if(String.isNotBlank(relationship.Billing_Account__r.Product_Name_360__c)){
                if(MetadataSelector.productValueSet.contains(relationship.Billing_Account__r.Product_Name_360__c)){
                    currentCase.Product__c = relationship.Billing_Account__r.Product_Name_360__c;    
                }
                else{
                    if(MetadataSelector.productToCgProduct_Map!=null 
                        && MetadataSelector.productToCgProduct_Map.size()>0 
                        && MetadataSelector.productToCgProduct_Map.containsKey(relationship.Billing_Account__r.Product_Name_360__c)){
                            String currentProduct = MetadataSelector.productToCgProduct_Map.get(relationship.Billing_Account__r.Product_Name_360__c);
                            currentCase.Product__c = currentProduct;    
                    }

                }
            }
        }
    }// method ends...
        
    public static
    Customer_Account_Relation__c filterBillingAccount(String ban, String accountId){
        List<Customer_Account_Relation__c> customerAccountRelation_List = [Select
                                                                           Billing_Account__c,
                                                                           Billing_Account__r.Product_Name_360__c,
                                                                           Billing_Account__r.Billing_Account_Number__c,
                                                                           Billing_Account__r.Last_Name__c,
                                                                           Billing_Account__r.First_Name__c,    
                                                                           Billing_Account__r.Billing_Address_Line_1__c,
                                                                           Billing_Account__r.Billing_Address_Line_2__c,
                                                                           Billing_Account__r.Billing_City__c,
                                                                           Billing_Account__r.Billing_State__c,
                                                                           Billing_Account__r.Billing_Zipcode__c,
                                                                           Billing_Account__r.Billing_Country__c,
                                                                           Billing_Account__r.Service_Address_Line_1__c,
                                                                           Billing_Account__r.Service_Address_Line_2__c,
                                                                           Billing_Account__r.Service_City__c,
                                                                           Billing_Account__r.Service_State__c,
                                                                           Billing_Account__r.Service_Zipcode__c,
                                                                           Billing_Account__r.Service_Country__c,
                                                                           Billing_Account__r.Contact_Number__c,
                                                                           Billing_Account__r.Email__c,
                                                                           Billing_Account__r.Account_Type__c,
                                                                           //Billing_Account__r.FAN_Number__c,
                                                                           Billing_Account__r.FAN_Id__c,
                                                                           Billing_Account__r.Customer_Type__c,
                                                                           Customer__c
                                                                           From Customer_Account_Relation__c
                                                                           Where Customer__c = :accountId
                                                                           And Billing_Account__r.Billing_Account_Number__c = :ban];
        if(customerAccountRelation_List.size()>0){
            return customerAccountRelation_List[0];
        }
        return null;                                                                            
    }
    
    // used by CaseCustomerSearchModalController lightning component
    // retrieve the Billing Account information via Customer_Account_Relation__c junction object
    @AuraEnabled public static
    List<Customer_Account_Relation__c> getBillingAccountInfo(String ban, String accountId) {
        System.debug('*** getBillingAccountInfo: ban ' + ban + ' accountId ' + accountId);
        List<Customer_Account_Relation__c> junctionList;
        
        if(String.isEmpty(ban)) {
            junctionList = [SELECT Billing_Account__c,
                           Billing_Account__r.Billing_Account_Number__c,
                           Billing_Account__r.First_Name__c,    
                           Billing_Account__r.Last_Name__c,
                           Billing_Account__r.Billing_Address_Line_1__c,
                           Billing_Account__r.Billing_Address_Line_2__c,
                           Billing_Account__r.Billing_City__c,
                           Billing_Account__r.Billing_State__c,
                           Billing_Account__r.Billing_Zipcode__c,
                           Billing_Account__r.Billing_Country__c,
                           Billing_Account__r.Service_Address_Line_1__c,
                           Billing_Account__r.Service_Address_Line_2__c,
                           Billing_Account__r.Service_City__c,
                           Billing_Account__r.Service_State__c,
                           Billing_Account__r.Service_Zipcode__c,
                           Billing_Account__r.Service_Country__c,
                           Billing_Account__r.Contact_Number__c,
                           Billing_Account__r.Email__c,
                           Billing_Account__r.Account_Type__c,
                           //Billing_Account__r.FAN_Number__c,
                           Billing_Account__r.FAN_Id__c
                           FROM Customer_Account_Relation__c
                           WHERE Customer__c = :accountId];
        } else {
            String searchBan = ban + '%';
            junctionList = [SELECT Billing_Account__c,
                           Billing_Account__r.Billing_Account_Number__c,
                           Billing_Account__r.First_Name__c,    
                           Billing_Account__r.Last_Name__c,
                           Billing_Account__r.Billing_Address_Line_1__c,
                           Billing_Account__r.Billing_Address_Line_2__c,
                           Billing_Account__r.Billing_City__c,
                           Billing_Account__r.Billing_State__c,
                           Billing_Account__r.Billing_Zipcode__c,
                           Billing_Account__r.Billing_Country__c,
                           Billing_Account__r.Service_Address_Line_1__c,
                           Billing_Account__r.Service_Address_Line_2__c,
                           Billing_Account__r.Service_City__c,
                           Billing_Account__r.Service_State__c,
                           Billing_Account__r.Service_Zipcode__c,
                           Billing_Account__r.Service_Country__c,
                           Billing_Account__r.Contact_Number__c,
                           Billing_Account__r.Email__c,
                           Billing_Account__r.Account_Type__c,
                           //Billing_Account__r.FAN_Number__c,
                           Billing_Account__r.FAN_Id__c
                           FROM Customer_Account_Relation__c
                           WHERE Customer__c = :accountId AND (Billing_Account__r.Billing_Account_Number__c = :ban OR Billing_Account__r.Billing_Account_Number__c LIKE :searchBan)];
        }
        
        return junctionList;
    }
    
    // used by CaseCustomerSearchModalController lightning component
    // update the Case with information from customer search
    @AuraEnabled public static 
    void updateCaseWithAccount(String caseId, String ban, String accountId, String searchProduct) {
        List<Case> cases = [SELECT BillingCustFirstName__c,
                            BillingCustLastName__c,
                            BillingStreet__c,
                            BillingCity__c,
                            BillingState__c,
                            BillingZip__c,
                            BillingCountry__c, 
                            BillingEmail__c,
                            ServiceCustFirstName__c,
                            ServiceCustLastName__c,
                            StreetName__c,
                            City__c,
                            State__c,
                            ZipPostalCode__c,
                            Country__c,
                            AddressDifferent__c,
                            Product__c,
                            AccountIdentifier__c,
                            ServiceEmail__c,
                            BillingPhone__c,
                            ServicePhone__c,
                            FAN__c,
                            Billing_Account__c,
                            AccountId FROM Case WHERE Id = :caseId LIMIT 1];
        if(cases.size() > 0) {
            Case currentCase = cases[0];
            
            SearchParameters searchParams = new SearchParameters();
            searchParams.product = searchProduct;
            searchParams.manualSearch = true;

            Customer_Account_Relation__c relationship = filterBillingAccount(ban, accountId); 
            if(relationship != null) {
                currentCase.AccountId = accountId;
                currentCase.AccountIdentifier__c = ban;
                populateCase(currentCase, relationship, searchParams);
            }
            
            updateCase(currentCase, searchParams, relationship);    
        }
    }
       
    public class SearchParameters{
        public String accountIdentifier;
        public String product;
        public String ctn='';
        public Boolean manualSearch;

        public SearchParameters(){
            manualSearch = false;
        }
    } 
}
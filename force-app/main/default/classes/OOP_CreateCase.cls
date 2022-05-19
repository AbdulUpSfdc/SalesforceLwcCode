public with sharing class OOP_CreateCase {

    @AuraEnabled
    public static Case createOOPCase(String billingAccountId) {        
        System.debug('###billingAccountId'+billingAccountId);
        
        //Check Billing Account Id exists
        if(String.isEmpty(billingAccountId)) {
            return null;
        }         
       try {
            //Create case - OOP
            Case oopCase = OOPCaseCreation(billingAccountId);
            return oopCase;
            }catch(Exception ex){
                System.debug(ex);
             AuraHandledException genericException=new AuraHandledException(ex.getDmlMessage(0)+'');
                genericException.setMessage(ex.getDmlMessage(0) +'');
                throw genericException;
        }
    }
    
    
    //Create Case - OOP method
    public static Case OOPCaseCreation(String billingAccountId) {        
        //Get Billing Account Info
        Billing_Account__c ba = getBillingAccount(billingAccountId);
        
        //System.debug('###ba '+ba );
        Case oopCase = new Case(); 
            if(ba != Null){ 
                // get OOP record type id
                String oopRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OOP').getRecordTypeId();
                
                // common oop case fields
                oopCase.Origin = 'Phone';
                oopCase.Status = 'New';  
                oopCase.Type = 'OOP';    
                oopCase.Priority = 'Medium';
                oopCase.SubmissionSourceCode__c = '2-Direct from Customer'; 
                oopCase.RecordTypeId = oopRecordTypeID;
                oopCase.Billing_Account__c = ba.Id;
                
                //get customer account relation record and assign account ID
                Customer_Account_Relation__c  custAcct = getCustomerAccountRelation(ba.Id);
                if(custAcct!=null){
                    oopCase.AccountId = custAcct.Customer__c;
                }
                
                //From Billing Account Fields
                oopCase.AccountIdentifier__c = ba.Billing_Account_Number__c;
                //oopCase.CustomerType__c = ba.Customer_Type__c; 
                /*
                if(String.isNotBlank(ba.Customer_Type__c) 
                    && MetadataSelector.customerToCgCustomerMap!=null & MetadataSelector.customerToCgCustomerMap.containsKey(ba.Customer_Type__c)){
                    oopCase.CustomerType__c = MetadataSelector.customerToCgCustomerMap.get(ba.Customer_Type__c);
                }*/
                
                oopCase.Subject = 'OOP case for BAN # '+ba.Billing_Account_Number__c ;
                
                oopCase.BillingCustFirstName__c = ba.First_Name__c;
                oopCase.BillingCustLastName__c = ba.Last_Name__c;
                oopCase.BillingEmail__c = ba.Email__c;
                oopCase.BillingPhone__c = ba.Contact_Number__c;
                
                oopCase.BillingStreet__c = ba.Billing_Address_Line_1__c;
                oopCase.BillingCity__c = ba.Billing_City__c;
                if(String.isNotBlank(ba.Billing_State__c)) {
                    oopCase.BillingState__c = stateNameFromStateCode(ba.Billing_State__c);
                }
                oopCase.BillingZip__c = ba.Billing_Zipcode__c;
                
                if(String.isNotBlank(ba.Billing_Country__c)) {
                    oopCase.BillingCountry__c = stateNameFromStateCode(ba.Billing_Country__c);
                }
                
                
                oopCase.ServiceCustFirstName__c = ba.First_Name__c;
                oopCase.ServiceCustLastName__c = ba.Last_Name__c;
                oopCase.ServicePhone__c = ba.Contact_Number__c;
                oopCase.ServiceEmail__c = ba.Email__c;
                
                oopCase.StreetName__c = ba.Service_Address_Line_1__c;
                oopCase.City__c = ba.Service_City__c;
                if(String.isNotBlank(ba.Service_State__c)) {
                    oopCase.State__c = stateNameFromStateCode(ba.Service_State__c);
                }
                
                if(String.isNotBlank(ba.Service_Country__c)) {
                    oopCase.Country__c= stateNameFromStateCode(ba.Service_Country__c);
                }
                
                if(String.isBlank(oopCase.Country__c)){
                    oopCase.Country__c='United States';  
                }    
                oopCase.ZipPostalCode__c = ba.Service_Zipcode__c;
                oopCase.FAN__c = ba.FAN_Number__c;
               
               
                //Check Account type and if Account type is uverse then populate PlanName, transport Type and Products 
                //if NOT uverse then only product will be populated 
                
                //Get CG Product mappings
                Map<String, String> productToCgProduct_Map  = new Map<String, String>();
                productToCgProduct_Map = MetadataSelector.productToCgProduct_Map;
                
                if(ba.Account_Type__c == 'Uverse'){
                    
                   
                    //retrieve plans
                    Map<Id,Plan__c> planMapRetrieved = getPlans(ba.Id);
                    
                    if(planMapretrieved.size()>0){
                        Set<String> prodNames = new Set<String>();
                        for(Plan__c p :planMapRetrieved.values()){
                            if(String.isNotBlank(p.Plan_Name__c)){
                                //assign plan name
                                oopCase.PlanName__c = p.Plan_Name__c;
                            }
                            if(String.isNotBlank(p.Transport_Type__c)){
                                //assign transport type
                                oopCase.TransportType__c = p.Transport_Type__c;
                            }
                            if(String.isNotBlank(p.Product__c)){
                                prodNames.add(p.Product__c);
                            }
                        }
                        
                        if(prodNames.size()>0 && productToCgProduct_Map.size()>0){
                            for(String prod:prodNames){
                                if(productToCgProduct_Map.containsKey(prod)){
                                    //assign products
                                    oopCase.Product__c = (String.isNotBlank(oopCase.Product__c)?oopCase.Product__c+';'+productToCgProduct_Map.get(prod):productToCgProduct_Map.get(prod));
                                }
                            }
                        }
                    }
                
                }
                else{
                    //product for non uverse type
                    //oopCase.Product__c = ba.Product_Name_360__c;                    
                    if(String.isNotBlank(ba.Product_Name_360__c)){
                        if(MetadataSelector.productValueSet.contains(ba.Product_Name_360__c)){
                            oopCase.Product__c = ba.Product_Name_360__c;    
                        }
                        else if(productToCgProduct_Map.size()>0 && productToCgProduct_Map.containsKey(ba.Product_Name_360__c)){
                                oopCase.Product__c = productToCgProduct_Map.get(ba.Product_Name_360__c);    
                        }
                    }
                }  
                
                //System.debug('###oopCase'+oopCase);
                insert  oopCase; 
               
                return oopCase;
            }
            else{
                return null;
            }    
    }
    
    //Get Billing Account Information   
    private static Billing_Account__c getBillingAccount(Id billAcctId){
        Billing_Account__c billAcct = [SELECT Id,FAN_Number__c,Name,Product_Name_360__c,Billing_Account_Number__c,First_Name__c,Last_Name__c,Email__c,Contact_Number__c,
                                       Customer_Type__c, Account_Type__c, 
                                       Billing_Address_Line_1__c,Billing_Address_Line_2__c,Billing_City__c,Billing_Country__c,Billing_State__c,Billing_Zipcode__c,
                                       Service_Address_Line_1__c,Service_Address_Line_2__c,Service_City__c,Service_Country__c,Service_State__c,Service_Zipcode__c 
                                       FROM Billing_Account__c 
                                       WHERE Id = :billAcctId WITH SECURITY_ENFORCED];
        
        return billAcct;
    }
    
    //Get Customer Account Relation for related Billing Account                
    private static Customer_Account_Relation__c  getCustomerAccountRelation(Id billAcctId){
        List<Customer_Account_Relation__c> CustAcctRel = [Select Id,Customer__c, Billing_Account__c 
                                                     FROM Customer_Account_Relation__c 
                                                     WHERE Billing_Account__c =:billAcctId WITH SECURITY_ENFORCED LIMIT 1];        
        
        return CustAcctRel.isEmpty() ? null : CustAcctRel[0];
    }
    
    //Get Plans for related Billing Account                 
    private static Map<Id,Plan__c> getPlans(Id billAcctId){
        Map<Id,Plan__c> planMap = new Map<Id,Plan__c>([Select 
                                                                    Id,Plan_Name__c,Transport_Type__c,Product__c,
                                                                     Billing_Account__c 
                                                                FROM Plan__c 
                                                                WHERE Billing_Account__c = :billAcctId WITH SECURITY_ENFORCED]);
    
        
        return planMap.isEmpty() ? null : planMap;
    }
    
    // state name from state code
    // can eventually be replaced with Metadata Selector
    private static String stateNameFromStateCode(String stateCode) {
        String stateName;

        State__mdt[] md = [SELECT State_Name__c FROM State__mdt WHERE StateCodes__c = :stateCode WITH SECURITY_ENFORCED LIMIT 1];
        if(!md.IsEmpty()) {
            stateName = md[0].State_Name__c;
        }

        return stateName;
    }
    

      
}
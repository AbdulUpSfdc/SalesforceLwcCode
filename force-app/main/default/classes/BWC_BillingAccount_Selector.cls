/* ================================================
* @class name: BWC_BillingAccount_Selector
* @author: Salesforce Inc.
* @purpose: Selector layer apex class
* @created date (mm/dd/yyyy) :  03/23/2021
================================================*/ 
public inherited sharing class BWC_BillingAccount_Selector {

    public static Billing_Account__c getBillingAccountFromAcctIdentifier(String billingacctNumber){
        
        List<Billing_Account__c> getBillAccts = [
                      SELECT id , Billing_Account_Number__c 
                      FROM Billing_Account__c
                      WHERE Billing_Account_Number__c = :billingacctNumber
                      WITH SECURITY_ENFORCED
                      LIMIT 1];
        System.debug('getBillAccts ' + getBillAccts.size());
        return (getBillAccts.size()>0)?getBillAccts[0]:null;         
    }
    
    
    
    //Get Map of Billing Accounts Information   
    public static Map<Id,Billing_Account__c> getBillingAccounts(Set<Id> billAcctIds){
        Map<Id,Billing_Account__c> billAccts = new Map<Id,Billing_Account__c>([SELECT Id,FAN_Number__c,Name,Product_Name_360__c,Billing_Account_Number__c,First_Name__c,Last_Name__c,Email__c,Contact_Number__c,
                                                                               Customer_Type__c, Account_Type__c, Billing_Market__c,
                                                                               Billing_Address_Line_1__c,Billing_Address_Line_2__c,Billing_City__c,Billing_Country__c,Billing_State__c,Billing_Zipcode__c,
                                                                               Service_Address_Line_1__c,Service_Address_Line_2__c,Service_City__c,Service_Country__c,Service_State__c,Service_Zipcode__c 
                                                                               FROM Billing_Account__c 
                                                                               WHERE Id IN :billAcctIds
                                                                               WITH SECURITY_ENFORCED]);
                                                    
        return billAccts;
    }

}
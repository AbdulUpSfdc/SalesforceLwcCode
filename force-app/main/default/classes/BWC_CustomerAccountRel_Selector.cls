/* ================================================
* @class name: BWC_CustomerAccountRel_Selector
* @author: Salesforce Inc.
* @purpose: Selector layer apex class
* @created date (mm/dd/yyyy) :  06/02/2021
================================================*/ 
public inherited sharing class BWC_CustomerAccountRel_Selector{

        
    //Get Map of Customer Account Relation based on billing account Ids   
    public static Map<Id,Customer_Account_Relation__c>  getCustomerAccountRelation(Set<Id> billAcctIds){
        Map<Id,Customer_Account_Relation__c> custAcctRel = new Map<Id,Customer_Account_Relation__c>([Select Id,Customer__c, Billing_Account__c,CreatedDate 
                                                                                                     FROM Customer_Account_Relation__c 
                                                                                                     WHERE Billing_Account__c IN :billAcctIds AND Customer__c != null 
                                                                                                     ORDER BY CreatedDate DESC]);        
                                                    
        return custAcctRel;
    }

}
@isTest 
private class BWC_BillingAccount_SelectorTest{

    @TestSetup
    static void makeData(){
        Billing_Account__c  objBillAcc=new Billing_Account__c ();
        objBillAcc.Product_Name_360__c='Wireless';
        objBillAcc.Billing_Account_Number__c='331525754';
        objBillAcc.Billing_Address_Line_1__c='8600 FM 2451';
        objBillAcc.Billing_City__c='NEW BERLIN';
        objBillAcc.Billing_State__c='FL';
        objBillAcc.Billing_Zipcode__c='32901-8117';
        objBillAcc.Service_Address_Line_1__c='8600 FM 2451';
        objBillAcc.Service_Address_Line_2__c='3392 FAN PALM BLVD';
        objBillAcc.Service_City__c='NEW BERLIN';
        objBillAcc.Service_State__c='FL';
        objBillAcc.Service_Zipcode__c ='32901-8117';
        objBillAcc.First_Name__c='test';
        objBillAcc.Last_Name__c='test';
        objBillAcc.Contact_Number__c='1234567890';
        objBillAcc.Email__c='test@gmail.com';
        objBillAcc.Service_Country__c='United States';
        objBillAcc.Billing_Country__c='United States';
        objBillAcc.Account_Type__c = 'Uverse';
        insert objBillAcc;

        Plan__c plan = new Plan__c();
        plan.Plan_Name__c = 'Test plan';
        plan.Transport_Type__c = 'Test transport';
        plan.Product__c = 'wireless';
        plan.Account_Type__c = 'Uverse';
        plan.Billing_Account__c = objBillAcc.Id;
        insert plan;

    }

    static testMethod void validateBillingAccount() {
         BWC_BillingAccount_Selector.getBillingAccountFromAcctIdentifier('331525754');
       
    }
    
    static testMethod void validategetBillingAccts() {
         Billing_Account__c ba = [Select Id from Billing_Account__c LIMIT 1];   
         Set<Id> baSet = new Set<Id>();
         baSet.add(ba.Id);
         BWC_BillingAccount_Selector.getBillingAccounts(baSet);
       
    }
    
}
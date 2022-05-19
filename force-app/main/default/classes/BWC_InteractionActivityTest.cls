@isTest
public with sharing class BWC_InteractionActivityTest {
    private static final String EQUIPMENT_REPLACEMENT_OPTIONS_ACTION = 'Equipment | Replacement options';
    private static final String ACCOUNT_INQUIRY_TYPE = 'Account Inquiry';
    
    static testMethod void testCreateInteractionActivity() {
        Account acct = BWC_TestDataFactory.createAccount();
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acct);
        Billing_Account__c billAcct = BWC_TestDataFactory.createBillingAccount('Wireless', acct);
        billAcct.Billing_Account_Number__c = '325310161';
        update billAcct;
        Test.startTest(); 
        BWC_InteractionActivity.createInteractionActivity(interaction.Id, EQUIPMENT_REPLACEMENT_OPTIONS_ACTION, '{"amountDueMsg":["",""],"amtDue":"117.59","ban":"325310161","billCycle":"29th to 28th","lastPayment":"0.00","paperlessBill":"Enrolled","pastDue":"78.23","service":"wireless","serviceLabel":"Wireless"}');
        BWC_InteractionActivity.createInteractionActivity(interaction.Id, '', '');
        Test.stopTest();
        
        Interaction_Activity__c ia = [SELECT Id,Type__c,Customer__c FROM Interaction_Activity__c WHERE Interaction__c = :interaction.Id LIMIT 1];
        System.assertEquals(ACCOUNT_INQUIRY_TYPE, ia.Type__c, 'Unexpected Type__c in Interaction Activity');
        System.assertEquals(acct.Id, ia.Customer__c, 'Unexpected Customer__c in Interaction Activity');
    }
    
    static testMethod void testGetInteractionActivities() {
        
        Account acct = BWC_TestDataFactory.createAccount();
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acct);
        Billing_Account__c billAcct = BWC_TestDataFactory.createBillingAccount('Wireless', acct);
        billAcct.Billing_Account_Number__c = '325310161';
        update billAcct;
        BWC_InteractionActivity.createInteractionActivity(interaction.Id, EQUIPMENT_REPLACEMENT_OPTIONS_ACTION, '{"amountDueMsg":["",""],"amtDue":"117.59","ban":"325310161","billCycle":"29th to 28th","lastPayment":"0.00","paperlessBill":"Enrolled","pastDue":"78.23","service":"wireless","serviceLabel":"Wireless"}');
        
        Test.startTest(); 
        
        List<Interaction_Activity__c> activities = BWC_InteractionActivity.getInteractionActivities(interaction.Id);
        
        Test.stopTest();
        
        System.assertEquals(1, activities.size());
        
    }
    
    static testMethod void testGetInteractionId() {
        
        Account acct = BWC_TestDataFactory.createAccount();
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acct);
        
        Test.startTest(); 
        
        String interactionId2 = BWC_InteractionActivity.getInteractionId(interaction.Id);
        
        Test.stopTest();
        
        System.assertEquals(interaction.Id, interactionId2);
        
    }
    
    static testMethod void testGetInteractionActivityTypes() {
        
        Test.startTest(); 
        
        Map<String, String> result = BWC_InteractionActivity.getInteractionActivityTypes();
        
        Test.stopTest();
        
        System.assertEquals(Interaction_Activity__c.Type__c.getDescribe().getPicklistValues().size(), result.size());
        
    }
    
    static testMethod void testCreateEscalationCase() {
        Account acct = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcct = BWC_TestDataFactory.createBillingAccount('Wireless', acct);
        Plan__c plans = BWC_TestDataFactory.createPlan('Wireless', billAcct);
        Asset asset = BWC_TestDataFactory.createEquipment('Wireless',acct, billAcct, null);
        List<Account> lstOfAccount =new List<Account>();
        
        lstOfAccount.add(new Account(name='Inquiry'));
        lstOfAccount.add(new Account(name='Payment'));
        insert lstOfAccount;
        
        List<Entitlement> lstOfEntitlement=new List<Entitlement>();
        
        lstOfEntitlement.add(new Entitlement(Name='Billing Inquiry',AccountId=lstOfAccount[0].id));
        lstOfEntitlement.add(new Entitlement(Name='Billing Payment',AccountId=lstOfAccount[1].id));
        
        insert lstOfEntitlement;
        //  billAcct.Billing_Account_Number__c = '287273122837';
        
        //   update billAcct;
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acct);
        
        String ecType = 'Billing';
        String ecFeature = 'Inquiry';
        String detailRecord = '{"ban":"423432423"}';
        
        Test.startTest();
        string escalationCaseId = BWC_InteractionActivity.createEscalationCase(interaction.Id, ecType, ecFeature, detailRecord);
        Test.stopTest();
        
        //List<Case> caseList = [SELECT Id,CaseCategory__c FROM Case WHERE Id = :escalationCaseId];
        //System.assert(caseList.size() > 0, 'Failed to create Escalation Case');
        //System.assertEquals('Escalation', caseList[0].CaseCategory__c, 'Incorrect Case Category for Escalation Case');
        
    }
    
    @isTest
    static void testCreateBillingAdjustmentEscalationCase() {
        Employee__c emp = BWC_TestDataFactory.createEmployee();
        emp.User__c = UserInfo.getUserId();
        emp.Organization__c  = 'Centers';
        emp.Channel1__c = 'Collections';
        emp.Sub_Channel__c = 'Collections';
        emp.EmployeeId__c = 'tt1234';
        insert emp;
        
        Account acct = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcct = BWC_TestDataFactory.createBillingAccount('Wireless', acct);
        Map<Id,Billing_Account__c> billAcctDetailsMap = BWC_BillingAccount_Selector.getBillingAccounts(New Set<Id>{billAcct.Id});
        String billAcctNum = billAcctDetailsMap.get(billAcct.Id).Billing_Account_Number__c;
        Plan__c plans = BWC_TestDataFactory.createPlan('Wireless', billAcct);
        Asset asset = BWC_TestDataFactory.createEquipment('Wireless',acct, billAcct, null);       
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acct);
        
        String ecType = 'Billing';
        //String ecFeature = 'Adjustment';
        String ecFeature = 'Inquiry';
        //String detailRecord = '{"ban":"#BAN#","paymentDate":"2021-09-22","paymentAmount":"500","paymentMethod":"CREDITCARD","paymentMethodLastFour":"1111","paymentType":"Online","paymentCategoryType":"Online","paymentStatus":"Complete","confirmationNumber":"12235675","methodTypeLabel":"Something","caseAction":"Goodwill","Type":"Billing","adjustmentData":{"adjType":"Goodwill","adjReasonExplanationCode":"Some Code","adjReasonDescription":"deascriptionData","adjReasonSystemCode":"magenta","adjComments":"stuff about test data"},"cdeData":{"overallCDEStatus":"something","cdeApprovedAmount":"5.00","cdeReasonForAgent":"something","cdeReasonForCustomer":"reason data","cdeRecommendationStatus":"Approved with Conditions","isCustomerAccepted":"true","overrideEscalate":"Override","overrideEscalateBy":"Anshul","cdeProductLevelId":"L5000"},"billData":{"billDate":"1995-12-17T09:24:00.000Z","billSequenceNumber":"1234","chargeCode":"chargeCodeData","chargeType":"Goodwill","chargeSequenceNumber":"241533","chargeDescription":"chargeDescriptionData","chargeAmount":"7500.00","requestAmount":"8500.00","agentAdjustedAmount":"3400"},"lineItemDataList":[{"billDate":"1995-12-17T09:24:00.000Z","billSequenceNumber":"1234","chargeCode":"chargeCodeData","chargeType":"Goodwill","chargeDescription":"chargeDescriptionData","chargeSequenceNumber":"241542","chargeAmount":"7510.00","requestAmount":"8200.00","agentAdjustedAmount":"3800"},{"billDate":"1995-12-17T09:24:00.000Z","billSequenceNumber":"124534","chargeCode":"chargeCodeDataNum2","chargeType":"Goodwill","chargeDescription":"chargeDescriptionDataNum2","chargeSequenceNumber":"331533","chargeAmount":"75090.00","requestAmount":"24336.00","agentAdjustedAmount":"33633"}]}';
        String detailRecord = '{"ban":"#BAN#","paymentDate":"2021-09-22","paymentAmount":"500","paymentMethod":"CREDITCARD","paymentMethodLastFour":"1111","paymentType":"Online","paymentCategoryType":"Online","paymentStatus":"Complete","confirmationNumber":"12235675","methodTypeLabel":"Something","caseAction":"Bill Image - Delayed Bill","Type":"Billing","adjustmentData":{"adjType":"Goodwill","adjReasonExplanationCode":"Some Code","adjReasonDescription":"deascriptionData","adjReasonSystemCode":"magenta","adjComments":"stuff about test data"},"cdeData":{"overallCDEStatus":"something","cdeApprovedAmount":"5.00","cdeReasonForAgent":"something","cdeReasonForCustomer":"reason data","cdeRecommendationStatus":"Approved with Conditions","isCustomerAccepted":"true","overrideEscalate":"Override","overrideEscalateBy":"Anshul","cdeProductLevelId":"L5000"},"billData":{"billDate":"1995-12-17T09:24:00.000Z","billSequenceNumber":"1234","chargeCode":"chargeCodeData","chargeType":"Goodwill","chargeSequenceNumber":"241533","chargeDescription":"chargeDescriptionData","chargeAmount":"7500.00","requestAmount":"8500.00","agentAdjustedAmount":"3400"},"lineItemDataList":[{"billDate":"1995-12-17T09:24:00.000Z","billSequenceNumber":"1234","chargeCode":"chargeCodeData","chargeType":"Goodwill","chargeDescription":"chargeDescriptionData","chargeSequenceNumber":"241542","chargeAmount":"7510.00","requestAmount":"8200.00","agentAdjustedAmount":"3800"},{"billDate":"1995-12-17T09:24:00.000Z","billSequenceNumber":"124534","chargeCode":"chargeCodeDataNum2","chargeType":"Goodwill","chargeDescription":"chargeDescriptionDataNum2","chargeSequenceNumber":"331533","chargeAmount":"75090.00","requestAmount":"24336.00","agentAdjustedAmount":"33633"}]}';          
        detailRecord = detailRecord.replace('#BAN#', billAcctNum);
        Test.startTest();
        string escalationCaseId = BWC_InteractionActivity.createEscalationCase(interaction.Id, ecType, ecFeature, detailRecord);
        Test.stopTest();
        
        /*List<Case> caseList = [SELECT Id,CaseCategory__c FROM Case WHERE Id = :escalationCaseId];
        System.assert(caseList.size() > 0, 'Failed to create Escalation Case');*/
        
    }
    
    static testMethod void testGetInteractionRecord() {
        
        Account acct = BWC_TestDataFactory.createAccount();
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acct);
        
        Test.startTest();
        Interaction__c interac = BWC_InteractionActivity.getInteractionRecord(interaction.Id);
        Test.stopTest();
        
    }
    
    
}
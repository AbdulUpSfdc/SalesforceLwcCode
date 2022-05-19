@isTest
public class BWC_CaseEmailAlertsUtility_Test{
    public static final string escalatedRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(BWC_Constants.CASERECORDTYPE_ESCALATION).getRecordTypeId();
    @testsetup static void createtestData(){
        Account testAccount1 = BWC_TestDataFactory.createAccount();
        Account testAccount2 = BWC_TestDataFactory.createAccount();

        System.runAs(new User(Id = UserInfo.getUserId())) {
            EmailTemplate template = new EmailTemplate(Name = 'Case Close Resolution Corrected ATT English', DeveloperName = 'Case_Close_Resolution_Corrected_ATT_English', FolderId = UserInfo.getUserId(), TemplateType = 'text', isActive = true);
            insert template;
        }
       
        Communication_Template_Mapping__c templateMapping1 = BWC_TestDataFactory.customTemplateMapping(BWC_Constants.CASEACTION_DIGITAL_PAYMENT,BWC_Constants.COMMUNICATIONTYPE_NEWCASE,'','',BWC_Constants.LANGUAGE_ENGLISH);
        templateMapping1.SMS_Template_Unique_Name__c = BWC_Constants.CTM_SMS_TEMPLATE;
        insert templateMapping1;
        Communication_Template_Mapping__c templateMapping2 = BWC_TestDataFactory.customTemplateMapping(BWC_Constants.CASEACTION_OVERPAYMENT,BWC_Constants.COMMUNICATIONTYPE_CASECLOSED,BWC_Constants.CASERESOLUTION_CORRECTED,BWC_Constants.CASERESOLUTION2_PRICING,BWC_Constants.LANGUAGE_SPANISH);
        templateMapping2.SMS_Template_Unique_Name__c = BWC_Constants.CTM_SMS_TEMPLATE;
        insert templateMapping2;
        Communication_Template_Mapping__c templateMapping3 = BWC_TestDataFactory.customTemplateMapping(BWC_Constants.CASEACTION_OVERPAYMENT,BWC_Constants.COMMUNICATIONTYPE_EMV,'','',BWC_Constants.LANGUAGE_SPANISH);
        templateMapping3.SMS_Template_Unique_Name__c = BWC_Constants.CTM_SMS_TEMPLATE;
        insert templateMapping3;
        Communication_Template_Mapping__c templateMapping4 = BWC_TestDataFactory.customTemplateMapping(BWC_Constants.CASEACTION_DELAYED_BILL,BWC_Constants.COMMUNICATIONTYPE_CASECLOSED,BWC_Constants.CASERESOLUTION_CORRECTED,null,BWC_Constants.LANGUAGE_SPANISH);
        templateMapping4.SMS_Template_Unique_Name__c = BWC_Constants.CTM_SMS_TEMPLATE;
        insert templateMapping4;
       
        Billing_Account__c billAcctObj1 = BWC_TestDataFactory.createUniqueBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless,testAccount1,'12345',BWC_Constants.LANGUAGE_ENGLISH);
        Billing_Account__c billAcctObj2 = BWC_TestDataFactory.createUniqueBillingAccount(BWC_Constants.BillingAccount_AccountType_Internet,testAccount2,'54321',BWC_Constants.LANGUAGE_SPANISH);
        Billing_Account__c billAcctObj3 = BWC_TestDataFactory.createUniqueBillingAccount(BWC_Constants.BillingAccount_AccountType_Internet,testAccount2,'5432178',BWC_Constants.LANGUAGE_SPANISH);
        Billing_Account__c billAcctObj4 = BWC_TestDataFactory.createUniqueBillingAccount(BWC_Constants.BillingAccount_AccountType_Internet,testAccount1,'5432123',BWC_Constants.LANGUAGE_SPANISH);
        
        Account acc1 = [select Id,PersonContactId from Account where id =: testAccount1.Id];
        Account acc2 = [select Id,PersonContactId from Account where id =: testAccount2.Id];
       
        Case caseRec1 = BWC_TestDataFactory.createEscalatedCase(acc1,billAcctObj1,acc1.PersonContactId);
        insert caseRec1;
        Case caseRec2 = BWC_TestDataFactory.createEscalatedCase(acc2,billAcctObj2,acc2.PersonContactId);
        insert caseRec2;
        Case caseRec3 = BWC_TestDataFactory.createEscalatedCase(acc1,billAcctObj3,acc1.PersonContactId);
        caseRec3.Type = BWC_Constants.CASETYPE_BILING_INQUIRY;
        caseRec3.caseAction__c = BWC_Constants.CASEACTION_DELAYED_BILL;
        insert caseRec3;
        Case caseRec4 = BWC_TestDataFactory.createEscalatedCase(acc1,billAcctObj4,acc2.PersonContactId);
        caseRec4.Type = BWC_Constants.CASETYPE_BILING_PAYMENT;
        caseRec4.caseAction__c = BWC_Constants.CASEACTION_OVERPAYMENT;
        insert caseRec4;
    }
    @istest static void updateActionTestMethod(){
        case caseRecord = [select Id,Type,caseAction__c,Account.PersonContactId from case where Billing_Account__r.Language_Preference__c =:BWC_Constants.LANGUAGE_ENGLISH LIMIT 1];    
        caseRecord.Status = BWC_Constants.CASESTATUS_NEW;
        test.startTest();
        update caseRecord;
        BWC_CaseEmailAlertsUtility.sendEmailFromCase(new List<Case>{caseRecord},null);
        //system.assertEquals(BWC_Constants.CASEACTION_DIGITAL_PAYMENT, [Select RecordType.DeveloperName,caseAction__c From Case Where ID = :caseRecord.Id].caseAction__c);
        test.stopTest();
    }
    @istest static void updateActionTestMethodforSMS(){
        case caseRecord = [select Id,Type,caseAction__c,Account.PersonContactId ,Billing_Account__c from case where caseAction__c=null and Status =: BWC_Constants.CASESTATUS_NEW and Billing_Account__r.Language_Preference__c =:BWC_Constants.LANGUAGE_ENGLISH LIMIT 1];    
        Billing_Account__c testAccount = [Select Id,Email__c, Contact_Number__c from Billing_Account__c where Id =: caseRecord.Billing_Account__c ];
        testAccount.Email__c = null;
        testAccount.Contact_Number__c = BWC_Constants.TEST_CONTACT_NUMBER;
        update testAccount;
        caseRecord.Type = BWC_Constants.CASETYPE_SERVICES_INQUIRY;
        caseRecord.caseAction__c = BWC_Constants.CASEACTION_DIGITAL_PAYMENT;
        test.startTest();
        update caseRecord;
        BWC_CaseEmailAlertsUtility.sendEmailFromCase(new List<Case>{caseRecord},null);
        system.assertEquals(BWC_Constants.CASEACTION_DIGITAL_PAYMENT, [Select RecordType.DeveloperName,caseAction__c From Case Where ID = :caseRecord.Id].caseAction__c);
        test.stopTest();
    }
    @istest static void updateMilestoneViolatedTestMethod(){
        case caseRecord = [select Id,Type,caseAction__c from case where Status =: BWC_Constants.CASESTATUS_NEW and caseAction__c = :BWC_Constants.CASEACTION_OVERPAYMENT LIMIT 1];    
        caseRecord.External_SLA_Violated__c = system.now();
        caseRecord.Status = BWC_Constants.CASESTATUS_IN_PROGRESS;
        update caseRecord;  
        BWC_CaseEmailAlertsUtility.sendEmailFromCase(new List<Case>{caseRecord},null);
    }
    @istest static void updateClosedTestMethod(){
        case caseRecord = [select Id,Type,caseAction__c from case where Status =: BWC_Constants.CASESTATUS_NEW and Billing_Account__r.Language_Preference__c =:BWC_Constants.LANGUAGE_SPANISH LIMIT 1];    
        caseRecord.Resolution__c = BWC_Constants.CASERESOLUTION_CORRECTED;
        caseRecord.Resolution2__c = BWC_Constants.CASERESOLUTION2_PRICING;
        caseRecord.CloseNotes__c = BWC_Constants.CASECLOSENOTE;
        caseRecord.status = BWC_Constants.CASESTATUS_CLOSED;
        update caseRecord;
        BWC_CaseEmailAlertsUtility.sendEmailFromCase(new List<Case>{caseRecord},null);
    }
    @istest static void updateClosedWithoutResolution2TestMethod(){
        case caseRecord = [select Id,Type,caseAction__c from case where Status =: BWC_Constants.CASESTATUS_NEW and caseAction__c = :BWC_Constants.CASEACTION_DELAYED_BILL LIMIT 1];    
        caseRecord.Resolution__c = BWC_Constants.CASERESOLUTION_CORRECTED;
        caseRecord.CloseNotes__c = BWC_Constants.CASECLOSENOTE;
        caseRecord.status = BWC_Constants.CASESTATUS_CLOSED;
        update caseRecord;
        BWC_CaseEmailAlertsUtility.sendEmailFromCase(new List<Case>{caseRecord},null);
    }
    @istest static void updateClosedTestMethodforSMS(){
        case caseRecord = [select Id,Type,caseAction__c,Account.PersonContactId ,Billing_Account__c from case where Status =: BWC_Constants.CASESTATUS_NEW and caseAction__c =:BWC_Constants.CASEACTION_OVERPAYMENT LIMIT 1];    
        Billing_Account__c testAccount = [Select Id,Email__c, Contact_Number__c from Billing_Account__c where Id =: caseRecord.Billing_Account__c ];
        testAccount.Email__c = null;
        testAccount.Contact_Number__c = BWC_Constants.TEST_CONTACT_NUMBER;
        update testAccount;
        caseRecord.Resolution__c = BWC_Constants.CASERESOLUTION_CORRECTED;
        caseRecord.Resolution2__c = BWC_Constants.CASERESOLUTION2_PRICING;
        caseRecord.CloseNotes__c = BWC_Constants.CASECLOSENOTE;
        caseRecord.status = BWC_Constants.CASESTATUS_CLOSED;
        test.startTest();
        update caseRecord;
        BWC_CaseEmailAlertsUtility.sendEmailFromCase(new List<Case>{caseRecord},null);
        system.assertEquals(BWC_Constants.CASERESOLUTION_CORRECTED, [Select RecordType.DeveloperName,Resolution__c From Case Where ID = :caseRecord.Id].Resolution__c);
        test.stopTest();
    }
}
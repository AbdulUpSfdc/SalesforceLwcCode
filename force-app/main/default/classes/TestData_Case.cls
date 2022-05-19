/* ================================================
* @author : Mike McKinley
* @date :   08/24/2020   
* @group : Case 
* @description : Generates test data for Case
================================================*/

@isTest
public class TestData_Case {
    
    // create a Case for testing purposes
    public static Case generateCase() {
        Case aCase;
        //User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        //system.runAs(oppAdministratorUser) {
            aCase = new Case();
            aCase.SubmissionSourceCode__c = '4-FCC';
            aCase.Product__c = 'Digital Life';
            aCase.State__c = 'California';
            aCase.Type = 'OOP';
            aCase.Origin = 'Web Form';
            aCase.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID;
            aCase.Description = 'Test scenario: Web-to-Case';
            aCase.Status = CaseConstants.NEW_STATUS;
            aCase.Priority = 'Medium';
            aCase.CustomerType__c = 'Consumer';
            aCase.SuppliedEmail = 'email@example.com';
            aCase.ExpectedResponseDate__c = Date.today();
            
            // Service Address
            aCase.City__c = 'City';
            aCase.Country__c = 'United States';
            aCase.ServiceCustFirstName__c = 'First';
            aCase.ServiceCustLastName__c = 'Last';
            aCase.ServicePhone__c = '9995551212';
            aCase.StreetName__c = '123 Main St';
            aCase.ZipPostalCode__c = '55555';
            
            aCase.ReferenceData__c = 'Reference data';
            aCase.ReferredByFirstName__c = 'RefFN';
            aCase.ReferredByLastName__c = 'RefLN';
                        
            insert aCase;
        //}
        
        return aCase;
    }
    public static Case generateCaseForAdjustment() {
        Account anAccount = BWC_TestDataFactory.createAccount();

        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount('Wireless', anAccount );
        billingAccount.Customer_Type__c = 'Consumer';

        update billingAccount;

        Set<Id> billAcctsSet = new Set<Id>();

        Case testCase = generateCase();
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Escalation').getRecordTypeId();
        testCase.Billing_Account__c =billingAccount.id;
        testCase.Product__c='Digital Life';
        testCase.Resolution__c='No Action';
        testCase.Resolution2__c='Already Resolved';
        testCase.SatisfactionIndicator__c = 'Satisfied';
        testCase.ProblemCode__c ='Billing';
        // testCase.ProblemCode2__c ='Adjustment';
        // testCase.ProblemCode3__c = 'Did not receive adjustment that was promised';
        upsert testCase;
        return testCase;
    }
    // create a Child Case Assignment so that child Case can be created
    public static void generateChildCaseAssignmentConfigForQueue(String queueName) {
        //User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        //System.runAs(oppAdministratorUser) {
            ChildCaseAssignmentConfig__c childConfig = new ChildCaseAssignmentConfig__c();
            childConfig.Action1__c = 'Billing'; 
            childConfig.Action2__c = 'Simple';
            childConfig.Action3__c = 'Midwest';
            childConfig.CustomerType__c = 'Business (Other)';
            childConfig.Product__c = 'Digital Life';
            childConfig.Queue__c = queueName;
            
            insert childConfig;
        //}
    }
        
    // create a Child Case Assignment so that child Case can be created
    private static void generateChildCaseAssignmentConfig() {
        String queueName = 'MobilityQueue';
        generateChildCaseAssignmentConfigForQueue(queueName);
    }
        
    // close Case with a specific Status
    public static void closeCase(Case caseToClose, String status) {
        // Close Notes, Problem Code, and Resolution fields are required when closing a Case
        if(String.isBlank(status)) {
            status = CaseConstants.CLOSED_STATUS;
        }
        System.debug('*** Setting Case Status to: ' + status);
        
       // User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
       // System.runAs(oppAdministratorUser) {
            if(String.isBlank(caseToClose.Workgroup__c)) {
                caseToClose.WorkGroup__c = 'MobilityQueue';
            }
            
            caseToClose.Status = status;
            caseToclose.CloseNotes__c = 'Close notes';
            caseToClose.ProblemCode__c = 'Billing';
            caseToClose.ProblemCode2__c = 'Payments';
            caseToClose.ProblemCode3__c = 'Payment status request';
            
            // set the Resolution
            String resolution = 'Corrected';
            if(caseToClose.recordTypeId == MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID) {
                resolution = 'Sustained';
            }
            caseToClose.Resolution__c = resolution;
            
            // set Resolution2 for non-OOPField Cases only
            if(caseToClose.recordTypeId != MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').ID) {
                caseToClose.Resolution2__c = 'Order';
                caseToClose.SatisfactionIndicator__c = 'Unknown';
            }
            
            update caseToClose;
       // }
    }
    
    // close a child case with a specific Resolution
    public static void closeChildCaseWithResolution(Case caseToClose, String status, String resolution) {
        // Close Notes, Problem Code, and Resolution fields are required when closing a Case
        if(String.isBlank(status)) {
            status = CaseConstants.CLOSED_STATUS;
        }
        
        //User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        //System.runAs(oppAdministratorUser) {
            if(String.isBlank(caseToClose.Workgroup__c)) {
                caseToClose.WorkGroup__c = 'MobilityQueue';
            }
            
            caseToClose.Status = status;
            caseToclose.CloseNotes__c = 'Close notes';
            caseToClose.ProblemCode__c = 'Billing';
            caseToClose.ProblemCode2__c = 'Payments';
            caseToClose.ProblemCode3__c = 'Payment status request';
            caseToClose.Resolution__c = resolution;
            caseToClose.SatisfactionIndicator__c = 'Unknown';
            
            update caseToClose;
       // }
    }

}
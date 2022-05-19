@isTest
public class CaseOwnerAssignmentHelperTest{

     @testSetup
    private static void dataSetup(){
        Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
        Profile oopAgentProfile = [Select ID From Profile Where Name='Minimum Access OOP Agent'];
        Profile sysAdminProfile = [Select ID From Profile Where Name='System Administrator'];
        
        UserRole oopAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='OOPAdmin'];
        UserRole fieldAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='FieldAdmin'];
        UserRole fieldAgentRole = [SELECT Id FROM UserRole WHERE DeveloperName='FieldAgent'];
        UserRole fieldIntakeAdminRole = [SELECT Id FROM UserRole WHERE UserRole.Name='Intake Admin'];
        List<User> userList = new List<User>();
        
        User oppAdministratorUser = Utility_Test.createTestUserWithRole(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin', oopAdminRole.Id);
        User intakeAdministratorUser = Utility_Test.createTestUserWithRole(sysAdminProfile.ID, 'firstName_intakeAdmin', 'lastName_intakeAdmin', fieldIntakeAdminRole.Id);
        userList.add(intakeAdministratorUser);
        userList.add(oppAdministratorUser);
        //insert oppAdministratorUser;
        
        oppAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_oopAdmin2', 'lastName_oopAdmin2');
        oppAdministratorUser.UserRoleId = fieldAdminRole.ID;
        userList.add(oppAdministratorUser);
        
        //Agent
        User oopAgent = Utility_Test.createTestUser(oopAgentProfile.ID, 'firstName_oppAgent', 'lastName_oopAgent');
        oppAdministratorUser.UserRoleId = fieldAgentRole.ID;
        userList.add(oopAgent);
        insert userList;
        
    }
    
    @isTest
    public static void productMatchingOwnerAssignmentTest(){
         Account anAccount = BWC_TestDataFactory.createAccount();
         List<User> intakeAdminUser=[ SELECT id FROM USER WHERE Profile.Name='System Administrator' and isActive = true Limit 1];
                                                                                                                  
         system.runAs(intakeAdminUser[0]){
                Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount('Wireless', anAccount );
                billingAccount.Customer_Type__c = 'Consumer';
                update billingAccount;
                
                Set<Id> billAcctsSet = new Set<Id>();
                
                Case parentCase = TestData_Case.generateCase();
        
                Test.startTest();
                    system.assertNotEquals(parentCase.Product__c,'DIRECTV STREAM;DIRECTV');
                    
                    parentCase.Billing_Account__c =billingAccount.id;
                    parentCase.Product__c='DIRECTV STREAM;DIRECTV';
                    update parentCase;
                    
                    List<Id> caseIdList=new List<Id>();
                    caseIdList.add(parentCase.id);
                    CaseOwnerAssignmentHelper.initiateOOPCaseOwnerProcess(caseIdList,true);  
					CaseOwnerAssignmentHelper.validateUpdateOwner(parentCase.id);
                    //CaseOwnerAssignmentHelper.reassignOOPQueue(parentCase.id);
                    
                    billAcctsSet.add(billingAccount.Id);
                    Map<id, List<Case>> getCaseMaplst = CaseOwnerAssignmentHelper.getbillingAccountsCaseMap(billAcctsSet);
                    system.assert(getCaseMaplst.size()>0);
                    Map<Id, Billing_Account__c> getBillActs = CaseOwnerAssignmentHelper.retrieveBillingAccts(billAcctsSet);
                    system.assert(getBillActs.size()>0);
                    
                Test.stopTest();
         }
    }
    @isTest
    public static void productMatchingOwnerAssignmenForRebuttalTest(){
         Account anAccount = BWC_TestDataFactory.createAccount();
         List<User> intakeAdminUser=[ SELECT id FROM USER WHERE Profile.Name='System Administrator' and isActive = true Limit 1];
                                                                                                                  
         system.runAs(intakeAdminUser[0]){
                Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount('Wireless', anAccount );
                billingAccount.Customer_Type__c = 'Consumer';
                update billingAccount;
                
                Set<Id> billAcctsSet = new Set<Id>();
                
                Case parentCase = TestData_Case.generateCase();
        
                Test.startTest();
                    parentCase.Product__c='DIRECTV';
					parentCase.SubmissionSourceCode__c = CaseConstants.R_FCC_REBUTTAL;
                    update parentCase;
                    
                    List<Id> caseIdList=new List<Id>();
                    caseIdList.add(parentCase.id);
                    CaseOwnerAssignmentHelper.initiateOOPCaseOwnerProcess(caseIdList,true);  
                    
                Test.stopTest();
         }
    }
	@isTest
    public static void productNotMatchingOwnerAssignmenForRebuttalTest(){
         Account anAccount = BWC_TestDataFactory.createAccount();
         List<User> intakeAdminUser=[ SELECT id FROM USER WHERE Profile.Name='System Administrator' and isActive = true Limit 1];
                                                                                                                  
         system.runAs(intakeAdminUser[0]){
                Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount('Wireless', anAccount );
                billingAccount.Customer_Type__c = 'Consumer';
                update billingAccount;
                
                Set<Id> billAcctsSet = new Set<Id>();
                
                Case parentCase = TestData_Case.generateCase();
        
                Test.startTest();
                    parentCase.Product__c='Wireless';
					parentCase.SubmissionSourceCode__c = CaseConstants.R_FCC_REBUTTAL;
                    update parentCase;
                    
                    List<Id> caseIdList=new List<Id>();
                    caseIdList.add(parentCase.id);
                    CaseOwnerAssignmentHelper.initiateOOPCaseOwnerProcess(caseIdList,true);  
                    
                Test.stopTest();
         }
    }
           
}
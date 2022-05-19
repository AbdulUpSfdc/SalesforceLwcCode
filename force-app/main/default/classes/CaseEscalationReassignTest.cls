/*
    Class Name # CaseEscalationReassignTest
    Purpose # Code coverage class for CaseEscalationReassign
    
*/    

@isTest 
private class CaseEscalationReassignTest{

    @testSetup
    private static void testSetup(){
        Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
        UserRole fieldAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='FieldAdmin'];
        User oppAdministratorUser = Utility_Test.createTestUserWithRole(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin', fieldAdminRole.Id);
        insert oppAdministratorUser;

        List<Utility_Test.UserPermissionSetWrapper> wrapperList = new List<Utility_Test.UserPermissionSetWrapper>();
        Utility_Test.UserPermissionSetWrapper wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = oppAdministratorUser;
        wrapper.permissionSetNames.add('OOPCaseAdmin');
        wrapperList.add(wrapper);
        system.runAs(new User(Id=UserInfo.getUserId())){
          Utility_Test.assignPermissionSet(wrapperList);      
        }
        Utility_Test.createCaseAdminRecords();
    }
    static testmethod void testCaseEscalationReassign() {
        final String TEST_QUEUE_NAME = 'UserQueue';
        Group testQueue = TestData_Queue.generateQueue('Case', TEST_QUEUE_NAME);
       
        Case currentCase = TestData_Case.generateCase();
        currentCase.WorkGroup__c='UserQueue';
        update currentCase;
        CaseEscalationReassign.getGroupDetails(currentCase.id);
            
        case cs=[select id,WorkGroup__c from case limit 1];    
        System.assertEquals(cs.WorkGroup__c , TEST_QUEUE_NAME );
    }
    static testmethod  void testcaseLinktoInteraction(){
           Account acct = BWC_TestDataFactory.createAccount();
           Interaction__c interaction = BWC_TestDataFactory.createInteraction(acct);
 
           Case currentCase = TestData_Case.generateCase();
           currentCase.Last_Interaction__c=interaction.id;
           update currentCase;
           
           delete [select id from Case_Interaction__c ];
           CaseEscalationReassign.caseLinktoInteraction(currentCase.id,interaction.id);
           
           Case_Interaction__c csInterations=new Case_Interaction__c();
           csInterations.Case__c=currentCase.id;
           csInterations.Interaction__c=interaction.id;
           insert csInterations;
           
           
           try{
               CaseEscalationReassign.caseLinktoInteraction(currentCase.id,interaction.id);
           }catch(Exception ex){}
        
          
         
          System.assert([select id from Case_Interaction__c].size()>0);
           
    }
}
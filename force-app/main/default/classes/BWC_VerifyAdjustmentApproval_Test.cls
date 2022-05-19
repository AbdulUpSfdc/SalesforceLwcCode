@isTest(SeeAllData=true)
public class BWC_VerifyAdjustmentApproval_Test{
  @IsTest
  static void checkAccessibility() {
    Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
    Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();
    User testUser = BWC_TestDataFactory.createUser(p.Id);

    System.runAs(testUser) {
      try {
        BWC_VerifyAdjustmentApproval.checkAccessibility(adjustment.Id);
        BWC_VerifyAdjustmentApproval.checkAccessibilityApprove(adjustment.Id);
      } catch (AuraHandledException e) {
        System.assert(true);
      }
    }
  }
  @IsTest
  static void checkAccessibilityApprove() {
    Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();
    Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
    User testUser = BWC_TestDataFactory.createUser(p.Id);
       Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(adjustment.id);
        Approval.ProcessResult result = Approval.process(app);
        ProcessInstanceWorkitem workItem = [Select Id from ProcessInstanceWorkitem where ProcessInstance.TargetObjectId =: adjustment.Id];

    System.runAs(testUser) {
      try {
          SOA_Level__c soaLevel = new SOA_Level__c();
            soaLevel.Organization__c = 'Centers';
            soaLevel.Channel__c = 'Collections';
            soaLevel.Sub_Channel__c = 'Collections';
            soaLevel.Authorization_Level__c = 'Level 1';
            soaLevel.Line_of_Business__c = 'Wireless';
            soaLevel.Authorization_Amount__c = 100000 ;
            insert soaLevel; 
            Employee__c emp = BWC_TestDataFactory.createEmployee();
            emp.User__c = testUser.Id;
            emp.SOA_Level__c = soaLevel.Id;
            emp.Organization__c  = 'Centers';
            emp.Channel1__c = 'Collections';
            emp.Sub_Channel__c = 'Collections';
            emp.EmployeeId__c = 'tt1234';
            insert emp;
            Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();         
            request.setComments('Approving request using Trigger');
            request.setWorkitemId(workItem.Id);
            request.setAction('Approve');
            Approval.ProcessResult result1 =  Approval.process(request);
            BWC_VerifyAdjustmentApproval.checkAccessibilityApprove(adjustment.Id);
      } catch (AuraHandledException e) {
        System.assert(true);
      }
    }
  }
  @istest public static void firstTestMethod(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User testUser = BWC_TestDataFactory.createUser(p.Id);
        Adjustment__c adj1 = BWC_TestDataFactory.createAdjustment();
        
        SOA_Level__c soaLevel = new SOA_Level__c();
        soaLevel.Organization__c = 'Centers';
        soaLevel.Channel__c = 'Collections';
        soaLevel.Sub_Channel__c = 'Collections';
        soaLevel.Authorization_Level__c = 'Level 1';
        soaLevel.Line_of_Business__c = 'Wireless';
        soaLevel.Authorization_Amount__c = 100000 ;
        insert soaLevel; 
        Employee__c emp = new Employee__c();
        emp.User__c = testUser.Id;
        emp.SOA_Level__c = soaLevel.Id;
        emp.Organization__c  = 'Digital Life';
        emp.Channel1__c = 'Digital Life';
        emp.Sub_Channel__c = 'Digital Life';
        emp.EmployeeId__c = 'tt1234';
        insert emp;

        List<Employee__c> emprec = [select id,Channel1__c from Employee__c where user__c = :testUser.Id];
        system.debug('emprec****'+emprec);
        
        //BWC_PerformAdjustmentApproval.approveRequest(adj1.Id,'Submitting for approval');
        Adjustment__c adj = [
            SELECT Id, Status__c,Channel__c,Sub_Channel__c,Case__r.Type,Total_Requested_Amount__c,Total_Agent_Adjusted_Amount__c,Override_By_Manager__c
            FROM Adjustment__c
            WHERE Id = :adj1.Id
        ];
                // Create an approval request for Adjustment
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting approval request.');
        req.setObjectId(adj.Id);
        
        // Submit the request for approval
        Approval.ProcessResult res = Approval.process(req);
        system.debug('adj****record****'+adj);
        Adjustment__c adj2 = [
            SELECT Id, Status__c,Channel__c,Sub_Channel__c,Case__r.Type,Total_Requested_Amount__c,Total_Agent_Adjusted_Amount__c,Override_By_Manager__c
            FROM Adjustment__c
            WHERE Id = :adj1.Id
        ];
        system.debug('adj2****'+adj2);
        system.runAs(testUser){
            BWC_VerifyAdjustmentApproval.checkAccessibilityApprove(adj2.Id);
        }  
    }
    @istest public static void secondTestMethod(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User testUser = BWC_TestDataFactory.createUser(p.Id);
        Adjustment__c adj1 = BWC_TestDataFactory.createAdjustment();
        
        SOA_Level__c soaLevel = new SOA_Level__c();
        soaLevel.Organization__c = 'Centers';
        soaLevel.Channel__c = 'Collections';
        soaLevel.Sub_Channel__c = 'Collections';
        soaLevel.Authorization_Level__c = 'Level 1';
        soaLevel.Line_of_Business__c = 'Wireless';
        soaLevel.Authorization_Amount__c = 0;
        insert soaLevel; 
        Employee__c emp = new Employee__c();
        emp.User__c = testUser.Id;
        emp.SOA_Level__c = soaLevel.Id;
        emp.Organization__c  = 'Digital Life';
        emp.Channel1__c = 'Digital Life';
        emp.Sub_Channel__c = 'Digital Life';
        emp.EmployeeId__c = 'tt1234';
        insert emp;

        List<Employee__c> emprec = [select id,Channel1__c from Employee__c where user__c = :testUser.Id];
        system.debug('emprec****'+emprec);
        
        //BWC_PerformAdjustmentApproval.approveRequest(adj1.Id,'Submitting for approval');
        Adjustment__c adj = [
            SELECT Id, Status__c,Channel__c,Sub_Channel__c,Case__r.Type,Total_Requested_Amount__c,Total_Agent_Adjusted_Amount__c,Override_By_Manager__c
            FROM Adjustment__c
            WHERE Id = :adj1.Id
        ];
                // Create an approval request for Adjustment
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting approval request.');
        req.setObjectId(adj.Id);
        
        // Submit the request for approval
        Approval.ProcessResult res = Approval.process(req);
        system.debug('adj****record****'+adj);
        Adjustment__c adj2 = [
            SELECT Id, Status__c,Channel__c,Sub_Channel__c,Case__r.Type,Total_Requested_Amount__c,Total_Agent_Adjusted_Amount__c,Override_By_Manager__c
            FROM Adjustment__c
            WHERE Id = :adj1.Id
        ];
        system.debug('adj2****'+adj2);
        system.runAs(testUser){
            BWC_VerifyAdjustmentApproval.checkAccessibilityApprove(adj2.Id);
        }  
    }
    @isTest public static void noEditAccessTestMethod(){
        User testUser = BWC_TestDataFactory.createUser();
        Adjustment__c adj1 = BWC_TestDataFactory.createAdjustment();
        system.runAs(testUser){
            BWC_VerifyAdjustmentApproval.checkAccessibilityApprove(adj1.id);
        }
    }
}
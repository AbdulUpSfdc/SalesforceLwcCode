@isTest
/*
* This class is used to test various test cases of prospect lead self assignment
* Author: Rashmi Thippeswamy
*/
private class LeadOwnershipAssignControllerTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    /* 
    *This method is used to setup test data of employee,employee store retail,leads and stores
    */
    @TestSetup
    static void makeData(){
    	dataFactoryWrap = dataFactory.createTestData(3,'lead');
    }
    @isTest
	static void testAccept(){
    	List<Lead>  lstLead =new List<Lead>();
        lstLead = [SELECT id ,recordtypeid,ownerid FROM Lead LIMIT 1];
        List<Employee__c> lstEmp =new List<Employee__c>();
        lstEmp = [Select id ,homeStoreLocation__c  FROM Employee__c where User__c=: Userinfo.getUserId()];
        if(lstEmp.isEmpty()){
             Employee__c emp =new Employee__c();
                Store__c st = [select id from Store__c where Name LIKE '%lead%' limit 1];
                emp.homeStoreLocation__c = st.id;
             emp.User__c =UserInfo.getUserId();
             insert emp;
        }
        Id prospectRecTypeId= TriggerHelper.getRecordTypeIdFromName('Prospect', 'Lead');
        if(!lstLead.isEmpty()){
            lstLead[0].recordtypeid= prospectRecTypeId;
            update lstLead;
            LeadOwnershipAssignController.manageProspectConversion(lstLead[0].Id);
        }
            
        
        
    }
}
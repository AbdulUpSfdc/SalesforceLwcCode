@isTest
		private class DCIPermSetAssignmentBatchTest {
			private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
			private static TestDataFactory dataFactory = new TestDataFactory();
			
			@TestSetup
			static void makeData(){
				dataFactoryWrap = dataFactory.createTestData(3,'EmpStrRetail');
			}

			@isTest
			static void testPermSetsAssigned() {
			List<EmployeeStoreRetail__c> lstEmpStore = [SELECT id,SFProfileId__c,Store__c,User__c FROM EmployeeStoreRetail__c Limit 8];
			Test.startTest();
			database.executeBatch(new DCIPermSetAssignmentBatch());
			Test.stopTest();
			}
		
			@isTest
			static void testPermSetsBatchScheduled() {
			String cronExpr = '0 0 0 * * ? '; 
			Test.startTest();
				DCIPermSetAssignmentBatchScheduler permSetAssignmentBatchScheduler = new DCIPermSetAssignmentBatchScheduler();
				System.schedule('Perm Set Assignment Test', cronExpr, permSetAssignmentBatchScheduler);
			Test.stopTest();
			}
			
			@isTest
			static void testPermSetsRepAssigned() {

			User u = new User(
			ProfileId = [SELECT Id FROM Profile WHERE Name = :DCIConstants.REP_PROFILE].Id,
			LastName = 'last',
			Email = 'puser000@amamama.com',
			Username = 'puser000@amamama.com' + System.currentTimeMillis(),
			CompanyName = 'TEST',
			Title = 'title',
			Alias = 'alias',
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US');
			
			insert u;

			List<PermissionSet> permSets = [ SELECT id FROM PermissionSet WHERE  Name = 'RetailDCI' OR  Name = 'RetailDCIRep'];
			List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();

				for ( PermissionSet ps : permSets ) {
					psa.add( new PermissionSetAssignment(
					assigneeId = u.id,
					permissionSetId = ps.id
					));
				}
				insert psa;
				
		System.runAs(u){
				Employee__c emp=new Employee__c(Name = 'Test',SFProfileId__c = 'RSC-REP');
				emp.User__c = u.Id;
				insert emp;

				//Employee__c emp1 = [select SFProfileId__c ,Id from Employee__c where Id = :emp.Id] ;
				Store__c st= new Store__c(name = 'TestStore');
				insert st;

				EmployeeStoreRetail__c esr = new EmployeeStoreRetail__c(HomeStore__c =True) ;
				esr.Employee__c = emp.Id;
				esr.Store__c = st.Id;
				insert esr;

				Formula.recalculateFormulas(new List<EmployeeStoreRetail__c>{ esr });

				Test.startTest();
				database.executeBatch(new DCIPermSetAssignmentBatch());
				Test.stopTest();
			}
		}
	}
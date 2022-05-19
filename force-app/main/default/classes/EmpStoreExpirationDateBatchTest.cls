@isTest
private class EmpStoreExpirationDateBatchTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();

    /* 
    *This method is used to setup test data of employee,employee store and stores
    */
    @TestSetup
    static void makeData(){
        dataFactoryWrap = dataFactory.createTestData(3,'Empl');
    }

    /* 
    *This method tests the batch job for setting isExpired to true for ARSM
    */
   @IsTest
    static void testBatchJob(){
        Date todaysDate = System.today();
        String ARSMProfile = RetailConstants.ARSM_POSITION;
        List<EmployeeStoreRetail__c> lstEmpStore = new List<EmployeeStoreRetail__c>();
        EmployeeStoreRetail__c empStore = new EmployeeStoreRetail__c();
        Integer index = 0; 

        List<Store__c> lstStore = [SELECT id FROM Store__c WHERE Name LIKE '%store%'];
        system.debug('store list-->' + lstStore);
        List<Employee__c> lstEmp = [SELECT id FROM Employee__c WHERE SFProfileId__c =: ARSMProfile];
        system.debug('emp list-->' + lstEmp);
        
       
        for(Integer i=0;i<20;i++){
            Store__c store = lstStore[index];
            Employee__c emp = lstEmp[index];
            empStore = new EmployeeStoreRetail__c(                        
                        Store__c = store.id,
                        Employee__c = emp.id                       
                    );
            
            lstEmpStore.add(empStore);
            index = lstStore.size() >= index ? 0 : index++;
        } 

        insert lstEmpStore;    

        List<EmployeeStoreRetail__c> lstEmpStoreExpDate = new List<EmployeeStoreRetail__c>();
        lstEmpStoreExpDate = [SELECT Id, SFProfileId__c FROM EmployeeStoreRetail__c WHERE Id IN: lstEmpStore];
        
        List<EmployeeStoreRetail__c> lstExpDateUpdate = new List<EmployeeStoreRetail__c>();
        integer count = 1;
        for(EmployeeStoreRetail__c es: lstEmpStoreExpDate){
            if(count <= 10){
                es.EffectiveEnddate__c = System.today().addDays(-2);
            }else{
                es.EffectiveEnddate__c = System.today().addDays(30);                
            }
            lstExpDateUpdate.add(es);
            
            count++;
        }
        
        system.debug('exp date list-->' + lstExpDateUpdate);
        Test.startTest();
        update lstExpDateUpdate;
            database.executeBatch(new EmpStoreExpirationDateBatch());
        Test.stopTest();
    }

    /* 
    * This method tests Schedulable class for Expiration Date Batch
    */
    @IsTest
    static void testScheduledJob() {
     
        BatchStatus__c batchDetails = new BatchStatus__c(Name = RetailConstants.EXPIRATIONDATE_BATCH_NAME,
        LastRun__c = System.now().addDays(-2),BatchSize__c=10);
        insert batchDetails;

        test.starttest();
        EmpStoreExpirationDateScheduler expDateScheduler = new EmpStoreExpirationDateScheduler ();   
        String cron = '0 0 23 * * ?';        
        system.schedule(RetailConstants.EXPIRATIONDATE_BATCH_NAME, cron, expDateScheduler);
        test.stopTest();
    }

}
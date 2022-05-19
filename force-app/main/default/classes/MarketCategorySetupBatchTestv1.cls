@isTest
public with sharing class MarketCategorySetupBatchTestv1 {
    public static testMethod void testAddDeleteProcessing(){
        user u = [Select Id,Name from User where IsActive=true AND UserPermissionsKnowledgeUser =true limit 1];
      
        PermissionSet p = [ Select Id,Name from PermissionSet where Name='ACC' limit 1];
        
        // Create Employee Record
        Employee__c e = new Employee__c();
        e.Name = 'testEmp';
        e.User__c = u.Id;
        insert e;

        //Create BWRolePermissions records
        BWRolePermissions__c brp = new BWRolePermissions__c();
        brp.PermissionSetId__c = String.valueOf(p.Id);
        brp.RoleName__c = 'KMRole';
        brp.RoleValue__c = 'ACC Rep';
        insert brp;

        // Create BWMarketMaster record
        BWMarketMaster__c bmm = new BWMarketMaster__c();
        bmm.MYCSPMarketId__c = '0014';
        bmm.MarketPromotedSearchTerm__c= 'T4';
        insert bmm;

        //Create BWRoleMarketMaster records
        BWRoleMarketMaster__c brm = new BWRoleMarketMaster__c();
        brm.MarketId__c = bmm.Id;
        brm.RoleValue__c ='ACC Rep';
        insert brm;
        // Create BW Employee Records
        BWEmployeeRole__c ber = new BWEmployeeRole__c();
        ber.RoleName__c= 'KMRole';
        ber.RoleValue__c = 'ACC Rep';
        ber.KMProcessingStatus__c = 'Awaiting Add Processing';
        ber.UserId__c = e.Id;
        insert ber;

        test.startTest();
        MarketCategorySetupBatchv1 mcsb = new MarketCategorySetupBatchv1();
        Database.executeBatch(mcsb, 1);
        test.stopTest();

        // Verify Results
        // Query Permission Set Assignments
        PermissionSetAssignment psa = [Select Id,AssigneeId,PermissionSetId from PermissionSetAssignment where AssigneeId =:u.Id limit 1];
        //system.assertEquals(P.Id, psa.PermissionSetId);

        // Query UserMarketAssociation
        BWUserMarketAssociation__c uma = [Select Id,BWMarketMaster__c,UserId__c  from BWUserMarketAssociation__c where BWMarketMaster__c=:bmm.Id limit 1];
        system.assertEquals(u.Id, uma.UserId__c);

        // Query BW Employee Records for Delete Processing
        BWEmployeeRole__c ber1 = [select Id,RoleName__c,RoleValue__c,KMProcessingStatus__c,UserId__c from BWEmployeeRole__c where Id=:ber.Id limit 1];
        ber1.KMProcessingStatus__c ='Awaiting Delete Processing';
        update ber1;

        MarketCategorySetupBatchv1 mcsb1 = new MarketCategorySetupBatchv1();
        Database.executeBatch(mcsb1, 1);

    }
}
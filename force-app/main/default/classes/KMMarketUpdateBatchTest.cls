@isTest
public with sharing class KMMarketUpdateBatchTest {
    public static testMethod void testNewMarketMaster(){
        
        user u = [Select Id,Name from User where IsActive=true AND UserPermissionsKnowledgeUser =true limit 1];

        PermissionSet p = [ Select Id,Name from PermissionSet where Name='ACC' limit 1];
        
        //create BWKMUserProfile record
        BWKMUserProfile__c kup = new BWKMUserProfile__c();
        kup.ATTUID__c = 'abcd12';
        kup.DefaultChannelId__c = '503';
        kup.DefaultMarketId__c = '4';
        kup.KSEmployeeTypeId__c = '13956';
        kup.KSUserRole__c = '343';
        kup.Status__c = 'Completed Add';
        kup.Sys_Role_ID__c = '1410:1417';
        insert kup;
        
       // Create Employee Record
        Employee__c e = new Employee__c();
        e.Name = 'testEmp';
        e.User__c = u.Id;
        e.EmployeeId__c = 'abcd12';
        e.BWDefaultKMChannel__c ='503';
        e.BWDefault_KM_Master__c = '4';
        e.Employee_Type_Id__c = '13946';
        e.User_Role__c = '343';
        insert e;
        
        // Create BWMarketMaster record
        BWMarketMaster__c bmm = new BWMarketMaster__c();
        bmm.MYCSPMarketId__c = '4';
        bmm.MarketPromotedSearchTerm__c= 'T4';
        insert bmm;
        
        BWMarketMaster__c bmm2 = new BWMarketMaster__c();
        bmm2.MYCSPMarketId__c = '300';
        bmm2.MarketPromotedSearchTerm__c= 'T5';
        insert bmm2;
        
        List<BWMarketMaster__c> bwMarketMasterList = new List<BWMarketMaster__c>();
        bwMarketMasterList.add(bmm);
        bwMarketMasterList.add(bmm2);
        
        
        // Create Role Master Record
        BWRoleMaster__c brmRole = new BWRoleMaster__c();
        brmRole.Role_Name__c = 'KMRole';
        brmRole.Role_Value__c = 'ACC Rep';
        brmRole.Sys_Role_ID__c = '1410';
        insert brmRole;
        
        BWRoleMaster__c brmRole1 = new BWRoleMaster__c();
        brmRole1.Role_Name__c = 'KMRole';
        brmRole1.Role_Value__c = 'Support Mgr';
        brmRole1.Sys_Role_ID__c = '1417';
        insert brmRole1;
        
        List<BWRoleMaster__c> bwRoleMasterList = new List<BWRoleMaster__c>();
        bwRoleMasterList.add(brmRole);
        bwRoleMasterList.add(brmRole1);

        // Create Role Market Master Record
        BWRoleMarketMaster__c brm = new BWRoleMarketMaster__c();
        brm.MarketId__c =  bwMarketMasterList[0].Id;  //bmm.Id;
        brm.RoleValue__c ='ACC Rep';
        insert brm;
        
        BWRoleMarketMaster__c brm1 = new BWRoleMarketMaster__c();
        brm1.MarketId__c =  bwMarketMasterList[1].Id; //bmm2.Id;
        brm1.RoleValue__c ='Support Mgr';
        insert brm1;
        
        List<BWRoleMarketMaster__c> bwRoleMarketMasterList = new List<BWRoleMarketMaster__c>();
        bwRoleMarketMasterList.add(brm);
        bwRoleMarketMasterList.add(brm1);
        
       
        //Create BWUserMarketAssociation__c records
        BWUserMarketAssociation__c buma = new BWUserMarketAssociation__c();
        buma.UserId__c = u.Id;
        buma.Primary__c = true;
        buma.BWMarketMaster__c = bwMarketMasterList[0].Id; //bmm.id;
        insert buma;
        
        test.startTest();
        KMMarketUpdateBatch kupb = new KMMarketUpdateBatch();
        Database.executeBatch(kupb, 1);
        test.stopTest();
        
         // Check if UMA record with correct master is created
        list<BWUserMarketAssociation__c> umaR = [Select Id,Primary__c,BWMarketMaster__c,UserId__c from BWUserMarketAssociation__c];
       // system.assertEquals(2, umaR.size());
        system.assertEquals(bmm.Id, umaR[0].BWMarketMaster__c);
        system.assertEquals(u.Id, umaR[0].UserId__c);
        
        // Check if Knowledge User Profile Status got Updated
        BWKMUserProfile__c kupResult = [Select Id,Status__c from BWKMUserProfile__c where Id=:kup.Id];
        system.assertEquals('Market Processing Complete', kupResult.Status__c);
        }

    
}
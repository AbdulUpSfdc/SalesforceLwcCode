@isTest
public with sharing class KMRolePermissionUpdateBatchTest {
    
    
    public static testMethod void testNewChannelMaster(){
        User u;
        PermissionSet ps;
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            Profile p = [select id from profile where name='System Administrator'];
            u = new User(alias = 'standt', email='standarduser@testorg.com', 
                         emailencodingkey='UTF-8', lastname='Testing', 
                         languagelocalekey='en_US', 
                         localesidkey='en_US', profileid = p.Id, 
                         timezonesidkey='America/Los_Angeles', IsActive=true,
                         UserPermissionsKnowledgeUser =true,
                         username='standarduser@testorg.com123');
            insert u;
            
            ps = [SELECT Id FROM PermissionSet WHERE Name = 'KM_Admin_Custom'];
            insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);
            
            
        }
        
        
        system.runAs(u){   
            //create BWKMUserProfile record
            BWKMUserProfile__c kup = new BWKMUserProfile__c();
            kup.ATTUID__c = 'abcd12';
            kup.DefaultChannelId__c = '503';
            kup.DefaultMarketId__c = '4';
            kup.KSEmployeeTypeId__c = '13946';
            kup.KSUserRole__c = '343';
            kup.Status__c = 'Awaiting Add Processing';
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
            
            BWEmployeeRole__c ber = new BWEmployeeRole__c();
            ber.RoleName__c = 'KMRole';
            ber.RoleValue__c = 'Support Mgr';
            ber.UserId__c = e.Id;
            insert ber;
            
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
            
            //Create BW Channel Mapping Record
            BW_Channel_Mapping__c bcm = new BW_Channel_Mapping__c();
            bcm.KM_Channel_ID__c = '503';
            bcm.Permission_Set_Id__c = ps.Id;
            insert bcm;
            
            BW_Channel_Mapping__c bcm1 = new BW_Channel_Mapping__c();
            bcm1.KM_Channel_ID__c = '13946';
            bcm1.Permission_Set_Id__c = ps.Id;
            insert bcm1;
            
            BW_Channel_Mapping__c bcm2 = new BW_Channel_Mapping__c();
            bcm2.KM_Channel_ID__c = '343';
            bcm2.Permission_Set_Id__c = ps.Id;
            insert bcm2;
            
            List<BW_Channel_Mapping__c> channelMapping = new List<BW_Channel_Mapping__c>();
            channelMapping.add(bcm);
            channelMapping.add(bcm1);
            channelMapping.add(bcm2);
            
            BWRolePermissions__c bRolePerm = new BWRolePermissions__c();
            bRolePerm.PermissionSetId__c = ps.Id;
            bRolePerm.PermissionSetName__c  = 'ACC_Test';
            bRolePerm.RoleName__c = 'KMRole';
            bRolePerm.RoleValue__c = 'Support Mgr';
            bRolePerm.SystemPermissionSet__c = true;
            insert bRolePerm;
            
            
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
            
            Employee__c emp1 = [select Id,BWDefaultKMChannel__c,BWDefault_KM_Master__c,Employee_Type_Id__c from Employee__c where Id=:e.Id];
            emp1.BWDefaultKMChannel__c = '504';
            emp1.BWDefault_KM_Master__c = '5';
            emp1.Employee_Type_Id__c = '353';
            emp1.User_Role__c = '13956';
            update emp1;
            
            UserProfileFailureLogs__c errorObject = new UserProfileFailureLogs__c();
            errorObject.Object_Name__c = 'Employee';
            errorObject.Error_Message__c = 'Insert Operation';
            errorObject.Operation__c = 'Insert';
            insert errorObject;
            
            test.startTest();
            KMRolePermissionUpdateBatch kupb = new KMRolePermissionUpdateBatch();
            Database.executeBatch(kupb, 1);
            test.stopTest();
            
            PermissionSetAssignment psaR = [Select Id,AssigneeId,PermissionSetId from PermissionSetAssignment where AssigneeId=:u.Id AND PermissionSet.Name='KM_Admin_Custom' limit 1];
            system.assertEquals(ps.Id, psaR.PermissionSetId);
            
            // Check if Employee Roles are created / updated
            list<BWEmployeeRole__c> listBers = [Select Id,KMProcessingStatus__c,RoleName__c,RoleValue__c,UserId__c from BWEmployeeRole__c];
            system.assertEquals(2, listBers.size());
            
            Employee__c emp = [select Id,BWDefaultKMChannel__c,BWDefault_KM_Master__c,User_Role__c from Employee__c where Id=:e.Id];
            system.assertEquals('503', emp.BWDefaultKMChannel__c);
            system.assertEquals('4', emp.BWDefault_KM_Master__c);
            
            // Check if Knowledge User Profile Status got Updated
            BWKMUserProfile__c kupResult = [Select Id,Status__c from BWKMUserProfile__c where Id=:kup.Id];
            system.assertEquals('Completed Add', kupResult.Status__c);
        }
        
    }
    
    
    
}
@isTest
public with sharing class KnowledgeUserProfileBatchTest {

    public static profile setProfile() {
        Profile p = [Select Id,Name from Profile where Name='System Administrator'];
        return p;
    }

    public static PermissionSet setPermSet() {
        PermissionSet permSet =  new PermissionSet();
        permSet.Label ='KMACCTest';
        permSet.Name ='ACC_Test';
        insert permSet;
        return permSet;
    }

    public static PermissionSet setPermSet1() {
        PermissionSet permSet1 = new PermissionSet();
        permSet1.Label ='KM ACC Sales Test';
        permSet1.Name ='KM_ACC_Sales_Test';
        insert permSet1;
        return permSet1;
    }

    public static PermissionSet setPermSet2() {
        PermissionSet permSet2 = new PermissionSet();
        permSet2.Label ='KM Employee Test';
        permSet2.Name ='KM_Employee_Test';
        insert permSet2;
        return permSet2;
    }
    public static PermissionSet setPermSet3() {
        PermissionSet permSet3 = new PermissionSet();
        permSet3.Label ='KM Sales / Call Center Representative Test';
        permSet3.Name ='KM_Sales_Call_Center_Representative_Test';
        insert permSet3;
        return permSet3;
    }



    public static User setUser() {
         // Create user record
         String orgId = UserInfo.getOrganizationId();
         String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
         Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
         String uniqueName = orgId + dateString + randomInt;
         User u = new user();
         u.Username = uniqueName + '@test' + orgId + '.org';
         u.Email = 'test@KM.com';
         u.Alias = 'tsamp';
         u.ProfileId = setProfile().Id;
         u.FederationIdentifier = 'abTest12';
         u.IsActive = true;
         u.UserPermissionsKnowledgeUser = true;
         u.LastName ='test';
         u.TimeZoneSidKey ='GMT';
         u.LocaleSidKey ='en_US';
         u.EmailEncodingKey ='UTF-8';
         u.LanguageLocaleKey ='en_US';
         insert u;
         return u;
    }

    public static BWKMUserProfile__c setKUP(String attUId,String defaultChannel,String defaultMarket,String defaultEmpType,String defaultUserRole, String sysRoleId){
        // Create Knowledge User Profile
        BWKMUserProfile__c kup = new BWKMUserProfile__c();
        kup.ATTUID__c = attUId;
        kup.DefaultChannelId__c = defaultChannel;
        kup.DefaultMarketId__c = defaultMarket;
        kup.KSEmployeeTypeId__c = defaultEmpType;
        kup.KSUserRole__c = defaultUserRole;
        kup.Status__c = 'Awaiting Add Processing';
        kup.Sys_Role_ID__c = sysRoleId;
        insert kup;
        return kup;
    }

    public static Employee__c setEmployee(User u,string defaultChannel,String defaultMaster,String defaultEmpType,String defaultUserRole){
        // insert Employee record
        Employee__c e = new Employee__c();
        e.Name = 'testEmp';
        e.User__c = u.Id;
        e.EmployeeId__c = u.FederationIdentifier;
        e.BWDefaultKMChannel__c =defaultChannel;
        e.BWDefault_KM_Master__c =defaultMaster;
        e.Employee_Type_Id__c = defaultEmpType;
        e.User_Role__c = defaultUserRole;
        insert e;
        return e;
    }

    public static BW_Channel_Mapping__c setBWChannel(String channelId, String permSetId){
         //insert BW_Channel_Mapping__c
         BW_Channel_Mapping__c bcm = new BW_Channel_Mapping__c();
         bcm.KM_Channel_ID__c =channelId;
         bcm.Permission_Set_Id__c = permSetId;
         insert bcm;
         return bcm;
    }

    public static BWMarketMaster__c setBWMarketMaster(String marketMaster){
        //insert BWMarketMaster__c
        BWMarketMaster__c bmm = new BWMarketMaster__c();
        bmm.MYCSPMarketId__c = marketMaster;
        insert bmm;
        return bmm;
    }

    public static BWRoleMaster__c setBWRoleMaster(String roleName,String roleValue,String sysRoleId){
        //insert BWRoleMaster__c
        BWRoleMaster__c brm = new BWRoleMaster__c();
        brm.Role_Name__c = roleName;
        brm.Role_Value__c = roleValue;
        brm.Sys_Role_ID__c = sysRoleId;
        insert brm;
        return brm;
    }

    public static BWEmployeeRole__c setBWEmpRole(String roleName,String roleValue,Id userId){
        //insert BWEmployeeRole__c
        BWEmployeeRole__c ber = new BWEmployeeRole__c();
        ber.RoleName__c = roleName;
        ber.RoleValue__c = roleValue;
        ber.UserId__c = userId;
        insert ber;
        return ber;
    }

    public static BWUserMarketAssociation__c setBWUMA(Id marketMasterId,boolean primary,Id userId){
        //insert BWEmployeeRole__c
        BWUserMarketAssociation__c uma = new BWUserMarketAssociation__c();
        uma.BWMarketMaster__c = marketMasterId;
        uma.Primary__c = primary;
        uma.UserId__c = userId;
        insert uma;
        return uma;
    }

    public static testMethod void testNewChannelMaster(){
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        system.runAs(thisUser){
        user u = setUser();
        BWKMUserProfile__c kup =  setKUP(u.FederationIdentifier,'1','4','373','13946','41:155:999');
        Employee__c e = setEmployee(u,' ',' ',' ',' ');
        PermissionSet p1 = setPermSet();
        PermissionSet p2 = setPermSet2();
        PermissionSet p3 = setPermSet3();
        BW_Channel_Mapping__c bcm = setBWChannel('1',String.valueOf(p1.Id));
        BW_Channel_Mapping__c bcm1 = setBWChannel('373',String.valueOf(p2.Id));
        BW_Channel_Mapping__c bcm2 = setBWChannel('13946',String.valueOf(p3.Id));
        BWMarketMaster__c bmm = setBWMarketMaster('4');
        BWRoleMaster__c brm = setBWRoleMaster('KMRole','ACC Rep','41');
        BWRoleMaster__c brm1 = setBWRoleMaster('KMRole','C&C Rep','155');

        test.startTest();
        KnowledgeUserProfileBatch kupb = new KnowledgeUserProfileBatch();
        Database.executeBatch(kupb, 1);
        test.stopTest();

        // Asserts
        // Check if perm set is assigned
        PermissionSetAssignment psa = [Select Id,AssigneeId,PermissionSetId from PermissionSetAssignment where AssigneeId=:u.Id AND PermissionSet.Name='ACC_Test' limit 1];
        system.assertEquals(p1.Id, psa.PermissionSetId);

        // Check if UMA record with correct master is created
        BWUserMarketAssociation__c uma = [Select Id,Primary__c,BWMarketMaster__c,UserId__c from BWUserMarketAssociation__c limit 1];
        system.assertEquals(bmm.Id, uma.BWMarketMaster__c);
        system.assertEquals(u.Id, uma.UserId__c);

        // Check if Employee Roles are created
        list<BWEmployeeRole__c> listBers = [Select Id,KMProcessingStatus__c,RoleName__c,RoleValue__c,UserId__c from BWEmployeeRole__c];
        system.assertEquals(2, listBers.size());

        // Check if Employee Channel and Master Id are updated
        Employee__c emp = [select Id,BWDefaultKMChannel__c,BWDefault_KM_Master__c from Employee__c where Id=:e.Id];
        system.assertEquals('1', emp.BWDefaultKMChannel__c);
        system.assertEquals('4', emp.BWDefault_KM_Master__c);

        // Check if Knowledge User Profile Status got Updated
        BWKMUserProfile__c kupResult = [Select Id,Status__c from BWKMUserProfile__c where Id=:kup.Id];
        system.assertEquals('Completed Add', kupResult.Status__c);
        }
    }

    public static testMethod void testDeleteChannelMaster(){
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        system.runAs(thisUser){
        // Create a user
        user u = setUser();
        PermissionSet p = setPermSet();
        PermissionSet p1 = setPermSet1();
        PermissionSet p2 = setPermSet2();
        PermissionSet p3 = setPermSet3();

        //Assign 'ACC' Permisison Set
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId= u.Id;
        psa.PermissionSetId = p.Id;
        insert psa;

        Employee__c e = setEmployee(u,'1','4','373','13946');

        BW_Channel_Mapping__c bcm = setBWChannel('1',String.valueOf(p.Id));
        BW_Channel_Mapping__c bcm1 = setBWChannel('2',String.valueOf(p1.Id));
        BW_Channel_Mapping__c bcm2 = setBWChannel('373',String.valueOf(p2.Id));
        BW_Channel_Mapping__c bcm3 = setBWChannel('13946',String.valueOf(p3.Id));
        BWMarketMaster__c bmm = setBWMarketMaster('4');
        BWMarketMaster__c bmm1 = setBWMarketMaster('300');
        BWUserMarketAssociation__c uma = setBWUMA(bmm.Id,true,u.Id);
        BWRoleMaster__c brm = setBWRoleMaster('KMRole','ACC Rep','41');
        BWRoleMaster__c brm1 = setBWRoleMaster('KMRole','C&C Rep','155');
        BWEmployeeRole__c ber = setBWEmpRole('KMRole','ACC Rep',e.Id);
        BWKMUserProfile__c kup =  setKUP(u.FederationIdentifier,'2','300','373','13946','155:999');

        test.startTest();
        KnowledgeUserProfileBatch kupb = new KnowledgeUserProfileBatch();
        Database.executeBatch(kupb, 1);
        test.stopTest();

        // Asserts
        // Check if perm set is assigned
        PermissionSetAssignment psaR = [Select Id,AssigneeId,PermissionSetId from PermissionSetAssignment where AssigneeId=:u.Id AND PermissionSet.Name='KM_ACC_Sales_Test' limit 1];
        system.assertEquals(p1.Id, psaR.PermissionSetId);

        // Check if UMA record with correct master is created
        list<BWUserMarketAssociation__c> umaR = [Select Id,Primary__c,BWMarketMaster__c,UserId__c from BWUserMarketAssociation__c];
        system.assertEquals(1, umaR.size());
        system.assertEquals(bmm1.Id, umaR[0].BWMarketMaster__c);
        system.assertEquals(u.Id, umaR[0].UserId__c);

        // Check if Employee Roles are created / updated
        list<BWEmployeeRole__c> listBers = [Select Id,KMProcessingStatus__c,RoleName__c,RoleValue__c,UserId__c from BWEmployeeRole__c];
        system.assertEquals(2, listBers.size());

        // Check if Employee Channel and Master Id are updated
        Employee__c emp = [select Id,BWDefaultKMChannel__c,BWDefault_KM_Master__c from Employee__c where Id=:e.Id];
        system.assertEquals('2', emp.BWDefaultKMChannel__c);
        system.assertEquals('300', emp.BWDefault_KM_Master__c);

        // Check if Knowledge User Profile Status got Updated
        BWKMUserProfile__c kupResult = [Select Id,Status__c from BWKMUserProfile__c where Id=:kup.Id];
        system.assertEquals('Completed Add', kupResult.Status__c);
        }

    }
}
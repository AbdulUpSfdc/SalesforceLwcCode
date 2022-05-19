/*User Story- 
 * Author: ag8026
 * */
@isTest
public class Profile_Perm_User_ReportTest {
 @isTest
    private static void testSetup(){
          Profile sysAdminProfile = [Select ID From Profile Where Name='System Administrator'];
        
        PermissionSet permSet =  new PermissionSet();
        permSet.Label ='Testperm1';
        permSet.Name ='Test_perm1';
        permSet.PERMISSIONSASSIGNPERMISSIONSETS=TRUE;
        insert permSet;
        
        List<User> userList = new List<User>();

        User sysAdministratorUser = Utility_Test.createTestUser(sysAdminProfile.ID, 'firstName_Admin', 'lastName_Admin');
        userList.add(sysAdministratorUser);
        insert userList;

        List<Utility_Test.UserPermissionSetWrapper> wrapperList = new List<Utility_Test.UserPermissionSetWrapper>();
        
        // sysAdmin
        Utility_Test.UserPermissionSetWrapper wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = userList[0];
        wrapper.permissionSetNames.add(permSet.Name);
        
        wrapperList.add(wrapper);

        Utility_Test.assignPermissionSet(wrapperList);
     
        }
@isTest
    public static void testUserRpt(){
          test.startTest();
           Profile_Perm_User_Report testrep = new Profile_Perm_User_Report();
			testrep.getReport();
            Integer i = Limits.getEmailInvocations();
            System.assertEquals(1, i);
            test.stopTest();
        
        
        
    }  
}
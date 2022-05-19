/* ================================================
* @author : Mike McKinley
* @date :   08/24/2020   
* @group : Case 
* @description : Generates test data for User
================================================*/

@isTest
public class TestData_User {
   	public static final String ROLE_NAME = 'TestingTeam';

	public static User generateUser(String profileName) {
        User u;
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            UserRole userRole;
            userRole = new UserRole(DeveloperName = ROLE_NAME, Name = ROLE_NAME);
            insert userRole;
            
            if(String.isBlank(profileName)) {
                profileName = 'System Administrator';
            }
            
            String emailName = generateEmail();
            
            u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id,
                LastName = 'last',
                Email = emailName,
                Username = emailName,
                Alias = emailName.substring(18, 23),
                CompanyName = 'Testing',
                TimeZoneSidKey = 'America/Chicago',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                UserRoleId = userRole.Id
            );
            
            insert u;
        }
        
        return u;
  	}
    
	private static final String DATE_FORMAT = 'ssSSS';
    public static String generateEmail() {
		String orgId = UserInfo.getOrganizationId();
    	String seconds = system.now().format(DATE_FORMAT);
    	return orgId + seconds + '@att.test.com';
    }
}
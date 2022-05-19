global without sharing class KMSandboxDataGenerator implements SandboxPostCopy {

        /*

To create a new agent and author user, run the following code in execute anonymous, changing your values accordingly.
You'll get a password reset.

String email = 'kjablonka@salesforce.com';
String firstName = 'kjablonka';
String authorlastName = 'Author';
String agentlastName = 'Agent';
String attUID = 'kj980n';
String username = null; // this will auto generate a lowercase user name in the form of: firstname + '.' + lastname + emailDomain + ORGNAME
//attuid must be unique
1) create record in employee table; base details 
2) create rec BWUserRole
3) run userprovisioning batch: 

Id,ATTUID__c,BusinessRole__c,DefaultChannelId__c,DefaultMarketId__c,EmployeeFlag__c,KSEmployeeTypeId__c,KSUserRole__c,Status__c,Sys_Role_ID__c FROM BWKMUserProfile__c
Batch Apex 1: KnowledgeUserProfileBatch b = new KnowledgeUserProfileBatch();
              Database.Executebatch(b,1);
Batch Apex 2: MarketCategorySetupBatch b = new MarketCategorySetupBatch();
                         Database.executeBatch(b,1);

4) 
python code is for data generation
csv files in package

test data


System.debug(KMSandboxDataGenerator.createAgentUser(email, firstname, agentlastName, username, attUID));
System.debug(KMSandboxDataGenerator.createAuthorUser(email, firstname, authorlastName, username, attUID));

//System.debug(KMSandboxDataGenerator.getEmailDomain(email));
*/
    
    public static final String ORGNAME = '.' + UserInfo.getUserName().substringAfterLast('.').toLowerCase();
    public static final Map<String, Id> profileNameMap = new Map<String, Id>();
    public static final Map<String, Id> psNameMap = new Map<String, Id>();
    public static final String KM_ROLE_AUTHOR = 'Author';
    public static final String KM_ROLE_AGENT = 'Agent';
    public static final String PROFILE_NAME_AUTHOR = 'Minimum Access Admin';
    public static final String PROFILE_NAME_AGENT = 'Minimum Access Agent';
    public static final String PERMISSION_SET_NAME_AUTHOR = 'KM_CA_Custom';
    public static final String PERMISSION_SET_NAME_AGENT = 'KM_Call_Center_Agent_Custom';
    
    static {
        List<PermissionSet> permissionSetList = [SELECT Id, Name FROM PermissionSet WHERE Name IN (:PERMISSION_SET_NAME_AUTHOR, :PERMISSION_SET_NAME_AGENT)];
        List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name IN (:PROFILE_NAME_AUTHOR, :PROFILE_NAME_AGENT )];
        for (PermissionSet ps: permissionSetList) {
         	psNameMap.put(ps.Name, ps.Id); 
        }
        for (Profile uprofile:profileList) {
         	profileNameMap.put(uprofile.Name, uprofile.Id); 
        }
    }
        
        
       
    
    public static User createAgentUser(String email, String firstName, String lastName, String userName, String attUID) {
        User newUser = createBaseKnowledgeUser(email, firstName, lastName, userName, attUID);
        return completeUserSetup(newUser, PROFILE_NAME_AGENT, PERMISSION_SET_NAME_AGENT);
    }
    
    public static User completeUserSetup(User newUser, String profileName, String permissionSetName) {
        newUser.ProfileId = profileNameMap.get(profileName); 
        insert newUser;
        assignPermissionSet(psNameMap.get(permissionSetName), newUser.Id);
        System.resetPassword(newUser.Id, true); 
        return newUser;
    }
    
    public static User createAuthorUser(String email, String firstName, String lastName, String userName, String attUID) {
        User newUser = createBaseKnowledgeUser(email, firstName, lastName, userName, attUID);
        return completeUserSetup(newUser, PROFILE_NAME_AUTHOR, PERMISSION_SET_NAME_AUTHOR);
    }
    
    global static void runApexClass(SandboxContext context) {
        System.debug('Context info' + context.organizationId() + ' ' + context.sandboxId() + context.sandboxName());
    }
    
    public static PermissionSetAssignment assignPermissionSet(Id permissionSetId, Id userId) {
        PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = permissionSetId, AssigneeId = userId);
		insert psa;
        return psa;
    }
    
    public static User createBaseKnowledgeUser(String email, String firstName, String lastName, String username, String attUID) {
        String emailDomain = getEmailDomain(email);
        
        if (username == null) {
            username = (firstname + '.' + lastname + emailDomain + ORGNAME).toLowerCase();
        }  
        User newUser = new User(
                Email = email,
                Username = username,
                LastName = lastName.deleteWhitespace(),
                FirstName = firstName.deleteWhiteSpace(),                  
                CompanyName = 'SandboxTestUser',
                Title = 'title',
                Alias = 'talias',
                TimeZoneSidKey = 'America/Chicago',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                UserPermissionsKnowledgeUser = TRUE,
        		isActive = TRUE,
          	ATTUID__c = attUID);
                
         return newUser;   
    }
    
    public static String getEmailDomain(String email) {
        String emailDomain = '';
        if (email != null) {
           List<String> emailParts = email.split('@');
            if (emailParts.size() > 0 ) {
           		 emailDomain = '@' + emailParts[1]; 
            }    
        } else {
            emailDomain = '@salesforce.com';
        }
        return emailDomain;
    }
   
    
}
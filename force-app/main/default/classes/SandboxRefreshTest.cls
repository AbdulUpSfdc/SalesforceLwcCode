/* 
 * This is a test class to test the SandboxRefresh Class
 * @Author - Daemin Lee
*/

@isTest
without sharing class SandboxRefreshTest {
    
    //This test set-up class populates the Sandbox with Test Deployment Records and assures that there is at least 1 Deployment Record prior to the test Sandbox Refresh
    @testSetup 
    static void preRefreshTestPopulation(){
        List<Deployment__c> testDeployRecords = new List<Deployment__c>();
        for(Integer x=0; x<6; x++){
            testDeployRecords.add(new Deployment__c(Name = 'Test Deploy' + x));
        } 
        insert testDeployRecords;
        Integer preDeployRecordNum = [Select COUNT() FROM Deployment__c WITH SECURITY_ENFORCED];
        System.debug('Total Number of Deployment Records Before Sandbox Refresh: ' + preDeployRecordNum);
        System.Assert(preDeployRecordNum>0,'There must be at least 1 deployment record to properly test post sandbox refresh deployment records deletion');
    }

    @isTest
    static void SandboxRefreshTestMethod(){
        
    //Executes an test sandbox refresh
    Test.startTest();
        Test.testSandboxPostCopyScript(
            new SandboxRefresh(), 
            UserInfo.getOrganizationId(), 
            UserInfo.getOrganizationId(), 
            UserInfo.getOrganizationName()
        ); 
    Test.stopTest();
    /*Pulls Federation Identifier and Email address from Users with the "System Administrator" Production Profile 
    *Extrapolated from the User Record Custom Metadata Type
    */
    List <UserRecord__mdt> adminUsers = new List<UserRecord__mdt>();
    adminUsers = [Select Federation_Id__c from UserRecord__mdt WITH SECURITY_ENFORCED];
    List<String> mandatoryAdmins = new List<String>{'dl336s','pc891b','my087d','ai087d', 'sl469u', 'kb9404', 'si570d', 'rv0834', 'hr548g', 'mk594g', 'cs027e'};
    Set<String> fedIdCustomMeta = new Set<String>(mandatoryAdmins);
	List<String> emailsPostSandboxRefresh= new List<String>();

    //Adds Federation Identifier from the User Record Custom Metadata Type to an list
    For (UserRecord__mdt addedUsers : adminUsers){
        fedIdCustomMeta.add(addedUsers.Federation_Id__c);
    }
    

 /*Searches active users within the sandbox, 
    *based on the Federation Identifier, extrapolated by the User Record Custom Metadata Type
    */
    List<User> searchedUsers = [SELECT id, email, username, FederationIdentifier, isActive 
    FROM User
    WHERE FederationIdentifier IN :fedIdCustomMeta AND isActive = true WITH SECURITY_ENFORCED
    ];

      //Prints SysAdmin Emails from the Sandbox to debug.log 
      For (User currentUser : searchedUsers){
        System.debug('Email in Sandbox Post Refresh: ' + currentUser.Email);
        emailsPostSandboxRefresh.add(currentUser.Email);
      }
        
    //Ensures that there is no deployment record after an sandbox refresh.
    Integer postDeployRecordNum = [Select COUNT() FROM Deployment__c WITH SECURITY_ENFORCED];
    System.debug('Number of Deployment Records after Refresh: '+ postDeployRecordNum);
    System.assertEquals(0, postDeployRecordNum);

    //Validates that the email addresses from the Sandbox does not contain ".invalid"
    For(String emailValidated: emailsPostSandboxRefresh){

        Boolean containsInvalid=true;
        if(emailValidated.contains('.invalid')){
        containsInvalid = false;  
        } 
    System.assertEquals(true, containsInvalid);
   }
        //end of test
}
}
/* 
 * This is a class used by the DevOps Team to automate on User Provisioning 
 * after every sandbox refresh by correcting invalid emails and resets password
 * @Author - Daemin Lee and Krishna Bomma
 * 
 * Notes:
 * ALL SOQL Queries have to include 'WITH SECURITY_ENFORCED' for considerations of field level security vulnerabilities
 * Explicit sharing definition of the 'without sharing' definition for the class is included to pass SonarQube Security scans
*/

//Class executes after every SandboxPostCopy

global without sharing class SandboxRefresh implements SandboxPostCopy {
  global void runApexClass(SandboxContext context) {
//Constant Variable that limits on how many admin users are provisioned.
 final Integer MAX_ADMINS=15;

 List<String> mandatoryAdmins = new List<String>{'dl336s', 'pc891b','my087d','ai087d', 'sl469u', 'kb9404', 'si570d', 'rv0834', 'hr548g', 'mk594g', 'cs027e'};

//Pulls Federation ID from the User Record Custom Metadata Type 
//and add it to a Federation Identifier list.
 List <UserRecord__mdt> adminUsersMeta = new List<UserRecord__mdt>();
 adminUsersMeta = [Select Federation_Id__c from UserRecord__mdt WITH SECURITY_ENFORCED];
 Set<String> fedIdList = new Set<String>(mandatoryAdmins);

 For (UserRecord__mdt usersAdded : adminUsersMeta){ 
    fedIdList.add(usersAdded.Federation_Id__c);
 }
      
  /* Queries Active users within
  * the Sandbox through the fedIdList extrapolated of the User Record Custom Metadata Type  
  */
  List<User> sandboxAdminUsers = new List<User>();
  sandboxAdminUsers = [SELECT id, email, Username, FederationIdentifier, IsActive 
  FROM User 
  WHERE FederationIdentifier IN :fedIdList AND IsActive = true 
 WITH SECURITY_ENFORCED
  ];

  //Security fail-safe to catch excessive updates to users with System Administrator profiles as limited by the MAX_ADMINS constant for Admin User Provisioning Post-Sandbox Refresh
  System.debug('Total Number of System Administrators : ' + sandboxAdminUsers.size());
  if(sandboxAdminUsers.size() > MAX_ADMINS){
    System.debug('Sandbox System Administrator Limit of '+ MAX_ADMINS +' Users has been reached');
    System.assert(false);
  }

  System.debug('List of Admin Users in the Sandbox: ');
  for(User listAdminResults:sandboxAdminUsers){
    System.debug(listAdminResults.Email);
  }

  
  //Corrects and sets users' email
  for (User currentUser : sandboxAdminUsers){
  if(currentUser.Id == UserInfo.getUserId()){
    System.debug('User email of whom initialized the Sandbox Refresh: ' + currentUser.FederationIdentifier+' has not been changed');
  }
      else if(currentUser.Id != UserInfo.getUserId()){
    currentUser.email = currentUser.email.removeEndIgnoreCase('.invalid');
    System.debug('Email for user: ' + currentUser.FederationIdentifier + ' has been corrected to: ' + currentUser.email);
      }
 }

  //DML Statement to update all the Admin users' email address within the Sandbox
  update sandboxAdminUsers;

  //When the email is changed an system email SHOULD be sent to the changed email address
  // to verify the change for that designated user name in the Sandbox post refresh. 
  //Which will then allow the system administrators to reset their password

  //Pre-Refresh Deployment Record Deletion

  //Collects and bulkifies ALL of the existing deployment records into an Deployment__c List and Details
  List<Deployment__c> prevDeployments = [Select Name FROM Deployment__c WITH SECURITY_ENFORCED];
  System.debug('The Following Deployment Records will now be deleted:');
  for(Deployment__c deployRecord : prevDeployments){
    System.debug(deployRecord.Name);
  }

  //DML statement takes the prevDeployment list and deletes them with DML exception handling p
  try{
    delete prevDeployments;
  } catch(DmlException e){
    System.debug(e.getMessage());
  }

}
//end of method
}
//end of class
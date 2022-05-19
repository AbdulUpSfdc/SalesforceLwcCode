public  with sharing class Profile_Perm_User_Report {
   public void getReport(){
        List<String> rows = new List<String> { 'PermissionSet Name,PermissionSet Id,UserId,UserName,Email,Is Active,FederationIdentifier,Created Date,Last Login Date,Profile Name,User Role Name,PERMISSIONSASSIGNPERMISSIONSETS,  PERMISSIONSAUTHORAPEX, PERMISSIONSCUSTOMIZEAPPLICATION,  PERMISSIONSEDITREADONLYFIELDS, PERMISSIONSMANAGEAUTHPROVIDERS, PERMISSIONSMANAGECERTIFICATES, PERMISSIONSMANAGECONTENTPERMISSIONS, PERMISSIONSMANAGECUSTOMPERMISSIONS, PERMISSIONSMANAGEDATAINTEGRATIONS, PERMISSIONSMANAGEENCRYPTIONKEYS, PERMISSIONSMANAGEHEALTHCHECK, PERMISSIONSMANAGEINTERNALUSERS, PERMISSIONSMANAGEIPADDRESSES, PERMISSIONSMANAGELOGINACCESSPOLICIES, PERMISSIONSMANAGENETWORKS, PERMISSIONSMANAGEPARTNERS, PERMISSIONSMANAGEPASSWORDPOLICIES, PERMISSIONSMANAGEPROFILESPERMISSIONSETS, PERMISSIONSMANAGEREMOTEACCESS, PERMISSIONSMANAGEROLES, PERMISSIONSMANAGESHARING, PERMISSIONSMANAGEUSERS, PERMISSIONSMODIFYALLDATA, PERMISSIONSMODIFYMETADATA , PERMISSIONSRESETPASSWORDS' };
List<String> rows1 = new List<String> { 'Profile.Name,Profile Id,UserId,UserName,Email,Is Active,FederationIdentifier,Created Date,Last Login Date,User Role Name,PERMISSIONSASSIGNPERMISSIONSETS,  PERMISSIONSAUTHORAPEX, PERMISSIONSCUSTOMIZEAPPLICATION,  PERMISSIONSEDITREADONLYFIELDS,  PERMISSIONSMANAGEAUTHPROVIDERS, PERMISSIONSMANAGECERTIFICATES, PERMISSIONSMANAGECONTENTPERMISSIONS, PERMISSIONSMANAGECUSTOMPERMISSIONS, PERMISSIONSMANAGEDATAINTEGRATIONS, PERMISSIONSMANAGEENCRYPTIONKEYS, PERMISSIONSMANAGEHEALTHCHECK, PERMISSIONSMANAGEINTERNALUSERS, PERMISSIONSMANAGEIPADDRESSES, PERMISSIONSMANAGELOGINACCESSPOLICIES, PERMISSIONSMANAGENETWORKS, PERMISSIONSMANAGEPARTNERS, PERMISSIONSMANAGEPASSWORDPOLICIES, PERMISSIONSMANAGEPROFILESPERMISSIONSETS, PERMISSIONSMANAGEREMOTEACCESS, PERMISSIONSMANAGEROLES, PERMISSIONSMANAGESHARING, PERMISSIONSMANAGEUSERS, PERMISSIONSMODIFYALLDATA, PERMISSIONSMODIFYMETADATA, PERMISSIONSRESETPASSWORDS' };
List<Profile> profallowed = new List<Profile>([SELECT Id, name FROM Profile WHERE
			 PERMISSIONSASSIGNPERMISSIONSETS=TRUE OR PERMISSIONSAUTHORAPEX=TRUE OR 
             PERMISSIONSCUSTOMIZEAPPLICATION=TRUE OR PERMISSIONSEDITREADONLYFIELDS=TRUE OR 
             PERMISSIONSMANAGEAUTHPROVIDERS=TRUE OR PERMISSIONSMANAGECERTIFICATES=TRUE OR 
             PERMISSIONSMANAGECONTENTPERMISSIONS=TRUE OR PERMISSIONSMANAGECUSTOMPERMISSIONS=TRUE OR 
             PERMISSIONSMANAGEDATAINTEGRATIONS=TRUE OR PERMISSIONSMANAGEENCRYPTIONKEYS=TRUE OR 
             PERMISSIONSMANAGEHEALTHCHECK=TRUE OR PERMISSIONSMANAGEINTERNALUSERS=TRUE OR 
             PERMISSIONSMANAGEIPADDRESSES=TRUE OR PERMISSIONSMANAGELOGINACCESSPOLICIES=TRUE OR 
             PERMISSIONSMANAGENETWORKS=TRUE OR PERMISSIONSMANAGEPARTNERS=TRUE OR 
             PERMISSIONSMANAGEPASSWORDPOLICIES=TRUE OR PERMISSIONSMANAGEPROFILESPERMISSIONSETS=TRUE OR 
             PERMISSIONSMANAGEREMOTEACCESS=TRUE OR PERMISSIONSMANAGEROLES=TRUE OR 
             PERMISSIONSMANAGESHARING=TRUE OR PERMISSIONSMANAGEUSERS=TRUE OR 
             PERMISSIONSMODIFYALLDATA=TRUE OR PERMISSIONSMODIFYMETADATA=TRUE OR 
             PERMISSIONSRESETPASSWORDS=TRUE
				ORDER BY NAME]);
    System.debug('profallowed:'+ profallowed);
Set<ID> profID = new Set<ID>();
for(Profile p:profallowed)
{
    profID.add(p.Id);
}
List<Permissionset> permallowed = new List<Permissionset>([SELECT Id, name,IsOwnedByProfile
									FROM Permissionset WHERE
(PERMISSIONSASSIGNPERMISSIONSETS=TRUE OR PERMISSIONSAUTHORAPEX=TRUE OR 
 PERMISSIONSCUSTOMIZEAPPLICATION=TRUE OR PERMISSIONSEDITREADONLYFIELDS=TRUE OR 
 PERMISSIONSMANAGEAUTHPROVIDERS=TRUE OR PERMISSIONSMANAGECERTIFICATES=TRUE OR 
 PERMISSIONSMANAGECONTENTPERMISSIONS=TRUE OR PERMISSIONSMANAGECUSTOMPERMISSIONS=TRUE OR 
 PERMISSIONSMANAGEDATAINTEGRATIONS=TRUE OR PERMISSIONSMANAGEENCRYPTIONKEYS=TRUE OR 
 PERMISSIONSMANAGEHEALTHCHECK=TRUE OR PERMISSIONSMANAGEINTERNALUSERS=TRUE OR 
 PERMISSIONSMANAGEIPADDRESSES=TRUE OR PERMISSIONSMANAGELOGINACCESSPOLICIES=TRUE OR 
 PERMISSIONSMANAGENETWORKS=TRUE OR PERMISSIONSMANAGEPARTNERS=TRUE OR 
 PERMISSIONSMANAGEPASSWORDPOLICIES=TRUE OR PERMISSIONSMANAGEPROFILESPERMISSIONSETS=TRUE OR 
 PERMISSIONSMANAGEREMOTEACCESS=TRUE OR PERMISSIONSMANAGEROLES=TRUE OR 
 PERMISSIONSMANAGESHARING=TRUE OR PERMISSIONSMANAGEUSERS=TRUE OR 
 PERMISSIONSMODIFYALLDATA=TRUE OR PERMISSIONSMODIFYMETADATA=TRUE OR 
 PERMISSIONSRESETPASSWORDS=TRUE)                                                          
 and IsOwnedByProfile = false ORDER BY NAME]);
    System.debug('permallowed:'+ permallowed);
Set<ID> permID = new Set<ID>();
for(Permissionset pr:permallowed)
{
    permID.add(pr.Id);
}

List<PermissionSetAssignment> permAss = new List<PermissionSetAssignment>();
if(!test.isRunningTest()){
permAss = [SELECT  PermissionSet.Name,PermissionSet.Id,AssigneeId, Assignee.Name,Assignee.IsActive,Assignee.FederationIdentifier, Assignee.UserRoleId, Assignee.UserRole.Name, Assignee.CreatedDate, Assignee.LastLoginDate,Assignee.Profile.Name, Assignee.Email,PermissionSet.PERMISSIONSASSIGNPERMISSIONSETS,
	 PermissionSet.PERMISSIONSAUTHORAPEX, PermissionSet.PERMISSIONSCUSTOMIZEAPPLICATION,  PermissionSet.PERMISSIONSEDITREADONLYFIELDS, PermissionSet.PERMISSIONSMANAGEAUTHPROVIDERS, PermissionSet.PERMISSIONSMANAGECERTIFICATES, PermissionSet.PERMISSIONSMANAGECONTENTPERMISSIONS, PermissionSet.PERMISSIONSMANAGECUSTOMPERMISSIONS, PermissionSet.PERMISSIONSMANAGEDATAINTEGRATIONS, PermissionSet.PERMISSIONSMANAGEENCRYPTIONKEYS, PermissionSet.PERMISSIONSMANAGEHEALTHCHECK, PermissionSet.PERMISSIONSMANAGEINTERNALUSERS, PermissionSet.PERMISSIONSMANAGEIPADDRESSES, PermissionSet.PERMISSIONSMANAGELOGINACCESSPOLICIES, PermissionSet.PERMISSIONSMANAGENETWORKS, PermissionSet.PERMISSIONSMANAGEPARTNERS, PermissionSet.PERMISSIONSMANAGEPASSWORDPOLICIES, PermissionSet.PERMISSIONSMANAGEPROFILESPERMISSIONSETS, PermissionSet.PERMISSIONSMANAGEREMOTEACCESS, PermissionSet.PERMISSIONSMANAGEROLES, PermissionSet.PERMISSIONSMANAGESHARING, PermissionSet.PERMISSIONSMANAGEUSERS, PermissionSet.PERMISSIONSMODIFYALLDATA, PermissionSet.PERMISSIONSMODIFYMETADATA, PermissionSet.PERMISSIONSRESETPASSWORDS
     FROM PermissionSetAssignment where PermissionSet.Id 
               IN :permID order by Assignee.IsActive desc,PermissionSet.Name,Assignee.FederationIdentifier];
}
else
{
    permAss = [SELECT  PermissionSet.Name,PermissionSet.Id,AssigneeId, Assignee.Name,Assignee.IsActive,Assignee.FederationIdentifier, Assignee.UserRoleId, Assignee.UserRole.Name, Assignee.CreatedDate, Assignee.LastLoginDate,Assignee.Profile.Name, Assignee.Email,PermissionSet.PERMISSIONSASSIGNPERMISSIONSETS,
         PermissionSet.PERMISSIONSAUTHORAPEX, PermissionSet.PERMISSIONSCUSTOMIZEAPPLICATION,  PermissionSet.PERMISSIONSEDITREADONLYFIELDS, PermissionSet.PERMISSIONSMANAGEAUTHPROVIDERS, PermissionSet.PERMISSIONSMANAGECERTIFICATES, PermissionSet.PERMISSIONSMANAGECONTENTPERMISSIONS, PermissionSet.PERMISSIONSMANAGECUSTOMPERMISSIONS, PermissionSet.PERMISSIONSMANAGEDATAINTEGRATIONS, PermissionSet.PERMISSIONSMANAGEENCRYPTIONKEYS, PermissionSet.PERMISSIONSMANAGEHEALTHCHECK, PermissionSet.PERMISSIONSMANAGEINTERNALUSERS, PermissionSet.PERMISSIONSMANAGEIPADDRESSES, PermissionSet.PERMISSIONSMANAGELOGINACCESSPOLICIES, PermissionSet.PERMISSIONSMANAGENETWORKS, PermissionSet.PERMISSIONSMANAGEPARTNERS, PermissionSet.PERMISSIONSMANAGEPASSWORDPOLICIES, PermissionSet.PERMISSIONSMANAGEPROFILESPERMISSIONSETS, PermissionSet.PERMISSIONSMANAGEREMOTEACCESS, PermissionSet.PERMISSIONSMANAGEROLES, PermissionSet.PERMISSIONSMANAGESHARING, PermissionSet.PERMISSIONSMANAGEUSERS, PermissionSet.PERMISSIONSMODIFYALLDATA, PermissionSet.PERMISSIONSMODIFYMETADATA, PermissionSet.PERMISSIONSRESETPASSWORDS
         FROM PermissionSetAssignment where PermissionSet.Id 
                   IN ('0PS6g000004lVqHGAU') order by Assignee.IsActive desc,PermissionSet.Name,Assignee.FederationIdentifier];
     
}   
for(PermissionSetAssignment psa : permAss){
    rows.add(psa.PermissionSet.Name + ',' + psa.PermissionSet.Id+ ',' + psa.AssigneeId + ','+ psa.Assignee.Name+ ','+ psa.Assignee.Email+ ','+ psa.Assignee.IsActive
            + ','+ psa.Assignee.FederationIdentifier+ ','+ psa.Assignee.CreatedDate+ ','+ psa.Assignee.LastLoginDate+ ','+ psa.Assignee.Profile.Name
            + ','+ psa.Assignee.UserRole.Name+ ','+ psa.PermissionSet.PERMISSIONSASSIGNPERMISSIONSETS+  ','+ psa.PermissionSet.PermissionsAuthorApex
            +','+psa.PermissionSet.PermissionsCustomizeApplication
            +','+psa.PermissionSet.PermissionsEditReadonlyFields
            +','+psa.PermissionSet.PermissionsManageAuthProviders+','+psa.PermissionSet.PermissionsManageCertificates
            +','+psa.PermissionSet.PermissionsManageContentPermissions+','+psa.PermissionSet.PermissionsManageCustomPermissions
            +','+psa.PermissionSet.PermissionsManageDataIntegrations+','+psa.PermissionSet.PermissionsManageEncryptionKeys
            +','+psa.PermissionSet.PermissionsManageHealthCheck+','+psa.PermissionSet.PermissionsManageInternalUsers
            +','+psa.PermissionSet.PermissionsManageIpAddresses+','+psa.PermissionSet.PermissionsManageLoginAccessPolicies
            +','+psa.PermissionSet.PermissionsManageNetworks+','+psa.PermissionSet.PermissionsManagePartners
            +','+psa.PermissionSet.PermissionsManagePasswordPolicies+','+psa.PermissionSet.PermissionsManageProfilesPermissionsets
            +','+psa.PermissionSet.PermissionsManageRemoteAccess+','+psa.PermissionSet.PermissionsManageRoles+','+psa.PermissionSet.PermissionsManageSharing
            +','+psa.PermissionSet.PermissionsManageUsers+','+psa.PermissionSet.PermissionsModifyAllData+','+psa.PermissionSet.PermissionsModifyMetadata
            +','+psa.PermissionSet.PermissionsResetPasswords);
}

List<User> user1 = new List<User>(
    [SELECT Profile.Name, Id,Name,IsActive, FederationIdentifier, profile.Id,  
     UserRoleId, UserRole.Name,CreatedDate, LastLoginDate,Email,Profile.PERMISSIONSASSIGNPERMISSIONSETS,
	 Profile.PERMISSIONSAUTHORAPEX, Profile.PERMISSIONSCUSTOMIZEAPPLICATION, Profile.PERMISSIONSEDITREADONLYFIELDS, Profile.PERMISSIONSMANAGEAUTHPROVIDERS, Profile.PERMISSIONSMANAGECERTIFICATES, Profile.PERMISSIONSMANAGECONTENTPERMISSIONS, Profile.PERMISSIONSMANAGECUSTOMPERMISSIONS, Profile.PERMISSIONSMANAGEDATAINTEGRATIONS, Profile.PERMISSIONSMANAGEENCRYPTIONKEYS, Profile.PERMISSIONSMANAGEHEALTHCHECK, Profile.PERMISSIONSMANAGEINTERNALUSERS, Profile.PERMISSIONSMANAGEIPADDRESSES, Profile.PERMISSIONSMANAGELOGINACCESSPOLICIES, Profile.PERMISSIONSMANAGENETWORKS, Profile.PERMISSIONSMANAGEPARTNERS, Profile.PERMISSIONSMANAGEPASSWORDPOLICIES, Profile.PERMISSIONSMANAGEPROFILESPERMISSIONSETS, Profile.PERMISSIONSMANAGEREMOTEACCESS, Profile.PERMISSIONSMANAGEROLES, Profile.PERMISSIONSMANAGESHARING, Profile.PERMISSIONSMANAGEUSERS, Profile.PERMISSIONSMODIFYALLDATA, Profile.PERMISSIONSMODIFYMETADATA, Profile.PERMISSIONSRESETPASSWORDS
	 FROM User WHERE Profile.Id 
     IN :profID    
     order by IsActive desc,Profile.Name,FederationIdentifier ]);
    
for(User ur : user1){
    rows1.add(ur.Profile.Name + ',' + ur.profile.Id + ','+ ur.Id + ','+ ur.Name + ','+ ur.Email+','+ur.IsActive+ ','+ur.FederationIdentifier
            + ',' + ur.CreatedDate + ',' + ur.LastLoginDate+ ',' + ur.UserRole.Name
			+ ','+ ur.Profile.PERMISSIONSASSIGNPERMISSIONSETS+ ','+ ur.Profile.PermissionsAuthorApex
            +','+ur.Profile.PermissionsCustomizeApplication
            +','+ur.Profile.PermissionsEditReadonlyFields
            +','+ur.Profile.PermissionsManageAuthProviders+','+ur.Profile.PermissionsManageCertificates
            +','+ur.Profile.PermissionsManageContentPermissions+','+ur.Profile.PermissionsManageCustomPermissions
            +','+ur.Profile.PermissionsManageDataIntegrations+','+ur.Profile.PermissionsManageEncryptionKeys
            +','+ur.Profile.PermissionsManageHealthCheck+','+ur.Profile.PermissionsManageInternalUsers
            +','+ur.Profile.PermissionsManageIpAddresses+','+ur.Profile.PermissionsManageLoginAccessPolicies
            +','+ur.Profile.PermissionsManageNetworks+','+ur.Profile.PermissionsManagePartners
            +','+ur.Profile.PermissionsManagePasswordPolicies+','+ur.Profile.PermissionsManageProfilesPermissionsets
            +','+ur.Profile.PermissionsManageRemoteAccess+','+ur.Profile.PermissionsManageRoles+','+ur.Profile.PermissionsManageSharing
            +','+ur.Profile.PermissionsManageUsers+','+ur.Profile.PermissionsModifyAllData+','+ur.Profile.PermissionsModifyMetadata
            +','+ur.Profile.PermissionsResetPasswords);
}

//String flNameDate = getFlDate(); 
Datetime myDT = Datetime.now();
String month = myDT.format('MM');
String day = myDT.format('dd');
String flNameDate = String.valueOf(myDT.year())+month+day;  
       
 System.debug('FileNameDate::'+flNameDate);      
       
List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();

Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
efa.setBody(Blob.valueOf(String.join(rows, '\n')));
efa.setFileName('Users_wAdminPermissions_ByPSet_'+flNameDate+'.csv');
attachments.add(efa);

Messaging.EmailFileAttachment efa1 = new Messaging.EmailFileAttachment();
efa1.setBody(Blob.valueOf(String.join(rows1, '\n')));
efa1.setFileName('Users_wAdminPermissions_ByProfile_'+flNameDate+'.csv');
attachments.add(efa1);

System.debug('dd::'+permAss);
System.debug('rows::'+rows);
Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
List<String> sendingTo = new List<String>(); 
List<String> sendingToTest = new List<String>();        
      
//String[] sendingTo = new String[]{'ag8026@att.com','aurabindo.gopu@accenture.com'}; 
   sendingTo.add('CCSF_SECURITY_DL@list.att.com');
   sendingTo.add('sp160t@att.com') ;  
   sendingTo.add('hugo.reyes@salesforce.com'); 
//   sendingTo.add('aurabindo.gopu@accenture.com') ;    
      
 sendingToTest.add('test@test.com');  
       
       if(!test.isRunningTest()){     
	email.setToAddresses(sendingTo);
       }
    else{
        email.setToAddresses(sendingToTest);
    }
   

System.debug('Sendto::'+sendingTo);
//email.setTargetObjectId(UserInfo.getUserId());
email.setSubject('Users with Administrative Permissions');
email.setPlainTextBody('Hi, Please see attached List of Users for both Profiles and Permissions who have Administrative Permissions');
//email.setSaveAsActivity(false);
email.setFileAttachments(attachments);
Messaging.sendEmail(new Messaging.SingleEmailMessage[]  { email });
System.debug('Email Sent');
    }
        
}
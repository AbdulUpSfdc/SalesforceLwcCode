public without sharing class WithoutSharingHelper {

    /*this method returns a tepmplate if its owner or last modified user is part of the specified group name. It has 
     * to be run without sharing because of the queries on groups and emailtemplates*/
    
	public static EmailTemplate getEmailTemplateById(Id emailTemplateId, String groupDevName) {
        List<GroupMember> memberList = [Select Group.DeveloperName, UserorGroupId FROM GroupMember Where Group.DeveloperName = :groupDevName];
        System.debug('Members of email group: ' + memberList);
        Set<Id> memberSet = new Set<Id>();
        for (GroupMember gm : memberList) {
            memberSet.add(gm.UserorGroupId);
        }
        List<EmailTemplate> templateList = [SELECT Id, FolderName, developername, CreatedById,LastModifiedById FROM EmailTemplate 
                                            WHERE Id = :emailTemplateId];
        if (templateList.isEmpty()) {
        	System.debug('No email template found matching Id: ' + emailTemplateId);
            return null;
        } else {
            System.debug('Email templates found: ' + templateList);
            if (memberset.contains(templateList[0].LastModifiedById ) || memberset.contains(templateList[0].CreatedById )) {
                System.debug('Group match found on creator or last modified');
                return templateList[0];
            } else 
                System.debug('No group match found on creator or last modified');

                return null;
            }  
    }
        

    
    
}
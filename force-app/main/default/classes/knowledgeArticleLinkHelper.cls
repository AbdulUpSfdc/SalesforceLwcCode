public with sharing class knowledgeArticleLinkHelper {
     private static string KM_CA_CUSTOM = 'KM_CA_Custom';
     private static string KM_CA_NO_FRONTLINE_CUSTOM = 'KM_CA_noFrontline_Custom';
    
    public static void beforeDelete(Map<Id,BWKnowledgeArticleLink__c> articleLinkRecords){
      if(articleLinkRecords!=null){
       // SELECT Id, PermissionSetId, PermissionSet.Name, PermissionSet.ProfileId, PermissionSet.Profile.Name, AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE Assignee.Name = 'JOHN SMITH'
       Set<String> permissionSetNames = new Set<String>();
       for (PermissionSetAssignment gm : [ SELECT Id, PermissionSetId, PermissionSet.Name, PermissionSet.ProfileId, PermissionSet.Profile.Name, AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE AssigneeId =:UserInfo.getUserId()]){
                   permissionSetNames.add(gm.PermissionSet.Name);
        }
        List<BWKnowledgeArticleLink__c> articleLinkList=[select Id,ShareLinkURL__c from BWKnowledgeArticleLink__c where Id IN:articleLinkRecords.keySet()];
        for(BWKnowledgeArticleLink__c articleObj : articleLinkList){
            if(articleObj.ShareLinkURL__c==null || articleObj.ShareLinkURL__c== '' ){
                if(permissionSetNames.contains(KM_CA_CUSTOM) || permissionSetNames.contains(KM_CA_NO_FRONTLINE_CUSTOM) ){
				
                BWKnowledgeArticleLink__c actualRecord = articleLinkRecords.get(articleObj.Id);
                    //&& UserInfo.getUserId() != articleLink.CreatedById
                    actualRecord.addError('You can only delete Emailable Article links'); 
                }
				
            }
            
        }  
      }
    }

}
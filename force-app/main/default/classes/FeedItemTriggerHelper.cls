public with sharing class FeedItemTriggerHelper {
    
   // private static string sponsorPostFix = '@salesforce.com';
    private static string sponsorPostFix = '@att.com';
    private static string htmlBody = '';
    private static string sechtmlBody = '';
    public static final String FEEDCOMMENT_TEXT = 'commented on a Chatter Post of Knowledge';
   
    public static void afterInsert(List<FeedComment> feedCommentList){
        
        String knowldegeKeyPrefix = Knowledge__ka.sObjectType.getDescribe().getKeyPrefix(); //kA0
        Map<Id,String> contentSponsor = new Map<Id,String>();
        Map<Id,String> secContentSponsor = new Map<Id,String>();
        Set<Id> feedCommentParentId = new Set<Id>();
        Set<Id> feedCommentItemID = new Set<Id>(); 
        Map<String,Knowledge__kav> knowledgeIdMap = new Map<String,Knowledge__kav>();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<Knowledge__kav> knowledgeList = new List<Knowledge__kav>();
        
        if(!feedCommentList.isEmpty() && feedCommentList.size() > 0){
        	for(FeedComment feedComment : feedCommentList){
             	if(feedComment.ParentId != NULL && String.ValueOf(feedComment.ParentId).startsWith('kA0')){
                 	feedCommentParentId.add(feedComment.ParentId);
                 	feedCommentItemID.add(feedComment.FeedItemId);
             	}
     
        	}
        }
        
      
        for(Knowledge__kav knowledge : [SELECT Id, versionnumber,Title,IsLatestVersion,ContentSponsor__c,BWSecContentSponsor__c , createddate, ArticleNumber, publishstatus, KnowledgeArticleId, 
                                        BWScheduledArticlePublicationDate__c FROM Knowledge__kav where KnowledgeArticleId IN : feedCommentParentId]){
             if(knowledge.ContentSponsor__c != NULL  ){
                 contentSponsor.put(knowledge.KnowledgeArticleId,knowledge.ContentSponsor__c + sponsorPostFix);
                   system.debug('contentSponsor'+ contentSponsor);
                 knowledgeIdMap.put(knowledge.KnowledgeArticleId,knowledge);                
            }
          if(knowledge.BWSecContentSponsor__c != NULL  ){
                 secContentSponsor.put(knowledge.KnowledgeArticleId,knowledge.BWSecContentSponsor__c + sponsorPostFix);
              system.debug('secContentSponsor'+ secContentSponsor);
            }                               
         }
       
        
        User u = [select id,firstname,lastname from user where id=:userinfo.getuserid()];
        // Query from Organization-Wide Email Address  
        Id orgwideIdAddressId;
        String displayName = 'Message From AT&T';     
        List<OrgWideEmailAddress> lstEmailAddress=[select Id, Displayname from OrgWideEmailAddress WHERE Displayname= :displayName];
       
        if (!lstEmailAddress.isEmpty()) {
        	orgwideIdAddressId = lstEmailAddress[0].Id;
        }
        for(FeedComment feedComment : feedCommentList){
            if(contentSponsor.get(feedComment.parentId)!= null){
                system.debug('Inside Content Sponsor');
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
                List<String> sendTo = new List<String>();
      			sendTo.add(contentSponsor.get(feedComment.ParentId));
      			mail.setToAddresses(sendTo);
                if (orgwideIdAddressId != null && !Test.isRunningTest()) {
                	mail.setOrgWideEmailAddressId(orgwideIdAddressId);
                } else {
                	mail.setSenderDisplayName(displayName);  //this can't be used when using orgwide email
                }  
                mail.setSubject(u.firstname +' '+ u.lastname +' '+ FEEDCOMMENT_TEXT);
                htmlBody= 'User Name: ' + u.firstname + ' '+ u.lastname +'<br/>';  
                htmlBody+= 'Feed Comment Details:'+'  '+feedComment.CommentBody+'<br/>';
                htmlBody+= 'For more details, please review the FeedItem here: '+'<br/>';
                htmlBody+=	URL.getSalesforceBaseUrl().toExternalForm()+'/'+feedComment.FeedItemId+'<br></br>';
                htmlBody+='Original Post: '+'<br/>';
                htmlBody+= 'Feed Details: '+' '+ knowledgeIdMap.get(feedComment.parentId).Title +'- '+ u.firstname +' '+ u.lastname +' '+'published this knowledge'+'<br/>';
                htmlBody+= 'Feed Created Date: '+' '+ feedComment.CreatedDate+'<br/>';
                htmlBody+= 'Feed Comment Details:'+' '+feedComment.CommentBody+'<br/>';
                htmlBody+= 'Feed Comment Created Date: ' + ' ' +feedComment.CreatedDate;
                string plainTextBody = htmlBody;
                mail.setHtmlBody(plainTextBody);
                mails.add(mail);
            
            }
            if(secContentSponsor.get(feedComment.parentId)!= null ){
              system.debug('Inside Secondary Content Sponsor');
                Messaging.SingleEmailMessage secmail = new Messaging.SingleEmailMessage(); 
                List<String> secsendTo = new List<String>();
      			secsendTo.add(secContentSponsor.get(feedComment.ParentId));
      			secmail.setToAddresses(secsendTo);
                if (orgwideIdAddressId != null && !Test.isRunningTest()) {
                	secmail.setOrgWideEmailAddressId(orgwideIdAddressId);
                } else {
                	secmail.setSenderDisplayName(displayName);  //this can't be used when using orgwide email
                }    
                secmail.setSubject(u.firstname +' '+ u.lastname +' '+ FEEDCOMMENT_TEXT);
                sechtmlBody= 'User Name: ' + u.firstname + ' '+ u.lastname +'<br/>';  
                sechtmlBody+= 'Feed Comment Details:'+'  '+feedComment.CommentBody+'<br/>';
                sechtmlBody+= 'For more details, please review the FeedItem here: '+'<br/>';
                sechtmlBody+=	URL.getSalesforceBaseUrl().toExternalForm()+'/'+feedComment.FeedItemId+'<br></br>';
                sechtmlBody+='Original Post: '+'<br/>';
                sechtmlBody+= 'Feed Details: '+' '+ knowledgeIdMap.get(feedComment.parentId).Title +'- '+ u.firstname +' '+ u.lastname +' '+'published this knowledge'+'<br/>';
                sechtmlBody+= 'Feed Created Date: '+' '+ feedComment.CreatedDate+'<br/>';
                sechtmlBody+= 'Feed Comment Details:'+' '+feedComment.CommentBody+'<br/>';
                sechtmlBody+= 'Feed Comment Created Date: ' + ' ' +feedComment.CreatedDate;
                string plainTextBody = sechtmlBody;
                secmail.setHtmlBody(plainTextBody);
                mails.add(secmail);
            
            }
            
            
        }
        Messaging.sendEmail(mails);       
     }
}
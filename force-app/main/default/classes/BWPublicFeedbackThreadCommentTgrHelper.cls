public class BWPublicFeedbackThreadCommentTgrHelper {
    
    public static void setDisplayNameValues(List<BWFeedbackThreadComment__c> threadCommentDNList){
        //String knowledgeIdString = '';
        String attuid;
        String primaryChannelEmployee;
        String channelId;
        String primaryPermLabel;
        String delimiter = ' ';
        String lastSplits;
        Set<Id> ThreadIdSet = new Set<Id>();
        String LoggedInUser = UserInfo.getUserId();
        Set<Id> articleIdSet = new Set<Id>();
        List<Employee__c> employees = new List<Employee__c>();
        List<BW_Channel_Mapping__c> channelMappings = new List<BW_Channel_Mapping__c>();
        List<PermissionSet> permSets = new List <PermissionSet>();
        
        
        for (BWFeedbackThreadComment__c thread : threadCommentDNList) {
            if (!String.isEmpty(thread.KMPublicFeedbackThread__c)) {
                ThreadIdSet.add(thread.KMPublicFeedbackThread__c);
            }       
        }
        /*
List<BWPublicFeedbackThread__c > ThreadList = new List<BWPublicFeedbackThread__c >();
ThreadList = [Select Id, Article_Version_Number__c, Name, DisplayName__c , Knowledge__c,Knowledge__r.Id, Knowledge_Parent_Id__c  
from BWPublicFeedbackThread__c 
where Id IN:ThreadIdSet];

System.debug('ThreadList'+ThreadList);*/
        
        //knowledgeIdString = ThreadList[0].Knowledge__c;
        //System.debug('knowledgeIdString'+knowledgeIdString);
        //
        List<BWPublicFeedbackThread__c> threadList = [SELECT Id, Knowledge__c FROM BWPublicFeedbackThread__c where Id in :ThreadIdSet];
        for (BWPublicFeedbackThread__c thread: threadList) {
            articleIdSet.add(thread.Knowledge__c);   
        }
        
        List<BWKMArticleSME__c> SMEList = new List<BWKMArticleSME__c>();
        SMEList = [Select Id, Knowledge_Article__c, Name, Role__c, User__c 
                   from BWKMArticleSME__c 
                   where Knowledge_Article__c IN: articleIdSet and User__c =:UserInfo.getUserId()];
        System.debug('SMEList'+SMEList);
        
        //attuid = [Select ATTUID__c from User where id =:UserInfo.getUserId()].ATTUID__c;
        try{
            employees = [SELECT EmployeeId__c, BWDefaultKMChannel__c FROM Employee__c where User__c =: UserInfo.getUserId() LIMIT 1];
            
            if(!employees.isEmpty()){
                primaryChannelEmployee = employees[0].BWDefaultKMChannel__c;
                attuid = employees[0].EmployeeId__c;
            }
            if(!String.isBlank(primaryChannelEmployee)){
                channelMappings = [SELECT Permission_Set_Id__c FROM BW_Channel_Mapping__c where KM_Channel_ID__c =:primaryChannelEmployee];
                if(!channelMappings.isEmpty()){
                    channelId = channelMappings[0].Permission_Set_Id__c;
                    permSets = [SELECT Label FROM PermissionSet where Id =:channelId];
                    if(!permSets.isEmpty()){
                        primaryPermLabel = permSets[0].Label;
                    }
                	lastSplits = primaryPermLabel.substringAfter(delimiter);
                } 
            }
            
        }
        catch(Exception ex){
            BWC_ExceptionUtils.handleException(ex, true);
            System.debug('User does not have a valid employee record. Please verify the entry for the user on the Employee__c custom object. '+ex);
        }
        
        for(BWFeedbackThreadComment__c thread : threadCommentDNList){
            if(!SMEList.isEmpty()){
                thread.DisplayName__c = 'Expert';
                thread.Unmasked_Display_Name__c = UserInfo.getFirstName()+' '+UserInfo.getLastName() +' ('+ attuid +'; '+ lastSplits+')';
            }
            else{
                try{
                    thread.DisplayName__c = UserInfo.getFirstName()+' '+UserInfo.getLastName() +' ('+ attuid +'; '+ lastSplits+')';
                    thread.Unmasked_Display_Name__c = UserInfo.getFirstName()+' '+UserInfo.getLastName() +' ('+ attuid +'; '+ lastSplits+')';
                    System.debug('DisplayName__c'+thread.DisplayName__c);
                }
                catch(Exception e){
                    BWC_ExceptionUtils.handleException(e, true);
                    System.debug('User does not have a valid employee record. Please verify the entry for the user on the Employee__c custom object. '+e);
                }
                
            }
        }
    }
    
    public static void updateParentThread(List<BWFeedbackThreadComment__c> commentList){
        Map<Id, BWPublicFeedbackThread__c> threadMap = new Map<Id, BWPublicFeedbackThread__c>();
        try{
            for(BWFeedbackThreadComment__c comment : commentList){
                BWPublicFeedbackThread__c thread = new BWPublicFeedbackThread__c();
                if(threadMap.containsKey(comment.KMPublicFeedbackThread__c)){
                    thread = threadMap.get(comment.KMPublicFeedbackThread__c);
                    Datetime latestCommentDate = thread.Last_Comment_Creation_Date__c;
                    if(comment.CreatedDate > latestCommentDate){
                        thread.Last_Comment_Creation_Date__c = comment.CreatedDate;
                        threadMap.put(comment.KMPublicFeedbackThread__c, thread);
                    }
                }
                else{
                    thread.Id = comment.KMPublicFeedbackThread__c;
                    thread.Last_Comment_Creation_Date__c = comment.CreatedDate;
                    threadMap.put(comment.KMPublicFeedbackThread__c, thread);
                }
            }
            if(!threadMap.values().isEmpty()){
                update threadMap.values();
            }
        }
        catch (Exception e) {
            BWC_ExceptionUtils.handleException(e, true);
        } 
    }
    
}
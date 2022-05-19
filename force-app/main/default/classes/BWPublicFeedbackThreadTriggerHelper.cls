public without sharing class BWPublicFeedbackThreadTriggerHelper {

    public static void setFieldValues(List<BWPublicFeedbackThread__c> threadList) {
    	Set<Id> knowledgeIdSet = new Set<Id>();
        Map<Id, Knowledge__kav> knowledgeMap;
        Knowledge__kav relatedArticle;
        for (BWPublicFeedbackThread__c thread : threadList) {
            system.debug('Thread' + thread);
            if (!String.isEmpty(thread.Knowledge__c)) {
            	knowledgeIdSet.add(thread.Knowledge__c);
                  system.debug('knowledgeIdSet' + knowledgeIdSet);
            }    
            
        }
        knowledgeMap = new Map<Id, Knowledge__kav>([SELECT Id, KnowledgeArticleId, VersionNumber FROM Knowledge__kav WHERE Id in :knowledgeIdSet ]);
          system.debug('knowledgeMap' + knowledgeMap);
    	
        for (BWPublicFeedbackThread__c thread : threadList) {
            system.debug('Inisde 2nd for loop' );
        	if (!String.isEmpty(thread.Knowledge__c)) {
                system.debug('knowledge is not empty' + thread.Knowledge__c);
            	relatedArticle = knowledgeMap.get(thread.Knowledge__c);
            	thread.Knowledge_Parent_Id__c = relatedArticle.KnowledgeArticleId;
                thread.Article_Version_Number__c = relatedArticle.VersionNumber;
                system.debug('thread' + thread);
    	
            }    
        }
    
    }
	
    public static void setDisplayNameValues(List<BWPublicFeedbackThread__c> threadDNList){
        String attuid;
        String primaryChannelEmployee;
        String channelId;
        String primaryPermLabel;
        String delimiter = ' ';
        String lastSplits;
        Set<Id> knowledgeIdSet = new Set<Id>();
        List<Employee__c> employee = new List<Employee__c>();
        List<BW_Channel_Mapping__c> channelMapping = new List<BW_Channel_Mapping__c>();
        List<PermissionSet> permSets = new List <PermissionSet>();
        String LoggedInUser = UserInfo.getUserId();
        System.debug('LoggedInUser'+LoggedInUser);
        for (BWPublicFeedbackThread__c thread : threadDNList) {
            if (!String.isEmpty(thread.Knowledge__c)) {
            	knowledgeIdSet.add(thread.Knowledge__c);
            }       
        }
        System.debug('knowledgeIdSet'+knowledgeIdSet);
        System.debug('threadDNList'+threadDNList);

        
        List<BWKMArticleSME__c> SMEList = new List<BWKMArticleSME__c>();
        SMEList = [Select Id, Knowledge_Article__c, Name, Role__c, User__c 
                   from BWKMArticleSME__c 
                   where Knowledge_Article__c IN:knowledgeIdSet 
                   and User__c =:UserInfo.getUserId()];
         System.debug('SMEList'+SMEList);
        
          //attuid = [Select ATTUID__c from User where id =:UserInfo.getUserId()].ATTUID__c;
        try{
            employee = [SELECT EmployeeId__c, BWDefaultKMChannel__c FROM Employee__c where User__c =: UserInfo.getUserId() LIMIT 1];
            
                if(!employee.isEmpty()){
                    primaryChannelEmployee = employee[0].BWDefaultKMChannel__c;
                    attuid = employee[0].EmployeeId__c;
                }
        	if(!String.isBlank(primaryChannelEmployee)){
                channelMapping = [SELECT Permission_Set_Id__c FROM BW_Channel_Mapping__c where KM_Channel_ID__c =:primaryChannelEmployee LIMIT 1];
                if(!channelMapping.isEmpty()){
                    channelId = channelMapping[0].Permission_Set_Id__c;
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
         
          
                 
        
        for (BWPublicFeedbackThread__c thread : threadDNList) {
            try{
        	if(!SMEList.isEmpty()){
                thread.DisplayName__c = 'Expert';
                thread.Unmasked_Display_Name__c = UserInfo.getFirstName()+' '+UserInfo.getLastName() +' ('+ attuid +'; '+ lastSplits+')';
                	System.debug('thread.DisplayName__c'+thread.DisplayName__c);
        	}
         	else{
               
                     thread.DisplayName__c = UserInfo.getFirstName()+' '+UserInfo.getLastName() +' ('+ attuid +'; '+ lastSplits+')';
                     thread.Unmasked_Display_Name__c = UserInfo.getFirstName()+' '+UserInfo.getLastName() +' ('+ attuid +'; '+ lastSplits+')';
                     System.debug('DisplayName__c'+thread.DisplayName__c);
                 }
               	
             }
             catch(Exception e){
                 BWC_ExceptionUtils.handleException(e, true);
                 System.debug('List index out of bounds for thread. '+e);
             }
             	
            }
         
        }
}
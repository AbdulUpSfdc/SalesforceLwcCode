public without sharing class CaseReassign_Escalation {

    @AuraEnabled  
    public static void updateCaseOwner(String caseId, String userOrGroupId) {
        System.debug('*** updateCaseOwner: caseId [' + caseId + '] userOrGroupId [' + userOrGroupId + ']');
        Case[] caseList = [SELECT Id,OwnerId,Status FROM Case WHERE Id = :caseId WITH SECURITY_ENFORCED];
        if(caseList.size() > 0) {
            Case caseToUpdate = caseList[0];
            caseToUpdate.OwnerId = userOrGroupId;
            caseToUpdate.Status = 'New';
            try {
                update caseToUpdate;
            } 
            catch(Exception ex){
             AuraHandledException genericException=new AuraHandledException(ex.getDmlMessage(0)+'');
                genericException.setMessage(ex.getDmlMessage(0) +'');
                throw genericException;
           }   
        }
    }
      
    public class ModelUserDetails{
        @AuraEnabled
        public String label{get;set;}
         @AuraEnabled
        public String value{get;set;}
        
        public ModelUserDetails(String label,String value){
            this.label=label;
            this.value=value;
        }
    }
     @AuraEnabled(cacheable=true)
    public static List<ModelUserDetails> getUserDetails(String userOrGroupName){
        List<ModelUserDetails> lstOfUserDetails=new List<ModelUserDetails>();
        lstOfUserDetails.add(new ModelUserDetails('--None--',''));
        Set<id> setOfUserGpIds=new Set<Id>();
        for(GroupMember gpMember:[SELECT UserOrGroupId FROM GroupMember WHERE  Group.Name=:userOrGroupName and Group.Type = 'Queue']){
            setOfUserGpIds.add(gpMember.UserOrGroupId); 
        }
        
        if(setOfUserGpIds.size()>0){
            for(User ur:[SELECT Id,Name FROM User where id in:setOfUserGpIds]){
                lstOfUserDetails.add(new ModelUserDetails(ur.name,ur.id));
            }
        }
        
        
        return lstOfUserDetails;
    }
    
    
    
}
/* ================================================
* @author : Salesforce
* @date :   12/16/2020   
* @group : Case 
* @description : class to reassign escalation case
================================================*/

public without sharing class CaseEscalationReassign{

    @AuraEnabled
    public static Group getGroupDetails(String recordId) {
        System.debug('*********************RECORDID'+recordId);
        Group retrievedGroup = new Group();
        
        if(String.isNotBlank(recordId)){
            //Retrieve case record info 
            Case c = [Select Id, WorkGroup__c from Case where Id = :recordId WITH SECURITY_ENFORCED];
            //String queueName = c.WorkGroup__c;
            
            if(String.isNotBlank(c.WorkGroup__c)){
                retrievedGroup = [Select Id, Type, Name,OwnerId from Group where  Name = :c.WorkGroup__c AND Type='Queue' WITH SECURITY_ENFORCED limit 1];
            }
        }    
        return retrievedGroup; 
        //return [Select Id, Type, Name from Group where  Name = 'CONSUMER-UNABLE-TO-COMPLETE' and Type='Queue' limit 1];
    }
    
    @AuraEnabled
    public static String caseLinktoInteraction(String recordId, String interactionId) {
                
        
            try{
                //retrieve case record and update with interaction
                Case c = [Select Id, Last_Interaction__c from Case where Id = :recordId WITH SECURITY_ENFORCED];
                if(interactionId != Null){
                    c.Last_Interaction__c = interactionId;            
                    update c;  
                    
                    List<Case_Interaction__c> newCaseInteractions = new List<Case_Interaction__c>();
                                
                    //Retrieve existing case interactions 
                    Map<Id,Case_Interaction__c> caseInteractionMap = new Map<Id,Case_Interaction__c>([Select Id, Case__c, Interaction__c from Case_Interaction__c where Case__c = :recordId 
                                                                                 AND Interaction__c = :interactionId WITH SECURITY_ENFORCED]);
                    
                    if(caseInteractionMap.size()==0){
                        newCaseInteractions.add(new Case_Interaction__c(Case__c = c.Id,Interaction__c = c.Last_Interaction__c));
                        //inserting new Case Interactions 
                        insert newCaseInteractions;
                        return 'Newly linked to Case';
                    }
                    else{
                        return 'Already Exists';
                    }          
                }
                else{
                    return 'No Last Interaction';
                }  
               
              }catch(Exception ex){
                        AuraHandledException genericException=new AuraHandledException(ex.getMessage()+'');
                        
                        throw genericException;
                  
              }  
               
               
       //}        
           
             
    }
    
    /*
    @AuraEnabled
    public static String caseLinktoInteraction(String recordId) {
        //Retrieve case record info 
        Case c = [Select Id, Last_Interaction__c from Case where Id = :recordId and Last_Interaction__c != Null];
        
        if(c.Last_Interaction__c != Null){        
            List<Case_Interaction__c> newCaseInteractions = new List<Case_Interaction__c>();
                        
            //Retrieve existing case interactions 
            Map<Id,Case_Interaction__c> caseInteractionMap = new Map<Id,Case_Interaction__c>([Select Id, Case__c, Interaction__c from Case_Interaction__c where Case__c = :recordId 
                                                                         AND Interaction__c = :c.Last_Interaction__c]);
            
            if(caseInteractionMap.size()==0){
                newCaseInteractions.add(new Case_Interaction__c(Case__c = c.Id,Interaction__c = c.Last_Interaction__c));
                //inserting new Case Interactions 
                insert newCaseInteractions;
                return 'Newly linked to Case';
            }
            else{
                return 'Already Exists';
            }
        }
        else{
            return 'No Last Interaction';
        }    
             
    }*/
}
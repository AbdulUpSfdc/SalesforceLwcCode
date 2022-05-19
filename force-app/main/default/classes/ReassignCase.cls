/* ================================================
* @author : Mike McKinley
* @date :   08/18/2020   
* @group : Case 
* @description : Controller for ReassignCase Aura component
================================================*/

/* ================================================
* Modified By  : Arun Pandey
* @date :   06/14/2021 
* @group : Case Action Reassign Functionality User Story 5839
* @description : Controller for ReassignCase Aura component
================================================*/

public without sharing class ReassignCase {
@AuraEnabled public static
    void updateCaseOwner(Id caseId, Id userOrGroupId) {
       
        System.debug('*** updateCaseOwner: caseId [' + caseId + '] userOrGroupId [' + userOrGroupId + ']');
        String sobjectApiName = getObjectApiName(caseId);
        sObject sobjectType =  getSobjectRecord(sobjectApiName,caseId);    
        updateOwner(sobjectApiName,sobjectType,userOrGroupId);      
    }
     

    // Don't think we need this function as we can have condition to show hide this component on Lighting record page
     @AuraEnabled public static
    boolean enableAssignButton(String caseId, String userId) {
        System.debug('ReassignCaseAction');
        String sobjectApiName = getObjectApiName(caseId);
        boolean enableButton =true;
        if(sobjectApiName ==Case_Action_Constants.Case_DEV_NAME){              
                List<User> users =   [Select id, UserRole.Name from User where id =:userId WITH SECURITY_ENFORCED Limit 1];
                    if(!users.isEmpty()) {
                        String roleUser = users[0].UserRole.Name;
                        Case[] caseList = [SELECT Id,OwnerId, RecordType.Name FROM Case WHERE Id = :caseId WITH SECURITY_ENFORCED Limit 1];
                        System.debug('*** updateCaseOwner: caseId [' + roleUser + '] recordtype [' + caseList[0].RecordType.Name + ']');
                        if((roleUser.equalsIgnoreCase('Field Agent') || roleUser.equalsIgnoreCase('Field Admin')) && caseList[0].RecordType.Name.equals('OOP Field') ){
                            system.debug('anshul in fieldage');
                            enableButton =false;
                        }
                        else if(roleUser.equalsIgnoreCase('OOP agent') && caseList[0].RecordType.Name.equals('OOP') ){
                                system.debug('anshul in OOP');
                            enableButton =false;
                        }
                        else if(roleUser.equalsIgnoreCase('Intake Admin') || roleUser.equalsIgnoreCase('OOP Admin') || roleUser.equalsIgnoreCase('Intake Agent')){
                            system.debug('anshul in intakeadmin');
                            enableButton =false;
                        }
                       
                    }
        }
        if(sobjectApiName ==Case_Action_Constants.Case_Action_DEV_NAME){
         enableButton =false;
        }
        return enableButton;
    }
   


    @AuraEnabled public static
    Map<Id,String> roleInfoForUser(String userId) {
        Map<Id,String> roleInfo = new Map<Id,String>();
        List<User> users = [SELECT UserRoleId,UserRole.Name FROM User WHERE Id =:userId WITH SECURITY_ENFORCED LIMIT 1];
        if(!users.isEmpty()) {
            User roleUser = users[0];
            roleInfo.put(roleUser.UserRoleId, roleUser.UserRole.Name);  
        }
        return roleInfo;
    }

    //Get the ApiName from the id passed from component
    public static string getObjectApiName (Id recordId){
        return recordId.getSObjectType().getDescribe().getName();
    }

    //Get the Sobject to update the OnwerId
    public static sObject getSobjectRecord(String sobjectApiName,Id caseId){
       String queryString = 'Select Id,OwnerId,Product__c From '+sobjectApiName+' Where Id=:caseId';
       return Database.query(queryString);
    }

    //Update the OwnerId of record
    public static void updateOwner (String sobjectApiName,sObject sobjectType,Id userOrGroupId){
       List<sObject> sobjectList = New List<sObject> ();
       if(sobjectApiName==Case_Action_Constants.Case_DEV_NAME){
           Case caseObj = (Case)sobjectType;
           caseObj.OwnerId=userOrGroupId;
           sobjectList.add(caseObj);
       }
       if(sobjectApiName==Case_Action_Constants.Case_Action_DEV_NAME){
           Case_Action__c caseActionObj = (Case_Action__c)sobjectType;
           caseActionObj.OwnerId=userOrGroupId;
           sobjectList.add(caseActionObj);
       }
       try {
           update sobjectList;
       }
       catch(Exception e) {
           System.debug('*** ' + e.getMessage());
           BWC_ExceptionUtils.handleException(e, true);
       }  
    }

    //Update the OwnerId of record with Status = New this is get called from autoAssignedQueueForRole when the Reassign is used by OOP Agent and Intake Agent
    public static void updateOwner (String sobjectApiName,sObject sobjectType,Id userOrGroupId,String StatusValue){
        List<sObject> sobjectList = New List<sObject> ();
        if(sobjectApiName==Case_Action_Constants.Case_DEV_NAME){
            Case caseObj = (Case)sobjectType;
            caseObj.Status = CaseConstants.CASE_STATUS_NEW;
            caseObj.OwnerId=userOrGroupId;
            sobjectList.add(caseObj);
        }
        if(sobjectApiName==Case_Action_Constants.Case_Action_DEV_NAME){
            Case_Action__c caseActionObj = (Case_Action__c)sobjectType;
            caseActionObj.OwnerId=userOrGroupId;
            caseActionObj.Status__c = Case_Action_Constants.NEW_STATUS;
            sobjectList.add(caseActionObj);
        }
        try {
            update sobjectList;
        }
        catch(Exception e) {
            System.debug('*** ' + e.getMessage());
            BWC_ExceptionUtils.handleException(e, true);
        }  
     }

    //get the product Associated with the case or with the caseAction
    public static string  getAssociatedProduct(String sobjectApiName,sObject sobjectType){
        String ProductName ='';
        if(sobjectApiName==Case_Action_Constants.Case_DEV_NAME){
            Case caseObj = (Case)sobjectType;
            ProductName = caseObj.Product__c;
        }
        if(sobjectApiName==Case_Action_Constants.Case_Action_DEV_NAME){
            Case_Action__c caseActionObj = (Case_Action__c)sobjectType;
            ProductName = caseActionObj.Product__c;
        }
        System.debug('*** ProductName' + ProductName);
        return ProductName;
    }

    @AuraEnabled public static
    Map<Id,String> autoAssignedQueueForRole(String caseId, String inputRoleName) {          
        String sobjectApiName = getObjectApiName(caseId);
        sObject sobjectType =  getSobjectRecord(sobjectApiName,caseId);  
        Map<Id,String> queueInfo;      
        String reassignQueueName,queueId;
        Boolean isQueueIdExists = TRUE;
        String associatedProduct = getAssociatedProduct(sobjectApiName,sobjectType);
        if(String.isNotBlank(associatedProduct)){
            List<String> productNamelst = new List<String>();
            if(associatedProduct.Contains(';')){
                productNamelst = associatedProduct.split(';');
            }
            else{
                productNamelst.add(associatedProduct);
            }
            reassignQueueName = checkRelatedAssignmentRecord(productNamelst, inputRoleName);
            if(string.isNotBlank(reassignQueueName)){
                queueId = retrieveGroupId(reassignQueueName);                    
            }
            else{
                isQueueIdExists = FALSE;
               
            }
           
        }
        if(!isQueueIdExists || String.isBlank(associatedProduct)){
            String assignmentName = assignmentNameForRole(inputRoleName);                    
            queueId = retrieveGroupId(assignmentName);    
        }
       
        if(String.isNotBlank(queueId) && !inputRoleName.equalsIgnoreCase('OOP Agent')){
            updateOwner(sobjectApiName,sobjectType,queueId,CaseConstants.CASE_STATUS_NEW);          
        }else{
            updateOwner(sobjectApiName,sobjectType,queueId);
        }

        return queueInfo;
    }
   
    public static String checkRelatedAssignmentRecord(List<String> productList, String inputRoleName) {  
        //retrieve case reassignment records
        List<Case_Reassignment_Settings__mdt> assignments =
            [SELECT Future_Group__c,OwnersRole__c,Products__c,Matching_Criteria__c,Priority_Order__c FROM Case_Reassignment_Settings__mdt  
             WHERE OwnersRole__c =:inputRoleName AND Products__c != Null WITH SECURITY_ENFORCED ORDER BY Priority_Order__c ASC];
       
        Boolean isProdMatch = false;  
        String futureGroupName;    
        if(assignments.size()>0){
            for(Case_Reassignment_Settings__mdt qa : assignments){
                if(String.isNotBlank(qa.products__c)){
                    //products comparison
                    isProdMatch = getProductsComparison(productList, qa);
                    if(isProdMatch){
                        futureGroupName = qa.Future_Group__c;
                        break;
                    }
                }
            }
        }    
        System.debug('*** futureGroupName ' + futureGroupName);
        return futureGroupName;
             
    }
   
    //Compare products with Case reassignment record ,Have to check exisitng functionality but need to be get verified
    public static Boolean getProductsComparison(List<String> caseProducts, Case_Reassignment_Settings__mdt matchRule){
     
       List<String> ruleproducts = new List<String>();
       Set<String> caseProds = new Set<String>();
       Set<String> ruleProds = new Set<String>();
       
       if(matchRule.Products__c.contains(';')){
           ruleproducts = matchRule.Products__c.split(';');
       }
       else{
           ruleproducts.add(matchRule.Products__c);
       }    
      caseProds.addAll(caseProducts);
      ruleProds.addAll(ruleproducts);
      String matchALLorANYbutNONE = 'All or Any (No Others)';    
      if(matchRule.Matching_Criteria__c == matchALLorANYbutNone){
          if(ruleProds.containsAll(caseProds)){
              return TRUE;
          }
      }
     
      return FALSE;
  }
   
    @AuraEnabled public static
    Id autoAssignmentForFieldAgentFix(String caseId, String workgroup) {        
        // special case when user is a Field Agent
        // assign to owner of Workgroup or Workgroup
        Id assigneeId;
        System.debug('*** caseId ' + caseId);
        System.debug('*** workgroup ' + workgroup);
        List<ChildCaseAssignmentConfig__c > objQueueList = [Select id, Queue__c , User__c from ChildCaseAssignmentConfig__c where Queue__c= :workgroup WITH SECURITY_ENFORCED];
        for(ChildCaseAssignmentConfig__c objQueue :  objQueueList){
            if(String.isblank(objQueue.User__c)){
                List<Group> queues = [SELECT Id,OwnerId FROM Group WHERE DeveloperName = :workgroup AND Group.Type = 'Queue' WITH SECURITY_ENFORCED LIMIT 1];
                System.debug('*** if ' + queues[0].Id);
                assigneeId = queues[0].Id;
            }else{
                System.debug('*** else ' + objQueue.User__c);
                assigneeId = objQueue.User__c;
            }
            break;
        }
       
        System.debug('*** assigneeId ' + assigneeId);



        String sobjectApiName = getObjectApiName(caseId);
        sObject sobjectType =  getSobjectRecord(sobjectApiName,caseId);    
        updateOwner(sobjectApiName,sobjectType,assigneeId);
        return assigneeId;
    }
       
        // retrieve the assignee for the input role from Case Reassignment custom metadata
    private static
    String assignmentNameForRole(String inputRoleName) {
        String assignment = '';
        List<Case_Reassignment_Settings__mdt > assignments =
            [SELECT Future_Group__c FROM Case_Reassignment_Settings__mdt  WHERE OwnersRole__c =:inputRoleName  AND Products__c = Null WITH SECURITY_ENFORCED LIMIT 1];
        if(!assignments.isEmpty()) {
            assignment = assignments[0].Future_Group__c ;
        }
        System.debug('assignment name = [' + assignment + ']');
       
        return assignment;
    }
   
    private static
    String retrieveGroupId(String groupName) {
        String groupId;
        List<Group> queues = [SELECT Id, Name FROM Group WHERE DeveloperName = :groupName AND Group.Type = 'Queue' WITH SECURITY_ENFORCED];
        if(!queues.isEmpty()) {
            groupId = queues[0].Id;
         }      
        System.debug('reassigned group = groupId' + groupId );
       
        return groupId;
    }
   
    @AuraEnabled public static
    Map<Id,String> retrieveGroupDetails(String groupName) {
        Map<Id,String> groupInfo = new Map<Id,String>();
        List<Group> queues = [SELECT Id, Name FROM Group WHERE DeveloperName = :groupName AND Group.Type = 'Queue' WITH SECURITY_ENFORCED];
        if(!queues.isEmpty()) {
            groupInfo.put(queues[0].Id, queues[0].Name);
         }      
        System.debug('reassigned group = [' + groupInfo + ']');
       
        return groupInfo;
    }

    @AuraEnabled(cacheable=true)
    public static Map<Id,Object> getAssignedQueuesForUser(String userId) {
    system.debug('See here' + userId);
        Map<Id,Object> queueInfo = new Map<Id,Object>();
        if (userId != null && !String.isBlank(userId)) {
            List<GroupMember> groupMembers = [SELECT Group.Id, Group.Name, Group.DeveloperName FROM GroupMember WHERE UserOrGroupId = :userId AND Group.Type = 'Queue' WITH SECURITY_ENFORCED];
               system.debug('See here' + groupMembers);
            if(!groupMembers.isEmpty()) {
             system.debug('See here' + groupMembers);
                for(GroupMember member : groupMembers) {
                system.debug('See here' + member.Group.Id + member.Group);
                    queueInfo.put(member.Group.Id, member.Group);
                }  
            }
        }
       
         system.debug('See here beforeee return' + queueInfo);
        return queueInfo;
    }
   
    @AuraEnabled(cacheable=true)
    public static Map<Id,String> getUsersForQueue(String queueId) {
        Map<Id,String> userInfo = new Map<Id,String>();
        if (queueId != null && !String.isBlank(queueId)) {
            List<User> users = [SELECT Id,Name FROM User WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.Id = :queueId) WITH SECURITY_ENFORCED];
            if(!users.isEmpty()) {
                for(User member : users) {
                    userInfo.put(member.Id, member.Name);
                }  
            }
        }
       
        return userInfo;
    }
    
}
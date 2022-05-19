/*
* Purpose: This Queueable class will be executed from Employee and  Employee Store Retail triggers.
*          It Will assign group members to arsm and sm public groups and arsm, sm public groups to store group.
* @Author : Reshma Jewrani
*/
public with sharing class RetailGroupMemberQueueable implements Queueable{
    public List<EmployeeStoreRetail__c> insertGroupMemberList = new List<EmployeeStoreRetail__c>();
    public List<EmployeeStoreRetail__c> deleteGroupMemberList = new List<EmployeeStoreRetail__c>();
    public List<Id> deleteGroupList = new List<Id>();
    public List<Store__c> closedStoreList = new List<Store__c>();
    Boolean isEmpStoreUpdate;
    list<EmployeeStoreRetail__c> updateEmpStoreList = new list<EmployeeStoreRetail__c>();
    public Map<String, String> mapGroupNameStoreMarketID = new Map<String, String>();
    public Map<String, String> deleteGroupMemberMap = new Map<String, String>();
    Map<string,Store__c> storeMap = new Map<string, Store__c>();
    
    
    public RetailGroupMemberQueueable(List<EmployeeStoreRetail__c> insertGroupMemberList, List<EmployeeStoreRetail__c> deleteGroupMemberList) {
        this.insertGroupMemberList = insertGroupMemberList;
        this.deleteGroupMemberList = deleteGroupMemberList;
        isEmpStoreUpdate = false;
        updateEmpStoreList = new List<EmployeeStoreRetail__c>();
    }
    public RetailGroupMemberQueueable(List<EmployeeStoreRetail__c> insertGroupMemberList, List<EmployeeStoreRetail__c> deleteGroupMemberList, Boolean  isEmpStoreUpdate, list<EmployeeStoreRetail__c> updateEmpStoreList) {
        this.insertGroupMemberList = insertGroupMemberList;
        this.deleteGroupMemberList = deleteGroupMemberList;
        this.isEmpStoreUpdate =  isEmpStoreUpdate;
        this.updateEmpStoreList =  updateEmpStoreList;
    }
    public RetailGroupMemberQueueable(Map<String, String> mapGroupNameStoreMarketID, Map<string,Store__c> retailStoreMap,
	set<Id> groupIdsList, Map<string,string> deleteGroupMemberMap, List<Store__c> closedStoreList ) {
        this.mapGroupNameStoreMarketID = mapGroupNameStoreMarketID;
        this.storeMap = retailStoreMap;
        if(groupIdsList != null && !groupIdsList.isEmpty()){
		  this.deleteGroupList.addAll(groupIdsList);
        }
        this.closedStoreList = closedStoreList;
		 this.deleteGroupMemberMap = deleteGroupMemberMap;
    }
    
    public void execute(QueueableContext context) {
        try{
            
            map<String, map<String, String>> userToGroupToEmpStoreMap = new  map<String, map<String, String>>();
            map<Id, EmployeeStoreRetail__c> grpMemberToEmpStoreMap = new map<Id, EmployeeStoreRetail__c>();
            List<Database.DeleteResult> deleteResultList= new List<Database.DeleteResult>();
            List<Database.SaveResult> insertResultList = new List<Database.SaveResult>();
            List<GroupMember> insertGrpMemberList = new List<GroupMember>();
            if(deleteGroupMemberList.size() > 0) {
                if(!isEmpStoreUpdate) {
                    List<GroupMember> deleteGrpMemberList = new List<GroupMember>();
                    
                    for(EmployeeStoreRetail__c empStore: deleteGroupMemberList) {
                        if(empStore.PublicGroupMemberId__c != null) {
                            grpMemberToEmpStoreMap.put(empStore.PublicGroupMemberId__c, empStore);
                            GroupMember grpMember = new GroupMember(id = empStore.PublicGroupMemberId__c);
                            deleteGrpMemberList.add(grpMember);
                        }
                    }
                    deleteResultList = Database.delete(deleteGrpMemberList, false);
                    
                    // Iterate through each returned result
                    for(Database.DeleteResult deleteResultRec : deleteResultList) {
                        if (deleteResultRec.isSuccess()) {
                            // Operation was successful, so get the ID of the record that was processed
                            String deleteId = deleteResultRec.getId();
                            System.debug('Successfully deleted account with ID: ' + deleteId);
                            if(grpMemberToEmpStoreMap.containsKey(deleteId)) {
                                EmployeeStoreRetail__c empStore = new EmployeeStoreRetail__c(id = grpMemberToEmpStoreMap.get(deleteId).id,
                                                                                             PublicGroupMemberId__c = null);
                                updateEmpStoreList.add(empStore);
                            }
                        }
                        else {
                            // Operation failed, so get all errors                
                            for(Database.Error err : deleteResultRec.getErrors()) {
                                System.debug('The following error has occurred.');                    
                                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                System.debug('Account fields that affected this error: ' + err.getFields());
                            }
                        }
                    }
                }
                
            }
            
            if(insertGroupMemberList.size() > 0) {
                if(!isEmpStoreUpdate) {
                    userToGroupToEmpStoreMap = new map<String, map<String, String>>();
                    for(EmployeeStoreRetail__c  empStore: insertGroupMemberList)  {
                        map<String, String> groupToEmpStoreMap = new map<String, String>();
                        if(userToGroupToEmpStoreMap.containsKey(empStore.User__c)) {
                            groupToEmpStoreMap = userToGroupToEmpStoreMap.get(empStore.User__c);
                        }
                        system.debug(empStore.Store__r.PublicGroupId__c+'empStore.Store__r.PublicGroupId__c==>');
                        groupToEmpStoreMap.put(empStore.Store__r.PublicGroupId__c, empStore.Id);
                        userToGroupToEmpStoreMap.put(empStore.User__c, groupToEmpStoreMap);
                        GroupMember grpMember = new GroupMember(UserOrGroupId = empStore.User__c,
                                                                GroupId = empStore.Store__r.PublicGroupId__c);
                        insertGrpMemberList.add(grpMember);
                        
                    }
                    
                    insertResultList = Database.insert(insertGrpMemberList, false);
                    // Iterate through each returned result
                    Integer i = 0;
                    for (Database.SaveResult insertResult : insertResultList) {
                        if (insertResult.isSuccess()) {
                            // Operation was successful, so get the ID of the record that was processed
                            String insertId = insertResult.getId();
                            System.debug('Successfully inserted account. Account ID: ' + insertResult.getId());
                            GroupMember grpMember = insertGrpMemberList.get(i);
                            if(userToGroupToEmpStoreMap.containsKey(grpMember.UserOrGroupId)) {
                                if(userToGroupToEmpStoreMap.get(grpMember.UserOrGroupId).containsKey(grpMember.GroupId))  {
                                    EmployeeStoreRetail__c empStore = new EmployeeStoreRetail__c(Id = userToGroupToEmpStoreMap.get(grpMember.UserOrGroupId).get(grpMember.GroupId),
                                                                                                 PublicGroupMemberId__c = insertId);
                                    updateEmpStoreList.add(empStore);
                                }
                            }
                        }
                        else {
                            // Operation failed, so get all errors                
                            for(Database.Error err : insertResult.getErrors()) {
                                System.debug('The following error has occurred.');                    
                                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                System.debug('Account fields that affected this error: ' + err.getFields());
                            }
                        }
                        i++;
                    }
                }
            }
            
            //Logic Added to role hirarchy to public Group
            List<Group> listGroup = new List<Group>();
            if (storeMap.size() > 0) {
                listGroup = [SELECT id, Name, DeveloperName from Group where DeveloperName IN:storeMap.Keyset()];
            }
            if(!mapGroupNameStoreMarketID.isEmpty()) { 
                Set<String> setRoleName = new set<String>();
                //listGroup = [SELECT id, Name, DeveloperName from Group where DeveloperName IN:mapGroupNameStoreMarketID.Keyset()];         
                Map<String, ID> mapGroupNameID = new  Map<String, ID>();
                List<String> lstMarketID = new List<String>();
                for(String strMarketID: mapGroupNameStoreMarketID.values()){
                    lstMarketID.add(strMarketID);
                }
                system.debug('--Market Id --'+lstMarketID);
                for(Group grp: listGroup){
                    mapGroupNameID.put(grp.DeveloperName, grp.ID);
                }
                system.debug('--mapGroupNameID Id --'+mapGroupNameID);
                List<Group> listUserGroupRoles = [SELECT ID, DeveloperName from Group where Type='Role' and DeveloperName IN:lstMarketID];
                Map<String, ID> mapRoleNameRoleID = new Map<String, ID>();
                for(Group usrRole: listUserGroupRoles){    
                    mapRoleNameRoleID.put(usrRole.Developername, usrRole.ID);
                }
                List<GroupMember> insertGrpMemberListwithUserRoleID = new List<GroupMember>();
                GroupMember grpMember;
                for(String sGroupName: mapGroupNameStoreMarketID.KeySet() ){
                    if(mapGroupNameID.containsKey(sGroupName)){
                        grpMember = new GroupMember(GroupId = mapGroupNameID.get(sGroupName));
                        
                        for(String sRoleName: mapRoleNameRoleID.KeySet()){
                            if(sRoleName.contains(mapGroupNameStoreMarketID.get(sGroupName))){
                                grpMember.UserOrGroupId = mapRoleNameRoleID.get(sRoleName);
                                break;
                            }
                        }
                        if(grpMember.UserOrGroupId!=null){
                            insertGrpMemberListwithUserRoleID.add(grpMember);
                        }    
                    }    
                }
                system.debug('--insertGrpMemberListwithUserRoleID Id --'+insertGrpMemberListwithUserRoleID);
                insertResultList = Database.insert(insertGrpMemberListwithUserRoleID, false); 
				
            }
            
            if(deleteGroupList!=null && deleteGroupList.size() > 0){
				  Database.delete(deleteGroupList, false);  

            }
            
               if (storeMap.size() > 0 || closedStoreList.size() > 0) {
                StoreUpdateQueueable suq = new StoreUpdateQueueable(listGroup, storeMap, closedStoreList);
                system.enqueueJob(suq);  
            }
            
            if(!deleteGroupMemberMap.isEmpty()){
                set<string> lstMarketID = new set<string>();
                for(String strMarketID: deleteGroupMemberMap.values()){
                    lstMarketID.add(strMarketID);
                }
                listGroup = [SELECT id, Name, DeveloperName from Group where Type ='Regular'AND DeveloperName IN:deleteGroupMemberMap.Keyset()];
                List<Group> listUserGroupRoles = [SELECT ID, DeveloperName from Group where Type='Role' and DeveloperName IN:lstMarketID];
              
               List<GroupMember> groupMemberList = [select Id from GroupMember where groupId in: listGroup and userOrGroupId =: listUserGroupRoles ];
               if(groupMemberList.size() > 0)
                 Database.delete(groupMemberList, false); 
            }

             /*** REDUNDANT CODE ****/ 
          /*  if(isEmpStoreUpdate && !updateEmpStoreList.isEmpty()) {
                if(updateEmpStoreList.size() > 0){
                    update updateEmpStoreList;    
                }    
            } else {
                if(mapGroupNameStoreMarketID.isEmpty()){
                    RetailGroupMemberQueueable queuableObj  = new RetailGroupMemberQueueable(insertGroupMemberList, deleteGroupMemberList, true, updateEmpStoreList);
                    system.enqueueJob(queuableObj);
                }   
            } */ 
        }catch (exception e){
            system.debug('DML Exception is:'+e.getStackTraceString());                            
        }
    }
}
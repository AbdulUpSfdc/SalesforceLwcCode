public without sharing class RetailGroupMemberBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
	
    public Set<Id> empIds = new Set<Id>();
    public Set<Id> userIds = new Set<Id>();
    public Set<Id> demotedSMs = new Set<Id>();
    public Set<Id> demotedSMUserIds = new Set<Id>();
    public Map<Id, Map<Id, GroupMember>> userToGroupMember = new Map<Id, Map<Id, GroupMember>>();
    public List<EmployeeStoreRetail__c> updateEmpStoreListDuringInsert = new List<EmployeeStoreRetail__c>();
    public List<EmployeeStoreRetail__c> updateEmpStoreListDuringDelete = new List<EmployeeStoreRetail__c>();
    public List<sObject> failedDMLsObjects = new List<sObject>();
    public List<LeadRedistribution__C> lrdsList = new List<LeadRedistribution__c>();
    
    public Database.QueryLocator start(Database.BatchableContext BC) {

        lrdsList = [SELECT Id, User__c, Employee__c, OldValue__c, NewValue__c, Reason__c FROM LeadRedistribution__c WHERE Reason__c IN ('Employee Promotion', 'Employee Demotion', 'New Employee') AND IsPrimary__c = true];
        if (lrdsList.size() > 0) {
            for(LeadRedistribution__C lrd : lrdsList) {
                empIds.add(lrd.Employee__c);
                if (lrd.Reason__c == 'Employee Demotion' && lrd.NewValue__c == RetailConstants.REP_POSITION) {
					demotedSMs.add(lrd.Employee__c);
                    demotedSMUserIds.add(lrd.User__c);
                }
            }
        }

        Datetime halfHourBack = Datetime.now().addMinutes(-30);
        return Database.getQueryLocator([SELECT Id, 
                                         Employee__c,
                                         Store__c, Store__r.PublicGroupId__c,
                                         User__c,
                                         EffectiveEnddate__c,
                                         EffectiveStartDate__c,
                                         HomeStore__c,
                                         IsExpired__c,
                                         SFProfileId__c,
                                         PublicGroupMemberid__c
                                         FROM EmployeeStoreRetail__c
                                         WHERE LastModifiedDate >= :halfHourBack]);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        
        System.debug('execute :::: scope.size() :::: ' + scope.size());
        
		List<EmployeeStoreRetail__c> insertGroupMemberList = new List<EmployeeStoreRetail__c>();
    	List<EmployeeStoreRetail__c> deleteGroupMemberList = new List<EmployeeStoreRetail__c>();
        userToGroupMember = new Map<Id, map<Id, GroupMember>>();
        for(LeadRedistribution__c lrd: lrdsList) {
            userIds.add(lrd.User__c);
        }
        for (sObject obj : scope) {
            
            EmployeeStoreRetail__c esr = (EmployeeStoreRetail__c) obj;
            
            //empIds.add(esr.Employee__c);
            userIds.add(esr.User__c);
            
            if (RetailConstants.SFPROFILE_MEMBERSHIP.split(',').contains(esr.SFProfileId__c)) {
                if( esr.IsExpired__c || (esr.EffectiveEnddate__c <= Date.today() && esr.SFProfileId__c == RetailConstants.ARSM_POSITION) ) {
                    deleteGroupMemberList.add(esr);
                } else {
                    insertGroupMemberList.add(esr);
                }
            }
            if (demotedSMs.size() > 0) {
                if (demotedSMs.contains(esr.Employee__c)) {
                    deleteGroupMemberList.add(esr);
                }
            }
  
        }
        
		userToGroupMember = getGrpMemByGrpByUser(userIds);
        // Handle Employess demoted to Reps
        if (demotedSMUserIds.size() > 0) {
            handleDemotedEmployees(demotedSMUserIds, userToGroupMember);
            demotedSMUserIds.clear();
        }
        
		// Handle User Permissions
        if (lrdsList.size() > 0) {
			List<sObject> userPermList = UserHandler.processUserPermissions(empIds, userToGroupMember);
	        failedDMLsObjects.addAll(userPermList);
            lrdsList.clear();
        }

        if (deleteGroupMemberList.size() > 0) {
            deleteGroupMember(deleteGroupMemberList, userToGroupMember);
        }  
        if (insertGroupMemberList.size() > 0) {
            insertGroupMember(insertGroupMemberList, userToGroupMember);
        }
        
    }
    
    public void finish(Database.BatchableContext BC) {
        if (updateEmpStoreListDuringDelete.size() > 0) {
            update updateEmpStoreListDuringDelete;
        }
        if (updateEmpStoreListDuringInsert.size() > 0) {
            update updateEmpStoreListDuringInsert;
        }
        
        // Lead Redistribution
        Database.executeBatch(new LeadRedistributionBatch());

        Database.executeBatch(new RetryBatchApex(failedDMLsObjects));
    }
    
    public void execute(SchedulableContext sc) {
		Database.executeBatch(new RetailGroupMemberBatch());
    }
    
	@testVisible
    private static map<Id, map<Id, GroupMember>> getGrpMemByGrpByUser(Set<Id> listuserId) {
        map<Id, map<Id, GroupMember>> mapGrpMemByGrpByUser = new map<Id, map<Id, GroupMember>>();
        list <GroupMember> listCurrGrpMem = new list<GroupMember>();
        listCurrGrpMem = [SELECT Id, UserOrGroupId, GroupId, Group.DeveloperName  FROM GroupMember 
                           WHERE UserOrGroupId IN :listuserId];
        
        for (Id userId : listuserId) {
            mapGrpMemByGrpByUser.put(userId, new map <Id, GroupMember>());
        }
        
        for (GroupMember iter : listCurrGrpMem) {          
            if (mapGrpMemByGrpByUser.get(iter.UserOrGroupId) != null) {
                mapGrpMemByGrpByUser.get(iter.UserOrGroupId).put(iter.Id, iter);
                if (iter.UserOrGroupId != null)
                    mapGrpMemByGrpByUser.get(iter.UserOrGroupId).put(iter.UserOrGroupId, iter);                
                if (iter.GroupId != null)
                    mapGrpMemByGrpByUser.get(iter.UserOrGroupId).put(iter.GroupId, iter);
            } else {
                map <Id, GroupMember> gmMap = new map <Id, GroupMember>();
                gmMap.put(iter.Id, iter);
                if (iter.UserOrGroupId != null)
                    gmMap.put(iter.UserOrGroupId, iter);
                if (iter.GroupId != null)
					gmMap.put(iter.GroupId, iter);
                mapGrpMemByGrpByUser.put(iter.UserOrGroupId, gmMap);
            }
        }
        return mapGrpMemByGrpByUser;
    }
    
    public void handleDemotedEmployees(Set<Id> demotedUsers, map<Id, map<Id, GroupMember>> userToGroupMemberMap) {
        Map<Id, GroupMember> gmlist = new Map<Id, GroupMember>();
        
        for(Id user : userToGroupMemberMap.keySet()) {
            if (demotedUsers.contains(user)) {
				Map<Id, GroupMember> gmMap = userToGroupMemberMap.get(user);
                for (Id gmId : gmMap.keySet()) {
                    GroupMember gm = gmMap.get(gmId);
                    if (gm.Group.DeveloperName.startsWith('Retail_') && !gmList.containsKey(gm.Id)) {
						gmlist.put(gm.Id, gm);
                    }
                }
            }
        }
        Database.delete(gmlist.values(), false);
    }

    private void deleteGroupMember(List<EmployeeStoreRetail__c> recs,  Map<Id, Map<Id, GroupMember>> userToGMMap) {
        map<Id, EmployeeStoreRetail__c> grpMemberToEmpStoreMap = new map<Id, EmployeeStoreRetail__c>();
        List<Database.DeleteResult> deleteResultList= new List<Database.DeleteResult>();
        
        if(recs.size() > 0) {
            List<GroupMember> deleteGrpMemberList = new List<GroupMember>();
            
            for(EmployeeStoreRetail__c empStore: recs) {
                if(empStore.PublicGroupMemberId__c != null 
                   && userToGroupMember.containsKey(empStore.User__c) 
                   // Check if the User has the empStore.PublicGroupMemberId__c(GroupMember.GroupId) assigned
                   && userToGroupMember.get(empStore.User__c).containsKey(empStore.PublicGroupMemberId__c)) {

                    grpMemberToEmpStoreMap.put(empStore.PublicGroupMemberId__c, empStore);
                    GroupMember grpMember = new GroupMember(id = empStore.PublicGroupMemberId__c);
                    deleteGrpMemberList.add(grpMember);
                }
            }
            deleteResultList = Database.delete(deleteGrpMemberList, false);
            
            // Iterate through each returned result
            for(Database.DeleteResult deleteResultRec : deleteResultList) {
                system.debug('deleteResultRec ::: ' + deleteResultRec);
                if (deleteResultRec.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    String deleteId = deleteResultRec.getId();
                    System.debug('Successfully deleted GroupMember with ID: ' + deleteId);
                    if(grpMemberToEmpStoreMap.containsKey(deleteId)) {
                        EmployeeStoreRetail__c empStore = new EmployeeStoreRetail__c(id = grpMemberToEmpStoreMap.get(deleteId).id,
                                                                                     PublicGroupMemberId__c = null);
                        updateEmpStoreListDuringDelete.add(empStore);
                    }
                } else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : deleteResultRec.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('GroupMember fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }
    
    private void insertGroupMember(List<EmployeeStoreRetail__c> recs, Map<Id, Map<Id, GroupMember>> userToGMMap) {
        
        map<String, map<String, String>> userToGroupToEmpStoreMap = new  map<String, map<String, String>>();
        List<Database.SaveResult> insertResultList = new List<Database.SaveResult>();
        List<GroupMember> insertGrpMemberList = new List<GroupMember>();
        
        if(recs.size() > 0) {
            userToGroupToEmpStoreMap = new map<String, map<String, String>>();
            
            for(EmployeeStoreRetail__c  empStore: recs)  {
                
				if(empStore.Store__r.PublicGroupId__c != null 
                   && userToGMMap.containsKey(empStore.User__c) 
                   // Check if the User has the empStore.Store__r.PublicGroupId__c(GroupMember.Id) already assigned
                   && !(userToGMMap.get(empStore.User__c).containsKey(empStore.Store__r.PublicGroupId__c)) ) {
                       
                        map<String, String> groupToEmpStoreMap = new map<String, String>();
                        if(userToGroupToEmpStoreMap.containsKey(empStore.User__c)) {
                            groupToEmpStoreMap = userToGroupToEmpStoreMap.get(empStore.User__c);
                        }
                        groupToEmpStoreMap.put(empStore.Store__r.PublicGroupId__c, empStore.Id);
                        userToGroupToEmpStoreMap.put(empStore.User__c, groupToEmpStoreMap);
                        GroupMember grpMember = new GroupMember(UserOrGroupId = empStore.User__c, GroupId = empStore.Store__r.PublicGroupId__c);
                        insertGrpMemberList.add(grpMember);   
                   }
            }
            
            insertResultList = Database.insert(insertGrpMemberList, false);
            // Iterate through each returned result
            Integer i = 0;
            for (Database.SaveResult insertResult : insertResultList) {
                if (insertResult.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    String insertId = insertResult.getId();
                    System.debug('Successfully inserted GroupMember. ID: ' + insertResult.getId());
                    GroupMember grpMember = insertGrpMemberList.get(i);
                    if(userToGroupToEmpStoreMap.containsKey(grpMember.UserOrGroupId)) {
                        if(userToGroupToEmpStoreMap.get(grpMember.UserOrGroupId).containsKey(grpMember.GroupId))  {
                            EmployeeStoreRetail__c empStore = new EmployeeStoreRetail__c(Id = userToGroupToEmpStoreMap.get(grpMember.UserOrGroupId).get(grpMember.GroupId),
                                                                                         PublicGroupMemberId__c = insertId);
                            updateEmpStoreListDuringInsert.add(empStore);
                        }
                    }
                } else {
                    failedDMLsObjects.add(insertGrpMemberList.get(i));
                    // Operation failed, so get all errors                
                    for(Database.Error err : insertResult.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('GroupMember fields that affected this error: ' + err.getFields());
                    }
                }
                i++;
            }
        }
    }
    
}
public with sharing class UserAccessHandlerService {
    
    public UserAccessHandlerService () {}
    
    private static void ManageUserFeatureAccess (map<Id, List<Employee_Jobduty_Assignment__c>> mapEmplJAByUserId, map<Id, User> mapUserByUserId) {
        map<Id, User> mapUserUpdateForRole = new map<Id, User>();
        map<Id, User> mapUserFeatureUpdate = new map<Id, User>();
        if (mapEmplJAByUserId <> null && mapUserByUserId <> null) {
            for (User iterUser : mapUserByUserId.values()) {
                list<Employee_Jobduty_Assignment__c> listCurrUserJA = mapEmplJAByUserId.get(iterUser.Id);
                if (listCurrUserJA <> null && listCurrUserJA.size() > 0) {
                    for (Employee_Jobduty_Assignment__c iterEmplJA : listCurrUserJA) {
                        // Process primary jobduty assignment details for Profile and Role
                        if (iterEmplJA.Primary_Or_Extended__c == 'Primary') {
                            // Current role of user is different than target role of the job duty
                            if (iterEmplJA.Employee_Jobduty_Reference__r.RoleId__c <> null) {
                                if (mapUserByUserId.get(iterUser.Id).UserRoleId <> Id.valueof(String.valueof(iterEmplJA.Employee_Jobduty_Reference__r.RoleId__c).trim())) {
                                    iterUser.UserRoleId = Id.valueof(String.valueof(iterEmplJA.Employee_Jobduty_Reference__r.RoleId__c).trim());
                                    mapUserUpdateForRole.put(iterUser.Id, iterUser);
                                }
                            } else { // Target role of the job duty is empty but current role is not empty
                                if (mapUserByUserId.get(iterUser.Id).UserRoleId <> null) {
                                    iterUser.UserRoleId = null;
                                    mapUserUpdateForRole.put(iterUser.Id, iterUser);
                                }
                            }
                            if (iterEmplJA.Employee_Jobduty_Reference__r.ProfileId__c <> null) {
                                if (mapUserByUserId.get(iterUser.Id).ProfileId <> Id.valueof(String.valueof(iterEmplJA.Employee_Jobduty_Reference__r.ProfileId__c).trim())) {
                                    iterUser.ProfileId = Id.valueof(String.valueof(iterEmplJA.Employee_Jobduty_Reference__r.ProfileId__c).trim());
                                    mapUserFeatureUpdate.put(iterUser.Id, iterUser);
                                }
                            }
                        }
                        // Check Flow user feature from Jobduty
                        if (iterEmplJA.Employee_Jobduty_Reference__r.IsFlowUser__c && !iterUser.UserPermissionsInteractionUser) {
                            iterUser.UserPermissionsInteractionUser = iterEmplJA.Employee_Jobduty_Reference__r.IsFlowUser__c;
                            mapUserFeatureUpdate.put(iterUser.Id, iterUser);
                        }
                        // Check Chat User feature from Jobduty
                        if (iterEmplJA.Employee_Jobduty_Reference__r.IsChatUser__c && !iterUser.UserPermissionsLiveAgentUser) {
                            iterUser.UserPermissionsLiveAgentUser = iterEmplJA.Employee_Jobduty_Reference__r.IsChatUser__c;
                            mapUserFeatureUpdate.put(iterUser.Id, iterUser);
                        }
                        // Check Knowledge User feature from Jobduty
                        if (iterEmplJA.Employee_Jobduty_Reference__r.IsKnowledgeUser__c && !iterUser.UserPermissionsKnowledgeUser) {
                            iterUser.UserPermissionsKnowledgeUser = iterEmplJA.Employee_Jobduty_Reference__r.IsKnowledgeUser__c;
                            mapUserFeatureUpdate.put(iterUser.Id, iterUser);
                        }
                        // Check Marketing User feature from Jobduty
                        if (iterEmplJA.Employee_Jobduty_Reference__r.IsMarketingUser__c && !iterUser.UserPermissionsMarketingUser) {
                            iterUser.UserPermissionsMarketingUser = iterEmplJA.Employee_Jobduty_Reference__r.IsMarketingUser__c;
                            mapUserFeatureUpdate.put(iterUser.Id, iterUser);
                        }
                        // Check Service Cloud user feature from Jobduty
                        if (iterEmplJA.Employee_Jobduty_Reference__r.IsServiceCloudUser__c && !iterUser.UserPermissionsSupportUser) {
                            iterUser.UserPermissionsSupportUser = iterEmplJA.Employee_Jobduty_Reference__r.IsServiceCloudUser__c;
                            mapUserFeatureUpdate.put(iterUser.Id, iterUser);
                        }
                        // Check Call Center feature from Jobduty
                        if (iterEmplJA.Employee_Jobduty_Reference__r.CallCenterId__c <> null) {
                            if (mapUserByUserId.get(iterUser.Id).CallCenterId <> Id.valueof(String.valueof(iterEmplJA.Employee_Jobduty_Reference__r.CallCenterId__c).trim())) {
                                    iterUser.CallCenterId = Id.valueof(String.valueof(iterEmplJA.Employee_Jobduty_Reference__r.CallCenterId__c).trim());
                                    mapUserFeatureUpdate.put(iterUser.Id, iterUser);
                            }
                        }
                    }
                }
            }
        }
        if (mapUserFeatureUpdate.size() > 0) {
            // Update user record for other feature updates including profile
            system.debug(mapUserFeatureUpdate.values());
            UPDATE mapUserFeatureUpdate.values();
        }
        if (mapUserUpdateForRole.size() > 0) {
            // Update user records for role update
            system.debug(mapUserUpdateForRole);
            list<User> listUserUpdForRole = new list<User>();
            if (mapUserFeatureUpdate.size() > 0) {
                // If other features were updated for some users along with role
                for (User iUserRole : mapUserFeatureUpdate.values()) {
                    if (mapUserUpdateForRole.get(iUserRole.Id) <> null) {
                        iUserRole.UserRoleId = mapUserUpdateForRole.get(iUserRole.Id).UserRoleId;
                        listUserUpdForRole.add(iUserRole);
                    }
                }
                for (User iUserRoleChangeOnly : mapUserUpdateForRole.values()) {
                    // If only role was changed for some users but not other features
                    if (mapUserFeatureUpdate.get(iUserRoleChangeOnly.Id) == null) {
                        listUserUpdForRole.add(mapUserUpdateForRole.get(iUserRoleChangeOnly.Id));
                    }
                }
            } else {
                // Only role was changed for all users
                if (mapUserUpdateForRole.values() <> null ) {
                    listUserUpdForRole.addAll(mapUserUpdateForRole.values());
                }
            }
            
            // Update Role - avoid mixed DML
            if (listUserUpdForRole.size() > 0) {
                system.debug(listUserUpdForRole);
                UPDATE listUserUpdForRole;
            }
        }
    }
    
    private static void ManagePermissionSetAccess (map<Id, List<Employee_Jobduty_Assignment__c>> mapEmplJAByUserId, map<Id, map<Id, PermissionSetAssignment>> mapPSAByPSByUser) {
        map<Id, list<PermissionSetAssignment>> mapNewPSAbyUser = new map<Id, list<PermissionSetAssignment>>();
        map<Id, list<PermissionSetAssignment>> mapDeletePSAbyUser = new map<Id, list<PermissionSetAssignment>>();
        set<Id> setEmplJAByPS;
        if (mapEmplJAByUserId <> null) { // If some users have some Jobduty assigned
            for (Id iterUserId : mapEmplJAByUserId.keyset()) {
                // Current user's permission set assignment map - mapUnitUserPSA
                map<Id, PermissionSetAssignment> mapUnitUserPSA = (mapPSAByPSByUser <> null ? mapPSAByPSByUser.get(iterUserId) : null);
                list<Employee_Jobduty_Assignment__c> listUnitUserJA = new list<Employee_Jobduty_Assignment__c>();
                listUnitUserJA = mapEmplJAByUserId.get(iterUserId);
                setEmplJAByPS = new set<Id>();
                if (listUnitUserJA <> null && listUnitUserJA.size() > 0) {
                    for (Employee_Jobduty_Assignment__c iterUnitUserJA : listUnitUserJA) {
                        if (iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetId__c <> null) {
                            setEmplJAByPS.add(Id.valueof(iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetId__c));
                        }
                        if (iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetGroupId__c <> null) {
                            setEmplJAByPS.add(Id.valueof(iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetGroupId__c));
                        }
                        system.debug(mapUnitUserPSA);
                        if (mapUnitUserPSA <> null && 
                            (
                                (
                                    iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetId__c <> null && 
                                    mapUnitUserPSA.get(Id.valueof(iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetId__c)) == null
                                ) || 
                                (
                                    iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetGroupId__c <> null && 
                                    mapUnitUserPSA.get(Id.valueof(iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetGroupId__c)) == null
                                )
                            )
                           ) // If current user under iteration has some permission set assigned
                        {
                            PermissionSetAssignment unitUserPermSet, unitUserPermSetGrp;
                            if (iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetId__c <> null) {
                                if (mapUnitUserPSA.get(Id.valueof(iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetId__c)) == null) {
                                    unitUserPermSet = instantiatePSA(iterUserId, Id.valueof(iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetId__c), null);
                                }
                                
                            }
                            if (iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetGroupId__c <> null) {
                                if (mapUnitUserPSA.get(Id.valueof(iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetGroupId__c)) == null) {
                                    unitUserPermSetGrp = instantiatePSA(iterUserId, null, Id.valueof(iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetGroupId__c));
                                }
                            }
                            
                            if (mapNewPSAbyUser.get(iterUserId) <> null && mapNewPSAbyUser.get(iterUserId).size() > 0) {
                                if (unitUserPermSet <> null)
                                	mapNewPSAbyUser.get(iterUserId).add(unitUserPermSet);
                                if (unitUserPermSetGrp <> null)
                                    mapNewPSAbyUser.get(iterUserId).add(unitUserPermSetGrp);
                            } else {
                                list<PermissionSetAssignment> listNewUserUnitPSA = new list<PermissionSetAssignment>();
                                if (unitUserPermSet <> null)
                                	listNewUserUnitPSA.add(unitUserPermSet);
                                if (unitUserPermSetGrp <> null)
                                    listNewUserUnitPSA.add(unitUserPermSetGrp);
                                mapNewPSAbyUser.put(iterUserId, listNewUserUnitPSA);
                            }
                        } else 
                        { // current user under iteration have no PermissionSetAssignment, create new ones
                            if (mapUnitUserPSA == null && (iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetId__c <> null || iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetGroupId__c <> null)) {
                                list<PermissionSetAssignment> listNewUserUnitPSA = new list<PermissionSetAssignment>();
                                if (iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetId__c <> null) {
                                    PermissionSetAssignment unitUserPermSet = instantiatePSA(iterUserId, Id.valueof(iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetId__c), null);
                                    listNewUserUnitPSA.add(unitUserPermSet);
                                }
                                if (iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetGroupId__c <> null) {
                                    PermissionSetAssignment unitUserPermSetGrp = instantiatePSA(iterUserId, null, Id.valueof(iterUnitUserJA.Employee_Jobduty_Reference__r.PermissionSetGroupId__c));
                                    listNewUserUnitPSA.add(unitUserPermSetGrp);
                                }
                                if (mapNewPSAbyUser.get(iterUserId) <> null && listNewUserUnitPSA.size() > 0) {
                                    mapNewPSAbyUser.get(iterUserId).addAll(listNewUserUnitPSA);
                                } else {
                                    mapNewPSAbyUser.put(iterUserId, listNewUserUnitPSA);
                                }
                            }
                        }
                    }
                    if (mapUnitUserPSA <> null) {
                        for (Id unitExistPS : mapUnitUserPSA.keyset()) {
                            if (!setEmplJAByPS.contains(unitExistPS)) { // Perm Set do not existing in Jobduty, potentially delete
                                PermissionSetAssignment unitUserDelPSA = mapUnitUserPSA.get(unitExistPS);
                                if (mapDeletePSAbyUser.get(iterUserId) <> null && mapDeletePSAbyUser.get(iterUserId).size() > 0) {
                                    mapDeletePSAbyUser.get(iterUserId).add(unitUserDelPSA);
                                } else {
                                    list<PermissionSetAssignment> listUserDelPSA = new list<PermissionSetAssignment>();
                                    listUserDelPSA.add(unitUserDelPSA);
                                    mapDeletePSAbyUser.put(iterUserId, listUserDelPSA);
                                }
                            }
                        }
                    }
                }
            }
        }
        // Insert Permission Set Assignment records
        if (mapNewPSAbyUser <> null && mapNewPSAbyUser.size() > 0) {
            system.debug(mapNewPSAbyUser.values());
            list<PermissionSetAssignment> listPSAInsert = new list<PermissionSetAssignment>();
            for (Id unitUser : mapNewPSAbyUser.keyset()) {
                listPSAInsert.addAll(mapNewPSAbyUser.get(unitUser));
            }
            if (listPSAInsert.size() > 0) {
                system.debug(listPSAInsert);
                List<Database.SaveResult> listPSInsertRes = new list<Database.SaveResult>();
                listPSInsertRes = Database.insert(listPSAInsert, false);
                for (Database.SaveResult iterInsertRes : listPSInsertRes) {
                    if (!iterInsertRes.isSuccess()) {
                        system.debug(iterInsertRes);
                        Logger.error('Failed to save permission set assignment', iterInsertRes);
                    }
                }
            }
            
        }
        // Delete Permission set assignment records
        if (mapDeletePSAbyUser <> null && mapDeletePSAbyUser.size() > 0) {
            system.debug(mapDeletePSAbyUser);
            list<PermissionSetAssignment> listPSADel = new list<PermissionSetAssignment>();
            for (Id unitUser : mapDeletePSAbyUser.keyset()) {
                listPSADel.addAll(mapDeletePSAbyUser.get(unitUser));
            }
            if (listPSADel.size() > 0) {
                system.debug(listPSADel);
                //DELETE listPSADel; - Temporarily commented
            }
            
        }
    }
    
    private static void ManageGroupMembership (map<Id, List<Employee_Jobduty_Assignment__c>> mapEmplJAByUserId, map<Id, map<Id, GroupMember>> mapGroupMemberByGrpByUser, map<Id, list<Id>> mapGroupIdByJARef) {
        map<Id, list<GroupMember>> mapNewGrpMemberbyUser = new map<Id, list<GroupMember>>();
        map<Id, list<GroupMember>> mapDelGrpMemberbyUser = new map<Id, list<GroupMember>>();
        set<Id> setEmplJAByGrp;
        if (mapEmplJAByUserId <> null && mapGroupIdByJARef <> null) {
            for (Id iterUserId : mapEmplJAByUserId.keyset()) {
                map<Id, GroupMember> mapUnitUserGrpMem = (mapGroupMemberByGrpByUser <> null ? mapGroupMemberByGrpByUser.get(iterUserId) : null);
                list<Employee_Jobduty_Assignment__c> listUnitUserJA = new list<Employee_Jobduty_Assignment__c>();
                listUnitUserJA = mapEmplJAByUserId.get(iterUserId);
                setEmplJAByGrp = new set<Id>();
                if (listUnitUserJA <> null && listUnitUserJA.size() > 0) {
                    for (Employee_Jobduty_Assignment__c iterUnitUserJA : listUnitUserJA) {
                        if (iterUnitUserJA.Employee_Jobduty_Reference__r.Associated_Groups__c <> 0) {
                            setEmplJAByGrp.addAll(mapGroupIdByJARef.get(iterUnitUserJA.Employee_Jobduty_Reference__c));
                        }
                        if (mapUnitUserGrpMem <> null && iterUnitUserJA.Employee_Jobduty_Reference__r.Associated_Groups__c <> 0) 
                        {
                            for (Id unitGrpId : mapGroupIdByJARef.get(iterUnitUserJA.Employee_Jobduty_Reference__c)) {
                                if (mapUnitUserGrpMem.get(unitGrpId) == null) {
                                    GroupMember unitUserGrpMem = instantiateGrpMember(iterUserId, unitGrpId);
                                    if (mapNewGrpMemberbyUser.get(iterUserId) <> null && mapNewGrpMemberbyUser.get(iterUserId).size() > 0) {
                                        mapNewGrpMemberbyUser.get(iterUserId).add(unitUserGrpMem);
                                    } else {
                                        list<GroupMember> listunitUserGrpMem = new list<GroupMember>();
                                        listunitUserGrpMem.add(unitUserGrpMem);
                                        mapNewGrpMemberbyUser.put(iterUserId, listunitUserGrpMem);
                                    }
                                }
                            }
                        } else 
                        { // No GroupMember record exists, create new ones
                            if (iterUnitUserJA.Employee_Jobduty_Reference__r.Associated_Groups__c <> 0) {
                                for (Id unitGrpId : mapGroupIdByJARef.get(iterUnitUserJA.Employee_Jobduty_Reference__c)) {
                                    GroupMember unitUserGrpMem = instantiateGrpMember(iterUserId, unitGrpId);
                                    if (mapNewGrpMemberbyUser.get(iterUserId) <> null && mapNewGrpMemberbyUser.get(iterUserId).size() > 0) {
                                        mapNewGrpMemberbyUser.get(iterUserId).add(unitUserGrpMem);
                                    } else {
                                        list<GroupMember> listunitUserGrpMem = new list<GroupMember>();
                                        listunitUserGrpMem.add(unitUserGrpMem);
                                        mapNewGrpMemberbyUser.put(iterUserId, listunitUserGrpMem);
                                    }
                                }
                            }
                        }
                    }
                    if (mapUnitUserGrpMem <> null) {
                        for (Id unitExistGrpMem : mapUnitUserGrpMem.keyset()) {
                            if (!setEmplJAByGrp.contains(unitExistGrpMem)) { // GroupMember record do not existing in Jobduty, potentially delete
                                GroupMember unitUserDelGrpMem = mapUnitUserGrpMem.get(unitExistGrpMem);
                                if (mapDelGrpMemberbyUser.get(iterUserId) <> null && mapDelGrpMemberbyUser.get(iterUserId).size() > 0) {
                                    mapDelGrpMemberbyUser.get(iterUserId).add(unitUserDelGrpMem);
                                } else {
                                    list<GroupMember> listUserDelGrpMem = new list<GroupMember>();
                                    listUserDelGrpMem.add(unitUserDelGrpMem);
                                    mapDelGrpMemberbyUser.put(iterUserId, listUserDelGrpMem);
                                }
                            }
                        }
                    }
                }
                
            }
        }
        
        // Insert Group Membership records
        if (mapNewGrpMemberbyUser <> null && mapNewGrpMemberbyUser.size() > 0) {
            system.debug(mapNewGrpMemberbyUser.values());
            list<GroupMember> listGroupMemberInsert = new list<GroupMember>();
            for (Id unitUser : mapNewGrpMemberbyUser.keyset()) {
                listGroupMemberInsert.addAll(mapNewGrpMemberbyUser.get(unitUser));
            }
            if (listGroupMemberInsert.size() > 0) {
                system.debug(listGroupMemberInsert);
                List<Database.SaveResult> listGrpInsertRes = new list<Database.SaveResult>();
                listGrpInsertRes = Database.insert(listGroupMemberInsert, false);
                for (Database.SaveResult iterGrpRes : listGrpInsertRes) {
                    if (!iterGrpRes.isSuccess()) {
                        Logger.error('Failed to save group membership change', iterGrpRes);
                    }
                }
            }
            
        }
        // Delete Group Membership records
        if (mapDelGrpMemberbyUser <> null && mapDelGrpMemberbyUser.size() > 0) {
            system.debug(mapDelGrpMemberbyUser);
            list<GroupMember> listGroupMemberDel = new list<GroupMember>();
            for (Id unitUser : mapDelGrpMemberbyUser.keyset()) {
                listGroupMemberDel.addAll(mapDelGrpMemberbyUser.get(unitUser));
            }
            if (listGroupMemberDel.size() > 0) {
                system.debug(listGroupMemberDel);
                //DELETE listGroupMemberDel; - Temporarily commented
            }
            
        }
    }
    //This method will update the public group/queue membership of employees (using GroupMember object)
    //input: Employee_Group_Assignment__c object list which holds user Ids, Group Ids & Activity (Adding/removing employees from public groups/queues)
    public static void ManageEmployeeGroupMembership(List<Employee_Group_Assignment__c> listEmpGroupAssignments){
        try{
            if (listEmpGroupAssignments <> null && listEmpGroupAssignments.size() > 0){
                List<GroupMember> listAddEmpToGroups = new List<GroupMember>();
                List<Employee_Group_Assignment__c> listDelEmpGrpAssign = new List<Employee_Group_Assignment__c>();
                List<Id> listDelGrpMemUserIds = new List<Id>();
                
                for(Employee_Group_Assignment__c empGrpAssign: listEmpGroupAssignments){ 
                    if(empGrpAssign.Activity__c == 'Adding employee to Public Group/Queue'){
                        GroupMember addGM = instantiateGrpMember(empGrpAssign.Employee__r.User__c, empGrpAssign.Group_ID__c);
                        listAddEmpToGroups.add(addGM);
                    }
                    else if(empGrpAssign.Activity__c == 'Removing employee from Public Group/Queue'){
                        listDelGrpMemUserIds.add(empGrpAssign.Employee__r.User__c);
                        listDelEmpGrpAssign.add(empGrpAssign);
                    }
                }

                //adding employees to public groups/queue (inserting records in GroupMember)
                if(listAddEmpToGroups <> null && listAddEmpToGroups.size() > 0)
                    Database.insert(listAddEmpToGroups);
                
                //removing employees from public groups/queues (deleting records from GroupMember)
                Set<GroupMember> setDelEmpFromGrpMem = new Set<GroupMember>();
                Map<Id, GroupMember> unitDelEmpFromGrpMem = new Map<Id, GroupMember>();
                Map<Id, Map<Id, GroupMember>> mapDelEmpFromGrpMem = getGrpMemByGrpByUser(listDelGrpMemUserIds);
                
                if(listDelEmpGrpAssign?.size() > 0 && mapDelEmpFromGrpMem?.size() > 0){
                    for(Employee_Group_Assignment__c unitEmpGrpAssign: listDelEmpGrpAssign){
                        if(mapDelEmpFromGrpMem.get(unitEmpGrpAssign.Employee__r.User__c)?.get(unitEmpGrpAssign.Group_ID__c) <> null && 
                            mapDelEmpFromGrpMem.get(unitEmpGrpAssign.Employee__r.User__c)?.get(unitEmpGrpAssign.Group_ID__c).GroupId == unitEmpGrpAssign.Group_ID__c && 
                            mapDelEmpFromGrpMem.get(unitEmpGrpAssign.Employee__r.User__c)?.get(unitEmpGrpAssign.Group_ID__c).UserOrGroupId == unitEmpGrpAssign.Employee__r.User__c) {
                                setDelEmpFromGrpMem.add(mapDelEmpFromGrpMem.get(unitEmpGrpAssign.Employee__r.User__c)?.get(unitEmpGrpAssign.Group_ID__c));
                        }else if(mapDelEmpFromGrpMem.get(unitEmpGrpAssign.Employee__r.User__c)?.get(unitEmpGrpAssign.Employee__r.User__c) <> null && 
                            mapDelEmpFromGrpMem.get(unitEmpGrpAssign.Employee__r.User__c)?.get(unitEmpGrpAssign.Employee__r.User__c).GroupId == unitEmpGrpAssign.Group_ID__c && 
                            mapDelEmpFromGrpMem.get(unitEmpGrpAssign.Employee__r.User__c)?.get(unitEmpGrpAssign.Employee__r.User__c).UserOrGroupId == unitEmpGrpAssign.Employee__r.User__c){
                                setDelEmpFromGrpMem.add(mapDelEmpFromGrpMem.get(unitEmpGrpAssign.Employee__r.User__c)?.get(unitEmpGrpAssign.Employee__r.User__c));
                        }
                    }
                }
                List<GroupMember> listDelEmpFromGrpMem = new List<GroupMember>();
                listDelEmpFromGrpMem.addAll(setDelEmpFromGrpMem);
                System.debug(setDelEmpFromGrpMem);
                if(listDelEmpFromGrpMem <> null && listDelEmpFromGrpMem.size() > 0)
                    Database.delete(listDelEmpFromGrpMem);                
            }
        } catch(exception e) {
            Logger.error('an error occured while updating the employee public group/queue membership records', e);
            System.debug(e);
        } finally {
            if(!System.isBatch())
                Logger.saveLog();
        }
    }
    
    private static GroupMember instantiateGrpMember (Id UserId, Id GroupId) {
        GroupMember grp = new GroupMember();
        grp.GroupId = GroupId;
        grp.UserOrGroupId = UserId;
        
        return grp;
    }
    
    private static PermissionSetAssignment instantiatePSA(Id UserId, Id PSAId, Id PSAGrpId) {
        PermissionSetAssignment newPSA = new PermissionSetAssignment();
        newPSA.AssigneeId = UserId;
        newPSA.PermissionSetId = PSAId;
        newPSA.PermissionSetGroupId = PSAGrpId;
        
        return newPSA;
    }
    
    
    public static void GrantEmployeeAccessByUserId (list<Id> listuserId) {
        Savepoint initSave = Database.setSavepoint();
        try {
            if (listuserId <> null && listuserId.size() > 0) {
                map<Id, list<Employee_Jobduty_Assignment__c>> mapEmplJAByUser = getEmployeeJAByUserId(listuserId);
                map<Id, User> mapUserByUserId = getUserByUserId(listuserId);
                map<Id, map<Id, PermissionSetAssignment>> mapPSAByPSByUser = getPSAByPermSetByUser(listuserId);
                map<Id, map<Id, GroupMember>> mapGrpMemByGrpByUser = getGrpMemByGrpByUser(listuserId);
                list<Employee_Jobduty_Assignment__c> listallCurrJA = new list<Employee_Jobduty_Assignment__c>();
                for (Id iEmplJA : mapEmplJAByUser.keyset()) {
                    listallCurrJA.addAll(mapEmplJAByUser.get(iEmplJA));
                }
                map<Id, list<Id>> mapGrpIdByJARef = getGroupIdByJARef(listallCurrJA);
                ManageUserFeatureAccess(mapEmplJAByUser, mapUserByUserId);
                ManagePermissionSetAccess(mapEmplJAByUser, mapPSAByPSByUser);
                ManageGroupMembership(mapEmplJAByUser, mapGrpMemByGrpByUser, mapGrpIdByJARef);
            }
        } catch (exception e) {
            Database.rollback(initSave);
            Logger.error('Exceptions occurred during transaction', e);
            system.debug(e);
            system.debug(e.getStackTraceString());
        } finally {
            Logger.saveLog();
        }
        
    }
    
    private static map<Id, list<Employee_Jobduty_Assignment__c>> getEmployeeJAByUserId (list<Id> listuserId) {
        List<Employee_Jobduty_Assignment__c> listEmplDuty = new list<Employee_Jobduty_Assignment__c>();
        listEmplDuty = [SELECT Id, Primary_Or_Extended__c, Employee_Jobduty_Reference__c, Employee_Jobduty_Reference__r.ProfileId__c, 
                        Employee_Jobduty_Reference__r.RoleId__c, Employee_Jobduty_Reference__r.CallCenterId__c, Employee_Jobduty_Reference__r.PermissionSetId__c, 
                        Employee_Jobduty_Reference__r.PermissionSetGroupId__c, Employee_Jobduty_Reference__r.IsKnowledgeUser__c, 
                        Employee_Jobduty_Reference__r.IsMarketingUser__c, Employee_Jobduty_Reference__r.IsServiceCloudUser__c,  
                       	Employee_Jobduty_Reference__r.IsFlowUser__c, Employee_Jobduty_Reference__r.IsChatUser__c, 
                        Employee_Jobduty_Reference__r.Associated_Groups__c, Employee__r.User__c 
                       	FROM Employee_Jobduty_Assignment__c 
                       	WHERE IsActive__c = true AND Employee__r.User__c IN :listuserId];
        map<Id, list<Employee_Jobduty_Assignment__c>> mapEmplJAByUserId = new map<Id, list<Employee_Jobduty_Assignment__c>>();
        if (listEmplDuty.size() > 0) {
            for (Employee_Jobduty_Assignment__c iter : listEmplDuty) {
                if (mapEmplJAByUserId.get(iter.Employee__r.User__c) <> null && mapEmplJAByUserId.get(iter.Employee__r.User__c).size() > 0) {
                    mapEmplJAByUserId.get(iter.Employee__r.User__c).add(iter);
                } else {
                    list<Employee_Jobduty_Assignment__c> listUserJA = new list<Employee_Jobduty_Assignment__c>();
                    listUserJA.add(iter);
                    mapEmplJAByUserId.put(iter.Employee__r.User__c, listUserJA);
                }
            }
        }
        if (mapEmplJAByUserId.size() > 0) {
            return mapEmplJAByUserId;
        } else {
            return null;
        }
        
    }
    
    private static map<Id, User> getUserByUserId (list<Id> listuserId) {
        map<Id, User> mapUserByUserId = new map<Id, User>([SELECT Id, ProfileId, UserRoleId, UserPermissionsInteractionUser
                                                           , UserPermissionsKnowledgeUser, CallCenterId, 
                                                           UserPermissionsLiveAgentUser, UserPermissionsMarketingUser
                                                           , UserPermissionsSupportUser
                                                           FROM User 
                                                           WHERE Id IN :listuserId]);
        if (mapUserByUserId <> null && mapUserByUserId.size() > 0) {
            return mapUserByUserId;
        } else {
            return null;
        }
        
    }
    
    private static map<Id, map<Id, PermissionSetAssignment>> getPSAByPermSetByUser (list<Id> listuserId) {
        map<Id, map<Id, PermissionSetAssignment>> mapPSAByPSByUser = new map<Id, map<Id, PermissionSetAssignment>>();
        list <PermissionSetAssignment> listCurrPermSet = new list<PermissionSetAssignment>();
        listCurrPermSet = [SELECT Id, AssigneeId, PermissionSetId, PermissionSetGroupId FROM PermissionSetAssignment 
                           WHERE AssigneeId IN :listuserId AND PermissionSet.IsOwnedByProfile = false];
        for (PermissionSetAssignment iter : listCurrPermSet) {
            if (mapPSAByPSByUser.get(iter.AssigneeId) <> null) {
                if (iter.PermissionSetId <> null && iter.PermissionSetGroupId == null )
                    mapPSAByPSByUser.get(iter.AssigneeId).put(iter.PermissionSetId, iter);
                if (iter.PermissionSetGroupId <> null)
                    mapPSAByPSByUser.get(iter.AssigneeId).put(iter.PermissionSetGroupId, iter);
            } else {
                map <Id, PermissionSetAssignment> mapPSAByPermSet = new map <Id, PermissionSetAssignment>();
                if (iter.PermissionSetId <> null && iter.PermissionSetGroupId == null )
                    mapPSAByPermSet.put(iter.PermissionSetId, iter);
                if (iter.PermissionSetGroupId <> null)
                    mapPSAByPermSet.put(iter.PermissionSetGroupId, iter);
                mapPSAByPSByUser.put(iter.AssigneeId, mapPSAByPermSet);
                
            }
        }
        if (mapPSAByPSByUser.size() > 0) {
            return mapPSAByPSByUser;
        } else {
            return null;
        }
    }
    
    private static map<Id, map<Id, GroupMember>> getGrpMemByGrpByUser (list<Id> listuserId) {
        map<Id, map<Id, GroupMember>> mapGrpMemByGrpByUser = new map<Id, map<Id, GroupMember>>();
        list <GroupMember> listCurrGrpMem = new list<GroupMember>();
        listCurrGrpMem = [SELECT Id, UserOrGroupId, GroupId  FROM GroupMember 
                           WHERE UserOrGroupId IN :listuserId];
        for (GroupMember iter : listCurrGrpMem) {
            if (mapGrpMemByGrpByUser.get(iter.UserOrGroupId) <> null) {
                if (iter.GroupId <> null)
                    mapGrpMemByGrpByUser.get(iter.UserOrGroupId).put(iter.GroupId, iter);
            } else {
                map <Id, GroupMember> mapPSAByPermSet = new map <Id, GroupMember>();
                if (iter.UserOrGroupId <> null)
                    mapPSAByPermSet.put(iter.UserOrGroupId, iter);
                mapGrpMemByGrpByUser.put(iter.UserOrGroupId, mapPSAByPermSet);
                
            }
        }
        if (mapGrpMemByGrpByUser.size() > 0) {
            return mapGrpMemByGrpByUser;
        } else {
            return null;
        }
    }
    
    private static map<Id, list<Id>> getGroupIdByJARef (list<Employee_Jobduty_Assignment__c> listEmplJA) {
        list<Id> listEmplJARef = new list<Id>();
        for (Employee_Jobduty_Assignment__c iterJA : listEmplJA) {
            listEmplJARef.add(iterJA.Employee_Jobduty_Reference__c);
        }
        map<Id, list<Id>> mapGroupIdsByJARef = new map<Id, list<Id>>();
        List<Jobduty_Group_Config__c> listGrpConfig = new list< Jobduty_Group_Config__c>();
        listGrpConfig = [SELECT Id, GroupId__c, Employee_Jobduty_Reference__c FROM Jobduty_Group_Config__c 
                        WHERE Employee_Jobduty_Reference__c IN :listEmplJARef];
        if (listGrpConfig.size() > 0) {
            for (Jobduty_Group_Config__c iConfig : listGrpConfig) {
                if (mapGroupIdsByJARef.get(iConfig.Employee_Jobduty_Reference__c) <> null) {
                    mapGroupIdsByJARef.get(iConfig.Employee_Jobduty_Reference__c).add(iConfig.GroupId__c);
                } else {
                    list<Id> listGroupIdPerConfig = new list<Id>();
                    listGroupIdPerConfig.add(iConfig.GroupId__c);
                    mapGroupIdsByJARef.put(iConfig.Employee_Jobduty_Reference__c, listGroupIdPerConfig);
                }
            }
        }
        if (mapGroupIdsByJARef.size() > 0){
            return mapGroupIdsByJARef;
        } else {
            return null;
        }
    }
}
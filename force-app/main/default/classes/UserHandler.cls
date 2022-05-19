public with sharing class UserHandler {
    public Class PermissionBean {
        public map<String, map<String, set<String>>> roleToTypeToPermMap ;
        public map<String, set<String>> typeToPermMap ;    
        public map<Id, String> permTypeToId;    
        public PermissionBean() {
            roleToTypeToPermMap = new map<String, map<String, set<String>>>();
            typeToPermMap = new map<String, set<String>>();        
            permTypeToId = new map<Id, String>();
        }
    }

    public static List<sObject> processUserPermissions(Set<Id> empIds, Map<Id, Map<Id, GroupMember>> userToGroupMember) {
        List<sObject> failedDMLsObjects = new List<sObject>();
        List<Employee__c> employeeList = new List<Employee__c>();
        PermissionBean perm = new PermissionBean();
        List<Id> userIdSet = new List<Id>();
        List<PermissionSetAssignment> insertPermSetAssignList = new List<PermissionSetAssignment>();
        List<PermissionSetLicenseAssign> insertPermLicAssignList = new List<PermissionSetLicenseAssign>();   
        map<Id, set<Id>> userToPermMap = new  map<Id, set<Id>>();
        List<GroupMember> insertGroupMemberList = new List<GroupMember>();
        Map<Id, GroupMember> deleteGroupMemberList = new Map<Id, GroupMember>();      
        perm = fetchPermissionsFromMetadata(perm);      
        List<String> recordIds;
        String recordId;
            
        employeeList = [SELECT Id, isActive__c, User__c, SFProfileId__c, RecordTypeId FROM Employee__c WHERE isActive__c =: TRUE AND Id IN: empIds WITH SECURITY_ENFORCED];

        for(Employee__c Employee : employeeList) {
            if(Employee.isActive__c && String.isNotBlank(Employee.User__c) && String.isNotBlank(Employee.SFProfileId__c)) {
                userIdSet.add(Employee.User__c);
            }
        }
        if(perm.typeToPermMap.containsKey(RetailConstants.RETAIL_PL)) {
            Set<String> pslic = perm.typeToPermMap.get(RetailConstants.RETAIL_PL);
            recordIds =  getPermRecordIds(perm, pslic);            
            for(PermissionSetLicenseAssign permLicAssign: [SELECT  id, AssigneeId, PermissionSetLicenseId 
                                                            FROM PermissionSetLicenseAssign
                                                            WHERE AssigneeId  IN :userIdSet AND
                                                            PermissionSetLicenseId IN :recordIds]) 
            {
                set<Id> permSet = new set<Id>();
                if(userToPermMap.containsKey(permLicAssign.AssigneeId)) {
                    permSet = userToPermMap.get(permLicAssign.AssigneeId);                 
                }            
                permSet.add(permLicAssign.PermissionSetLicenseId);
                userToPermMap.put(permLicAssign.AssigneeId, permSet);
            }          
        }

        if(perm.typeToPermMap.containsKey(RetailConstants.RETAIL_PS)) {
            Set<String> ps = perm.typeToPermMap.get(RetailConstants.RETAIL_PS);           
            recordIds =  getPermRecordIds(perm, ps); 
            for(PermissionSetAssignment permSetAssign: [SELECT AssigneeId, PermissionSetId, id
                                                            FROM PermissionSetAssignment
                                                            WHERE AssigneeId IN :userIdSet AND 
                                                            PermissionSetId IN :recordIds]) 
            {
                set<Id> permSet = new set<Id>();
                if(userToPermMap.containsKey(permSetAssign.AssigneeId)) {                    
                    permSet = userToPermMap.get(permSetAssign.AssigneeId);                    
                }  
                permSet.add(permSetAssign.PermissionSetId);
                userToPermMap.put(permSetAssign.AssigneeId, permSet);               
            }           
        }
        /*
        if(roleToTypeToPermMap.values().containsKey(RetailConstants.RETAIL_PS)) {
            for(GroupMember grpMember: [SELECT Id, GroupId, UserOrGroupId
                                        FROM GroupMember 
                                        WHERE UserOrGroupId IN :userIdSet AND
                                        GroupId IN :roleToTypeToPermMap.values().containsKey(RetailConstants.RETAIL_GM)]) 
            {
                set<Id> permSet = new set<Id>();
                if(userToPermMap.containsKey(grpMember.UserOrGroupId)) {
                    permSet = userToPermMap.get(grpMember.UserOrGroupId);
                }
                permSet.add(grpMember.GroupId);
                userToPermMap.put(grpMember.UserOrGroupId, permSet);
            }
        }*/

        for(Employee__c Employee : employeeList) {
            if(Employee.isActive__c && String.isNotBlank(Employee.User__c) && String.isNotBlank(Employee.SFProfileId__c)  
                && Employee.RecordTypeId == RetailConstants.RETAIL_RECORDTYPEID) {
                    set<Id> permSet = new set<Id>();
                    if(userToPermMap.containsKey(Employee.User__c)) {
                        permSet = userToPermMap.get(Employee.User__c);
                    }
                    for(String role: perm.roleToTypeToPermMap.keySet()) {
                        if(role.equalsIgnoreCase(Employee.SFProfileId__c)) {
                            map<String, set<String>> typeToPermMap = perm.roleToTypeToPermMap.get(role);                                                        
                            for(String permType: typeToPermMap.keySet()) {
                                set<String> desiredPermSet = typeToPermMap.get(permType); 
                                for(String permId: desiredPermSet) {  
                                    if(permType.equalsIgnoreCase(RetailConstants.RETAIL_GM)) {
                                    
                                        recordId =  getPermRecordId(perm, permId); 
                                        // Add GroupMember only if the User doesn't have it already
                                        if (userToGroupMember.containsKey(Employee.User__c)
                                            && !(userToGroupMember.get(Employee.User__c).containsKey(recordId)) ) {
                                        
                                                GroupMember gm = new GroupMember(UserOrGroupId = Employee.User__c, GroupId = recordId);
                                                insertGroupMemberList.add(gm);
                                        }                                      
                                    } else if(!permSet.contains(getPermRecordId(perm, permId))) {
                                        if(permType.equalsIgnoreCase(RetailConstants.RETAIL_PL)) {
                                            //Assign Permission License to user                                           
                                            recordId =  getPermRecordId(perm, permId);       
                                            PermissionSetLicenseAssign psal = new PermissionSetLicenseAssign(AssigneeId = Employee.User__c,
                                                                                                            PermissionSetLicenseId = recordId);
                                            insertPermLicAssignList.add(psal);
                                        
                                        } else if(permType.equalsIgnoreCase(RetailConstants.RETAIL_PS)) {
                                            //Assign Permission Set to user                                          
                                            recordId =  getPermRecordId(perm, permId);       
                                            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = Employee.User__c,
                                                                                                        PermissionSetId = recordId);
                                            insertPermSetAssignList.add(psa);
                                            
                                        }
                                    }
                                } 
                            }
                        } else {
                            map<String, set<String>> typeToPermMap = perm.roleToTypeToPermMap.get(role);
                            for(String permType: typeToPermMap.keySet()) {
                                set<String> desiredPermSet = typeToPermMap.get(permType);
                                for(String permId: desiredPermSet) {
                                    if(permType.equalsIgnoreCase(RetailConstants.RETAIL_GM)) {
                                        recordId =  getPermRecordId(perm, permId);
                                        if (userToGroupMember.containsKey(Employee.User__c)
                                            && (userToGroupMember.get(Employee.User__c).containsKey(recordId)) ) {
                                                GroupMember gm = userToGroupMember.get(Employee.User__c).get(recordId);
                                                if (!deleteGroupMemberList.containsKey(gm.Id)) {
                                                    deleteGroupMemberList.put(gm.Id, gm);
                                                }
                                            }
                                    }
                                }
                            }
                        } 
                    }
            }
        }

        // SPTSFDCSLS-2812
        // We are only adding GM if User doesn't have one already (insertGroupMemberList above)
        /* if(perm.typeToPermMap.containsKey(RetailConstants.RETAIL_GM)){
            Set<String> grp = perm.typeToPermMap.get(RetailConstants.RETAIL_GM);           
            recordIds =  getPermRecordIds(perm, grp); 
            deleteGroupMemberList = [SELECT Id, GroupId, UserOrGroupId 
                                        FROM GroupMember 
                                        WHERE UserOrGroupId IN: userIdSet AND 
                                        GroupId IN :recordIds];

        } */
        if(!deleteGroupMemberList.isEmpty()){
            delete deleteGroupMemberList.values();
        }

        if(!insertGroupMemberList.isEmpty()) {
            
            Database.SaveResult[] srList = Database.insert(insertGroupMemberList, false);
            
            Integer i = 0;
            for (Database.SaveResult insertResult : srList) {
                if (!insertResult.isSuccess()) {
                    failedDMLsObjects.add(insertGroupMemberList.get(i));
                    for(Database.Error err : insertResult.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
                i++;
            }


            
        }     
        if(!insertPermLicAssignList.isEmpty()) {
            insert insertPermLicAssignList;
        }             
        if(!insertPermSetAssignList.isEmpty()) {
            insert insertPermSetAssignList;
        }

        return failedDMLsObjects;
        
    }
   
    private static PermissionBean fetchPermissionsFromMetadata(PermissionBean permBean) {
        set<String> permLabelSet = new set<String>();
        List<UserPermission__mdt> permissionList = [SELECT DeveloperName, Label, PermissionType__c, RetailProfile__c 
                                                    FROM UserPermission__mdt];         
       
        for(UserPermission__mdt perm: permissionList) {           
            if(perm.RetailProfile__c != null && perm.PermissionType__c != null && perm.Label != null) {
                map<String, set<String>> typeToPermMap = new map<String, set<String>>();
                set<String> permSet = new set<String>();
                if(permBean.roleToTypeToPermMap.containsKey(perm.RetailProfile__c)) {
                    typeToPermMap = permBean.roleToTypeToPermMap.get(perm.RetailProfile__c);
                }
                if(typeToPermMap.containsKey(perm.PermissionType__c)) {
                    permSet = typeToPermMap.get(perm.PermissionType__c);
                }
                
                permSet.add(perm.Label);               
                
                if(!permLabelSet.contains(perm.Label))
                    permLabelSet.add(perm.Label);
                
                typeToPermMap.put(perm.PermissionType__c, permSet);
                permBean.roleToTypeToPermMap.put(perm.RetailProfile__c, typeToPermMap);
                if(permBean.typeToPermMap.containsKey(perm.PermissionType__c)) {
                    permBean.typeToPermMap.get(perm.PermissionType__c).add(perm.Label);
                } else {
                    permBean.typeToPermMap.put(perm.PermissionType__c, new set<String>{perm.Label});
                }               
            }
        }
        if(!permLabelSet.isEmpty()) {
            List<PermissionSet> psList =  [SELECT Id, Name FROM PermissionSet WHERE Name IN :permLabelSet];
            for(PermissionSet ps : psList) {
                permBean.permTypeToId.put(ps.Id, ps.Name);
            }
            List<PermissionSetLicense> pslList = [SELECT Id, DeveloperName FROM PermissionSetLicense WHERE DeveloperName IN: permLabelSet ];
            for(PermissionSetLicense psl : pslList){
                permBean.permTypeToId.put(psl.Id, psl.DeveloperName);        
            }

            List<Group> grpList =  [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN: permLabelSet];
            for(Group g : grpList){       
                permBean.permTypeToId.put(g.Id, g.DeveloperName);
            }  
        }

        return permBean;
    }

    public static List<String> getPermRecordIds(PermissionBean perm, Set<String> permIds) {       
        List<String> recId = new List<String>();      
         for(String pId : permIds){
            for(Id key : perm.permTypeToId.keySet()) { 
                if(pId == perm.permTypeToId.get(key))
                    recId.add(key);
            }
         } 

        return recId;
     }  
     
     public static String getPermRecordId(PermissionBean perm, String permId) {       
        String recId = '';            
        for(Id key : perm.permTypeToId.keySet()) { 
            if(permId == perm.permTypeToId.get(key))
                recId = key;
        }            
     
        return recId;
     }   
    
    
}
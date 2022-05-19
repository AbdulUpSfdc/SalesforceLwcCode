global with sharing class KMRolePermissionUpdateBatch implements Database.Batchable<sObject>,Database.Stateful {
    
    set<Id> setKMUserProfiles = new set<Id>();
    List<UserProfileFailureLogs__c> errorLogList = new List<UserProfileFailureLogs__c>();
     
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator(
            'SELECT Id,Name,ATTUID__c,Sys_Role_ID__c,BusinessRole__c,DefaultChannelId__c,DefaultMarketId__c,EmployeeFlag__c,KSEmployeeTypeId__c,KSUserRole__c,Status__c FROM BWKMUserProfile__c WHERE Status__c =\'Awaiting Add Processing\''
        );
       
    }
    
    global void execute(Database.BatchableContext BC, List<BWKMUserProfile__c> listKMUsers) {        
        set<Id> setUserIDs = new set<Id>();
        set<Id> setEmpIds = new set<Id>();
        set<String> setattUIDS = new set<String>();
        set<String> setChannelIds = new set<String>();
        List<String> strRoleValues = new List<String>();
        
        
        
        map<String,Id> mapATTtoUserID = new map<String,Id>();
        map<String,Employee__c> mapATTtoEmployee = new map<String,Employee__c>();
        map<String,String> mapEmpMaster = new map<String,String>();
        map<String,String> mapEmpChannel = new map<String,String>();
        map<String,String> mapChannelPermSet = new map<String,String>();
        map<Id,List<PermissionSetAssignment>> mapAssigneePermSets = new map<Id,List<PermissionSetAssignment>>();
        map<String,String> mapRoleMaster = new map<String,String>();
        map<String,String> mapStrRoleNames = new map<String,String>();
        map<String,Set<Id>> mapRolePermission = new map<String,Set<Id>>();
        
        List<PermissionSetAssignment> listToDeletePermSets = new List<PermissionSetAssignment>();
        List<PermissionSetAssignment> listPSAsToInsert= new List<PermissionSetAssignment>();
        
        for(BWKMUserProfile__c kup : listKMUsers){
            setattUIDS.add(kup.ATTUID__c);
            setChannelIds.add(kup.DefaultChannelId__c);
            strRoleValues = kup.Sys_Role_ID__c.split(':');
            system.debug('strRoleValues'+strRoleValues);
        }
        
        for(Employee__c e : [Select Id,Name,BWDefaultKMChannel__c,BWDefault_KM_Master__c,User__c,Employee_Type_Id__c,User_Role__c,EmployeeId__c from Employee__c where EmployeeId__c IN:setattUIDS]){
            mapATTtoEmployee.put(e.EmployeeId__c,e);
            mapATTtoUserID.put(e.EmployeeId__c,e.User__c);
            setUserIDs.add(e.User__c);
            mapEmpMaster.put(e.EmployeeId__c,e.BWDefault_KM_Master__c);
            mapEmpChannel.put(e.EmployeeId__c,e.BWDefaultKMChannel__c);
            setEmpIds.add(e.Id);
        }
        
        
        for(BWRoleMaster__c mmRole : [SELECT Id,Role_Name__c,Role_Value__c,Sys_Role_ID__c FROM BWRoleMaster__c where Sys_Role_ID__c IN:strRoleValues ]){
            mapRoleMaster.put(mmRole.Sys_Role_ID__c,mmRole.Role_Value__c);
            mapStrRoleNames.put(mmRole.Role_Value__c,mmRole.Role_Name__c);
        }
        
        for(BWRolePermissions__c rolePerm : [SELECT Id,PermissionSetId__c,PermissionSetName__c,RoleName__c,RoleValue__c,SystemPermissionSet__c FROM BWRolePermissions__c where RoleValue__c IN: mapRoleMaster.values()]){
              if(rolePerm.SystemPermissionSet__c == true){
            if(mapRolePermission.containsKey(rolePerm.RoleValue__c)){
                mapRolePermission.get(rolePerm.RoleValue__c).add(rolePerm.PermissionSetId__c);
            }
            else{
                mapRolePermission.put(rolePerm.RoleValue__c,new Set<Id>{rolePerm.PermissionSetId__c});
            }
           }
        }
        for(BW_Channel_Mapping__c bcm : [Select Id,KM_Channel_ID__c,Permission_Set_Id__c from BW_Channel_Mapping__c]){
            mapChannelPermSet.put(bcm.KM_Channel_ID__c,bcm.Permission_Set_Id__c);
        }
        
        for(PermissionSetAssignment psa : [Select Id,PermissionSetId,AssigneeId,PermissionSet.Name,PermissionSet.Label from PermissionSetAssignment where AssigneeId IN:setUserIDs]){
            if(mapAssigneePermSets.containsKey(psa.AssigneeId)){
                mapAssigneePermSets.get(psa.AssigneeId).add(psa);
            }
            else{
                mapAssigneePermSets.put(psa.AssigneeId,new List<PermissionSetAssignment>{psa});
            }
            
        }  
        
        // Add the permission set names to KMPermissionSet__mdt metadata which don't need to be deleted.
        Map<String, KMPermissionSet__mdt > mapPermSetNames = KMPermissionSet__mdt.getAll();        
        
        for(BWKMUserProfile__c kup:listKMUsers){
            
            Id userId = mapATTtoUserID.get(kup.ATTUID__c);
          
            List<PermissionSetAssignment> PermSetListToDelete = mapAssigneePermSets.get(userId);
            if(PermSetListToDelete != null && !PermSetListToDelete.isEmpty()){
                for(PermissionSetAssignment psa : PermSetListToDelete){
                    if(mapPermSetNames.containsKey(psa.PermissionSet.Name)){
                        String permissionSetName = mapPermSetNames.get(psa.PermissionSet.Name).PermissionSetName__c;
                        if(psa.PermissionSet.Label == permissionSetName){
                            listToDeletePermSets.add(psa);
                        }
                    }
                }
            } 
            
            List<PermissionSetAssignment> PermSetIdsToInsert = new List<PermissionSetAssignment>();
            Set<Id> PermSetIds = new Set<Id>();
            Id defaultChannelPermSetId;
            Id defaultEmpTypePermSetId;
            Id defaultUserRolePermSetId;
            Id defaultUserMarketRoleId;
            
            // Perm Set Id for the KUP from master table
            if(kup.DefaultChannelId__c!=null){
                defaultChannelPermSetId = Id.valueOf(mapChannelPermSet.get(kup.DefaultChannelId__c));
            }
            if(kup.KSEmployeeTypeId__c!=null){
                defaultEmpTypePermSetId = Id.valueOf(mapChannelPermSet.get(kup.KSEmployeeTypeId__c));
            }
            if(kup.KSUserRole__c!=null){
                defaultUserRolePermSetId = Id.valueOf(mapChannelPermSet.get(kup.KSUserRole__c));
            }
            
            if(defaultChannelPermSetId != null){
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.AssigneeId = userId;
                psa.PermissionSetId=defaultChannelPermSetId;
                listPSAsToInsert.add(psa);
            }
            if(defaultEmpTypePermSetId != null){
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.AssigneeId = userId;
                psa.PermissionSetId=defaultEmpTypePermSetId;
                listPSAsToInsert.add(psa);
            }
            if(defaultUserRolePermSetId != null){
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.AssigneeId = userId;
                psa.PermissionSetId=defaultUserRolePermSetId;
                listPSAsToInsert.add(psa);
            }
            
            for(PermissionSetAssignment perSetID :listPSAsToInsert){
                PermSetIds.add(perSetID.PermissionSetId);
            }
            
            set<Id> setPermissionSet = new set<Id>();
            List<String> roleValuePermList = strRoleValues;
            for(String roleValueRec : roleValuePermList){
                String roleName = mapRoleMaster.get(roleValueRec);
                Set<Id> tempPermSet = mapRolePermission.get(roleName);
                if(tempPermSet != NULL && !tempPermSet.isEmpty() ){
                    for(Id tempPerm : tempPermSet){
                        try{
                            setPermissionSet.add(tempPerm);
                        }
                        catch(Exception e){
                            system.debug('Exception' + e.getMessage());
                        }
                    }
                    
                }                    
            }
            if(setPermissionSet != NULL && !setPermissionSet.isEmpty()){
                for(Id permSetId :setPermissionSet ) {
                    if(!PermSetIds.contains(permSetId)){
                        PermissionSetAssignment psa = new PermissionSetAssignment();
                        psa.PermissionSetId = permSetId;
                        psa.AssigneeId = userId;
                        listPSAsToInsert.add(psa);
                    }
                }
                
            }
            setKMUserProfiles.add(kup.Id);
        }
        
        if(listToDeletePermSets.size() > 0){
            // insert listToDeletePermSets;
            Database.DeleteResult[] srList = Database.delete(listToDeletePermSets, false);
            for (Database.DeleteResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully deleted Perm sets. Perm set assignment Role ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors 
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Perm set assignment fields that affected this error: ' + err.getFields());
                        UserProfileFailureLogs__c errorLog = new UserProfileFailureLogs__c();
                        errorLog.Error_Message__c  = 'The following error has occurred.' + err.getStatusCode() + ': ' + err.getMessage();
                        errorLog.Object_Name__c = 'PermissionSetAssignment';
                        errorLog.Operation__c ='Delete';
                        errorLogList.add(errorLog);
                    }
                }
                
            }
        }
        
        if(listPSAsToInsert.size() > 0){
            // insert listPSAsToInsert;
            Database.SaveResult[] srList = Database.insert(listPSAsToInsert, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully updated Permset assignment role. Perm set assignment ID: ' + sr.getId());
                }
                else {
                    
                    // Operation failed, so get all errors  
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Perm set assignment fields that affected this error: ' + err.getFields());
                        UserProfileFailureLogs__c errorLog = new UserProfileFailureLogs__c();
                        errorLog.Error_Message__c  = 'The following error has occurred.' + err.getStatusCode() + ': ' + err.getMessage();
                        errorLog.Object_Name__c = 'PermissionSetAssignment';
                        errorLog.Operation__c ='Insert';
                        errorLogList.add(errorLog);
                        
                    }
                    
                }
                
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        KMUserProfileERBatch kupmab = new KMUserProfileERBatch(setKMUserProfiles,errorLogList);
        Database.executeBatch(kupmab,1);
    }
    
}
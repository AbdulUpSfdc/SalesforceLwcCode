public with sharing class KMUserProfileERBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    set<Id> setIds = new set<Id>();
    List<UserProfileFailureLogs__c> logList = new List<UserProfileFailureLogs__c>();
    public KMUserProfileERBatch(set<Id> setKMUserProfiles,List<UserProfileFailureLogs__c> errorLogList){
        setIds=setKMUserProfiles;
        logList = errorLogList;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            'SELECT Id,Name,ATTUID__c,Sys_Role_ID__c,BusinessRole__c,DefaultChannelId__c,DefaultMarketId__c,EmployeeFlag__c,KSEmployeeTypeId__c,KSUserRole__c,Status__c FROM BWKMUserProfile__c WHERE ID IN:setIds'
        );
        
       
    }
    
    public void execute(Database.BatchableContext BC, List<BWKMUserProfile__c> listKMUsers) {
        set<Id> setEmpIds = new set<Id>();
        set<Id> setUserIDs = new set<Id>();
        set<String> setattUIDS = new set<String>();
        list<String> strRoleValues = new list<String>();
        
        map<String,Id> mapATTtoUserID = new map<String,Id>();
        map<String,String> mapEmpMaster = new map<String,String>();
        map<String,String> mapEmpChannel = new map<String,String>();
        map<String,Employee__c> mapEmployee = new map<String,Employee__c>();
        
        map<Id,list<BWEmployeeRole__c>>  mapEmployeeRoleValue = new map<Id,list<BWEmployeeRole__c>>();
        map<String,String> mapStrRoleValues = new map<String,String>();
        map<String,String> mapStrRoleNames = new map<String,String>();
        
        list<BWEmployeeRole__c> listEmployeeRolesToInsert = new list<BWEmployeeRole__c>();
        list<BWEmployeeRole__c> listToDeleteEmpRole = new list<BWEmployeeRole__c>();
        list<Employee__c> listEmployeesToUpdate = new list<Employee__c>();
        list<BWUserMarketAssociation__c> listUMAsToDelete = new list<BWUserMarketAssociation__c>();
        list<BWUserMarketAssociation__c> listUMAsToInsert = new list<BWUserMarketAssociation__c>();
        list<BWKMUserProfile__c> listKUPsToUpdate = new list<BWKMUserProfile__c>();
        
        for(BWKMUserProfile__c kup : listKMUsers){
            setattUIDS.add(kup.ATTUID__c);
            strRoleValues = kup.Sys_Role_ID__c.split(':');
        }
        
        for(Employee__c e : [Select Id,Name,BWDefault_KM_Master__c,BWDefaultKMChannel__c,Employee_Type_Id__c,User_Role__c,User__c,EmployeeId__c from Employee__c where EmployeeId__c IN:setattUIDS]){
            mapEmpMaster.put(e.EmployeeId__c,e.BWDefault_KM_Master__c);
            mapEmpChannel.put(e.EmployeeId__c,e.BWDefaultKMChannel__c);
            mapEmployee.put(e.EmployeeId__c,e);
            mapATTtoUserID.put(e.EmployeeId__c,e.User__c);
            setUserIDs.add(e.User__c);
            setEmpIds.add(e.Id);
        }
        for(BWEmployeeRole__c ber :[Select Id,Name,KMProcessingStatus__c,RoleName__c,RoleValue__c,UserId__c from BWEmployeeRole__c where UserId__c IN:setEmpIds]){
            if(mapEmployeeRoleValue.containsKey(ber.UserId__c)){
                mapEmployeeRoleValue.get(ber.UserId__c).add(ber);
            }
            else{
                mapEmployeeRoleValue.put(ber.UserId__c,new list<BWEmployeeRole__c>{ber});
            }
        }
        
        for(BWRoleMaster__c rm : [Select Id,Role_Name__c,Role_Value__c,Sys_Role_ID__c from BWRoleMaster__c where Sys_Role_ID__c IN:strRoleValues]){
            mapStrRoleValues.put(rm.Sys_Role_ID__c,rm.Role_Value__c);
            mapStrRoleNames.put(rm.Role_Value__c,rm.Role_Name__c);
        }  
        
        
        // Actual Logic
        for(BWKMUserProfile__c kup : listKMUsers){
            Id UserId = mapATTtoUserID.get(kup.ATTUID__c);
            Id empId  = mapEmployee.get(kup.ATTUID__c).Id;
            list<BWEmployeeRole__c> empRoleListToDelete = mapEmployeeRoleValue.get(empId);
            if(empRoleListToDelete != null && !empRoleListToDelete.isEmpty()){
                for(BWEmployeeRole__c empRole : empRoleListToDelete){
                    if(empRole.RoleName__c != null && empRole.RoleName__c.contains('KMRole')){
                        listToDeleteEmpRole.add(empRole);
                    }
                    
                }
                
            }
            
            set<String> setEmployeeRole = new set<String>();
            List<String> employeeRoleValue = strRoleValues;
            if(strRoleValues != null && !strRoleValues.isEmpty()){
                for(String roleValueRec : strRoleValues){
                    String roleName = mapStrRoleValues.get(roleValueRec);
                    BWEmployeeRole__c ber = new BWEmployeeRole__c();
                    ber.KMProcessingStatus__c = 'Completed Add';
                    ber.RoleName__c = mapStrRoleNames.get(roleName);
                    ber.RoleValue__c = mapStrRoleValues.get(roleValueRec);
                    ber.UserId__c = empId;
                    listEmployeeRolesToInsert.add(ber);
                }
            }
            if(kup.DefaultChannelId__c != mapEmpChannel.get(kup.ATTUID__c) || kup.DefaultMarketId__c != mapEmpMaster.get(kup.ATTUID__c) || kup.KSEmployeeTypeId__c != mapEmployee.get(kup.ATTUID__c).Employee_Type_Id__c || kup.KSUserRole__c != mapEmployee.get(kup.ATTUID__c).User_Role__c){
                Employee__c e = mapEmployee.get(kup.ATTUID__c);
                if(kup.DefaultChannelId__c != mapEmpChannel.get(kup.ATTUID__c)){
                    e.BWDefaultKMChannel__c = kup.DefaultChannelId__c;
                }
                if(kup.DefaultMarketId__c != mapEmpMaster.get(kup.ATTUID__c)){
                    e.BWDefault_KM_Master__c = kup.DefaultMarketId__c;
                }
                if(kup.KSEmployeeTypeId__c != mapEmployee.get(kup.ATTUID__c).Employee_Type_Id__c){
                    e.Employee_Type_Id__c = kup.KSEmployeeTypeId__c;
                }
                if(kup.KSUserRole__c != mapEmployee.get(kup.ATTUID__c).User_Role__c){
                    e.User_Role__c = kup.KSUserRole__c;
                }
                listEmployeesToUpdate.add(e);
            }            
            kup.Status__c ='Completed Add';
            listKUPsToUpdate.add(kup);
            
         
            
        }
        
        if(listToDeleteEmpRole.size() > 0){
            Database.DeleteResult[] srList = Database.delete(listToDeleteEmpRole, false);
            for (Database.DeleteResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully deleted Employee roles. Employee Role ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors 
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Employee Role fields that affected this error: ' + err.getFields());
                        UserProfileFailureLogs__c errorLog = new UserProfileFailureLogs__c();
                        errorLog.Error_Message__c  = 'The following error has occurred.' + err.getStatusCode() + ': ' + err.getMessage();
                        errorLog.Object_Name__c = 'Employee Role';
                        errorLog.Operation__c ='Delete';
                        logList.add(errorLog);
                       
                    }
                }
                
            }
        }
        
        
        if(listEmployeeRolesToInsert.size() > 0){
            Database.SaveResult[] srList = Database.insert(listEmployeeRolesToInsert, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully Inserted Employee Role. Employee Role ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors 
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Employee Role fields that affected this error: ' + err.getFields());
                        UserProfileFailureLogs__c errorLog = new UserProfileFailureLogs__c();
                        errorLog.Error_Message__c  = 'The following error has occurred.' + err.getStatusCode() + ': ' + err.getMessage();
                        errorLog.Object_Name__c = 'Employee Role';
                        errorLog.Operation__c ='Insert';
                       logList.add(errorLog);
                       
                    }
                }
                
            }
        }
        
        
        if(listEmployeesToUpdate.size() > 0){
            Database.SaveResult[] srList = Database.update(listEmployeesToUpdate, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully Updated Employee Table. Employee Table ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors 
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Perm set assignment fields that affected this error: ' + err.getFields());
                        UserProfileFailureLogs__c errorLog = new UserProfileFailureLogs__c();
                        errorLog.Error_Message__c  = 'The following error has occurred.' + err.getStatusCode() + ': ' + err.getMessage();
                        errorLog.Object_Name__c = 'Employee';
                        errorLog.Operation__c ='Update';
                        logList.add(errorLog);
                      
                    }
                }
                
            }
        }
        
        if(listKUPsToUpdate.size() > 0){
            Database.SaveResult[] srList = Database.update(listKUPsToUpdate, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully Knowledge User Profile Table. User Profile ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors 
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Knowledge User Profile fields that affected this error: ' + err.getFields());
                        UserProfileFailureLogs__c errorLog = new UserProfileFailureLogs__c();
                        errorLog.Error_Message__c  = 'The following error has occurred.' + err.getStatusCode() + ': ' + err.getMessage();
                        errorLog.Object_Name__c = 'Knowledge User Profile';
                        errorLog.Operation__c ='Update';
                        logList.add(errorLog);
                       
                    }
                }
                
            }
        }
        
        if(logList.size()>0){
            try{
                insert logList;
            }catch(Exception e){
                system.debug('Error Exception : ' + e.getMessage());
            }
        }
    }
    
    public void finish(Database.BatchableContext BC) {
         
    }
    
}
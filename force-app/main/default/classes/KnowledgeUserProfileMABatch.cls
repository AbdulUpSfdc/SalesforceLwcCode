public with sharing class KnowledgeUserProfileMABatch implements Database.Batchable<sObject>, Database.Stateful{

    set<Id> setIds = new set<Id>();
    public KnowledgeUserProfileMABatch(set<Id> setKMUserProfiles){
        setIds=setKMUserProfiles;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        //system.debug('KUPMABatch'+setIds);
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator(
            'SELECT Id,Name,ATTUID__c,Sys_Role_ID__c,BusinessRole__c,DefaultChannelId__c,DefaultMarketId__c,EmployeeFlag__c,KSEmployeeTypeId__c,KSUserRole__c,Status__c FROM BWKMUserProfile__c WHERE ID IN:setIds'
        );
    }

    public void execute(Database.BatchableContext BC, List<BWKMUserProfile__c> listKMUsers) {

        //system.debug('KUPMABatch:'+listKMUsers.size());

        set<Id> setEmpIds = new set<Id>();
        set<String> setMarketIds = new set<String>();
        set<Id> setUserIDs = new set<Id>();
        set<String> setattUIDS = new set<String>();
        list<String> strRoleValues = new list<String>();

        map<String,Id> mapATTtoUserID = new map<String,Id>();
        map<String,String> mapEmpMaster = new map<String,String>();
        map<String,String> mapEmpChannel = new map<String,String>();
        map<String,Employee__c> mapEmployee = new map<String,Employee__c>();
        map<Id,set<Id>> mapUMAs = new map<Id,set<Id>>();
        map<string,BWUserMarketAssociation__c> mapUMAId = new map<string,BWUserMarketAssociation__c>();
        map<String,Id> mapMarketMaster = new map<String,Id>();
        map<Id,list<BWEmployeeRole__c>>  mapEmployeeRoleValue = new map<Id,list<BWEmployeeRole__c>>();
        map<String,String> mapStrRoleValues = new map<String,String>();
        map<String,String> mapStrRoleNames = new map<String,String>();

        list<BWEmployeeRole__c> listEmployeeRolesToInsert = new list<BWEmployeeRole__c>();
        list<BWEmployeeRole__c> listEmployeeRolesToUpdate = new list<BWEmployeeRole__c>();
        list<Employee__c> listEmployeesToUpdate = new list<Employee__c>();
        list<BWUserMarketAssociation__c> listUMAsToDelete = new list<BWUserMarketAssociation__c>();
        list<BWUserMarketAssociation__c> listUMAsToInsert = new list<BWUserMarketAssociation__c>();
        list<BWKMUserProfile__c> listKUPsToUpdate = new list<BWKMUserProfile__c>();

        for(BWKMUserProfile__c kup : listKMUsers){
            setattUIDS.add(kup.ATTUID__c);
            setMarketIds.add(kup.DefaultMarketId__c);
            strRoleValues = kup.Sys_Role_ID__c.split(':');
        }

        //system.debug('KUPMABatch'+setattUIDS);
       // system.debug('KUPMABatch'+setMarketIds);

        for(Employee__c e : [Select Id,Name,BWDefault_KM_Master__c,BWDefaultKMChannel__c,Employee_Type_Id__c,User_Role__c,User__c,EmployeeId__c from Employee__c where EmployeeId__c IN:setattUIDS]){
            mapEmpMaster.put(e.EmployeeId__c,e.BWDefault_KM_Master__c);
            mapEmpChannel.put(e.EmployeeId__c,e.BWDefaultKMChannel__c);
            mapEmployee.put(e.EmployeeId__c,e);
            mapATTtoUserID.put(e.EmployeeId__c,e.User__c);
            setUserIDs.add(e.User__c);
            setEmpIds.add(e.Id);
        }

       // system.debug('KUPMABatch'+mapEmpMaster);
       // system.debug('KUPMABatch'+mapEmpChannel);

        for(BWUserMarketAssociation__c uma :[Select Id,BWMarketMaster__c,BWMarketMaster__r.MYCSPMarketId__c,Primary__c,UserId__c from BWUserMarketAssociation__c where UserId__c IN:setUserIDs AND Primary__c=true ]){
            mapUMAId.put(String.valueOf(uma.UserId__c)+String.valueOf(uma.BWMarketMaster__c),uma);
            if(mapUMAs.containsKey(uma.UserId__c)){
                mapUMAs.get(uma.UserId__c).add(uma.BWMarketMaster__c);
            }
            else{
                mapUMAs.put(uma.UserId__c,new set<Id>{uma.BWMarketMaster__c});
            }
        }

       // system.debug('KUPMABatch:'+mapUMAs);

        for(BWMarketMaster__c mm :[Select Id,Name,MarketPromotedSearchTerm__c,MYCSPMarketId__c from BWMarketMaster__c]){
            mapMarketMaster.put(mm.MYCSPMarketId__c,mm.Id);
        }

        //system.debug('KUPMABatch:'+mapMarketMaster);

        for(BWEmployeeRole__c ber :[Select Id,Name,KMProcessingStatus__c,RoleName__c,RoleValue__c,UserId__c from BWEmployeeRole__c where UserId__c IN:setEmpIds]){
            if(mapEmployeeRoleValue.containsKey(ber.UserId__c)){
                mapEmployeeRoleValue.get(ber.UserId__c).add(ber);
            }
            else{
                mapEmployeeRoleValue.put(ber.UserId__c,new list<BWEmployeeRole__c>{ber});
            }
        }

        //system.debug('KUPMABatch:'+mapEmployeeRoleValue);

        for(BWRoleMaster__c rm : [Select Id,Role_Name__c,Role_Value__c,Sys_Role_ID__c from BWRoleMaster__c]){
            mapStrRoleValues.put(rm.Sys_Role_ID__c,rm.Role_Value__c);
            mapStrRoleNames.put(rm.Role_Value__c,rm.Role_Name__c);
        }

        //system.debug('KUPMABatch:'+mapStrRoleValues);
        //system.debug('KUPMABatch:'+mapStrRoleNames);


        // Actual Logic
        for(BWKMUserProfile__c kup : listKMUsers){
            // logic for Market Associations to insert or delete - START
            string empMasterId = mapEmpMaster.get(kup.ATTUID__c);
            Id masterId = mapMarketMaster.get(empMasterId);
            Id defaultMarketMasterId = mapMarketMaster.get(kup.DefaultMarketId__c);
            set<Id> setMarkets = mapUMAs.get(mapATTtoUserID.get(kup.ATTUID__c));

            if(empMasterId!=null && (kup.DefaultMarketId__c !=empMasterId)){
                if(setMarkets !=null && setMarkets.contains(masterId)){
                    String assigneeMarketId = String.ValueOf(mapATTtoUserID.get(kup.ATTUID__c))+String.ValueOf(masterId);
                    //system.debug('KUPMABatch:'+assigneeMarketId);
                    listUMAsToDelete.add(mapUMAId.get(assigneeMarketId)); //Delete row related to primary market
                }
            }
            if(setMarkets==null || (setMarkets!=null && !setMarkets.contains(defaultMarketMasterId))){
                //Add row for new market in user market association and set primary flag as true only if it do not exist
                BWUserMarketAssociation__c uma = new BWUserMarketAssociation__c();
                uma.BWMarketMaster__c =mapMarketMaster.get(kup.DefaultMarketId__c);
                uma.Primary__c = true;
                uma.UserId__c = mapATTtoUserID.get(kup.ATTUID__c);
                listUMAsToInsert.add(uma);
            }
            //system.debug('KUPMABatch:'+listUMAsToInsert);
            //system.debug('KUPMABatch:'+listUMAsToDelete);
            // logic for Market Associations to insert or delete - END

            // logic for Employee Roles to insert or update - START
            //Parse the value of KB system role field to get list of all KB roles for user
            set<String> setRoleValues = new set<String>();
            list<String> listStrKUPRoles = new list<String>();  // list of role values on knowledge user profile
            list<String> listStrEmpRoles = new list<String>(); // list of role values on BW Employee Role

            // Parse role values on KUP
            for(String s : kup.Sys_Role_ID__c.split(':')){
                if(mapStrRoleValues.get(s)!=null){
                    listStrKUPRoles.add(mapStrRoleValues.get(s));
                    setRoleValues.add(mapStrRoleValues.get(s));
                }
            }
            //system.debug('KUPMABatch:'+listStrKUPRoles);
           // system.debug('KUPMABatch:'+setRoleValues);

            // Parse role values on BW Employee Role
            // Get the list Of Employee Role records for KUP
            list<BWEmployeeRole__c> listEmpRoles = mapEmployeeRoleValue.get(mapEmployee.get(kup.ATTUID__c).Id);
            if(listEmpRoles!=null){
                //system.debug('KUPMABatch:'+listEmpRoles);
                for(BWEmployeeRole__c ber : listEmpRoles){
                    listStrEmpRoles.add(ber.RoleValue__c);
                    setRoleValues.add(ber.RoleValue__c);
                }
            }
            //system.debug('KUPMABatch:'+listStrEmpRoles);
           // system.debug('KUPMABatch:'+setRoleValues);

            // Loop thru all Role Values
            for(String s : setRoleValues){
                //If KB role is present in BWEmployeeRole__c but not in new list
                if(listStrEmpRoles.contains(s) && !listStrKUPRoles.contains(s)){
                    //system.debug('KUPMABatch:'+s);
                    for(BWEmployeeRole__c ber :listEmpRoles){
                        if(ber.RoleValue__c == s){
                            ber.KMProcessingStatus__c ='Awaiting Delete Processing';
                            listEmployeeRolesToUpdate.add(ber);
                        }
                    }
                }
                //If KB role is not present in BWEmployeeRole__c but present in new list
                else if(!listStrEmpRoles.contains(s) && listStrKUPRoles.contains(s)){
                    //system.debug('KUPMABatch:'+s);
                    BWEmployeeRole__c ber = new BWEmployeeRole__c();
                    ber.KMProcessingStatus__c = 'Awaiting Add Processing';
                    ber.RoleName__c = mapStrRoleNames.get(s);
                    ber.RoleValue__c = s;
                    ber.UserId__c = mapEmployee.get(kup.ATTUID__c).Id;
                    listEmployeeRolesToInsert.add(ber);
                }
            }
            //system.debug('KUPMABatch:'+listEmployeeRolesToUpdate);
            //system.debug('KUPMABatch:'+listEmployeeRolesToInsert);
            // logic for Employee Roles to insert or update - END

            // logic for updating Employee with correct Default Channel & Default Market - START
            // Update Employee Default Channel & Default Market if different from KUP DefaultMarketId__c
            if(kup.DefaultChannelId__c != mapEmpChannel.get(kup.ATTUID__c) || kup.DefaultMarketId__c != mapEmpMaster.get(kup.ATTUID__c)){
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

            //system.debug('KUPMABatch:'+listEmployeesToUpdate);
            // logic for updating Employee with correct Default Channel & Default Market - END

            // logic for updating Knowledge User Profile Status - START
            kup.Status__c ='Completed Add';
            listKUPsToUpdate.add(kup);
            // logic for updating Knowledge User Profile Status - START
            //system.debug('KUPMABatch:'+listKUPsToUpdate);
        }

        // DMLs
        //system.debug('KUPMABatch:'+listUMAsToDelete.size());
        if(listUMAsToDelete.size() > 0){
            try{
                Database.delete(listUMAsToDelete,false);
            }
            catch(System.Exception e){
                system.debug('KUPMABatch:'+e);
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }

        //system.debug('KUPMABatch:'+listUMAsToInsert.size());
        if(listUMAsToInsert.size() > 0){
            try{
                Database.insert(listUMAsToInsert,false);
            }
            catch(System.Exception e){
                system.debug('KUPMABatch:'+e);
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }

        //system.debug('KUPMABatch:'+listEmployeeRolesToUpdate.size());
        if(listEmployeeRolesToUpdate.size() > 0){
            try{
                Database.update(listEmployeeRolesToUpdate,false);
            }
            catch(System.Exception e){
                system.debug('KUPMABatch:'+e);
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }

        //system.debug('KUPMABatch:'+listEmployeeRolesToInsert.size());
        if(listEmployeeRolesToInsert.size() > 0){
            try{
                Database.insert(listEmployeeRolesToInsert,false);
            }
            catch(System.Exception e){
                system.debug('KUPMABatch:'+e);
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }

        // system.debug('KUPMABatch:'+listEmployeesToUpdate.size());
        if(listEmployeesToUpdate.size() > 0){
            try{
                Database.update(listEmployeesToUpdate,false);
            }
            catch(System.Exception e){
                system.debug('KUPMABatch:'+e);
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }

        //system.debug('KUPMABatch:'+listKUPsToUpdate.size());
        if(listKUPsToUpdate.size() > 0){
            try{
                Database.update(listKUPsToUpdate,false);
            }
            catch(System.Exception e){
                system.debug('KUPMABatch:'+e);
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
    }

}
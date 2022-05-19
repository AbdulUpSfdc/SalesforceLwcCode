global class KnowledgeUserProfileBatch implements Schedulable,Database.Batchable<sObject>, Database.Stateful {
     /*
        Schedulable execute.
    */
    public void execute(SchedulableContext SC) {
        if(!Test.isRunningTest()){
            Database.executeBatch(new KnowledgeUserProfileBatch(),1);
        }
    }

    // set of KMUserProfile records to pass to next batch for processing Market Assocaitions,Creating BW Employee Roles & update status on Knowledge User Profile
    set<Id> setKMUserProfiles = new set<Id>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator(
            'SELECT Id,Name,ATTUID__c,Sys_Role_ID__c,BusinessRole__c,DefaultChannelId__c,DefaultMarketId__c,EmployeeFlag__c,KSEmployeeTypeId__c,KSUserRole__c,Status__c FROM BWKMUserProfile__c WHERE Status__c =\'Awaiting Add Processing\' limit 2000'
        );
    }

    global void execute(Database.BatchableContext BC, List<BWKMUserProfile__c> listKMUsers) {
        //system.debug('KUPBatch:'+listKMUsers.size());

        set<Id> setUserIDs = new set<Id>();
        set<String> setattUIDS = new set<String>();
        set<String> setChannelIds = new set<String>();

        map<String,Id> mapATTtoUserID = new map<String,Id>();
        map<String,Employee__c> mapATTtoEmployee = new map<String,Employee__c>();
        map<string,PermissionSetAssignment> mapPSAId = new map<string,PermissionSetAssignment>();
        map<String,String> mapChannelPermSet = new map<String,String>();
        map<Id,set<Id>> mapAssigneePermSets = new map<Id,set<Id>>();

        list<PermissionSetAssignment> listDeletePSAs = new list<PermissionSetAssignment>();
        list<PermissionSetAssignment> listPSAsToInsert = new list<PermissionSetAssignment>();

        // prepare collections from Knowledge User Profile
        for(BWKMUserProfile__c kup : listKMUsers){
            setattUIDS.add(kup.ATTUID__c);
            setChannelIds.add(kup.DefaultChannelId__c);
        }

        //system.debug('KUPBatch:'+setattUIDS);
        //system.debug('KUPBatch:'+setChannelIds);

        for(Employee__c e : [Select Id,Name,BWDefaultKMChannel__c,User__c,Employee_Type_Id__c,User_Role__c,EmployeeId__c from Employee__c where EmployeeId__c IN:setattUIDS]){
            mapATTtoEmployee.put(e.EmployeeId__c,e);
            mapATTtoUserID.put(e.EmployeeId__c,e.User__c);
            setUserIDs.add(e.User__c);
        }

        //system.debug('KUPBatch:'+mapATTtoEmployee);
        //system.debug('KUPBatch:'+mapATTtoUserID);
       // system.debug('KUPBatch:'+setUserIDs);

        for(BW_Channel_Mapping__c bcm : [Select Id,KM_Channel_ID__c,Permission_Set_Id__c from BW_Channel_Mapping__c]){
            mapChannelPermSet.put(bcm.KM_Channel_ID__c,bcm.Permission_Set_Id__c);
        }

        system.debug('KUPBatch:'+mapChannelPermSet);

        for(PermissionSetAssignment psa : [Select Id,PermissionSetId,AssigneeId from PermissionSetAssignment where AssigneeId IN:setUserIDs]){
            mapPSAId.put(String.valueOf(psa.AssigneeId)+String.valueOf(psa.PermissionSetId),psa);
            if(mapAssigneePermSets.containsKey(psa.AssigneeId)){
                mapAssigneePermSets.get(psa.AssigneeId).add(psa.PermissionSetId);
            }
            else{
                mapAssigneePermSets.put(psa.AssigneeId,new set<Id>{psa.PermissionSetId});
            }
        }

        //system.debug('KUPBatch:'+mapAssigneePermSets);

        // Actual Logic
        for(BWKMUserProfile__c kup : listKMUsers){

            Employee__c e = mapATTtoEmployee.get(kup.ATTUID__c);
            if(e==null){
                return;
            }
            Id userId = mapATTtoUserID.get(kup.ATTUID__c);
            Id empChannnelPermSetId ;
            Id empTypePermSetId;
            Id empUserRolePermSetId;
            Id defaultChannelPermSetId;
            Id defaultEmpTypePermSetId;
            Id defaultUserRolePermSetId;

            if(e.BWDefaultKMChannel__c !=null){
                empChannnelPermSetId = Id.valueOf(mapChannelPermSet.get(e.BWDefaultKMChannel__c)); // Perm set Id for the employee Channel from master table
            }
            if(e.Employee_Type_Id__c !=null){
                empTypePermSetId = Id.valueOf(mapChannelPermSet.get(e.Employee_Type_Id__c)); // Perm set Id for the employee type from master table
            }
            if(e.User_Role__c !=null){
                empUserRolePermSetId = Id.valueOf(mapChannelPermSet.get(e.User_Role__c)); // Perm set Id for the employee user role from master table
            }
            //system.debug('KUPBatch:'+empChannnelPermSetId);
            //system.debug('KUPBatch:'+empTypePermSetId);
            //system.debug('KUPBatch:'+empUserRolePermSetId);


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
            //system.debug('KUPBatch:'+defaultChannelPermSetId);
            //system.debug('KUPBatch:'+defaultEmpTypePermSetId);
            //system.debug('KUPBatch:'+defaultUserRolePermSetId);

            set<Id> PermSetIds = mapAssigneePermSets.get(userId); // Set of Perm Sets for the KUP user
            //system.debug('KUPBatch:'+PermSetIds);

            // Check if the Employee record has different channel when compared to Knowledge User Profile channel
            if(/*e.BWDefaultKMChannel__c!=null &&*/ (kup.DefaultChannelId__c != e.BWDefaultKMChannel__c)){
                system.debug('KUPBatch:'+empChannnelPermSetId);
                //  delete the perm set related to old channel on employee record
                if(PermSetIds !=null && PermSetIds.contains(empChannnelPermSetId)){
                    String assigneePermSetId = String.ValueOf(userId)+String.ValueOf(empChannnelPermSetId);
                    system.debug('KUPBatch:'+assigneePermSetId);
                    // Add the PSA to delete list to delete the assignment of old channel
                    listDeletePSAs.add(mapPSAId.get(assigneePermSetId));
                }
            }
             // Check if the Employee record has different Employee type when compared to Knowledge User Profile channel
             if(/*e.Employee_Type_Id__c!=null && */(kup.KSEmployeeTypeId__c != e.Employee_Type_Id__c)){
                //system.debug('KUPBatch:'+empTypePermSetId);
                //  delete the perm set related to old channel on employee record
                if(PermSetIds !=null && PermSetIds.contains(empTypePermSetId)){
                    String assigneePermSetId = String.ValueOf(userId)+String.ValueOf(empTypePermSetId);
                    //system.debug('KUPBatch:'+assigneePermSetId);
                    // Add the PSA to delete list to delete the assignment of old channel
                    listDeletePSAs.add(mapPSAId.get(assigneePermSetId));
                }
            }
             // Check if the Employee record has different User Role when compared to Knowledge User Profile channel
             if(/*e.User_Role__c!=null && */(kup.KSUserRole__c != e.User_Role__c)){
                //system.debug('KUPBatch:'+empUserRolePermSetId);
                //  delete the perm set related to old channel on employee record
                if(PermSetIds !=null && PermSetIds.contains(empUserRolePermSetId)){
                    String assigneePermSetId = String.ValueOf(userId)+String.ValueOf(empUserRolePermSetId);
                    //system.debug('KUPBatch:'+assigneePermSetId);
                    // Add the PSA to delete list to delete the assignment of old channel
                    listDeletePSAs.add(mapPSAId.get(assigneePermSetId));
                }
            }


            if(PermSetIds == null || (PermSetIds !=null && !PermSetIds.contains(defaultChannelPermSetId))){
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.AssigneeId = userId;
                psa.PermissionSetId=defaultChannelPermSetId;
                listPSAsToInsert.add(psa);
            }
            if(PermSetIds == null || (PermSetIds !=null && !PermSetIds.contains(defaultEmpTypePermSetId))){
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.AssigneeId = userId;
                psa.PermissionSetId=defaultEmpTypePermSetId;
                listPSAsToInsert.add(psa);
            }
            if(PermSetIds == null || (PermSetIds !=null && !PermSetIds.contains(defaultUserRolePermSetId))){
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.AssigneeId = userId;
                psa.PermissionSetId=defaultUserRolePermSetId;
                listPSAsToInsert.add(psa);
            }

            //system.debug('KUPBatch:'+listPSAsToInsert);
            //system.debug('KUPBatch:'+listDeletePSAs);

            setKMUserProfiles.add(kup.Id);
        }

        //system.debug('KUPBatch:'+listDeletePSAs.size());
        if(listDeletePSAs.size() > 0){
            try{
                Database.delete(listDeletePSAs,false);
            }
            catch(System.Exception e){
                system.debug('KUPBatch:'+e);
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }

        //system.debug('KUPBatch:'+listPSAsToInsert.size());
        //system.debug('KUPBatch:'+listPSAsToInsert);
        if(listPSAsToInsert.size() > 0){
            try{
                Database.insert(listPSAsToInsert,false);
            }
            catch(System.Exception e){
                system.debug('KUPBatch:'+e);
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        //system.debug('KUPBatch'+setKMUserProfiles);
        KnowledgeUserProfileMABatch kupmab = new KnowledgeUserProfileMABatch(setKMUserProfiles);
        Database.executeBatch(kupmab,1);
    }
}
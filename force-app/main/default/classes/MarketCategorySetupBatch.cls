global with sharing class MarketCategorySetupBatch implements Schedulable,Database.Batchable<sObject>,Database.Stateful{

     /*
        Schedulable execute.
    */
    public void execute(SchedulableContext SC) {
        if(!Test.isRunningTest()){
            Database.executeBatch(new MarketCategorySetupBatch(),1);
        }
    }

    // set of BWEmployeeRole records to pass to next batch for processing Market Assocaitions and Update Status on BWWmployeeRoles
    set<Id> setBWEmployeeRoles = new set<Id>();
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator(
            'SELECT Id,RoleName__c,RoleValue__c,UserId__c,KMProcessingStatus__c,UserId__r.User__c FROM BWEmployeeRole__c WHERE KMProcessingStatus__c =\'Awaiting Add Processing\' OR KMProcessingStatus__c = \'Awaiting Delete Processing\''
        );
    }

    global void execute(Database.BatchableContext BC, List<BWEmployeeRole__c> listEmployeeRole) {
        system.debug('--MCBatch.EmployeeRoles'+listEmployeeRole.size());
        map<String,set<Id>> mapRoleValuePermSets = new map<String,set<Id>> ();
        list<PermissionSetAssignment> listInsertPSAs = new list<PermissionSetAssignment>();
        list<PermissionSetAssignment> listDeletePSAs = new list<PermissionSetAssignment>();
        set<String> strRoleValues = new set<String>();
        set<Id> setUserIds = new set<Id>();
        map<Id,set<Id>> mapUserPerms = new map<Id,set<Id>>();

        for(BWEmployeeRole__c ber:listEmployeeRole ){
            strRoleValues.add(ber.RoleValue__c);
            setUserIds.add(ber.UserId__r.User__c);
        }
        system.debug('--MCBatch.RoleValues'+strRoleValues);
        system.debug('--MCBatch.UserIDs'+setUserIds);
        // Prepare map to have perm set Ids for each Role Value
        for(BWRolePermissions__c brp : [SELECT  Id,PermissionSetId__c,PermissionSetName__c,RoleName__c,RoleValue__c FROM BWRolePermissions__c where RoleValue__c IN:strRoleValues AND PermissionSetId__c!='']){
            system.debug('--MCBatch.BWRolePerm'+brp);
            if(mapRoleValuePermSets.containsKey(brp.RoleValue__c)){
                mapRoleValuePermSets.get(brp.RoleValue__c).add(Id.valueOf(brp.PermissionSetId__c));
            }
            else{
                mapRoleValuePermSets.put(brp.RoleValue__c,new set<Id>{Id.valueOf(brp.PermissionSetId__c)});
            }
        }
        system.debug('--MCBatch.RoleValuePermSets'+mapRoleValuePermSets);

        // Prepare a map of user with existing perm sets
        for(PermissionSetAssignment psa :[Select Id,AssigneeId,PermissionSetId from PermissionSetAssignment where AssigneeId IN:setUserIds]){
            if(mapUserPerms.containsKey(psa.AssigneeId)){
                mapUserPerms.get(psa.AssigneeId).add(psa.PermissionSetId);
            }
            else{
                mapUserPerms.put(psa.AssigneeId,new set<Id>{psa.PermissionSetId});
            }
        }
        system.debug('--MCBatch.UserPermSets'+mapUserPerms);

        for(BWEmployeeRole__c ber:listEmployeeRole ){
            if(ber.KMProcessingStatus__c =='Awaiting Add Processing'){
                //get the list of perm set Ids from BWRolePermissions__c
                set<Id> setPermSetIds = mapRoleValuePermSets.get(ber.RoleValue__c);
                system.debug('--MCBatch.RoleValuePermSets'+setPermSetIds);
                set<Id> userPermIds = mapUserPerms.get(ber.UserId__r.User__c);
                system.debug('--MCBatch.UserPermSets'+userPermIds);
                if(setPermSetIds!=null){
                    for(Id id : setPermSetIds){
                        if(id!=null && !userPermIds.contains(id)){
                            PermissionSetAssignment psa = new PermissionSetAssignment();
                            psa.PermissionSetId = id;
                            psa.AssigneeId = ber.UserId__r.User__c;
                            listInsertPSAs.add(psa);
                        }
                    }
                }
                setBWEmployeeRoles.add(ber.Id);
                system.debug('--MCBatch.BWEmployeeRole'+setBWEmployeeRoles);
            }
            else if(ber.KMProcessingStatus__c =='Awaiting Delete Processing'){
                set<Id> setDeletePermIds = new set<Id>();
                //get the list of perm set Ids from BWRolePermissions__c
                set<Id> setPermSetIds = mapRoleValuePermSets.get(ber.RoleValue__c);
                if(setPermSetIds!=null){
                    for(Id id : setPermSetIds){
                        if(id!=null){
                            setDeletePermIds.add(id);
                        }
                    }
                }
                for(PermissionSetAssignment psa : [Select Id,PermissionSetId,AssigneeId from PermissionSetAssignment where PermissionSetId IN:setDeletePermIds]){
                    if(ber.UserId__r.User__c == psa.AssigneeId){
                        listDeletePSAs.add(psa);
                    }
                }
                setBWEmployeeRoles.add(ber.Id);
                system.debug('--MCBatch.BWEmployeeRole'+setBWEmployeeRoles);
            }
        }
        system.debug('--MCBatch.InsertPSA'+listInsertPSAs);
        if(listInsertPSAs.size() >0){
            try{
                insert listInsertPSAs;
            }
            catch(System.Exception e){
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }
        system.debug('--MCBatch.DeletePSA'+listDeletePSAs);
        if(listDeletePSAs.size() >0){
            try{
                delete listDeletePSAs;
            }
            catch(System.Exception e){
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        system.debug('--MCBatch.BWEmployeeRoles'+setBWEmployeeRoles);
        MarketAssociationBatch mab = new MarketAssociationBatch(setBWEmployeeRoles);
        Database.executeBatch(mab,1);
    }
}
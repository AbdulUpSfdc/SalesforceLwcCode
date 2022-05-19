/***
 * Class: MarketAssociationBatchv2
 * Description: This class is the first class to be run as part of 2nd second step of user provisioning process. It processes the rows in the 
 * BWEmployeeRole table which have 'Awaiting Add Processing' and 'Awaiting Delete Processing', to add/remove permission sets annd/or markets associated to the user.
 * Version: 2
 * Version Difference:The class calls the new MarketAssociationBatchv2 class in the finish method and the limit is reduce to 1000 for the initial query
 * 
***/

global with sharing class MarketCategorySetupBatchv2 implements Schedulable,Database.Batchable<sObject>,Database.Stateful{

     /*
        Schedulable execute.
    */
    public void execute(SchedulableContext SC) {
        if(!Test.isRunningTest()){
            Database.executeBatch(new MarketCategorySetupBatchv2(),1);
        }
    }

    // set of BWEmployeeRole records to pass to next batch for processing Market Assocaitions and Update Status on BWWmployeeRoles
    set<Id> setBWEmployeeRoles = new set<Id>();
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator(
            'SELECT Id,RoleName__c,RoleValue__c,UserId__c,KMProcessingStatus__c,UserId__r.User__c FROM BWEmployeeRole__c WHERE KMProcessingStatus__c =\'Awaiting Add Processing\' OR KMProcessingStatus__c = \'Awaiting Delete Processing\' limit 1000'
        );
    }

    global void execute(Database.BatchableContext BC, List<BWEmployeeRole__c> listEmployeeRole) {
        //system.debug('--MCBatch.EmployeeRoles'+listEmployeeRole.size());
        map<String,set<Id>> mapRoleValuePermSets = new map<String,set<Id>> ();
        list<PermissionSetAssignment> listInsertPSAs = new list<PermissionSetAssignment>();
        list<PermissionSetAssignment> listDeletePSAs = new list<PermissionSetAssignment>();
        set<String> strRoleValues = new set<String>();
        set<Id> setUserIds = new set<Id>();
        map<Id,set<Id>> mapUserPerms = new map<Id,set<Id>>();
        map<string,PermissionSetAssignment> mapPSAId = new map<string,PermissionSetAssignment>();

        for(BWEmployeeRole__c ber:listEmployeeRole ){
            strRoleValues.add(ber.RoleValue__c);
            setUserIds.add(ber.UserId__r.User__c);
        }
        //system.debug('--MCBatch.RoleValues'+strRoleValues);
        //system.debug('--MCBatch.UserIDs'+setUserIds);
        // Prepare map to have perm set Ids for each Role Value
        for(BWRolePermissions__c brp : [SELECT  Id,PermissionSetId__c,PermissionSetName__c,RoleName__c,RoleValue__c FROM BWRolePermissions__c where RoleValue__c IN:strRoleValues AND PermissionSetId__c!='' AND SystemPermissionSet__c = True]){
            system.debug('--MCBatch.BWRolePerm'+brp);
            if(mapRoleValuePermSets.containsKey(brp.RoleValue__c)){
                mapRoleValuePermSets.get(brp.RoleValue__c).add(Id.valueOf(brp.PermissionSetId__c));
            }
            else{
                mapRoleValuePermSets.put(brp.RoleValue__c,new set<Id>{Id.valueOf(brp.PermissionSetId__c)});
            }
        }
        //system.debug('--MCBatch.RoleValuePermSets'+mapRoleValuePermSets);

        // Prepare a map of user with existing perm sets
        for(PermissionSetAssignment psa :[Select Id,AssigneeId,PermissionSetId from PermissionSetAssignment where AssigneeId IN:setUserIds]){
            mapPSAId.put(String.valueOf(psa.AssigneeId)+String.valueOf(psa.PermissionSetId),psa);
            if(mapUserPerms.containsKey(psa.AssigneeId)){
                mapUserPerms.get(psa.AssigneeId).add(psa.PermissionSetId);
            }
            else{
                mapUserPerms.put(psa.AssigneeId,new set<Id>{psa.PermissionSetId});
            }
        }
        //system.debug('--MCBatch.UserPermSets'+mapUserPerms);

        for(BWEmployeeRole__c ber:listEmployeeRole ){
            if(ber.KMProcessingStatus__c =='Awaiting Add Processing'){
                //get the list of perm set Ids from BWRolePermissions__c
                set<Id> setPermSetIds = mapRoleValuePermSets.get(ber.RoleValue__c);
                //system.debug('--MCBatch.RoleValuePermSets'+setPermSetIds);
                set<Id> userPermIds = mapUserPerms.get(ber.UserId__r.User__c);
                //system.debug('--MCBatch.UserPermSets'+userPermIds);
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
                //system.debug('--MCBatch.BWEmployeeRole'+setBWEmployeeRoles);
            }
            else if(ber.KMProcessingStatus__c =='Awaiting Delete Processing'){
                set<Id> setDeletePermIds = new set<Id>();
                //get the list of perm set Ids from BWRolePermissions__c
                set<Id> setPermSetIds = mapRoleValuePermSets.get(ber.RoleValue__c);
                if(setPermSetIds!=null){
                    for(Id id : setPermSetIds){
                        if(id!=null){
                            setDeletePermIds.add(id);
                            system.debug('setDeletePermIds'+setDeletePermIds.add(id));
                        }
                    }
                }
                for(Id deletePerm :setDeletePermIds){
                    String assigneePermSetId = String.ValueOf(ber.UserId__r.User__c)+String.ValueOf(deletePerm);
                    // Add the PSA to delete list
                    PermissionSetAssignment newPSA = mapPSAId.get(assigneePermSetId);
                    if(newPSA != null){
                    	listDeletePSAs.add(mapPSAId.get(assigneePermSetId));
                    }
                    else{
                        System.debug('PSA for PermissionSetAssignment newPSA:'+assigneePermSetId);
                    }
                }
                /*
                for(PermissionSetAssignment psa : [Select Id,PermissionSetId,AssigneeId from PermissionSetAssignment where PermissionSetId IN:setDeletePermIds]){
                    if(ber.UserId__r.User__c == psa.AssigneeId){
                        listDeletePSAs.add(psa);
                    }
                }*/

                setBWEmployeeRoles.add(ber.Id);
                //system.debug('--MCBatch.BWEmployeeRole'+setBWEmployeeRoles);
            }
        }
        //system.debug('--MCBatch.InsertPSA'+listInsertPSAs);
        if(listInsertPSAs.size() >0){
            try{
                //Database.insert(listInsertPSAs,false);
                insert listInsertPSAs;
            }
            catch(System.Exception e){
                system.debug('MCBatch:'+e);
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }
        //system.debug('--MCBatch.DeletePSA'+listDeletePSAs);
        if(listDeletePSAs.size() >0){
            try{
                //Database.delete(listDeletePSAs,false);
                delete listDeletePSAs;
            }
            catch(System.Exception e){
                system.debug('MCBatch:'+e);
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        //system.debug('--MCBatch.BWEmployeeRoles'+setBWEmployeeRoles);
        MarketAssociationBatchv2 mab = new MarketAssociationBatchv2(setBWEmployeeRoles);
        Database.executeBatch(mab,1);
    }
}
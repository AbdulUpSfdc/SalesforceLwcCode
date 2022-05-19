/***
 * Class: MarketAssociationBatchv1
 * Description: This class is run after the MarketCategorySetupBatch has completed. It is part of the User Provisioning Batch processing Step2.
 *              The class performs the activity of allocating the markets to the user.
 * Version: 1
 * Version Difference: This version corrects the Awaiting Delete Processing Logic which is querying more than 50K rows in UserMarketAssociation table.
 * 
 * 
***/
global with sharing class MarketAssociationBatchv1 implements Database.Batchable<sObject>, Database.Stateful {
    set<Id> setIds = new set<Id>();
    public MarketAssociationBatchv1(set<Id> setBWEmployeeRoles){
        setIds=setBWEmployeeRoles;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        //system.debug('--MABatch.BWEmployeeRoles'+setIds);
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator(
            'SELECT Id,RoleName__c,RoleValue__c,UserId__c,KMProcessingStatus__c,UserId__r.User__c FROM BWEmployeeRole__c WHERE ID IN:setIds'
        );
    }

    global void execute(Database.BatchableContext BC, List<BWEmployeeRole__c> listEmployeeRole) {
        //system.debug('--MABatch.EmployeeRoles'+listEmployeeRole.size());
        map<String,set<Id>> mapRoleMarketMasters = new map<String,set<Id>> ();
        list<BWUserMarketAssociation__c> listInsertUMAs = new list<BWUserMarketAssociation__c>();
        list<BWUserMarketAssociation__c> listDeleteUMAs = new list<BWUserMarketAssociation__c>();
        list<BWEmployeeRole__c> listUpdateEmployeeRoles = new list<BWEmployeeRole__c>();
        set<String> strRoleValues = new set<String>();
        set<Id> setUserIds = new set<Id>();
        map<Id,set<Id>> mapUserMarkets = new map<Id,set<Id>>();
        map<string,BWUserMarketAssociation__c> mapUMAId = new map<string,BWUserMarketAssociation__c>();

        for(BWEmployeeRole__c ber:listEmployeeRole ){
            strRoleValues.add(ber.RoleValue__c);
            setUserIds.add(ber.UserId__r.User__c);
        }
        //system.debug('--MABatch.RoleValues'+strRoleValues);
        //system.debug('--MABatch.UserIDs'+setUserIds);

        for(BWRoleMarketMaster__c brmm : [SELECT  Id,MarketId__c,RoleName__c,RoleValue__c FROM BWRoleMarketMaster__c where RoleValue__c IN:strRoleValues]){
            //system.debug('--MABatch.BWMarketMaster'+brmm);
            if(mapRoleMarketMasters.containsKey(brmm.RoleValue__c)){
                mapRoleMarketMasters.get(brmm.RoleValue__c).add(brmm.MarketId__c);
            }
            else{
                mapRoleMarketMasters.put(brmm.RoleValue__c,new set<Id>{brmm.MarketId__c});
            }
        }
        //system.debug('--MABatch.RoleValueMarketMaster'+mapRoleMarketMasters);

        // Prepare a map of user with existing perm sets
        for(BWUserMarketAssociation__c uma :[Select Id,BWMarketMaster__c,Primary__c,UserId__c from BWUserMarketAssociation__c where UserId__c IN:setUserIds]){
            mapUMAId.put(String.valueOf(uma.UserId__c)+String.valueOf(uma.BWMarketMaster__c),uma);
            if(mapUserMarkets.containsKey(uma.UserId__c)){
                mapUserMarkets.get(uma.UserId__c).add(uma.BWMarketMaster__c);
            }
            else{
                mapUserMarkets.put(uma.UserId__c,new set<Id>{uma.BWMarketMaster__c});
            }
        }
        //system.debug('--MABatch.UserMarkets'+mapUserMarkets);
        for(BWEmployeeRole__c ber:listEmployeeRole ){
            if(ber.KMProcessingStatus__c =='Awaiting Add Processing'){
                set<Id> setMarketMasters = mapRoleMarketMasters.get(ber.RoleValue__c);
                //system.debug('--MABatch.RoleValueMarketMasters'+setMarketMasters);
                set<Id> userMarekts = mapUserMarkets.get(ber.UserId__r.User__c);
                //system.debug('--MABatch.UserMarkets'+userMarekts);
                if(setMarketMasters!=null){
                    for(Id marketMasterId:setMarketMasters){
                        if(marketMasterId!=null && (userMarekts==null || (userMarekts!=null &&!userMarekts.contains(marketMasterId)))){
                            BWUserMarketAssociation__c uma = new BWUserMarketAssociation__c();
                            uma.BWMarketMaster__c = marketMasterId;
                            uma.Primary__c = false;
                            uma.UserId__c = ber.UserId__r.User__c;
                            listInsertUMAs.add(uma);
                        }
                    }
                }
                ber.KMProcessingStatus__c='Completed Add';
                listUpdateEmployeeRoles.add(ber);
                //system.debug('--MABatch.BWEmployeeRole'+listUpdateEmployeeRoles);
            }
            else if(ber.KMProcessingStatus__c =='Awaiting Delete Processing'){
                set<Id> setMarketMasters = mapRoleMarketMasters.get(ber.RoleValue__c);
                if(setMarketMasters!=null){
                    for(Id deleteMarket :setMarketMasters){
                        String assigneeMarketId = String.ValueOf(ber.UserId__r.User__c)+String.ValueOf(deleteMarket);
                        //system.debug('KUPMABatch:'+assigneeMarketId);
                        if(mapUMAId.get(assigneeMarketId) != null){
                        	listDeleteUMAs.add(mapUMAId.get(assigneeMarketId));
                        }
                        else{
                        	System.debug('PSA for mapUMAId is: '+mapUMAId.get(assigneeMarketId)+' Value:'+assigneeMarketId);
                    	}
                    /*
                    for(BWUserMarketAssociation__c uma : [Select Id,BWMarketMaster__c,Primary__c,UserId__c from BWUserMarketAssociation__c where BWMarketMaster__c IN: setMarketMasters]){
                        if(ber.UserId__r.User__c == uma.UserId__c){
                            listDeleteUMAs.add(uma);
                        }
                    }*/
                    }
                }
                ber.KMProcessingStatus__c='Completed Delete';
                listUpdateEmployeeRoles.add(ber);
                //system.debug('--MABatch.BWEmployeeRole'+listUpdateEmployeeRoles);
            }
        }

        //system.debug('--MABatch.InsertUMA'+listInsertUMAs);
        if(listInsertUMAs.size() >0){
            try{
                Database.insert(listInsertUMAs,false);
            }
            catch(System.Exception e){
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }
        //system.debug('--MABatch.DeleteUMA'+listDeleteUMAs);
        if(listDeleteUMAs.size() >0){
            try{
                Database.delete(listDeleteUMAs,false);
            }
            catch(System.Exception e){
                system.debug('MABatch:'+e);
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }
        //system.debug('--MABatch.BWEmployeeRole'+listUpdateEmployeeRoles);
        if(listUpdateEmployeeRoles.size() >0){
            try{
                Database.update(listUpdateEmployeeRoles,false);
            }
            catch(System.Exception e){
                system.debug('MABatch:'+e);
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }

    }
    global void finish(Database.BatchableContext BC) {
    }
}
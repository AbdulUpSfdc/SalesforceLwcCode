global with sharing class MarketAssociationBatch implements Database.Batchable<sObject>, Database.Stateful {
    set<Id> setIds = new set<Id>();
    public MarketAssociationBatch(set<Id> setBWEmployeeRoles){
        setIds=setBWEmployeeRoles;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('--MABatch.BWEmployeeRoles'+setIds);
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator(
            'SELECT Id,RoleName__c,RoleValue__c,UserId__c,KMProcessingStatus__c,UserId__r.User__c FROM BWEmployeeRole__c WHERE ID IN:setIds'
        );
    }

    global void execute(Database.BatchableContext BC, List<BWEmployeeRole__c> listEmployeeRole) {
        system.debug('--MABatch.EmployeeRoles'+listEmployeeRole.size());
        map<String,set<Id>> mapRoleMarketMasters = new map<String,set<Id>> ();
        list<BWUserMarketAssociation__c> listInsertUMAs = new list<BWUserMarketAssociation__c>();
        list<BWUserMarketAssociation__c> listDeleteUMAs = new list<BWUserMarketAssociation__c>();
        list<BWEmployeeRole__c> listUpdateEmployeeRoles = new list<BWEmployeeRole__c>();
        set<String> strRoleValues = new set<String>();
        set<Id> setUserIds = new set<Id>();
        map<Id,set<Id>> mapUserMarkets = new map<Id,set<Id>>();

        for(BWEmployeeRole__c ber:listEmployeeRole ){
            strRoleValues.add(ber.RoleValue__c);
            setUserIds.add(ber.UserId__r.User__c);
        }
        system.debug('--MABatch.RoleValues'+strRoleValues);
        system.debug('--MABatch.UserIDs'+setUserIds);

        for(BWRoleMarketMaster__c brmm : [SELECT  Id,MarketId__c,RoleName__c,RoleValue__c FROM BWRoleMarketMaster__c where RoleValue__c IN:strRoleValues]){
            system.debug('--MABatch.BWMarketMaster'+brmm);
            if(mapRoleMarketMasters.containsKey(brmm.RoleValue__c)){
                mapRoleMarketMasters.get(brmm.RoleValue__c).add(brmm.MarketId__c);
            }
            else{
                mapRoleMarketMasters.put(brmm.RoleValue__c,new set<Id>{brmm.MarketId__c});
            }
        }
        system.debug('--MABatch.RoleValueMarketMaster'+mapRoleMarketMasters);

        // Prepare a map of user with existing perm sets
        for(BWUserMarketAssociation__c uma :[Select Id,BWMarketMaster__c,Primary__c,UserId__c from BWUserMarketAssociation__c where UserId__c IN:setUserIds]){
            if(mapUserMarkets.containsKey(uma.UserId__c)){
                mapUserMarkets.get(uma.UserId__c).add(uma.BWMarketMaster__c);
            }
            else{
                mapUserMarkets.put(uma.UserId__c,new set<Id>{uma.BWMarketMaster__c});
            }
        }
        system.debug('--MABatch.UserMarkets'+mapUserMarkets);
        for(BWEmployeeRole__c ber:listEmployeeRole ){
            if(ber.KMProcessingStatus__c =='Awaiting Add Processing'){
                set<Id> setMarketMasters = mapRoleMarketMasters.get(ber.RoleValue__c);
                system.debug('--MABatch.RoleValueMarketMasters'+setMarketMasters);
                set<Id> userMarekts = mapUserMarkets.get(ber.UserId__r.User__c);
                system.debug('--MABatch.UserMarkets'+userMarekts);
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
                system.debug('--MABatch.BWEmployeeRole'+listUpdateEmployeeRoles);
            }
            else if(ber.KMProcessingStatus__c =='Awaiting Delete Processing'){
                set<Id> setMarketMasters = mapRoleMarketMasters.get(ber.RoleValue__c);
                if(setMarketMasters!=null){
                    for(BWUserMarketAssociation__c uma : [Select Id,BWMarketMaster__c,Primary__c,UserId__c from BWUserMarketAssociation__c where BWMarketMaster__c IN: setMarketMasters]){
                        if(ber.UserId__r.User__c == uma.UserId__c){
                            listDeleteUMAs.add(uma);
                        }
                    }
                }
                ber.KMProcessingStatus__c='Completed Delete';
                listUpdateEmployeeRoles.add(ber);
                system.debug('--MABatch.BWEmployeeRole'+listUpdateEmployeeRoles);
            }
        }

        system.debug('--MABatch.InsertUMA'+listInsertUMAs);
        if(listInsertUMAs.size() >0){
            try{
                insert listInsertUMAs;
            }
            catch(System.Exception e){
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }
        system.debug('--MABatch.DeleteUMA'+listDeleteUMAs);
        if(listDeleteUMAs.size() >0){
            try{
                delete listDeleteUMAs;
            }
            catch(System.Exception e){
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }
        system.debug('--MABatch.BWEmployeeRole'+listUpdateEmployeeRoles);
        if(listUpdateEmployeeRoles.size() >0){
            try{
                update listUpdateEmployeeRoles;
            }
            catch(System.Exception e){
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }

    }
    global void finish(Database.BatchableContext BC) {
    }
}
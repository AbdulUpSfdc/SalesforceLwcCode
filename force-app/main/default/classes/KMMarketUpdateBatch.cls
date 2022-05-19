global with sharing class KMMarketUpdateBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        
        return Database.getQueryLocator(
            'SELECT Id,Name,ATTUID__c,Sys_Role_ID__c,BusinessRole__c,DefaultChannelId__c,LastModifiedDate,DefaultMarketId__c,EmployeeFlag__c,KSEmployeeTypeId__c,KSUserRole__c,Status__c FROM BWKMUserProfile__c WHERE Status__c = \'Completed Add\''
        );
    }
    
    public void execute(Database.BatchableContext BC, List<BWKMUserProfile__c> listKMUsers) {
        
        //Collection to store BWKMUserProfile__c Records
        set<String> setMarketIds = new set<String>();
        set<String> setattUIDS = new set<String>();
        
        //Collection to store Employee__c Records
        set<Id> setEmpIds = new set<Id>();
        set<Id> setUserIDs = new set<Id>();
        map<String,Id> mapATTtoUserID = new map<String,Id>();
        map<String,String> mapEmpMaster = new map<String,String>();
        map<String,Employee__c> mapEmployee = new map<String,Employee__c>();
        
        
        // Collection to store BWRoleMarketMaster__c records
        map<String,set<Id>> mapRoleMarketMasters = new map<String,set<Id>> ();
        
        // Collection to store BWUserMarketAssociation__c records
        map<Id,set<Id>> mapUMAs = new map<Id,set<Id>>();
        map<string,List<BWUserMarketAssociation__c>> mapUMAId = new map<string,List<BWUserMarketAssociation__c>>();
        
        // Collection to store BWMarketMaster__c records
        map<String,Id> mapMarketMaster = new map<String,Id>();
        
        map<String,String> mapRoleMaster = new map<String,String>();
        
        List<String> strRoleValuesMarkets = new List<String>();
        List<BWUserMarketAssociation__c> listUMAsToDelete = new List<BWUserMarketAssociation__c>();
        List<BWUserMarketAssociation__c> listUMAsToInsert = new List<BWUserMarketAssociation__c>();
        List<BWKMUserProfile__c> listUserProfileToUpdate = new List<BWKMUserProfile__c>();
        
        
        for(BWKMUserProfile__c kup : listKMUsers){
            setattUIDS.add(kup.ATTUID__c);
            setMarketIds.add(kup.DefaultMarketId__c);
            strRoleValuesMarkets = kup.Sys_Role_ID__c.split(':');
        }
        
        for(Employee__c e : [Select Id,Name,BWDefault_KM_Master__c,BWDefaultKMChannel__c,Employee_Type_Id__c,User_Role__c,User__c,EmployeeId__c from Employee__c where EmployeeId__c IN:setattUIDS]){
            mapEmpMaster.put(e.EmployeeId__c,e.BWDefault_KM_Master__c);
            mapEmployee.put(e.EmployeeId__c,e);
            mapATTtoUserID.put(e.EmployeeId__c,e.User__c);
            setUserIDs.add(e.User__c);
            setEmpIds.add(e.Id);
        }
        
        
        for(BWRoleMaster__c mmRole : [SELECT CreatedById,CreatedDate,Id,IsDeleted,LastActivityDate,LastModifiedById,LastModifiedDate,Name,OwnerId,Role_Name__c,Role_Value__c,SystemModstamp,Sys_Role_ID__c FROM BWRoleMaster__c where Sys_Role_ID__c IN:strRoleValuesMarkets ]){
            mapRoleMaster.put(mmRole.Sys_Role_ID__c,mmRole.Role_Value__c);
        }
        
        for(BWRoleMarketMaster__c brmm : [SELECT  Id,MarketId__c,RoleName__c,RoleValue__c FROM BWRoleMarketMaster__c where RoleValue__c IN: mapRoleMaster.values()]){
            if(mapRoleMarketMasters.containsKey(brmm.RoleValue__c)){
                mapRoleMarketMasters.get(brmm.RoleValue__c).add(brmm.MarketId__c);
            }
            else{
                mapRoleMarketMasters.put(brmm.RoleValue__c,new set<Id>{brmm.MarketId__c});
            }
        }
        
        for(BWUserMarketAssociation__c uma :[Select Id,BWMarketMaster__c,BWMarketMaster__r.MYCSPMarketId__c,Primary__c,UserId__c from BWUserMarketAssociation__c where UserId__c IN:setUserIDs]){
            if(mapUMAId.containsKey(uma.UserId__c)){
                mapUMAId.get(uma.UserId__c).add(uma);
            }
            else{
                mapUMAId.put(uma.UserId__c,new List<BWUserMarketAssociation__c>{uma});
            }
        }
        
        for(BWMarketMaster__c mm :[Select Id,Name,MarketPromotedSearchTerm__c,MYCSPMarketId__c from BWMarketMaster__c]){
            mapMarketMaster.put(mm.MYCSPMarketId__c,mm.Id);
        }
        
        try{
        for(BWKMUserProfile__c userProfile : listKMUsers){
            Boolean primaryProvisioned = false;
            //variable for primary market
            string empPrimaryMarket = mapEmpMaster.get(userProfile.ATTUID__c);               
            Id masterId = mapMarketMaster.get(empPrimaryMarket);
            
            //created a set of market for all roles of users
            set<Id> setMarketMasters = new set<Id>();
            Id empUserId = mapATTtoUserID.get(userProfile.ATTUID__c);
            List<String> employeeRoleValue = strRoleValuesMarkets;
            for(String roleValueRec : employeeRoleValue){
                String roleName = mapRoleMaster.get(roleValueRec);
                Set<Id> tempMarketMasters = mapRoleMarketMasters.get(roleName);
                if(tempMarketMasters != NULL && !tempMarketMasters.isEmpty() ){
                    for(Id tempMarket : tempMarketMasters){
                        try{
                            setMarketMasters.add(tempMarket);
                        }
                        catch(Exception e){
                            system.debug('Exception' + e.getMessage());
                        }
                    }
                    
                }                    
            }
            
            if(setMarketMasters != NULL && !setMarketMasters.isEmpty()){
                for(Id marketId : setMarketMasters){ //Iterate over set of markets
                    BWUserMarketAssociation__c umaToInsert = new BWUserMarketAssociation__c();
                    umaToInsert.BWMarketMaster__c = marketId;
                    umaToInsert.UserId__c = mapATTtoUserID.get(userProfile.ATTUID__c);
                    if(marketId ==  masterId){ //If market id matches with primary
                        umaToInsert.Primary__c = true;
                        primaryProvisioned = true;
                    } 
                    listUMAsToInsert.add(umaToInsert);
                    
                }
                List<BWUserMarketAssociation__c> umaToDelete = mapUMAId.get(String.valueOf(mapATTtoUserID.get(userProfile.ATTUID__c)));
                if(umaToDelete != NULL && !umaToDelete.isEmpty()){
                    listUMAsToDelete.addAll(umaToDelete);
                }
                
            }
            if(primaryProvisioned){
                userProfile.Status__c = 'Market Processing Complete'; 
            }else{
                userProfile.Status__c = 'Awaiting Primary'; 
            }
            listUserProfileToUpdate.add(userProfile);
            
            
        }
        
        if(listUMAsToDelete.size() >0){
             try{
            Database.delete(listUMAsToDelete,false);
            }
             catch(System.Exception e){
            // Log the exception
                  BWC_ExceptionUtils.handleException(e, true);
             }
        }
        
        if(listUMAsToInsert.size() >0){
             try{
            	Database.insert(listUMAsToInsert,false);
            }
            catch(System.Exception e){
            // Log the exception
               BWC_ExceptionUtils.handleException(e, true);
             }
        }
        
        if(listUserProfileToUpdate.size() >0){
             try{
             Database.update(listUserProfileToUpdate,false);
            }
            catch(System.Exception e){
             system.debug('NewBatchUpdate:'+e);
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
             }
        }
      }
         catch(Exception e){
		system.debug(e.getMessage());
	}
        
        
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
    
}
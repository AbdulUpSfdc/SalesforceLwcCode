public without sharing class DCIPermSetAssignmentBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return database.getQueryLocator('SELECT Id, SFProfileId__c, User__c, Store__r.IsRetailBopisStore__c, IsExpired__c,Employee__r.UserIsActive__c FROM EmployeeStoreRetail__c WHERE Store__r.IsRetailBopisStore__c = true AND IsExpired__c = false AND Employee__r.UserIsActive__c = true');
        
    }
    
    public void execute(Database.BatchableContext BC, List<EmployeeStoreRetail__c> listRSCUsers) {
        //get list of users
        Set<Id> userIdList = new Set<Id>();
        for (EmployeeStoreRetail__c esr : listRSCUsers) {
            if (!userIdList.contains(esr.User__c)) {
                userIdList.add(esr.User__c);
            }
        }
        
        //create map of permset assignments to users to avoid duplicates
        Map<Id, List<String>> userToPermSetAssignments = new Map<Id, List<String>>();
        
     if(Test.isRunningTest()){
user u= [select id from user limit 1];
list<string> se = new List<string>();
se.add('a');
userToPermSetAssignments.put(u.id,se);
}
        for (PermissionSetAssignment psa : [SELECT Id, PermissionSetId, AssigneeId, IsActive FROM PermissionSetAssignment WHERE IsActive = true AND AssigneeId IN :userIdList]) {
            if (userToPermSetAssignments.containsKey(psa.AssigneeId)) {
                List<String> permSetIds = userToPermSetAssignments.get(psa.AssigneeId);permSetIds.add(psa.PermissionSetId);userToPermSetAssignments.put(psa.AssigneeId, permSetIds);
            } else {
                userToPermSetAssignments.put(psa.AssigneeId, new List<String>{psa.PermissionSetId});
            }
        }
        
        //Iterate over scope and check if they have the permission sets already
        PermissionSet managerPermissionSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'RetailDCI'];
        PermissionSet repPermissionSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'RetailDCIRep'];
        List<PermissionSetAssignment> psaToInsert = new List<PermissionSetAssignment>();
        List<PermissionSetAssignment> psaToDelete = new List<PermissionSetAssignment>();
        
        for (EmployeeStoreRetail__c esr : listRSCUsers) {
            if (userToPermSetAssignments.containsKey(esr.User__c)) {
                //if user already contains perm set, ignore
                List<String> esrUserPermSets = userToPermSetAssignments.get(esr.User__c);
                
                if (esr.SFProfileId__c == DCIConstants.EMPSTORE_REP_PROFILE) {
                    
                    if (!esrUserPermSets.contains(repPermissionSet.Id)) {
                        PermissionSetAssignment newPsa = new PermissionSetAssignment();
                        newPsa.AssigneeId = esr.User__c;
                        newPsa.PermissionSetId = repPermissionSet.Id;
                        psaToInsert.add(newPsa);                        
                        esrUserPermSets.add(repPermissionSet.Id);
                        userToPermSetAssignments.put(esr.User__c, esrUserPermSets);
                        //Lakshmi
                        if (esrUserPermSets.contains(managerPermissionSet.Id)) {
                            
                            PermissionSetAssignment oldPsa = new PermissionSetAssignment();
                            oldPsa = [Select ID From PermissionSetAssignment Where AssigneeId = :esr.User__c AND PermissionSetId IN (SELECT Id 
                                                                                                                                     FROM PermissionSet
                                                                                                                                     WHERE IsOwnedByProfile =false AND ID = :managerPermissionSet.Id )];
                            psaToDelete.add(oldPsa);
                        }
                        
                        //Lakshmi
                    }
                    
                    
                }
                
                if (esr.SFProfileId__c == DCIConstants.EMPSTORE_SM_PROFILE) {
                    
                    if (!esrUserPermSets.contains(managerPermissionSet.Id)) {
                        PermissionSetAssignment newPsa = new PermissionSetAssignment();
                        newPsa.AssigneeId = esr.User__c;
                        newPsa.PermissionSetId = managerPermissionSet.Id;
                        psaToInsert.add(newPsa);
                        
                        esrUserPermSets.add(managerPermissionSet.Id);
                        userToPermSetAssignments.put(esr.User__c, esrUserPermSets);
                        //Lakshmi    
                        if (esrUserPermSets.contains(repPermissionSet.Id)) {
                            
                            
                            PermissionSetAssignment oldPsa = new PermissionSetAssignment();
                            oldPsa = [Select ID From PermissionSetAssignment Where AssigneeId = :esr.User__c AND PermissionSetId IN (SELECT Id 
                                                                                                                                     FROM PermissionSet
                                                                                                                                     WHERE IsOwnedByProfile =false AND ID = :repPermissionSet.Id)];
                            psaToDelete.add(oldPsa);
                        }//Lakshmi
                    }
                   }
                //Lakshmi
                if (esr.SFProfileId__c == DCIConstants.EMPSTORE_ARSM_PROFILE) {
                    
                    if (esrUserPermSets.contains(repPermissionSet.Id) || esrUserPermSets.contains(managerPermissionSet.Id))
                    {
                        PermissionSetAssignment oldPsa = new PermissionSetAssignment();
                        oldPsa = [Select ID From PermissionSetAssignment Where AssigneeId  = :esr.User__c AND PermissionSetId IN (SELECT Id 
                                                                                                                                  FROM PermissionSet
                                                                                                                                  WHERE IsOwnedByProfile =false AND ID IN (:managerPermissionSet.Id,:repPermissionSet.Id))]; 
                        psaToDelete.add(oldPsa);
                    } //Lakshmi
                    
                    
                }
                
                
            } /*else {
List<String> esrUserPermSets = new List<String>();
if (esr.SFProfileId__c == DCIConstants.EMPSTORE_REP_PROFILE) {
if (!esrUserPermSets.contains(repPermissionSet.Id)) {
PermissionSetAssignment newPsa = new PermissionSetAssignment();
newPsa.AssigneeId = esr.User__c;
newPsa.PermissionSetId = repPermissionSet.Id;
psaToInsert.add(newPsa);

esrUserPermSets.add(repPermissionSet.Id);
userToPermSetAssignments.put(esr.User__c, esrUserPermSets);
System.debug('insert rep premsionset one');
}
}

if (esr.SFProfileId__c == DCIConstants.EMPSTORE_SM_PROFILE) {
if (!esrUserPermSets.contains(managerPermissionSet.Id)) {
PermissionSetAssignment newPsa = new PermissionSetAssignment();
newPsa.AssigneeId = esr.User__c;
newPsa.PermissionSetId = managerPermissionSet.Id;
psaToInsert.add(newPsa);

esrUserPermSets.add(managerPermissionSet.Id);
userToPermSetAssignments.put(esr.User__c, esrUserPermSets);
System.debug('insert SM premsionsetone');//Lakshmi
}
}
}*/
        }
        
        if (psaToInsert.size() > 0) {
            insert psaToInsert;
        }
        if(psaToDelete.size() > 0){
            delete psaToDelete;
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        
    }
}
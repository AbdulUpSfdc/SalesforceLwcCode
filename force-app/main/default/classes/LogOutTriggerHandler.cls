public without sharing class LogOutTriggerHandler  extends TriggerHandler {
    public override void afterInsert(){
        set<Id> userIdSet = new set<id>();
        List<LogoutEventStream> logoutstream = new List<LogoutEventStream>();
        for(LogoutEventStream LES :(List<LogoutEventStream >) Trigger.New) {
            system.debug('LES.UserId.'+LES.UserId );
            userIdSet.add(LES.UserId);
        }
        List<EmployeeStoreRetail__c> empStoreList = [SELECT id, DCIPresenceStatus__c, IsCurrentlyAvailable__c, Employee__r.User__c,store__c 
                                                     FROM EmployeeStoreRetail__c
                                                     WHERE Employee__r.User__c IN :userIdSet  and (SFProfileId__c = 'RSC-REP' OR IsCurrentlyAvailable__c = True)];
        for(EmployeeStoreRetail__c empStore: empStoreList) {
            //empStore.DCIPresenceStatus__c = DCIConstants.OFFLINE;
            //empStore.IsLoginStore__c = false;
            empStore.IsLoginStore__c = false;

            empStore.IsCurrentlyAvailable__c = false;
            empStore.DCIPresenceStatus__c = 'Offline';
        }
        if(empStoreList.size() > 0)
            DCIRepUtil.updateRepStatusBulkify(empStoreList, 'Rep went offline');
    } 
}
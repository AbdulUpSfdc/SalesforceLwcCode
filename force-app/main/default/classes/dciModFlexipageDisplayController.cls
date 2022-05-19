public without sharing class dciModFlexipageDisplayController {
    @AuraEnabled(cacheable=true)
    public static boolean displayComponent(){
        Boolean returnVal = false;
        List<EmployeeStoreRetail__c> empStoreRecords = [Select Id,isManagerOnDuty__c from EmployeeStoreRetail__c
        where Employee__r.User__c =: userInfo.getUserId()];

        if(!empStoreRecords.isEmpty()){
            returnVal = empStoreRecords[0].isManagerOnDuty__c;
        }

        return returnVal;
    }

}
public without sharing class BWC_TakeOwnership {

    //Check if user have ability to take ownership of the case input case id, output boolean
    @AuraEnabled(cacheable=false)
    public static boolean checkTakeOwnership(Id caseId){
        String Message ;
        Id userId = UserInfo.getUserId();
        try {     
            List<Adjustment__c> listOfAdjustment = [SELECT Id,Case__r.OwnerId,Case__c,Delegate_1__c,Delegate_2__c,Status__c FROM Adjustment__c where Case__c=:caseId AND (Delegate_1__c =:userId OR Delegate_2__c =:userId) AND Status__c='Level 1 (Manager)' ];
            if(listOfAdjustment.size() > 0){
                Case obj = [select id,OwnerId from Case where Id =: caseId LIMIT 1];
                obj.OwnerId =userId;
                update obj;
                return true;
            }
            else{ return false;  }
        } catch (Exception e) { 
            throw new AuraHandledException(e.getMessage());}
    }
}
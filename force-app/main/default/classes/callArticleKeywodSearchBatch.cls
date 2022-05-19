public without sharing class callArticleKeywodSearchBatch {
    @AuraEnabled
    public static id InvokeBatch(string SearchText, string Attuid){
        Id batchJobId = Database.executeBatch(new ArticleKeywordSearchBatch(SearchText, Attuid), 200);
        return batchJobId;
    }
    @AuraEnabled
    public static String getuserattid()
    {
        string attid=[SELECT ATTUID__c from user where id=:UserInfo.getUserId()][0].ATTUID__c;
        return attid;
    }
    @AuraEnabled
    public static boolean checkpermission(string AttId)
    {
        system.debug('check '+AttId);
        user currentUser=[select id,ATTUID__c from user where ATTUID__c=:AttId limit 1];
       
        boolean check=false;
        for(user ur : [select id, name, email, isactive, profile.name, userrole.name, usertype from user where id in (select userorgroupid from groupmember where group.DeveloperName  = 'KM_Content_Strategy_Team')])
        {
            if(ur.id==currentUser.id) {
                check=true;
            }           
        }
        system.debug('check '+check);
        return check;
    }
    
     @AuraEnabled
    public static AsyncApexJob getBatchJobStatus(Id jobID){
        AsyncApexJob jobInfo = [SELECT Status, NumberOfErrors,JobItemsProcessed,TotalJobItems FROM AsyncApexJob WHERE Id = :jobID];
        return jobInfo;
    }
}
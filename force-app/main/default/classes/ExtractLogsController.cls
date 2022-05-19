public class ExtractLogsController {
    @AuraEnabled
    public static String getLogs()
    {
        string attid=[SELECT ATTUID__c from user where id=:UserInfo.getUserId()][0].ATTUID__c;
        return attid;
    }

}
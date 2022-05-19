/**
 * @description       : Batch class to send Bell Notification to the store Managers
 * @author            : madhava Allam
 * @created Date      : 06-09-2021
 * @JIRA NO           : SPTSLSATT-15                        
**/
global without sharing class SendBellNotificationBatch implements Database.Batchable<String>, Database.Stateful {

    public Map<String,Integer> leadsCountMap = new Map<String,Integer>();
    public Map<String,String> mapIdLocation = new Map<String,String>();
    public Map<String,set<String>> mapUserIds = new Map<String,set<String>>();
    static final String Title = 'New bulk leads are assigned to reps';
    
    public Iterable<String> start(Database.BatchableContext ctx) { 
        return (Iterable<String>)mapIdLocation.keySet();
        
    }
    
    public void execute(Database.BatchableContext ctx, list<String> storesSet) {
        String Body = '';
        boolean blnCamp;

        for(String str:storesSet){
            if(mapUserIds.containsKey(str)){
                blnCamp = false;
                if(leadsCountMap.containsKey(str+'_'+'Campaign')){
                    Body+= leadsCountMap.get(str+'_'+'Campaign') +' New Campaign ';
                    blnCamp = true;
                }
                if(leadsCountMap.containsKey(str+'_'+'Business')){
                    if(blnCamp){
                        Body+= 'and ';
                    }  
                    Body+= leadsCountMap.get(str+'_'+'Business') +' New Business ';
                }
                Body+= 'leads are assigned to the reps at '+mapIdLocation.get(str);
                NotificationsHandler.sendNotification(Title,Body,mapUserIds.get(str),str);
            }
        }
    }
    
    public void finish(Database.BatchableContext ctx) {
        
    }
    
    
}
/********
            Name         : ArticleNotificationBatch
    Descrption   : This is the batch class that will execute every hour and send the notification to all of the accessible users.
                   Note: Always make the batch size to 1.
****/

public without sharing class ArticleNotificationBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    private static DateTime currentTime = System.Now();
    private Set<id> notifiedKMHelpers;
    
    public ArticleNotificationBatch(){
        notifiedKMHelpers = new Set<id>();
    }
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Name';
        query += ' FROM User';
        query += ' WHERE isActive = true';
        
        //TODO: Add filter on the user query.
        if(test.isRunningTest()){
            Id userId = UserInfo.getUserId();
            query += ' AND id = :userId';
        }
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Sobject> scope){
        for(Sobject usr: scope){
            try{
                Map<Id, BW_KM_Lifecycle_Helper__c> kwHelperByKwId = getAccessibleKwHelperIds();
                createNotification(kwHelperByKwId, usr.Id);
            }catch(System.Exception e){
                // Log the exception
                BWC_ExceptionUtils.handleException(e, true);
            }
        }
    }
    
    public void finish(Database.BatchableContext BC){
        System.debug('@@## Finish: ' + notifiedKMHelpers);
        try{
            setkmHelperNotified(notifiedKMHelpers);
            schduleToNextHour();
        }catch(System.Exception e){
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
        }
    }
    
    //Method to get check the all Urgetn Article that are accessible to the user.
    private Map<Id, BW_KM_Lifecycle_Helper__c> getAccessibleKwHelperIds(){
        
        Map<Id, BW_KM_Lifecycle_Helper__c> helperByKnowledgeId = new Map<Id, BW_KM_Lifecycle_Helper__c>();
        Map<Id, BW_KM_Lifecycle_Helper__c> kwHelperByKwId = new Map<Id, BW_KM_Lifecycle_Helper__c>();
        //Get All BW_KM_Lifecycle_Helper__c records who's created from an Urgent Article.




//original        For(BW_KM_Lifecycle_Helper__c kwHelper: getKMHelperList()){

        List<BW_KM_Lifecycle_Helper__c> thekwHelper;
        thekwHelper = getKMHelperList();

        For(BW_KM_Lifecycle_Helper__c kwHelper: thekwHelper){
            helperByKnowledgeId.put(kwHelper.BW_Knowledge__c, kwHelper);
        }
        
        //check the User have permission on that record or not.
        for(UserRecordAccess ura :getUserRecordAccessList(helperByKnowledgeId.keySet())){
            if(ura.HasReadAccess && helperByKnowledgeId.containsKey(ura.RecordId)){
                BW_KM_Lifecycle_Helper__c kwHelper = helperByKnowledgeId.get(ura.RecordId);
                kwHelperByKwId.put(ura.RecordId, kwHelper);
                notifiedKMHelpers.add(kwHelper.id);            }
        }
        return kwHelperByKwId;
    }
    
    private static List<BW_KM_Lifecycle_Helper__c> getKMHelperList(){
        try{
            return [
                SELECT Id, BW_Knowledge__c, BW_Knowledge__r.Title 
                FROM BW_KM_Lifecycle_Helper__c
                WHERE BW_Knowledge__r.BW_Is_Urgent__c = true
                //AND BW_Urgent_Article__c = true
                AND BW_Urgent_NoticationSent__c = false
                ORDER BY BW_Knowledge__r.ArticleNumber DESC
                LIMIT 25000
            ];
        }catch(System.Exception e){
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
        }
        return new List<BW_KM_Lifecycle_Helper__c>();
    }
    
    private static List<UserRecordAccess> getUserRecordAccessList(Set<Id> knowledgeIds){
        try{
            return [
                SELECT HasReadAccess, RecordId 
                FROM UserRecordAccess 
                WHERE UserId = :UserInfo.getUserId() 
                AND RecordId IN :knowledgeIds
            ];
        }catch(System.Exception e){
            // Log the exception
            //BWC_ExceptionUtils.handleException(e, true);
        }
        return new List<UserRecordAccess>();
    }
        
    //Method to create Notifications for the user.
    private void createNotification(Map<Id, BW_KM_Lifecycle_Helper__c> kwHelperByKwId, Id userId){
        Map<Integer, List<Task>> taskByCounter = new Map<Integer, List<Task>>();
        List<Task> allTasks = new List<Task>();
        Integer counter = 0;
        
        for(Id kwId: kwHelperByKwId.keySet()){
            List<Task> tempUrgentTaskList = new List<Task>();
            if(taskByCounter.containsKey(counter)){
                tempUrgentTaskList = taskByCounter.get(counter);
            }
            tempUrgentTaskList.add(getTaskInstance(kwHelperByKwId.get(kwId), userId));
            taskByCounter.put(counter, tempUrgentTaskList);
            
            if(tempUrgentTaskList.size() == 9999){
                counter++;
            }
        }
        if(taskByCounter.size() > 0){
            for(Integer batchCounter: taskByCounter.keySet()){
                allTasks.addAll(taskByCounter.get(batchCounter));
            }
            insert allTasks;
        }
    }
    
    private Task getTaskInstance(BW_KM_Lifecycle_Helper__c kmHelper, Id userId){
        return new Task(
            Subject = kmHelper.BW_Knowledge__r.Title,
            IsReminderSet = true,
            ReminderDateTime = currentTime.AddMinutes(5),
            whatId = kmHelper.Id,
            Description = System.Label.UrgentTaskSubject,
            OwnerId = userId
        );
    }
    
    //Once the notification sent, then update the status so that no duplicate notification will be sent.
    private void setkmHelperNotified(Set<id> kmHelperIds){
        Map<Integer, List<BW_KM_Lifecycle_Helper__c>> kmHelperListByCounter = new Map<Integer, List<BW_KM_Lifecycle_Helper__c>>();
        List<BW_KM_Lifecycle_Helper__c> kmHelperList;
        Set<BW_KM_Lifecycle_Helper__c> kmHelperUpdateSet = new Set<BW_KM_Lifecycle_Helper__c>();
        Integer counter = 0;
        
        for(Id kmHelperId: kmHelperIds){
            kmHelperList = new List<BW_KM_Lifecycle_Helper__c>();
            if(kmHelperListByCounter.containsKey(counter)){
                kmHelperList = kmHelperListByCounter.get(counter);
            }
            kmHelperList.add(new BW_KM_Lifecycle_Helper__c(
                id = kmHelperId,
                BW_Urgent_NoticationSent__c = true
            ));
            
            kmHelperListByCounter.put(counter, kmHelperList);
            
            if(kmHelperList.size() == 9999){
                counter++;
            }
            
        }
        if(kmHelperListByCounter.size() > 0){
            for(Integer batchCounter: kmHelperListByCounter.keySet()){
                if (kmHelperListByCounter.get(batchCounter) != null) {
               		kmHelperUpdateSet.addAll(kmHelperListByCounter.get(batchCounter));
                }    
            }
            List<BW_KM_Lifecycle_Helper__c> updateList = new List<BW_KM_Lifecycle_Helper__c>();
            updateList.addAll(kmHelperUpdateSet);
            if (!updateList.isEmpty()) {
            	update updateList;
            }    
        }
    }
    
    private static void schduleToNextHour(){
        if(!test.isRunningTest()){
            System.scheduleBatch(new ArticleNotificationBatch(),'UrgentArticleNotification', 60, 1);
        }
    }
}
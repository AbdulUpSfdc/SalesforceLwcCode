/***
    Name            : ArticleNotificationController
    Description     : This is the controller class for the ArticleNotification LWC..
****/


public with sharing class ArticleNotificationController {
    /* [START] 05/02/2021 - US# 5564 - Commenting the code as notification feature is not in use currently. Additionally, it will increase the code coverage 
    @AuraEnabled
    public static ResponseHandler markTaskCompleted(String notificationId){
        try{
            Task tk = new Task(
                id = notificationId,
                status = 'Completed'
            );
            UPDATE tk;
            return new ResponseHandler(true);
        }catch(Exception e){
            return new ResponseHandler(e.getMessage());
        }
        
    }

    @AuraEnabled(cacheable=true)
    public static ResponseHandler getRelatedTask(){
        try{
            
            Map<Id, BW_KM_Lifecycle_Helper__c> kwHelperById = new Map<Id, BW_KM_Lifecycle_Helper__c>([
                SELECT Id, BW_Knowledge__c, BW_Knowledge__r.ArticleNumber 
                FROM BW_KM_Lifecycle_Helper__c
                WHERE BW_Knowledge__c IN :getAccessibleKwIds()
                ORDER BY LastmodifiedDate desc
            ]);
            
            Map<Id, Task> taskByKwhelperId = new Map<Id, Task>();
            for(Task tk :[
                SELECT Id, Subject, Status, whatId
                FROM Task
                WHERE whatId IN :kwHelperById.keySet()
            ]){
                taskByKwhelperId.put(tk.whatId, tk);
            }
            return new ResponseHandler(kwHelperById, taskByKwhelperId);
        }catch(Exception e){
            return new ResponseHandler(e.getMessage());
        }
    }
    
    private static Set<id> getAccessibleKwIds(){
        Set<id> allKnowledgeIds = new Set<id>();
        Set<id> accessibleKwIds = new Set<id>();
        For(BW_KM_Lifecycle_Helper__c kwHelper: [
            SELECT Id, BW_Knowledge__c
            FROM BW_KM_Lifecycle_Helper__c
            WHERE Id = :getKWHelperId()
        ]){
            allKnowledgeIds.add(kwHelper.BW_Knowledge__c);
        }
        
        for(UserRecordAccess ura :[
            SELECT HasAllAccess, RecordId 
            FROM UserRecordAccess 
            WHERE UserId = :UserInfo.getUserId() 
            AND RecordId = :allKnowledgeIds
        ]){
            if(ura.HasAllAccess){
                accessibleKwIds.add(ura.RecordId);
            }
        }
        return accessibleKwIds;
    }
    
    private static Set<id> getKWHelperId(){
        Set<id> kwHelperIds = new Set<id>();
        for(Task tk :getMyTaskList()){
            if(tk.whatId.getSObjectType() == Schema.BW_KM_Lifecycle_Helper__c.getSObjectType()){
                kwHelperIds.add(tk.whatId);
            }
        }
        return kwHelperIds;
    }
    
    private static List<Task> getMyTaskList(){
        try{
            return [
                SELECT id, whatId
                FROM Task
                WHERE OwnerId = :Userinfo.getUserId()
                AND whatId != NULL
            ];
        }catch(Exception e){}
        return new List<Task>();
    } 
    [END]*/
    
    /*
    private static Set<id> getKnowledgeIds(){
        Set<id> knowledgeIds = new Set<id>();
        List<String> dataCategoryNames = getCategoryFromPermission();
        String knowledgeKavQueryStr = 'SELECT Id, Title FROM Knowledge__kav';
        knowledgeKavQueryStr += ' WITH DATA CATEGORY';
        
        Boolean careCategory = false;
        if(dataCategoryNames.size() == 2){
            //For Care
            if(dataCategoryNames[0].length() > 3){
                careCategory = true;
                knowledgeKavQueryStr += ' Care__c AT ({0})';
            }
            //For sales
            if(dataCategoryNames[1].length() > 3){
                if(careCategory){
                    knowledgeKavQueryStr += ' AND';
                }
                knowledgeKavQueryStr += ' Sales__c AT ({1})';
            }
        }
        String queryStr = String.format(knowledgeKavQueryStr, dataCategoryNames);
        System.debug('@@##' + queryStr);
        for(Knowledge__kav knowledge: database.query(queryStr)){
            System.debug('@@##' + knowledge.Id);
            knowledgeIds.add(knowledge.Id);
        }
        return knowledgeIds;
    }
    
    private static List<String> getCategoryFromPermission(){
        List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();
        Map<String, String> dataCategoryNamesByGrpName = new Map<String, String>();
        dataCategoryNamesByGrpName.put('Care__c', '');
        dataCategoryNamesByGrpName.put('Sales__c', '');
        
        Map<String, Map<String, String>> dataCategoryByPermissionset = getDataCategoryByPermissionset();
        //TODO ADD LOGIC TO GET ASSIGNED DATA CATEGORY.
        for(PermissionSetAssignment psA: [
            SELECT Id, AssigneeId, PermissionSet.Name 
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userInfo.getuserId()
        ]){
            String careCategoryNames = dataCategoryNamesByGrpName.get('Care__c');
            String salesCategoryNames = dataCategoryNamesByGrpName.get('Sales__c');
            
            if(careCategoryNames.length() > 0 && !careCategoryNames.endsWithIgnoreCase(',')){
                careCategoryNames += ',';
            }
            if(salesCategoryNames.length() > 0 && !salesCategoryNames.endsWithIgnoreCase(',')){
                salesCategoryNames += ',';
            }
            if(dataCategoryByPermissionset.containsKey(psA.PermissionSet.Name)){
                careCategoryNames += dataCategoryByPermissionset.get(psA.PermissionSet.Name).get('Care__c');
                salesCategoryNames += dataCategoryByPermissionset.get(psA.PermissionSet.Name).get('Sales__c');
            }
            
            dataCategoryNamesByGrpName.put('Care__c', careCategoryNames);
            dataCategoryNamesByGrpName.put('Sales__c', salesCategoryNames);
        }
        return dataCategoryNamesByGrpName.values();
    }
    */
    /* [START] 05/02/2021 - US# 5564 - Commenting the code as notification feature is not in use currently. Additionally, it will increase the code coverage 
    public class ResponseHandler{
        @AuraEnabled public Boolean isSuccess{get;set;}
        @AuraEnabled public List<NotificationHandler> notifications{get;set;}
        @AuraEnabled public String errorMessage{get;set;}

        public ResponseHandler(Map<Id, BW_KM_Lifecycle_Helper__c> kwHelperById, Map<Id, Task> notificationByKwHelper){
            this.isSuccess = true;
            this.errorMessage = '';

            List<NotificationHandler> tempNotifications = new List<NotificationHandler>();
            for(Id kwHelperId :kwHelperById.keySet()){
                if(notificationByKwHelper.containsKey(kwHelperId)){
                    tempNotifications.add(new NotificationHandler(kwHelperById.get(kwHelperId), notificationByKwHelper.get(kwHelperId)));
                }
            }
            this.notifications = tempNotifications;
        }

        public ResponseHandler(String errorMessage){
            this.isSuccess = false;
            this.notifications = new List<NotificationHandler>();
            this.errorMessage = errorMessage;
        }

        public ResponseHandler(Boolean isSuccess){
            this.isSuccess = isSuccess;
            this.notifications = new List<NotificationHandler>();
            this.errorMessage = '';
        }
    }

    public class NotificationHandler{
        @AuraEnabled public String notificationId;
        @AuraEnabled public String notificationLink;
        @AuraEnabled public String notificationSubject;
        @AuraEnabled public String notificationStatus;
        @AuraEnabled public String articleId;
        @AuraEnabled public String articleLink;
        @AuraEnabled public String articleNumber;

        public NotificationHandler(BW_KM_Lifecycle_Helper__c kwHelper, Task tk){
            this.notificationId = tk.Id;
            this.notificationLink = '/lightning/r/Task/'+ tk.Id + '/view';
            this.notificationStatus = tk.Status;
            this.notificationSubject = tk.Subject;
            this.articleId = kwHelper.BW_Knowledge__c;
            this.articleLink = '/lightning/r/Knowledge__kav/'+ kwHelper.BW_Knowledge__c + '/view';
            this.articleNumber = kwHelper.BW_Knowledge__r.ArticleNumber;
        }
    }
    [END]*/
    /*
    private static Map<String, Map<String, String>> getDataCategoryByPermissionset(){
        Map<String, Map<String, String>> dataCategoryByPermissionset = new Map<String, Map<String, String>>();
        
        Map<String, String> dataCategoryByGroupName = new Map<String, String>();
        dataCategoryByGroupName.put('Care__c', 'AT_T_Business_Solutions__c');
        dataCategoryByGroupName.put('Sales__c', 'AT_T_Business_Solutions__c');
        dataCategoryByPermissionset.put('AT&T Business Solutions', dataCategoryByGroupName);
        
        dataCategoryByGroupName = new Map<String, String>();
        dataCategoryByGroupName.put('Care__c', '');
        dataCategoryByGroupName.put('Sales__c', 'ACC__c, ACC_Sales__c');
        dataCategoryByPermissionset.put('ACC', dataCategoryByGroupName);
        
        return dataCategoryByPermissionset;
    }
    
    public class PermissionSetDataCatagoryClass{
        public String permissionSetName;
        public List<DataCategoriesClass> dataCategories;
        
        public PermissionSetDataCatagoryClass(String permissionSetName, Map<String, String> dataCategoryByGroupName){
            List<DataCategoriesClass> tempDataCategories = new List<DataCategoriesClass>();
            for(String groupName: dataCategoryByGroupName.keySet()){
                tempDataCategories.add(new DataCategoriesClass(groupName, dataCategoryByGroupName.get(groupName)));
            }
            this.permissionSetName = permissionSetName;
            this.dataCategories = tempDataCategories;
        }
    }
    
    public class DataCategoriesClass{
        public String dataCategoryGroupName;
        public List<String> dataCategoryNames;
        
        public DataCategoriesClass(String dataCategoryGroupName, String categoryNamesStr){
            this.dataCategoryGroupName = dataCategoryGroupName;
            if(STRING.ISNOTBLANK(categoryNamesStr)){
                for(String categoryName: categoryNamesStr.split(',')){
                    this.dataCategoryNames.add(categoryName.trim());
                }
            }
        }
    }
    */
}
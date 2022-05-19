public without sharing class LookUpController {
    @AuraEnabled(cacheable=true)
    public static List<sobject> findRecords(String useCase, String searchKey, String objectName, String additionalInfo) {
     //String profileName=[select name from Profile where id=:UserInfo.getProfileId()].Name;
     User userInfo=[select id,Channel__c,Profile.name from user where id=:UserInfo.getUserId() limit 1];
        if (useCase == 'CHANGE_LEAD_OWNER') {
            String searchText = '\'' + String.escapeSingleQuotes(searchKey) + '%\'';
            String channel = additionalInfo;

            // Query
            String fields = 'Id, Name, attuid__c';
            String activeFilter = String.join(new List<String>{'IsActive', '=', 'true'}, ' ');
            String nameFilter = String.join(new List<String>{'AND', 'Name', 'LIKE', searchText}, ' ');
            String attuidFilter = String.join(new List<String>{'AND', 'ATTUID__C', 'LIKE', searchText}, ' ');
            String channelFilter ='';

             if(userInfo.Channel__c !='N/A' || userInfo.Profile.name!=RetailConstants.ARSM_PROFILE_NAME){
             channelFilter = String.isEmpty(channel) ? '' : String.join(new List<String> {'AND', 'Channel__c', '=', '\'' + String.escapeSingleQuotes(channel) + '\''}, ' ');
            }
            
           // String query='';
            String query = String.join(new List<String>{'SELECT', fields, 'FROM', objectName, 'WHERE', activeFilter, nameFilter,channelFilter, 'LIMIT 5'}, ' ');
            List<sobject> queryResult=Database.query(query); 
           if(queryResult.isEmpty() || queryResult==null){
            query = String.join(new List<String>{'SELECT', fields, 'FROM', objectName, 'WHERE',activeFilter,channelFilter, attuidfilter,  'LIMIT 5'}, ' ');
            queryResult=Database.query(query);
           }
            System.debug('Query is --> ' + query);
            
            
            
            return queryResult;
           // return Database.query(query); 
        } else {
            return null;
        }
    }
    // This Method is used to fetch employee from store retaled to lead object: :US 5200 Sushanth Reddy Mile 
    @AuraEnabled(cacheable=false)
    public static List<sObject> findRecordsEmployee( String searchKey, String objectName, String additionalInfo) {
        Store__c homeStore = new Store__c();
        //Fetches store for the logged in user
        List<Employee__c> homeStoreList = [SELECT id, HomeStoreLocation__c, HomeStoreLocation__r.Name,HomeStoreLocation__r.DCIStoreRepActiveCapacity__c
                                           FROM Employee__c 
                                           WHERE User__c = :UserInfo.getUserId()];
        if(homeStoreList.size() > 0 && homeStoreList.get(0).HomeStoreLocation__c != null) {
            homeStore = homeStoreList.get(0).HomeStoreLocation__r;
        }
        String searchText = '\'' + String.escapeSingleQuotes(searchKey) + '%\'';
        String leadId = additionalInfo;
        //Commented the below line to fetch store related to logged in User and not from the lead 
        //String storeId = [SELECT Store__c FROM Lead WHERE Id =: leadId ].Store__c;
        String storeId = homeStore!=null ? homeStore.id : '';
        
        // Query to fetch Employee related to Lead.
        String fields = 'Id, Name,User__r.Name,SFProfileId__c,User__c';
        String activeFilter = String.join(new List<String>{'IsActive__c', '=', 'true'}, ' ');
        String nameFilter = String.join(new List<String>{'AND', 'Name', 'LIKE', searchText}, ' ');          
        String storeFilter = String.isEmpty(storeId) ? '' : String.join(new List<String> {'AND', 'HomeStoreLocation__c', '=', '\'' + String.escapeSingleQuotes(storeId) + '\''}, ' ');
        String profileFilter = String.join(new List<String>{'AND','SFProfileId__c', 'IN', '(\'RSC-MGR\',\'RSC-REP\')'}, ' ');
        
        String query = String.join(new List<String>{'SELECT', fields, 'FROM', objectName, 'WHERE', activeFilter, nameFilter, storeFilter,profileFilter, 'LIMIT 5'}, ' ');
        System.debug('Query is --> ' + query);
        Set<Employee__c> empToReturn = new Set<Employee__c>();
        for(Employee__c e : Database.query(query)){
            empToReturn.add(e);
            system.debug(e.User__c);
        }
        
        // Query to fetch Employees rrelated to Employee Store Retail Junction object.
        String fields1 = 'ID,Employee__c';
        String activeFilter1 = String.join(new List<String>{'Employee__r.IsActive__c', '=', 'true'}, ' ');
        String nameFilter1 = String.join(new List<String>{'AND', 'Employee__r.Name', 'LIKE', searchText}, ' ');         
        String storeFilter1 = String.isEmpty(storeId) ? '' : String.join(new List<String> {'AND', 'Store__c', '=', '\'' + String.escapeSingleQuotes(storeId) + '\''}, ' ');
        String profileFilter1 = String.join(new List<String>{'AND','Employee__r.SFProfileId__c', 'IN', '(\'RSC-MGR\',\'RSC-REP\')'}, ' ');
        
        String query1 = String.join(new List<String>{'SELECT', fields1, 'FROM', 'EmployeeStoreRetail__c', 'WHERE', activeFilter1, nameFilter1, storeFilter1,profileFilter1, 'LIMIT 5'}, ' ');
        system.debug(query1);
        List<Id> empIdsFromEmployeeStoreRetail = new List<Id>();
        //Fetching employes from EmployeeStoreRetail__c object.
        for(EmployeeStoreRetail__c emp :Database.query(query1)){
            empIdsFromEmployeeStoreRetail.add(emp.Employee__c);
        }
        system.debug(empIdsFromEmployeeStoreRetail.size());
        if(empIdsFromEmployeeStoreRetail.size() >  0){
            for(Employee__c e : [SELECT Id,Name,User__r.Name,SFProfileId__c,User__c FROM Employee__c WHERE Id IN : empIdsFromEmployeeStoreRetail]){
                empToReturn.add(e);
            }
        }
        //Converting from set to List since AuraEnabled Doesnt support return type as Set.
        List<Employee__c> emps = new List<Employee__c>(empToReturn);
        return emps; 
        
    } 
    
    // This method is used to check if login users is manager or not :US 5200 Sushanth Reddy Mile  
    @AuraEnabled(cacheable=false)
    public static Boolean isUserManager(String leadIds) { 
        system.debug('leadIds'+leadIds);
        //Checking if profile is System Administrator
        string profileName = [Select Id, Profile.Name from User where Id=: UserInfo.getUserId() ].Profile.Name;
        if(profileName == 'System Administrator' || profileName == 'Retail SM' || profileName == 'Retail ARSM'){
            return true;
        }else{
            return false; 
        }
        /*String storeId = '';
        if(leadIds != null){
            storeId = [SELECT Store__c FROM Lead WHERE Id =: leadIds ].Store__c;
        }
        system.debug('leadIds'+ leadIds);
        system.debug('storeId'+ storeId);
        List<Employee__c> empList = [SELECT Id, Name,User__r.Name,SFProfileId__c,User__c 
                                     FROM Employee__c 
                                     WHERE IsActive__c = true 
                                     AND User__c =: UserInfo.getUserId() AND HomeStoreLocation__c =: storeId AND SFProfileId__c= 'RSC-MGR'];
        system.debug('empList'+ empList.size());
        List<EmployeeStoreRetail__c> employStoreDetails = [Select Id FROM EmployeeStoreRetail__c WHERE Employee__r.IsActive__c= true AND Store__c =: storeId AND SFProfileId__c = 'RSC-MGR'];
        if(empList.size() > 0 || employStoreDetails.size() > 0){
            return true;
        }else{
            return false;
        }*/
    } 
}
/*
* This class will have all the methods for the Lead overview page
* Author: Ravindra Babu Badineedi
*
*/
public with sharing class cLeadHomePageController {
    /*
* This method will return list of leads that are open in last 30 days, today ,next 3days and unresponded notifications.
* Author: Ravindra Babu Badineedi
*
*/
    @AuraEnabled
    public static Map<String,List<Lead>> getLeadCountDetails( ) {
        String storeId = StoreController.getStoreFromCache();
        Map<String,List<Lead>> listViewCountMap = new Map<String,List<Lead>>();
        String profileName = [Select Name from Profile where Id = :userinfo.getProfileId()].Name;
        DateTime currentTime = DateTime.Now().addHours(-0);
        //DateTime currentTime = DateTime.newInstance(2021, 04, 26);
        List<Lead> notificationLeadList = new List<Lead>();
        List<Id> messagingIdList = new List<Id>();
        
        List<Lead> pastDueList = getLeadCount('ExpiryDate__c != TODAY  AND ExpiryDate__c = LAST_N_DAYS:30',profileName);
        List<Lead> dueTodayList = getLeadCount('ExpiryDate__c = TODAY',profileName);
        List<Lead> dueNextList = getLeadCount('ExpiryDate__c != TODAY  AND ExpiryDate__c = NEXT_N_DAYS:3', profileName);
        
        
        
        List<Messaging_Message__c> messagingList =  new List<Messaging_Message__c>();
        if(profileName == 'Retail RSC Rep'){
            messagingList =  [SELECT Id,Lead__c,Lead__r.Name,Lead__r.Owner.Name,Is_Inbound__c,
                              Lead__r.Store__c ,Sent_Date_Time__c
                              FROM Messaging_Message__c
                              WHERE Lead__r.Owner__c=: UserInfo.getUserId() 
                              AND lead__r.store__c=:storeId
                              AND Lead__c != null 
                              AND lead__r.Status != 'Closed'
                              AND Lead__r.LastContactedSMS__c != null 
                              AND Lead__r.LastContactedSMS__c <:currentTime];
        }
        else{
            
            messagingList =  [SELECT Id,Lead__c,Lead__r.Name,Lead__r.Owner.Name,Is_Inbound__c,
                              Lead__r.Store__c ,Sent_Date_Time__c
                              FROM Messaging_Message__c
                              WHERE
                              Lead__r.Store__c = :storeId 
                              AND Lead__c != null 
                              AND lead__r.Status != 'Closed'
                              AND Lead__r.LastContactedSMS__c != null 
                              AND Lead__r.LastContactedSMS__c <:currentTime];
        }
        
        
        
        
        map<Id, Messaging_Message__c> mapInboundDate = new map<Id, Messaging_Message__c>();
        map<Id, Messaging_Message__c> mapOutboundDate = new map<Id, Messaging_Message__c>();      
        
        
        for(Messaging_Message__c msgonLead: messagingList){
            
            if(msgonLead.Is_Inbound__c == true){
                //   system.debug(msgonLead);
                if(mapInboundDate.keySet().contains(msgonLead.Lead__c)){
                    system.debug(mapInboundDate);
                    if(mapInboundDate.get(msgonLead.Lead__c).Sent_Date_Time__c < msgonLead.Sent_Date_Time__c){
                        mapInboundDate.put(msgonLead.Lead__c, msgonLead);
                        //system.debug(mapInboundDate);
                    }
                }
                else{
                    mapInboundDate.put(msgonLead.Lead__c, msgonLead);
                    
                }
            }
            
            
            
            
            if(msgonLead.Is_Inbound__c == false){
                if(mapOutboundDate.keySet().contains(msgonLead.Lead__c)){
                    if(mapOutboundDate.get(msgonLead.Lead__c).Sent_Date_Time__c < msgonLead.Sent_Date_Time__c){
                        mapOutboundDate.put(msgonLead.Lead__c, msgonLead);
                    }
                }
                else{
                    mapOutboundDate.put(msgonLead.Lead__c, msgonLead);
                }
            }
            
            
        }
        
        
        Integer notresponded = 0;
        set<Id> notrespondedLead = new set<ID>();
        for(Id leadId: mapInboundDate.keySet()){
            
            
            if(mapOutboundDate.keySet().contains(leadId)){
                system.debug(mapInboundDate.get(leadId).Sent_Date_Time__c);
                system.debug(mapOutboundDate.get(leadId).Sent_Date_Time__c);
                
                
                if(mapInboundDate.get(leadId).Sent_Date_Time__c > mapOutboundDate.get(leadId).Sent_Date_Time__c){
                    notresponded = notresponded +1;
                    notrespondedLead.add(leadId);
                }
            }
            else{
                notresponded = notresponded +1;
                notrespondedLead.add(leadId);
            }
        }
        
        notificationLeadList = [SELECT Id,Name,LeadSource,MobilePhone,ProductsDiscussed__c, 
                                Status,Store__r.Name,Owner__r.Name  
                                FROM Lead WHERE Id IN: notrespondedLead];
        
        
        listViewCountMap.put('DueTodayCount',dueTodayList);
        listViewCountMap.put('PastDueCount',pastDueList);
        listViewCountMap.put('DueNextCount',dueNextList);
        listViewCountMap.put('NotificationsCount',notificationLeadList);
        
        return listViewCountMap;
    }
    /*
* This method will return current logged in profile
* Author: Ravindra Babu Badineedi
*
*/
    @AuraEnabled
    public static Map<String,String> getLeadOverviewData( ) {
        Map<String,String> leadOverview = new Map<String,String>();
        String profileName = [Select Name from Profile where Id = :userinfo.getProfileId()].Name;
        leadOverview.put('ProfileName',profileName);
        return leadOverview;
        
    }
    /*
* This method will return count of leads based on user logged in
* Author: Ravindra Babu Badineedi
*
*/
    public static List<Lead> getLeadCount(String expiryDate, String profileName){
        String storeId = StoreController.getStoreFromCache();
        UserCurrentLocation__c userCurrLoc = UserCurrentLocation__c.getInstance(UserInfo.getUserId());
        String currentStoreId = userCurrLoc.Store__c;
        String userId = UserInfo.getuserId();
        List<Lead> leadListCount  = new List<Lead>();
        String query = 'SELECT Id,Name,LeadSource,MobilePhone,ProductsDiscussed__c, Status,Store__r.Name,Owner__r.Name FROM Lead  WHERE IsConverted = false AND '+ expiryDate +' AND Status != \'Closed\''; 
        
        if(profileName =='Retail SM' || profileName =='Retail ARSM'){
            query = query +' AND Store__c=:storeId';
            leadListCount  = Database.query(query);
            
        }
        
        System.debug('profileName-----'+profileName);
        if(profileName == 'Retail RSC Rep'){
            System.debug('profileName-----+++++++'+profileName);
            query = query +' AND Owner__c =: userId' +' AND Store__c=:storeId';
            leadListCount  = Database.query(query);
        }
        
        System.debug('leadListCount'+leadListCount); 
        
        return leadListCount;
    }
    @AuraEnabled
    public static Map<string,integer> getListViewCount( ) {
        String storeId = StoreController.getStoreFromCache();
        Map<string,integer>ListViewCountMap = new Map<string,integer>();
        String profileName = [Select Name from Profile where Id =: userinfo.getProfileId()].Name;
        Integer capturedCount,contactedCount,connectedCount,closedCount;
        date currDate = date.today();
        date newDate = currDate.addDays(-30);
        
        string homestoreId = getStoreLocationId(userinfo.getuserid());
      
        
        
        List<Employee__c> lstEmp =new List<Employee__c>();
        
        if(profileName.contains('Retail SM')){
            capturedCount = [SELECT Count() FROM Lead WHERE  Status = 'Captured'  AND LeadSource!='Digital Check-in'  AND store__c =: homestoreId];
            contactedCount = [SELECT Count() FROM Lead WHERE  Status =  'Contacted'   AND LeadSource!='Digital Check-in' AND store__c =: homestoreId];
            connectedCount = [SELECT Count() FROM Lead WHERE  Status ='Connected'  AND LeadSource!='Digital Check-in' AND store__c =: homestoreId ];
            closedCount = [SELECT Count() FROM Lead WHERE  Status = 'Closed'  AND LeadSource!='Digital Check-in'  AND store__c =: homestoreId AND CloseDate__c  = LAST_N_DAYS:30]; 
            
        }
        else if(profileName.contains('Retail RSC Rep')){
            capturedCount = [SELECT Count() FROM Lead WHERE  Status = 'Captured'  AND LeadSource!='Digital Check-in'  AND store__c =: homestoreId  AND Owner__c =: UserInfo.getuserId() ];
            contactedCount = [SELECT Count() FROM Lead WHERE  Status =  'Contacted'  AND LeadSource!='Digital Check-in' AND store__c =: homestoreId  AND Owner__c =: UserInfo.getuserId() ];
            connectedCount = [SELECT Count() FROM Lead WHERE  Status ='Connected'  AND LeadSource!='Digital Check-in' AND store__c =: homestoreId  AND Owner__c =: UserInfo.getuserId()];
            closedCount = [SELECT Count() FROM Lead WHERE  Status = 'Closed'  AND LeadSource!='Digital Check-in'  AND store__c =: homestoreId AND CloseDate__c  = LAST_N_DAYS:30  AND Owner__c =: UserInfo.getuserId()]; 
        }
        else if(profileName.contains('Retail ARSM')){
            /*   list<EmployeeStoreRetail__c> empStoreList = [SELECT ID,Name,Store__c,User__c FROM EmployeeStoreRetail__c  
WHERE Employee__r.User__c =:UserInfo.getUserId() ];
set<Id> storeid = new set<Id>();
for(EmployeeStoreRetail__c esr: empStoreList){
storeid.add(esr.Store__c);
}*/
            
            capturedCount = [SELECT Count() FROM Lead 
                             WHERE  Status = 'Captured'   AND LeadSource!='Digital Check-in'
                             AND store__c =: homestoreId];
            contactedCount = [SELECT Count() FROM Lead 
                              WHERE  Status =  'Contacted'  AND LeadSource!='Digital Check-in'
                              AND store__c =: homestoreId];
            connectedCount = [SELECT Count() FROM Lead 
                              WHERE  Status ='Connected'  AND LeadSource!='Digital Check-in'
                              AND store__c =: homestoreId];
            closedCount = [SELECT Count() FROM Lead 
                           WHERE  Status = 'Closed'   AND LeadSource!='Digital Check-in'
                           AND CloseDate__c >=:newDate    
                           AND store__c =: homestoreId]; 
        }
        else{
            
            capturedCount = [SELECT Count() FROM Lead WHERE  Status = 'Captured'  AND LeadSource!='Digital Check-in' AND store__c =: homestoreId ];
            contactedCount = [SELECT Count() FROM Lead WHERE  Status =  'Contacted'  AND LeadSource!='Digital Check-in' AND store__c =: homestoreId ];
            connectedCount = [SELECT Count() FROM Lead WHERE  Status ='Connected' AND LeadSource!='Digital Check-in'  AND store__c =: homestoreId ];
            closedCount = [SELECT Count() FROM Lead WHERE  Status = 'Closed'   AND LeadSource!='Digital Check-in' AND store__c =: homestoreId AND CloseDate__c  = LAST_N_DAYS:30]; 
            
        }
        
        
       
        ListViewCountMap.put('capturedCount',capturedCount);
        ListViewCountMap.put('contactedCount',contactedCount);
        ListViewCountMap.put('connectedCount',connectedCount);
        ListViewCountMap.put('closedCount',closedCount);
        
        return ListViewCountMap;
        
    }
    
// This method will return StoreNames(Wrapper Class) . It contains either all Store names or Single Store Location
  // Author: Narasimha Rao  Story : SPTSLSATT-580 Date : 11/11/2021
   
  
    @AuraEnabled
    public static StoreNames getStoreLocation(Id userId){
        system.debug('userId--->'+userId);
      //Storing the List of Store Names 
        list<string> storeList = new list<string>();
        String UserCurrentLocationStore;
        if(userId !=null || userId!=''){            
            Employee__c employee = [SELECT id, HomeStoreLocation__c, HomeStoreLocation__r.Name, NumberOfAssociatedStores__c
                                    FROM Employee__c 
                                    WHERE User__c = :userId LIMIT 1];
            system.debug('employee'+employee);

            //Getting current logged in user profile
            String profileId = UserInfo.getProfileId();
                
            //Getting profile information
            Profile profile = [SELECT Id, Name FROM Profile WHERE Id =:profileId];
                       
            if(employee != null && employee.NumberOfAssociatedStores__c != null && employee.NumberOfAssociatedStores__c > 1){ 
                
                //Getting current logged in user name
                String Name = UserInfo.getName();   
        
               //Getting custom setting data based on logged in user.
                UserCurrentLocation__c uc =  [SELECT StoreName__c FROM UserCurrentLocation__c where SetupOwner.Name=:Name limit 1];                
               
                list<EmployeeStoreRetail__c>  empstoreList = [SELECT Id, Name, Employee__c, Store__r.Name FROM EmployeeStoreRetail__c where Employee__c =:employee.id];
                
                if(empstoreList != null){
                    
                    for(EmployeeStoreRetail__c empstr:empstoreList){                    

                        storeList.add(empstr.Store__r.Name);
                               
                    }
                   
                }
                try{
                    //Preparing wrapper class
                    StoreNames sn = new StoreNames();
                    sn.CurrentLocationstorename = uc.StoreName__c.toUpperCase();
                    sn.StoreRetailStores = storeList;
                    sn.CurrentProfileName = profile.Name;
                                            
                    system.debug('Wrapper result==>' +sn);

                    //Returning StoreName
                    return sn;  
                }
                catch(Exception e){
                    throw new AuraHandledException(e.getMessage()); 
                }
               
                
            }
            else if(employee != null && employee.NumberOfAssociatedStores__c != null && employee.NumberOfAssociatedStores__c == 1){
                if(employee.HomeStoreLocation__c != null) {
                    try{
                        //Preparing wrapper class
                        StoreNames sn = new StoreNames();
                        sn.CurrentLocationstorename = employee.HomeStoreLocation__r.Name.toUpperCase();
                        sn.CurrentProfileName = profile.Name;
                              
                        system.debug('Wrapper result==>' +sn);
    
                        //Returning StoreName
                        return sn;  
                    }
                    catch(Exception e){
                        throw new AuraHandledException(e.getMessage()); 
                    }
                }
            }
        }
            return null;
    }
    
    //Method to update the UserCurrentLocation custom setting with Selected Store Name
  //Author: Narasimha Rao  Story : SPTSLSATT-580 Date : 11/11/2021
      
    @AuraEnabled
    public static void SelectedStoreUpdate(string selectedStore){
         try {

            //Getting current logged in user name
            String Name = UserInfo.getName();   
        
           
            UserCurrentLocation__c uc =  [SELECT StoreName__c FROM UserCurrentLocation__c where SetupOwner.Name=:Name limit 1];
            store__c st = [select id,GeoLocation__Latitude__s,GeoLocation__Longitude__s from store__c where name=:selectedStore];
            uc.StoreName__c = selectedStore;
            uc.store__c=st.id;
            uc.Latitude__c=st.GeoLocation__Latitude__s;
            uc.Longitude__c=st.GeoLocation__Longitude__s;
            update uc;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
     @AuraEnabled
    public static String getStoreLocationId(Id userId){
        List<Employee__c> employeelst = new List<Employee__c>();
       employeelst = [SELECT id, HomeStoreLocation__c, HomeStoreLocation__r.Name, NumberOfAssociatedStores__c
                                FROM Employee__c 
                                WHERE User__c = :userId LIMIT 1];
        if(employeelst.size() > 0 && employeelst[0].NumberOfAssociatedStores__c != null && employeelst[0].NumberOfAssociatedStores__c > 1){            
            UserCurrentLocation__c userCurrLoc = UserCurrentLocation__c.getInstance(userId);
            if(userCurrLoc.id != null && userCurrLoc.StoreName__c != null) {
                return userCurrLoc.Store__c;
            }
        }
        else if(employeelst.size() > 0 && employeelst[0].NumberOfAssociatedStores__c != null && employeelst[0].NumberOfAssociatedStores__c == 1){
            if(employeelst[0].HomeStoreLocation__c != null) {
                return employeelst[0].HomeStoreLocation__c;
            }
        }
        return null;
    }
   
    
    @AuraEnabled
    public static Id getDefaultRT(String ObjName){
        Schema.DescribeSObjectResult dsr;
        dsr = Lead.SObjectType.getDescribe();
        Schema.RecordTypeInfo defaultRecordType;
        for(Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) {
            if(rti.isDefaultRecordTypeMapping()) {
                defaultRecordType = rti;
                return rti.getRecordTypeId();
            }
        }
        return null;
    }
    // To return the list views count, Id, name
    
    @AuraEnabled
    public static List<listviewWrapper> getListViewData() {
     
        String storeId = StoreController.getStoreFromCache();
        String profileName = [Select Name from Profile where Id = :userinfo.getProfileId()].Name;
        String consumerRecordTye=System.Label.ConsumerRecordType;
        String smbRecordType=System.Label.SMBRecordType;
        String digitalCheckInRecordType=System.Label.Lead_Digital_Check_In_Recordtype_Name  ;
        String prospectRecordType=System.Label.Prospect_Record_type;
        Integer pastDueCount=0,dueTodayCount=0,allLeadsMGR=0,allLeads=0,smallBusinessLeads=0,smallBusinessLeadsMGR=0,marketingLeadsMGR=0,marketingLeads=0,priorityLeadsMGR=0,priorityLeads=0,customerInteractionLeads=0;
        
        
        
        
        List<String> viewnames = new List<String>();
        
        
        if(profileName.contains('Retail SM')){
            dueTodayCount = [SELECT Count() FROM Lead WHERE IsConverted = false AND ExpiryDate__c  <= TODAY AND Status != 'Closed' AND  RecordType.developerName!=:digitalCheckInRecordType AND store__c=:storeId ]; 
            allLeadsMGR =  [Select count() FROM Lead where  RecordType.developerName!=:digitalCheckInRecordType and  RecordType.developerName!=:prospectRecordType and Status!='Closed' and store__c=:storeId  ];
            smallBusinessLeadsMGR =[Select count() FROM Lead where  Status!='Closed' and (LeadSource='Business' OR LeadSource='Customer Interaction - Business') and store__c=:storeId 
                                    and RecordType.developerName=: smbRecordType];
            marketingLeadsMGR=[Select count() FROM Lead where  Status!='Closed' and  LeadSource='Campaign' and RecordType.developerName=: consumerRecordTye and store__c=:storeId  ];
            priorityLeadsMGR=[select count() from lead where  (RecordType.developerName=: consumerRecordTye or RecordType.developerName=: smbRecordType)  and store__c=:storeId 
                              and rating ='Priority' ];
            customerInteractionLeads=[Select count() FROM Lead where  Status!='Closed' and  (LeadSource='Customer Interaction'  OR  LeadSource='Customer Interaction - Business') and store__c=:storeId  ];
            
            viewnames = new List<String>{
                'ContactTodayMGR' , 
                    'AllLeadsMGR',
                    'SmallBusinessLeadsMGR', 
                    'MarketingLeadsMGR',
                    'PriorityLeadsMGR',
                    'CustomerInteraction'};
                        } 
        else if(profileName.contains('Retail RSC Rep') ){
            pastDueCount = [SELECT Count() FROM Lead WHERE IsConverted = false AND  ExpiryDate__c <= TODAY  AND Status != 'Closed' AND RecordType.developerName!=:digitalCheckInRecordType AND store__c=:storeId ]; 
            allLeads =  [Select count() FROM Lead where  RecordType.developerName!=:digitalCheckInRecordType and RecordType.developerName!=:prospectRecordType and Status!='Closed' AND store__c=:storeId ];
            smallBusinessLeads =[Select count() FROM Lead where  Status!='Closed' and (LeadSource='Business' OR LeadSource='Customer Interaction - Business') 
                                 and RecordType.developerName=: smbRecordType AND store__c=:storeId ];
            marketingLeads=[Select count() FROM Lead where  Status!='Closed' and  LeadSource='Campaign' and RecordType.developerName=: consumerRecordTye and store__c=:storeId  ];
            
            priorityLeads=[select count() from lead where Status!='Closed' and (RecordType.developerName=: consumerRecordTye or RecordType.developerName=: smbRecordType) 
                           and rating ='Priority' and store__c=:storeId  ];
            customerInteractionLeads=[Select count() FROM Lead where  Status!='Closed' and  (LeadSource='Customer Interaction'  OR  LeadSource='Customer Interaction - Business') and store__c=:storeId  ];
            
            viewnames = new List<String>{
                'ContactToday', 
                    'AllLeads',
                    'SmallBusinessLeads',
                    'MarketingLeads',
                    'PriorityLeads', 
                    'CustomerInteraction'};
                        } 
        else if(profileName.contains('Retail ARSM')){
            
             pastDueCount = [SELECT Count() FROM Lead WHERE IsConverted = false AND  ExpiryDate__c <= TODAY  AND Status != 'Closed' AND RecordType.developerName!=:digitalCheckInRecordType AND store__c=:storeId ]; 
            allLeads =  [Select count() FROM Lead where  RecordType.developerName!=:digitalCheckInRecordType and RecordType.developerName!=:prospectRecordType and Status!='Closed' AND store__c=:storeId ];
            smallBusinessLeads =[Select count() FROM Lead where  Status!='Closed' and (LeadSource='Business' OR LeadSource='Customer Interaction - Business') 
                                 and RecordType.developerName=: smbRecordType AND store__c=:storeId ];
            marketingLeads=[Select count() FROM Lead where  Status!='Closed' and  LeadSource='Campaign' and RecordType.developerName=: consumerRecordTye and store__c=:storeId  ];
            
            priorityLeads=[select count() from lead where Status!='Closed' and (RecordType.developerName=: consumerRecordTye or RecordType.developerName=: smbRecordType) 
                           and rating ='Priority' and store__c=:storeId  ];
            customerInteractionLeads=[Select count() FROM Lead where  Status!='Closed' and  (LeadSource='Customer Interaction'  OR  LeadSource='Customer Interaction - Business') and store__c=:storeId  ];
           
            
            viewnames = new List<String>{
                'ContactToday', 
                    'AllLeads',
                    'SmallBusinessLeads',
                    'MarketingLeads',
                    'PriorityLeads', 
                    'CustomerInteraction'};
                        } 
        else{
            
            pastDueCount = [SELECT Count() FROM Lead WHERE IsConverted = false AND  ExpiryDate__c <= TODAY  AND Status != 'Closed' AND RecordType.developerName!=:digitalCheckInRecordType AND store__c=:storeId ]; 
            allLeads =  [Select count() FROM Lead where  RecordType.developerName!=:digitalCheckInRecordType and RecordType.developerName!=:prospectRecordType and Status!='Closed' AND store__c=:storeId ];
            smallBusinessLeads =[Select count() FROM Lead where  Status!='Closed' and (LeadSource='Business' OR LeadSource='Customer Interaction - Business') 
                                 and RecordType.developerName=: smbRecordType AND store__c=:storeId ];
            marketingLeads=[Select count() FROM Lead where  Status!='Closed' and  LeadSource='Campaign' and RecordType.developerName=: consumerRecordTye and store__c=:storeId  ];
            
            priorityLeads=[select count() from lead where Status!='Closed' and (RecordType.developerName=: consumerRecordTye or RecordType.developerName=: smbRecordType) 
                           and rating ='Priority' and store__c=:storeId  ];
            customerInteractionLeads=[Select count() FROM Lead where  Status!='Closed' and  (LeadSource='Customer Interaction'  OR  LeadSource='Customer Interaction - Business') and store__c=:storeId  ];
            
            
            
            viewnames = new List<String>{
                'ContactToday', 
                    'AllLeads',
                    'SmallBusinessLeads',
                    'MarketingLeads',
                    'PriorityLeads', 
                    'CustomerInteraction'};
                        } 
        
        
        List<Listview> lstListView = [select Id, Name,developername from listview where sobjecttype = 'Lead' and developername IN: viewnames ];
        list<listviewWrapper> lstWrapper = new list<listviewWrapper>();
        for(Listview lv : lstListView){
            listviewWrapper wrapper = new listviewWrapper(); 
            wrapper.viewLabel = lv.Name;
            wrapper.viewId = lv.Id;
            if(lv.developername == 'ContactToday'){
                wrapper.viewCount = pastDueCount;
            }
            if(lv.developername == 'ContactTodayMGR' ){
                wrapper.viewCount = dueTodayCount;
            }
            if(lv.developername == 'AllLeadsMGR'){
                wrapper.viewCount = allLeadsMGR;
            }
            if(lv.developername == 'AllLeads'){
                wrapper.viewCount = allLeads;
            }
            if(lv.developername == 'SmallBusinessLeadsMGR'){
                wrapper.viewCount = smallBusinessLeadsMGR;
            }
            if(lv.developername == 'SmallBusinessLeads'){
                wrapper.viewCount = smallBusinessLeads;
            }
            if(lv.developername == 'MarketingLeadsMGR'){
                wrapper.viewCount = marketingLeadsMGR;
            }
            if(lv.developername == 'PriorityLeadsMGR'){
                wrapper.viewCount = priorityLeadsMGR;
            }
            if(lv.developername == 'PriorityLeads'){
                wrapper.viewCount = priorityLeads;
            }
            if(lv.developername == 'CustomerInteraction'){
                wrapper.viewCount = customerInteractionLeads;
            }
            if(lv.developername == 'MarketingLeads'){
                wrapper.viewCount = marketingLeads;
            }
            lstWrapper.add(wrapper);
            
        }
        return lstWrapper;
    }
    
    
    public class listviewWrapper{
        @AuraEnabled public String viewLabel{get;set;}
        @AuraEnabled public String viewId{get;set;}
        @AuraEnabled public Integer viewCount{get;set;}
    } 

    //Using this class to store list of Store Names, Current Store Name , Current Profile Name  
   // Author: Narasimha Rao  Story : SPTSLSATT-580 Date : 11/11/2021
     public class StoreNames{
        
        @AuraEnabled
        public string CurrentLocationstorename {set;get;}
        
        @AuraEnabled
        public list<string> StoreRetailStores {set;get;}

        @AuraEnabled
        public string CurrentProfileName {set;get;}
    }
    
}
//rb518a
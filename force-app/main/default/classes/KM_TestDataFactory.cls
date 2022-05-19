@isTest
public with sharing class KM_TestDataFactory {
    
    public static final String PROFILE_NAME_KM_AUTHOR = 'Minimum Access Admin';
    public static final String PROFILE_NAME_KM_AGENT= 'Minimum Access Agent';
    public static final String PROFILE_NAME_SYS_ADMIN = 'System Administrator';

    
    public static GroupMember addUserToGroup(Id userId, String groupDeveloperName) {
        Group memberGroup = [SELECT Id, developerName From Group Where developerName = :groupDeveloperName];
        GroupMember gm = new GroupMember();
        gm.UserOrGroupId = userId;
        gm.GroupId = memberGroup.Id;
        insert gm;
        return gm;
    }
    
    public static Profile getProfileByName(String profileName) {
     	List<Profile> profileList = [SELECT id from Profile WHERE name  = :profileName];   
        if (profileList.isEmpty()) {
            return null;
        } else {
            return profileList[0];
        }
    }
    
    public static BWKMKnowledgeFeatureAccessibility__c getFeatureAccessibility(String featureName, String filterType, String filterValue,Boolean isVisible){
        BWKMKnowledgeFeatureAccessibility__c access = new BWKMKnowledgeFeatureAccessibility__c();
        access.Accessibility_Filter_Type__c = filterType;
        access.Filter_Value__c= filterValue;
        access.Feature_Name__c = featureName;
        access.Public_Feedback_Visible__c = isVisible;
            return access;
    }
    
    
    public static User createKnowledgeUser(Id profileId, String userNameBase) {
        String timeStamp = String.valueOf(DateTime.now());
        timestamp = timestamp.replaceAll('\\D', '');
        Integer randomNum = Integer.valueOf(math.rint(math.random()*1000000)); 
        User u = new User(
                LastName = 'ABCTestUser',
                Email = 'ABCTestUser@test.com',
                Username = userNameBase + '.testSandbox' + String.valueOf(randomNum),
                CompanyName = 'TEST',
            	UserPermissionsKnowledgeUser = TRUE,
				Title = 'title',
                Alias = 'talias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                profileId = profileId,
                isActive = true
                
                
            ); 
   		return u;
    }
    
     public static User createAuthorUser(String attUID) {
        Profile p = getProfileByName(PROFILE_NAME_KM_AUTHOR);
        User authorUser = createKnowledgeUser(p.iD, 'attKMAuthorUser@bademail.com');
        authorUser.attUId__c = attUID;
        authorUser.FederationIdentifier = attUID ;
        insert authorUser;
        return authorUser;
        
    }
    
    public static User createAuthorUser() {
        Profile p = getProfileByName(PROFILE_NAME_KM_AUTHOR);
        User authorUser = createKnowledgeUser(p.iD, 'attKMAuthorUser@bademail.com');
        insert authorUser;
        return authorUser;
        
    }
    
    public static User createSysAdminUser() {
        Profile p = getProfileByName(PROFILE_NAME_SYS_ADMIN);
        User adminUser = createKnowledgeUser(p.iD, 'attKMSysAdminUser@bademail.com');
       
        insert adminUser;
        return adminUser;
        
    }
    
    
     public static User createAgentUser() {
        Profile p = getProfileByName(PROFILE_NAME_KM_AGENT);
        User agentUser = createKnowledgeUser(p.iD, 'attKMAgentUser@bademail.com');
        insert agentUser;
        return agentUser;
        
    }
    
    public static User createContentSponsorUser(String contentSponsor) {
    	List<User> userList = [SELECT Id, attUId__c, FederationIdentifier FROM USER WHERE attUId__c = :ContentSponsor and FederationIdentifier =  :ContentSponsor ];
        User contentUser;
        if (userList.isEmpty()) {
            contentUser = createAuthorUser(ContentSponsor); 
            
            System.debug('No user found for ' + ContentSponsor + '; new User Created: ' + contentUser);
            
        } else {
        	contentUser = userList[0];
            System.debug('User found for ' + ContentSponsor + ': ' + contentUser);

        }
        return contentUser;
        
    }
    
    public static Knowledge__kav getKnowledKav(Date bwnewsstartdate, String title, String urlname,Boolean doInsert, String ContentSponsor){
       Knowledge__kav  knowledgeKav = new Knowledge__kav(
           BW_Is_Urgent__c =  true,
           Title = title,
           UrlName = urlname,
           ContentSponsor__c = ContentSponsor
       );
        
       createContentSponsorUser(ContentSponsor); 
      
        
       if(doInsert){
           insert knowledgeKav;
           Knowledge__kav knw = [select KnowledgeArticleId from Knowledge__kav where Id = :knowledgeKav.Id];
           KbManagement.PublishingService.publishArticle(knw.KnowledgeArticleId, true);
       }
       return knowledgeKav;
   }
   
    public static Knowledge__kav getKnowledKavdata(Date bwnewsstartdate, String title, String urlname,Boolean doInsert,String ContentSponsor){
       Knowledge__kav  knowledgeKav = new Knowledge__kav(
           BW_Is_Urgent__c =  true,
           Title = title,
           BW_FrontLine_Focus__c=True,
           UrlName = urlname,
           ContentSponsor__c = ContentSponsor,
           MyCSPArticleName__c='testCSPArticleName'
       );
       
       createContentSponsorUser(ContentSponsor); 
        
       if(doInsert){
           insert knowledgeKav;
           Knowledge__kav knw = [select KnowledgeArticleId from Knowledge__kav where Id = :knowledgeKav.Id];
           KbManagement.PublishingService.publishArticle(knw.KnowledgeArticleId, true);
       }
       return knowledgeKav;
   }
    public static Knowledge__kav getKnowledKavDataForDeleteArchiveBat(Date bwnewsstartdate, Date retentiondate, String title, String urlname,Boolean doInsert,String ContentSponsor){
       Knowledge__kav  knowledgeKav = new Knowledge__kav(
           BW_Is_Urgent__c =  true,
           RetentionDate__c = retentiondate,
           Title = title,
           BW_FrontLine_Focus__c=True,
           UrlName = urlname,
           ContentSponsor__c = ContentSponsor
       );
        
      createContentSponsorUser(ContentSponsor);  
       if(doInsert){
           insert knowledgeKav;
           Knowledge__kav knw = [select KnowledgeArticleId from Knowledge__kav where Id = :knowledgeKav.Id];
           KbManagement.PublishingService.publishArticle(knw.KnowledgeArticleId, true);
           KbManagement.PublishingService.archiveOnlineArticle(knw.KnowledgeArticleId, system.now());
       }
       return knowledgeKav;
   }
    public static Knowledge__kav getKnowledKavTest(Id recordtypename, DateTime bwnewsstartdate,string title, String urlname,Boolean doInsert,String ContentSponsor){
      
        Knowledge__kav  knowledgeKav = new Knowledge__kav(
           BW_Is_Urgent__c =  true,
           RecordTypeId=recordtypename,
           BW_News_Start_Date__c=bwnewsstartdate,
           BW_News_End_Date__c = bwnewsstartdate.addMinutes(1),
           Title = title,
           UrlName = urlname,
           BW_Home_Page_Display__c = true,
           BW_Link_Center_Article__c = true,
           ContentSponsor__c = ContentSponsor
       );
       createContentSponsorUser(ContentSponsor); 
        
       if(doInsert){
           insert knowledgeKav;
           Knowledge__kav knw = [select KnowledgeArticleId from Knowledge__kav where Id = :knowledgeKav.Id];
           KbManagement.PublishingService.publishArticle(knw.KnowledgeArticleId, true);
       }
       return knowledgeKav;
    }
    
    public static Knowledge__kav getKnowledKavfronlinefocus(Id recordtypename, DateTime bwnewsstartdate,string title, String urlname,Boolean doInsert,String ContentSponsor){
       Knowledge__kav  knowledgeKav = new Knowledge__kav(
           BW_Is_Urgent__c =  true,
           RecordTypeId=recordtypename,
           BW_News_Start_Date__c=bwnewsstartdate,
           BW_News_End_Date__c = bwnewsstartdate.addMinutes(1),
           Title = title,
           UrlName = urlname,
           BW_Home_Page_Display__c = true,
           BW_FrontLine_Focus__c= true,
           ContentSponsor__c = ContentSponsor
       );
       
       createContentSponsorUser(ContentSponsor);  
       if(doInsert){
           insert knowledgeKav;
           Knowledge__kav knw = [select KnowledgeArticleId from Knowledge__kav where Id = :knowledgeKav.Id];
           KbManagement.PublishingService.publishArticle(knw.KnowledgeArticleId, true);
       }
       return knowledgeKav;
    }
    public static BWMarketMaster__c getBWMarketMaster() {
        return new BWMarketMaster__c(
            MarketPromotedSearchTerm__c = 'SEARCH TERM',
            MYCSPMarketId__c = '123ACVV'
        );
    }
}
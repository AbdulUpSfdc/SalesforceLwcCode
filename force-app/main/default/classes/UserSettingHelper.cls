public with sharing class UserSettingHelper {

    public static User_Setting__c getUserSetting(String userId) {
    	List<User_Setting__c> userSettingList = [SELECT Id, UserId__c, Article_Search_JSON__c FROM User_Setting__c WHERE UserId__c = :userId];
        if (userSettingList.isEmpty()) {
            return null;
        } else {
            return userSettingList[0];
        }
    }
    
    @future
    public static void upsertUserSetting(String userId, 
    			String searchText,
                        String sortBy,
                        String filterBy,
                        Integer currentPage,
                        String startDate,
                                String endDate) {
     	 ArticleSearchWrapper searchWrapper = new ArticleSearchWrapper(searchText, sortBy, filterBy, currentPage,
                        											startDate, endDate);
        upsertUserSetting(userId, searchWrapper);
      
    }
    
    public static User_Setting__c upsertUserSetting(String userId, ArticleSearchWrapper searchWrapper) {
    	User_Setting__c userSetting;
        userSetting = getUserSetting(userId);
        Boolean newUserSetting = false;
        if (userSetting != null) {
       		userSetting.Article_Search_JSON__c = JSON.serialize(searchWrapper);   
            update userSetting;
        } else {
   			userSetting = new User_Setting__c();
            userSetting.userId__c = userId;
            userSetting.Article_Search_JSON__c = JSON.serialize(searchWrapper);
            userSetting.user__c = userId;
            insert userSetting;
            newUserSetting = true;
        }  
        System.debug('New User setting ' + newUserSetting  + '; ' + userSetting);
        return userSetting;
    }
    
   
    
}
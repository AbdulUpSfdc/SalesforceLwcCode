public without sharing class RetailHomePageController {

    @AuraEnabled
    public static RetailDTO.LoggedInUserInfoDTO getLoggedInUserInfo(){
        RetailDTO.LoggedInUserInfoDTO userInfoDTO = new RetailDTO.LoggedInUserInfoDTO();
        try{
            String DueTodyListView = 'AllLeads';
            String profileName;
            RetailCustomSetting__c mgrDueTodayLabel = RetailCustomSetting__c.getInstance('DueTodayListViewManager');
            RetailCustomSetting__c repDueTodayLabel = RetailCustomSetting__c.getInstance('DueTodayListViewRep');
            //SPTSLSATT-1236
            User currentUser = [SELECT Id, Channel__c FROM User WHERE Id =: userInfo.getUserId() LIMIT 1];
            List<Profile> userProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId()];
            //SPTSLSATT-1236
            if(currentUser !=null && currentUser.Channel__c !=null){
                userInfoDTO.channel=currentUser.Channel__c;
            }
            if(userProfile.size()>0)
                profileName = userProfile[0].Name;
            
            if(profileName!=null && (profileName.contains('Retail SM') || profileName.contains('System Administrator'))){	
                if(mgrDueTodayLabel!=null && mgrDueTodayLabel.KeyValue__c!=null)
                    DueTodyListView = mgrDueTodayLabel.KeyValue__c;
            }else{
                if(repDueTodayLabel!=null && repDueTodayLabel.KeyValue__c!=null)
                    DueTodyListView = repDueTodayLabel.KeyValue__c;
            }
            userInfoDTO.profileName = profileName;
            userInfoDTO.dueTodayListViewName = DueTodyListView;
            System.debug(userInfoDTO);
           
        }catch(Exception e){
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage()); 
        }

        return userInfoDTO;  
  } 
  @AuraEnabled
  public static boolean getIsCurrentlyAvailable(){
      
      String RSCRep = '';
      RSCRep = RetailConstants.REP_PROFILE_NAME;
      String profileName='';
      List<Profile> userProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId()];
          if(userProfile.size()>0)
              profileName = userProfile[0].Name;
     List<EmployeeStoreRetail__c> empStore = [Select Id,IsCurrentlyAvailable__c,lastmodifieddate,createddate from EmployeeStoreRetail__c where  
                                               User__c=:userinfo.getUserId() and HomeStore__c = true];
      
      
      user u = [select id, lastlogindate,My_Availability_Status__c from user where id=:userinfo.getUserId()];
          
      List<loginhistory> loginhist = [select id, userid, logintime,status from loginhistory where userid=:userinfo.getUserId() and logintime = today order by logintime desc];
      if(profileName.contains(RSCRep) && !loginhist.isEmpty()
        && (loginhist.size() == 1 || (loginhist.size() > 1 && string.valueOf(u.lastlogindate) != u.My_Availability_Status__c)))
      {
         return true;
      }
      
      return empStore != null?empStore[0].IsCurrentlyAvailable__c:false;
  }
  @AuraEnabled
  public static void updateIsCurrentlyAvailable(boolean currentlyAvailable){
    if(currentlyAvailable){
        DCIController.changeRepStatus(DCIConstants.ONLINE);
    }else{
        DCIController.changeRepStatus(DCIConstants.OFFLINE);    
    }
    user u = [select id, lastlogindate,My_Availability_Status__c from user where id=:userinfo.getUserId()];
    u.My_Availability_Status__c = string.valueOf(u.lastlogindate);
    //update u;
  }

    
    @AuraEnabled
    public static void updateDCIPresenceStatus(){
        List<Profile> userProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId()];
        String profileName;
        String RSCRep = '';
        String RscMgr ='';
        RscMgr = RetailConstants.SM_PROFILE_NAME;
        RSCRep = RetailConstants.REP_PROFILE_NAME;
        if(userProfile.size()>0)
            profileName = userProfile[0].Name;
        
        if(profileName!=null && (profileName.contains(RSCRep) || profileName.contains(RSCMgr ) || profileName.contains('System Administrator'))){
            List<EmployeeStoreRetail__c> empStore = [Select Id from EmployeeStoreRetail__c where  
                                                     User__c=:userinfo.getUserId() and HomeStore__c = true];
            system.debug('--emp store'+empStore);
            if(empStore!= null && !empStore.isEmpty()){
                empStore[0].DCIPresenceStatus__c = 'Busy';
                update empStore[0];
            }
        }
    }

    @AuraEnabled
    public static boolean getCurrentUserforWalkinCustomer()
    {
        String RSCRep = '';
        String RscMgr ='';
        RscMgr = RetailConstants.SM_PROFILE_NAME;
        RSCRep = RetailConstants.REP_PROFILE_NAME;
        List<Profile> userProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId()];
        String profileName = '';
        if(userProfile.size()>0)
        {
            profileName = userProfile[0].Name;
        }
        
        if(profileName!=null && (profileName.contains(RscMgr) || profileName.contains(RSCRep) || profileName.contains('System Administrator')))
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    @AuraEnabled(cacheable=true) 
    public static String getInactiveTime(){
        String inActivityTime;
        String DCI_INACTIVE_TIME = 'DCIRepAllowedIdleTime';
        inActivityTime = RetailUtil.getRetailCustomSettings(DCI_INACTIVE_TIME); 
        return inActivityTime;
    } 

}
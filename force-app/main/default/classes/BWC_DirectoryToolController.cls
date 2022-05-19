public class BWC_DirectoryToolController {
    
    public static final String ATT_ID_EMPTY = 'ATT ID is empty for the User';
    public static final String EMPLOYEE_NOT_FOUND = 'Employee Record not found';
    public static final String ERR_CODENAME = 'Code Name is Required';
    
    @AuraEnabled
    public static DirectoryToolWrapper initialize(){
        try{
            User currentUser = currentUserRecord();
            if(String.isEmpty(currentUser.ATTUID__c)){
                throw new BWC_Exception(ATT_ID_EMPTY);
            }
            Employee__c employeeRecord = currentEmployeeRecord(currentUser.ATTUID__c);
            if(employeeRecord == null){
                throw new BWC_Exception(EMPLOYEE_NOT_FOUND);
            }
            DirectoryToolWrapper dtInfo = new DirectoryToolWrapper();
            dtInfo.employee = employeeRecord;
            dtInfo.userRecord = currentUser;
            dtInfo.channels = [SELECT Channel_Id__c, Channel_Name__c FROM Bolton_Channel__mdt WHERE Type__c = 'Directory Tool' ORDER BY Channel_Name__c ASC];
            
            return dtInfo;
        }catch(Exception e){
            throw BWC_Controller.handleException(e) ;
        }
    }
    
    public class DirectoryToolWrapper {
        @AuraEnabled
        public Employee__c employee;
        @AuraEnabled
        public User userRecord;
        @AuraEnabled
        public List<Bolton_Channel__mdt> channels;
        
    }
    
    
    //Edit Settings Controller
    @AuraEnabled(continuation=true)
    public static Object editSettings(){
        try {
            BWC_DirectoryTool.DTEditSettingsResponse editSettingsResponse = new BWC_DirectoryTool.DTEditSettingsResponse();
            User currentUser = currentUserRecord();
            if(String.isEmpty(currentUser.ATTUID__c)){
                throw new BWC_Exception(ATT_ID_EMPTY);
            }
            Employee__c employeeRecord = currentEmployeeRecord(currentUser.ATTUID__c);
            if(employeeRecord == null){
                throw new BWC_Exception(EMPLOYEE_NOT_FOUND);
            }
            
            String attuid = currentUser?.attuid__c;
            String channelid = employeeRecord?.BWDefaultKMChannel__c;
            String channelName = employeeRecord?.Channel1__c;
            String roleid = employeeRecord?.User_Role__c;
            String roleName = '';
            BWC_DirectoryToolService.GetEditSettings service = new BWC_DirectoryToolService.GetEditSettings(attuid,channelid,channelName,roleid,roleName);
            Object response = service.callWithContinuation();
            if(response instanceof Continuation){
                ((Continuation)response).ContinuationMethod = 'getEditSettings';
                return response;
            }
            editSettingsResponse = (BWC_DirectoryTool.DTEditSettingsResponse) response;
            system.debug('response--' + JSON.serialize(editSettingsResponse));
            return JSON.serialize(editSettingsResponse,true);
            
        } catch (Exception e) {
            throw BWC_Controller.handleException(e) ;
        }
        
        
    }
    
    //Edit Settings Continuation Callback
    @AuraEnabled
    public static String getEditSettings(List<String> labels, Object state){
        try {
            BWC_DirectoryToolService.GetEditSettings service =
                (BWC_DirectoryToolService.GetEditSettings)state;
            
            BWC_DirectoryTool.DTEditSettingsResponse editSettingsResponse =
                (BWC_DirectoryTool.DTEditSettingsResponse)service.processContinuationResponse();
            system.debug('json.' +JSON.serialize(editSettingsResponse,true));
            return JSON.serialize(editSettingsResponse,true);
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
    
    //Save Settings Controller
    @AuraEnabled(continuation=true)
    public static Object saveEditSettings(String locationid, String quicklistid, String stateid){
        try {
            User currentUser = currentUserRecord();
            if(String.isEmpty(currentUser.ATTUID__c)){
                throw new BWC_Exception(ATT_ID_EMPTY);
            }
            
            BWC_DirectoryToolService.saveEditSettings service = new BWC_DirectoryToolService.saveEditSettings(locationid,quicklistid,stateid,currentUser.ATTUID__c);
            Object response = service.callWithContinuation();
            if(response instanceof Continuation){
                ((Continuation)response).ContinuationMethod = 'saveEditSettingsCallback';
                return response;
            }
            BWC_DirectoryTool.DTSaveSettingsResponse SaveSettingsResponse = (BWC_DirectoryTool.DTSaveSettingsResponse) response;
            return JSON.serialize(SaveSettingsResponse,true); 
        } catch (Exception e) {
            
            throw BWC_Controller.handleException(e);
        }
    }
    
    
    //Save Settings Continuation Call Back
    @AuraEnabled
    public static String saveEditSettingsCallback(List<String> labels, Object state){
        try {
            BWC_DirectoryToolService.SaveEditSettings service =
                (BWC_DirectoryToolService.SaveEditSettings)state;
            
            BWC_DirectoryTool.DTSaveSettingsResponse SaveSettingsResponse =
                (BWC_DirectoryTool.DTSaveSettingsResponse)service.processContinuationResponse();
            return JSON.serialize(SaveSettingsResponse,true);
            
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
    
    //GET Feedback Controller
    
    @AuraEnabled(continuation=true)
    public static Object getFeedback(String contactid,String contactname){
        try {
            User currentUser = currentUserRecord();
            if(String.isEmpty(currentUser.ATTUID__c)){
                throw new BWC_Exception(ATT_ID_EMPTY);
            }
            Employee__c employeeRecord = currentEmployeeRecord(currentUser.ATTUID__c);
            if(employeeRecord == null){
                throw new BWC_Exception(EMPLOYEE_NOT_FOUND);
            }
            
            BWC_DirectoryToolService.GetFeedback service = 
                new BWC_DirectoryToolService.GetFeedback(contactid,currentUser.ATTUID__c,employeeRecord.BWDefaultKMChannel__c,employeeRecord.Channel1__c,contactname);
            Object response = service.callWithContinuation();
            if(response instanceof Continuation){
                ((Continuation)response).ContinuationMethod = 'getFeedbackCallback';
                return response;
            }
            BWC_DirectoryTool.GetFeedbackResponse getFeedbackResponse = (BWC_DirectoryTool.GetFeedbackResponse) response;
            return JSON.serialize(getFeedbackResponse,true);          
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
    //Get Feedback Continuation Callback
    @AuraEnabled
    public static String getFeedbackCallback(List<String> labels, Object state){
        try {
            
            BWC_DirectoryToolService.GetFeedback service =
                (BWC_DirectoryToolService.GetFeedback)state;
            
            BWC_DirectoryTool.GetFeedbackResponse getFeedbackResponse =
                (BWC_DirectoryTool.GetFeedbackResponse)service.processContinuationResponse();
            return JSON.serialize(getFeedbackResponse,true);
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
    //POST Feedback
    //Add Feed back Controller
    @AuraEnabled(continuation=true)
    public static Object addFeedback(String feedback,String contactname,String contactid,String location, String locationid){
        try {
            User currentUser = currentUserRecord();
            if(String.isEmpty(currentUser.ATTUID__c)){
                throw new BWC_Exception(ATT_ID_EMPTY);
            }
            Employee__c employeeRecord = currentEmployeeRecord(currentUser.ATTUID__c);
            if(employeeRecord == null){
                throw new BWC_Exception(EMPLOYEE_NOT_FOUND);
            }
            
            
            BWC_DirectoryToolService.AddFeedback service = new BWC_DirectoryToolService.AddFeedback(currentUser.ATTUID__c,contactname,UserInfo.getName(),contactid,
                                                                                                    location,locationid,employeeRecord?.Channel1__c,employeeRecord?.BWDefaultKMChannel__c,feedback);
            Object response = service.callWithContinuation();
            if(response instanceof Continuation){
                ((Continuation)response).ContinuationMethod = 'addFeedbackCallback';
                return response;
            }
            BWC_DirectoryTool.AddFeedbackResponse addFeedbackResponse = (BWC_DirectoryTool.AddFeedbackResponse) response;
            return JSON.serialize(addFeedbackResponse,true);
            
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
    //Add Feedback Continuation Callback
    @AuraEnabled
    public static String addFeedbackCallback(List<String> labels, Object state){
        try {
            
            BWC_DirectoryToolService.AddFeedback service =
                (BWC_DirectoryToolService.AddFeedback)state;
            
            BWC_DirectoryTool.AddFeedbackResponse addFeedbackResponse =
                (BWC_DirectoryTool.AddFeedbackResponse)service.processContinuationResponse(); 
            return JSON.serialize(addFeedbackResponse,true);
            
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
    //QuickLists
    //Quick List Controller
    @AuraEnabled(continuation=true)
    public static Object getQuickList(){
        try {
            User currentUser = currentUserRecord();
            if(String.isEmpty(currentUser.ATTUID__c)){
                throw new BWC_Exception(ATT_ID_EMPTY);
            }
            Employee__c employeeRecord = currentEmployeeRecord(currentUser.ATTUID__c);
            if(employeeRecord == null){
                throw new BWC_Exception(EMPLOYEE_NOT_FOUND);
            }
            
            BWC_DirectoryToolService.GetQuickLists service = new BWC_DirectoryToolService.GetQuickLists(currentUser.ATTUID__c,employeeRecord?.BWDefaultKMChannel__c);
            Object response = service.callWithContinuation();
            
            if(response instanceof Continuation){
                ((Continuation)response).ContinuationMethod = 'getQuickListCallback';
                return response;
            }
            BWC_DirectoryTool.DTQuickListsChannelResponse quickListResponse = (BWC_DirectoryTool.DTQuickListsChannelResponse) response;
            return JSON.serialize(quickListResponse,true);
            
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
    //Quick List Continuation Callback
    @AuraEnabled
    public static String getQuickListCallback(List<String> labels, Object state){
        try {
            
            BWC_DirectoryToolService.GetQuickLists service =
                (BWC_DirectoryToolService.GetQuickLists)state;
            
            BWC_DirectoryTool.DTQuickListsChannelResponse quickListResponse =
                (BWC_DirectoryTool.DTQuickListsChannelResponse)service.processContinuationResponse();
            return JSON.serialize(quickListResponse,true);
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
    //Search Contacts
    //Search Contacts Controller
    @AuraEnabled(continuation=true)
    public static Object searchContactList(String offset, String codeid, String searchLimit,String channelId){ 
        try {
            User currentUser = currentUserRecord();
            if(String.isEmpty(currentUser.ATTUID__c)){
                throw new BWC_Exception(ATT_ID_EMPTY);
            }
            Employee__c employeeRecord = currentEmployeeRecord(currentUser.ATTUID__c);
            if(employeeRecord == null){
                throw new BWC_Exception(EMPLOYEE_NOT_FOUND);
            }
            
            BWC_DirectoryToolService.GetSearchResults service = new BWC_DirectoryToolService.GetSearchResults(currentUser.ATTUID__c,channelId
                                                                                                              ,codeid,offset,searchLimit);
            Object response = service.callWithContinuation();
            
            if(response instanceof Continuation){
                ((Continuation)response).ContinuationMethod = 'getSearchResults';
                return response;
            }
            BWC_DirectoryTool.DTSearchResultsResponse searchResultsResponse = ( BWC_DirectoryTool.DTSearchResultsResponse) response;
            return JSON.serialize(searchResultsResponse,true);
            
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
    //Search Contacts Continuation Callback
    @AuraEnabled
    public static String getSearchResults(List<String> labels, Object state){
        try {
            
            BWC_DirectoryToolService.GetSearchResults service =
                ( BWC_DirectoryToolService.GetSearchResults)state;
            
            BWC_DirectoryTool.DTSearchResultsResponse searchResultsResponse =
                ( BWC_DirectoryTool.DTSearchResultsResponse)service.processContinuationResponse();
            
            return JSON.serialize(searchResultsResponse,true);
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
    //Search Contacts by QuickList Controller
    @AuraEnabled(continuation=true)
    public static Object searchbyQuickListId(String quicklistId,String channelId){
        try {
            User currentUser = currentUserRecord();
            if(String.isEmpty(currentUser.ATTUID__c)){
                throw new BWC_Exception(ATT_ID_EMPTY);
            }
            Employee__c employeeRecord = currentEmployeeRecord(currentUser.ATTUID__c);
            if(employeeRecord == null){
                throw new BWC_Exception(EMPLOYEE_NOT_FOUND);
            }
            
            
            BWC_DirectoryToolService.GetSearchResultsbyQLId service = new BWC_DirectoryToolService.GetSearchResultsbyQLId(quicklistId, currentUser.ATTUID__c, channelId);
            Object response = service.callWithContinuation();
            
            if(response instanceof Continuation){
                ((Continuation)response).ContinuationMethod = 'getSearchResultsbyQLId';
                return response;
            }
            BWC_DirectoryTool.DTSearchResultsResponse searchResultsResponse = ( BWC_DirectoryTool.DTSearchResultsResponse) response;
            return JSON.serialize(searchResultsResponse,true);
            
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
    
    //Search Contacts by QuickList Continuation Callback
    @AuraEnabled
    public static String getSearchResultsbyQLId(List<String> labels, Object state){
        try {
            
            BWC_DirectoryToolService.GetSearchResultsbyQLId service =
                ( BWC_DirectoryToolService.GetSearchResultsbyQLId)state;
            
            BWC_DirectoryTool.DTSearchResultsResponse  searchResultsResponse =
                ( BWC_DirectoryTool.DTSearchResultsResponse)service.processContinuationResponse();
            
            return JSON.serialize(searchResultsResponse,true);
            
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
    //get Contact Details
    @AuraEnabled(continuation=true)
    public static Object getContactDetails(String codeName){    
        try {
            User currentUser = currentUserRecord();
            if(String.isEmpty(currentUser.ATTUID__c)){
                throw new BWC_Exception(ATT_ID_EMPTY);
            }
            if(String.isEmpty(codeName)){
                throw new BWC_Exception(ERR_CODENAME);
            }    
            
            BWC_DirectoryToolService.GetContactDetails service = 
                new BWC_DirectoryToolService.GetContactDetails(currentUser.ATTUID__c,codeName);
            Object response = service.callWithContinuation();
            if(response instanceof Continuation){
                ((Continuation)response).ContinuationMethod = 'getContactDetailsCallback';
                return response;
            }           
            
            BWC_DirectoryTool.GetContactDetailsResponse GetContactDetailsResponse = (BWC_DirectoryTool.GetContactDetailsResponse) response;
            return JSON.serialize(GetContactDetailsResponse,true); 
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
    //Get Contact Details Continuation Callback
    @AuraEnabled
    public static String getContactDetailsCallback(List<String> labels, Object state){
        try {

            BWC_DirectoryToolService.GetContactDetails service =
                (BWC_DirectoryToolService.GetContactDetails)state;

            BWC_DirectoryTool.GetContactDetailsResponse getContactDetailsResponse =
            (BWC_DirectoryTool.GetContactDetailsResponse)service.processContinuationResponse();            
           
            return JSON.serialize(getContactDetailsResponse,true);

        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
    private static Employee__c currentEmployeeRecord(String attuid){
        try{
            List<Employee__c> empRecords = [SELECT id,Name,BWDefaultKMChannel__c,Sub_Channel__c,Channel1__c,User_Role__c,EmployeeId__c,Work_State__c,Work_City__c from Employee__c WHERE  EmployeeId__c =:attuid];
            if(empRecords.size() > 0){
                return empRecords[0];   
            }else{
                return null;
            }
        }catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
    @AuraEnabled
    public static String updateEmployeeRecord(String state, String city,String attuid){
        try{
            return (new WithoutSharing()).updateEmployeeRecord(state, city, attuid);
        }catch(exception e){
            return e.getMessage();
        }
        
        
    }
    
    private static User currentUserRecord(){
        return [Select Id,ATTUID__C,UserRole.Name,Name from User WHERE id =:UserInfo.getUserId()];
    }
    
    private without sharing class WithoutSharing{
        /*This class needs to run without sharing to update the employee record when the edit settings service returns any state or location
			Users won't be given access to this object its updated only when backend service returns a city and state or user selects any location to update the mycsp backend */
        public String updateEmployeeRecord(String state, String city,String attuid){
            try{
                Employee__c empRecord = currentEmployeeRecord(attuid);
                
                if(empRecord != null){
                    empRecord.Work_State__c = state;
                    empRecord.Work_City__c = city;
                    update empRecord;
                    return 'Success';
                }else{
                    return 'Failed';
                }
            }catch(exception e){
                return e.getMessage();
            } 
        }
    }
    @AuraEnabled
    public static Boolean hasChannelAccess(String recId){
        Boolean hasAccess = false;
        try{
            List<UserRecordAccess> access = [Select RecordId,HasReadAccess,
                                               HasEditAccess 
                                               from UserRecordAccess 
                                               where RecordId = :recId 
                                               and userId =:UserInfo.getUserId()];
            if(access.size() > 0){
                hasAccess = access[0].HasReadAccess;
            }
            return hasAccess;
        }catch(exception e){
            system.debug('--error--' + e.getMessage());
            throw BWC_Controller.handleException(e);
        }finally{
            return hasAccess;
        }
    }
}
@isTest
public class BWC_DirectoryToolController_Test {
    private static final String OFFSET ='20';
    private static final String CODEID ='5556';
    private static final String SEARCHLIMIT ='20';
    private static final String QUICKLISTID ='12';
    private static final String CHANNELID ='103';
    private static final String ATTUID = 'aa1234';
    private static final String CONTACT_ID = '556';
    private static final String CONTACT_NAME = 'ASUS';
    private static final String LOCATION = 'test location';
    private static final String LOCATIONID = '123';
    private static final String GET_FEEDBACK_MOCK = 'DT_GET_Feedback_Success';
    private static final String ADD_FEEDBACK_MOCK = 'DT_Add_Feedback_Success';
    private static final String ATTUIDEXCEPTIONMSG = 'ATT ID is empty for the User';
    private static final String CODENAME = '103';
    private static final String GET_CONTACTDETAILS_MOCK = 'DT_GET_ContactDetails_Success';
    
    @testSetup
    public static void testDataSetup(){
        User u = new User(); 
        Profile sysAdminProfile = [Select ID From Profile Where Name='System Administrator'];
        UserRole roleRec = [SELECT Id FROM UserRole WHERE DeveloperName='VPServices'];
        User adminUser1 =Utility_Test.createTestUserWithRole(sysAdminProfile.Id, 'testFirst1', 'testLast1', roleRec.Id);
        adminUser1.ATTUID__c =ATTUID;
        insert adminUser1;
        User adminUser2 =Utility_Test.createTestUserWithRole(sysAdminProfile.Id, 'testFirst2', 'testLast2', roleRec.Id);
        insert adminUser2;
        createTestEmployee();
    }
    @isTest
    private static void test_getFeedback_success() {
        User contextUser = [Select Id, FirstName, LastName, ATTUID__c from User where FirstName = 'testFirst1'];
        
        System.runAs(contextUser){
            System.Continuation continuation =
                (System.Continuation)BWC_DirectoryToolController.getFeedback(CONTACT_ID, CONTACT_NAME);        
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_DirectoryToolCallout.API_DT_GET_FEEDBACK, GET_FEEDBACK_MOCK);
            String responseJson = BWC_DirectoryToolController.getFeedbackCallback(null, BWC_Callout.lastContinuationState);
            BWC_ApiMock.setTestApiMock( BWC_DirectoryToolCallout.API_DT_GET_FEEDBACK, GET_FEEDBACK_MOCK);
            responseJson = (String)BWC_DirectoryToolController.getFeedback(CONTACT_ID, CONTACT_NAME);
            BWC_DirectoryTool.GetFeedbackResponse getfeedbackWrapper = (BWC_DirectoryTool.GetFeedbackResponse)JSON.deserialize(responseJson, BWC_DirectoryTool.GetFeedbackResponse.class);
            System.assertEquals(ATTUID, getfeedbackWrapper.attuid);
        }
        
    }
    
    @isTest
    private static void test_addFeedback_success() {
        User contextUser = [Select Id, FirstName, LastName, ATTUID__c from User where FirstName = 'testFirst1'];
        System.runAs(contextUser){
            // Call method using continuation
            System.Continuation continuation =
                (System.Continuation)BWC_DirectoryToolController.addFeedback('Test feedback',
                                                                             CONTACT_NAME,CONTACT_ID,LOCATION,LOCATIONID);        
            
            // Set mock response
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_DirectoryToolCallout.API_DT_CREATE_FEEDBACK,ADD_FEEDBACK_MOCK);
            
            // Get continuation response
            String responseJson = BWC_DirectoryToolController.addFeedbackCallback(null, BWC_Callout.lastContinuationState);
            
            BWC_ApiMock.setTestApiMock( BWC_DirectoryToolCallout.API_DT_CREATE_FEEDBACK, ADD_FEEDBACK_MOCK);
            responseJson = (String)BWC_DirectoryToolController.addFeedback('Test feedback',
                                                                           CONTACT_NAME,CONTACT_ID,location,locationId);
            BWC_DirectoryTool.AddFeedbackResponse addfeedbackWrapper= (BWC_DirectoryTool.AddFeedbackResponse)JSON.deserialize(responseJson, BWC_DirectoryTool.AddFeedbackResponse.class);
            System.assertEquals('127', addfeedbackWrapper.referenceCode);
            
        }
        
    }
    @isTest
    public static void testToGetSearchResults(){
        User adminUser = [Select Id, FirstName, LastName, ATTUID__c from User where FirstName = 'testFirst1'];
        Test.startTest();
        system.runAs(adminUser){
            System.Continuation continuation =
                (System.Continuation)BWC_DirectoryToolController.searchContactList(OFFSET,CODEID,SEARCHLIMIT,CHANNELID);
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_DirectoryToolCallout.API_DT_Get_Search_Results, 'DT_Get_Search_Results');
            String responseJson = BWC_DirectoryToolController.getSearchResults(null, BWC_Callout.lastContinuationState);
            BWC_ApiMock.setTestApiMock(BWC_DirectoryToolCallout.API_DT_Get_Search_Results, 'DT_Get_Search_Results');
            String res = (String)BWC_DirectoryToolController.searchContactList(OFFSET,CODEID,SEARCHLIMIT,CHANNELID);
            BWC_DirectoryTool.DTSearchResultsResponse responseWrapper =(BWC_DirectoryTool.DTSearchResultsResponse)JSON.deserialize(res, BWC_DirectoryTool.DTSearchResultsResponse.class);
            system.assertEquals(1, responseWrapper.searchListResponse.size());
        }
        
        Test.stopTest();
        
    }
    @isTest
    public static void testToGetSearchResultsbyQLId(){
        User adminUser = [Select Id, FirstName, LastName, ATTUID__c from User where FirstName = 'testFirst1'];
        Test.startTest();
        system.runAs(adminUser){
            System.Continuation continuation =
                (System.Continuation)BWC_DirectoryToolController.searchbyQuickListId(QUICKLISTID,CHANNELID);
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_DirectoryToolCallout.API_DT_Get_Search_Results_byQLId, 'DT_Get_Search_Results_byQLId');
            String responseJson = BWC_DirectoryToolController.getSearchResultsbyQLId(null, BWC_Callout.lastContinuationState);
            BWC_DirectoryTool.DTSearchResultsResponse responseWrapper =
                ( BWC_DirectoryTool.DTSearchResultsResponse)JSON.deserialize(responseJson,  BWC_DirectoryTool.DTSearchResultsResponse.class);
            system.assertEquals(1, responseWrapper.searchListResponse.size());
            BWC_ApiMock.setTestApiMock(BWC_DirectoryToolCallout.API_DT_Get_Search_Results_byQLId, 'DT_Get_Search_Results_byQLId');
            String res = (String)BWC_DirectoryToolController.searchbyQuickListId(QUICKLISTID,CHANNELID);
            responseWrapper =(BWC_DirectoryTool.DTSearchResultsResponse)JSON.deserialize(res, BWC_DirectoryTool.DTSearchResultsResponse.class);
            system.assertEquals(1, responseWrapper.searchListResponse.size());
        }
        
        Test.stopTest();
        
    }
    
    @isTest
    public static void testExceptionsForSearchList(){
        String offsetExceptionMessage = 'Offset is Required';
        User adminUser1 = [Select Id, FirstName, LastName, ATTUID__c from User where FirstName = 'testFirst1'];
        User adminUser2 = [Select Id, FirstName, LastName, ATTUID__c from User where FirstName = 'testFirst2'];
        Test.startTest();
        system.runAs(adminUser2){
            try{
                System.Continuation continuation =
                    (System.Continuation)BWC_DirectoryToolController.searchContactList(OFFSET,CODEID,SEARCHLIMIT,CHANNELID);  
            }catch(Exception e){
                system.assertEquals(ATTUIDEXCEPTIONMSG, e.getMessage());
            }
        }
        system.runAs(adminUser1){
            try{
                String res = (String)BWC_DirectoryToolController.searchContactList(null,CODEID,SEARCHLIMIT,CHANNELID);
                system.debug('Response '+res);
                
            }catch(Exception e){
                system.debug('Exception '+e.getMessage());
            }
        }
        Test.stopTest();
    }
    @isTest
    public static void testExceptionsForSearchListbyQLid(){
        String quickListIdExceptionMessage = 'Quicklist ID is Required';
        User adminUser1 = [Select Id, FirstName, LastName, ATTUID__c from User where FirstName = 'testFirst1'];
        User adminUser2 = [Select Id, FirstName, LastName, ATTUID__c from User where FirstName = 'testFirst2'];    
        Test.startTest();
        system.runAs(adminUser2){
            try{
                System.Continuation continuation =
                    (System.Continuation)BWC_DirectoryToolController.searchbyQuickListId(QUICKLISTID,CHANNELID);  
            }catch(Exception e){
                system.assertEquals(ATTUIDEXCEPTIONMSG, e.getMessage());
            }
        }
        system.runAs(adminUser1){
            try{
                String res = (String)BWC_DirectoryToolController.searchbyQuickListId(null,CHANNELID);  
                system.debug('response==cv '+res);
                
            }catch(Exception e){
                system.debug('Exception '+e.getMessage());
            }
        }
        Test.stopTest();
        
    }
    @isTest
    static void checkEditSettings(){
        User adminUser = [Select Id, FirstName, LastName, ATTUID__c from User where FirstName = 'testFirst1'];
        Test.startTest();
        system.runAs(adminUser){
            System.Continuation continuation =
                (System.Continuation)BWC_DirectoryToolController.EditSettings();
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_DirectoryToolCallout.API_DT_EDIT_SETTINGS, 'DT_EDIT_SETTINGS');
            String responseJson = BWC_DirectoryToolController.getEditSettings(null, BWC_Callout.lastContinuationState);
            BWC_DirectoryTool.DTEditSettingsResponse responseWrapper =
                ( BWC_DirectoryTool.DTEditSettingsResponse)JSON.deserialize(responseJson,  BWC_DirectoryTool.DTEditSettingsResponse.class);
            
            BWC_ApiMock.setTestApiMock(BWC_DirectoryToolCallout.API_DT_EDIT_SETTINGS, 'DT_EDIT_SETTINGS');
            String res = (String)BWC_DirectoryToolController.EditSettings();
            responseWrapper =(BWC_DirectoryTool.DTEditSettingsResponse)JSON.deserialize(res, BWC_DirectoryTool.DTEditSettingsResponse.class);
            
        }
        
        Test.stopTest();
    }
    @isTest
    public static void checkSaveSettings(){
        User adminUser = [Select Id, FirstName, LastName, ATTUID__c from User where FirstName = 'testFirst1'];
        Test.startTest();
        system.runAs(adminUser){
            System.Continuation continuation =
                (System.Continuation)BWC_DirectoryToolController.SaveEditSettings('123',QUICKLISTID,'123');
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_DirectoryToolCallout.API_DT_SAVE_SETTINGS, 'DT_SAVE_EDIT_SETTINGS');
            String responseJson = BWC_DirectoryToolController.SaveEditSettingsCallback(null, BWC_Callout.lastContinuationState);
            BWC_DirectoryTool.DTSaveSettingsResponse responseWrapper =
                ( BWC_DirectoryTool.DTSaveSettingsResponse)JSON.deserialize(responseJson,  BWC_DirectoryTool.DTSaveSettingsResponse.class);
            BWC_ApiMock.setTestApiMock(BWC_DirectoryToolCallout.API_DT_SAVE_SETTINGS, 'DT_SAVE_EDIT_SETTINGS');
            String res = (String)BWC_DirectoryToolController.SaveEditSettings('123',QUICKLISTID,'123');
            responseWrapper =(BWC_DirectoryTool.DTSaveSettingsResponse)JSON.deserialize(res, BWC_DirectoryTool.DTSaveSettingsResponse.class);
        }
        
        Test.stopTest();
    }
    @isTest
    public static void testQuickListSuccess(){
        User contextUser = [Select Id, FirstName, LastName, ATTUID__c from User where FirstName = 'testFirst1'];
        Test.startTest();
        system.runAs(contextUser){
            System.Continuation continuation =
                (System.Continuation)BWC_DirectoryToolController.getQuickList();
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_DirectoryToolCallout.API_DT_QUICKLIST_SETTINGS, 'DT_QuickList');
            String responseJson = BWC_DirectoryToolController.getQuickListCallback(null, BWC_Callout.lastContinuationState);
            BWC_DirectoryTool.DTQuickListsChannelResponse responseWrapper =
                ( BWC_DirectoryTool.DTQuickListsChannelResponse)JSON.deserialize(responseJson,  BWC_DirectoryTool.DTQuickListsChannelResponse.class);
            System.assertEquals(3, responseWrapper.quicklists.size());
            BWC_ApiMock.setTestApiMock(BWC_DirectoryToolCallout.API_DT_QUICKLIST_SETTINGS, 'DT_QuickList');
            String res = (String)BWC_DirectoryToolController.getQuickList();
            responseWrapper =(BWC_DirectoryTool.DTQuickListsChannelResponse)JSON.deserialize(res, BWC_DirectoryTool.DTQuickListsChannelResponse.class);
            System.assertEquals(3, responseWrapper.quicklists.size());
        }
        
        Test.stopTest();
    }
    @isTest
    public static void testQuickListATTIdException(){
        User contextUser = [Select Id, FirstName, LastName, ATTUID__c from User where FirstName = 'testFirst2'];
        Test.startTest();
        system.runAs(contextUser){
            try{
                System.Continuation continuation =
                    (System.Continuation)BWC_DirectoryToolController.getQuickList();
                
            } catch(Exception e){
                system.assertEquals('ATT ID is empty for the User', e.getMessage());
            }
            
        }
        
        Test.stopTest();
    }
    @isTest
    public static void testQuickListChannelIdException(){
        User contextUser = [Select Id, FirstName, LastName, ATTUID__c from User where FirstName = 'testFirst1'];
        Test.startTest();
        system.runAs(contextUser){
            try{
                String responseJson = (String)BWC_DirectoryToolController.getQuickList();
                system.debug('QuicklistResponse '+responseJson);
                
            } catch(Exception e){
                system.debug('exception '+e.getMessage());
            }
            
        }
        
        Test.stopTest();
    }
    @isTest
    public static void testInitialize(){
        User contextUser = [Select Id, FirstName, LastName, ATTUID__c from User where FirstName = 'testFirst1'];
        Test.startTest();
        system.runAs(contextUser){
            try{
                BWC_DirectoryToolController.DirectoryToolWrapper wrapper = (BWC_DirectoryToolController.DirectoryToolWrapper)BWC_DirectoryToolController.initialize();
                system.debug('QuicklistResponse '+wrapper);
                
            } catch(Exception e){
                system.debug('exception '+e.getMessage());
            }
            
        }
        
        Test.stopTest();
    }
    @isTest
    public static void testEmpUpdate(){
        User contextUser = [Select Id, FirstName, LastName, ATTUID__c from User where FirstName = 'testFirst1'];
        Test.startTest();
        system.runAs(contextUser){
            try{
                String res = (String)BWC_DirectoryToolController.updateEmployeeRecord('','','Test12');
                system.debug('QuicklistResponse '+res);
                
            } catch(Exception e){
                system.debug('exception '+e.getMessage());
            }
            
        }
        
        Test.stopTest();
    }
    @future
     private static void createTestEmployee(){
        Employee__c testEmp= new Employee__c(BWDefaultKMChannel__c ='103', EmployeeId__c= 'aa1234',
                                        User_Role__c ='1234',
                                        Organization__c = 'Centers',
      									Channel__c = 'Collections',
        								Channel1__c = 'Collections',
        								Sub_Channel__c = 'Collections');
        insert testEmp;
    }
    @isTest
    private static void test_getContactDetails_success() {
        Test.startTest();
        User contextUser = [Select Id, FirstName, LastName, ATTUID__c from User where FirstName = 'testFirst1'];
        
        System.runAs(contextUser){
            System.Continuation continuation =
                (System.Continuation)BWC_DirectoryToolController.getContactDetails(CODENAME);                    
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_DirectoryToolCallout.API_DT_GET_CONTACTDETAILS, GET_CONTACTDETAILS_MOCK);
            String responseJson = BWC_DirectoryToolController.getContactDetailsCallback(null, BWC_Callout.lastContinuationState);
            
            BWC_DirectoryTool.GetContactDetailsResponse getContactDetailsWrapper = (BWC_DirectoryTool.GetContactDetailsResponse)JSON.deserialize
                (responseJson, BWC_DirectoryTool.GetContactDetailsResponse.class);
            
            BWC_ApiMock.setTestApiMock( BWC_DirectoryToolCallout.API_DT_GET_CONTACTDETAILS, GET_CONTACTDETAILS_MOCK);
            String resp = (String)BWC_DirectoryToolController.getContactDetails(CODENAME);            
            getContactDetailsWrapper = (BWC_DirectoryTool.GetContactDetailsResponse)JSON.deserialize(resp, BWC_DirectoryTool.GetContactDetailsResponse.class);            
            System.assertEquals(Integer.valueOf(CODENAME), getContactDetailsWrapper.cntid);
            try{
                BWC_DirectoryToolController.getContactDetails(''); 
            }
            Catch(Exception ex){
                system.assertEquals('BWC_Exception:[code=null, requestContext=null, responseContext=null]: Code Name is Required', String.valueOf(ex));
            }
            try{
                BWC_DirectoryToolController.getContactDetailsCallback(null,null); 
            }
            Catch(Exception ex){
                system.assertEquals('System.NullPointerException: Attempt to de-reference a null object', String.valueOf(ex));
            }
        }
        test.stopTest();        
    }
}
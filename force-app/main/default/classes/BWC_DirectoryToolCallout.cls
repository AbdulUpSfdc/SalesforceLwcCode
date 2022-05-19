public class BWC_DirectoryToolCallout {

    public static final String API_DT_EDIT_SETTINGS = 'DT_Edit_Settings';
    public static final String API_DT_SAVE_SETTINGS = 'DT_Save_Settings';
    public static final String API_DT_QUICKLIST_SETTINGS = 'DT_Quicklist_Settings';
    public static final String API_DT_GET_FEEDBACK = 'DT_GET_Feedback';
    public static final String API_DT_CREATE_FEEDBACK = 'DT_Create_Feedback';
    public static final String API_DT_Get_Search_Results = 'DT_Get_Search_Results';
    public static final String API_DT_Get_Search_Results_byQLId = 'DT_Get_Search_Results_byQLId';
    public static final String API_DT_GET_CONTACTDETAILS = 'DT_GET_ContactDetails';
    
    //Edit Settings
    public class GetEditSettingsCallout extends BWC_Callout{
        BWC_DirectoryTool.DTEditSettingsResponse response;
        
        public GetEditSettingsCallout(String queryString){
            this.setCallout(API_DT_EDIT_SETTINGS,null,null,queryString,null);
        }
        
        public override Object buildResponse(){

            this.response = new BWC_DirectoryTool.DTEditSettingsResponse();
            this.response = (BWC_DirectoryTool.DTEditSettingsResponse) this.deserialize(BWC_DirectoryTool.DTEditSettingsResponse.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);

            return this.response;
        }
    }
    
    //Save Settings
    public class SaveSettingsCallout extends BWC_Callout{
        
        BWC_DirectoryTool.DTSaveSettingsResponse response;
        
        public SaveSettingsCallout(String requestBody){
            this.setCallout(API_DT_SAVE_SETTINGS,requestBody,null,null,null);
        }
        
        public override Object buildResponse(){

            this.response = new BWC_DirectoryTool.DTSaveSettingsResponse();
            this.response = (BWC_DirectoryTool.DTSaveSettingsResponse) this.deserialize(BWC_DirectoryTool.DTSaveSettingsResponse.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);

            return this.response;
        }
    }
   
    
    //QuickList GET Callout
    public class GetQuickListsCallout extends BWC_Callout{
        BWC_DirectoryTool.DTQuickListsChannelResponse response;
        
        public GetQuickListsCallout(String queryString){
            this.setCallout(API_DT_QUICKLIST_SETTINGS,null,null,queryString,null);
        }
        
        public override Object buildResponse(){

            this.response = new BWC_DirectoryTool.DTQuickListsChannelResponse();
            this.response = (BWC_DirectoryTool.DTQuickListsChannelResponse) this.deserialize(BWC_DirectoryTool.DTQuickListsChannelResponse.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);

            return this.response;
        }
    }
    
    
    //FEED BACK CALLOUTS

    //get feedback callout
    public class GetFeedbackCallout extends BWC_Callout{
        BWC_DirectoryTool.GetFeedbackResponse response;
        
        public GetFeedbackCallout(String queryString){
            this.setCallout(API_DT_GET_FEEDBACK,null,null,queryString,null);
        }
        
        public override Object buildResponse(){
            this.response = new BWC_DirectoryTool.GetFeedbackResponse();
            this.response = (BWC_DirectoryTool.GetFeedbackResponse) this.deserialize(BWC_DirectoryTool.GetFeedbackResponse.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);
            return this.response;
        }
    }

    //add feedback callout
    public class AddFeedbackCallout extends BWC_Callout{
        //BWC_DirectoryTool.AddFeedbackRequest request;
        BWC_DirectoryTool.AddFeedbackResponse response;
        
        public AddFeedbackCallout(BWC_DirectoryTool.AddFeedbackRequest reqBody){
            this.setCallout(API_DT_CREATE_FEEDBACK,reqBody,null,null,null);
        }
        
        public override Object buildResponse(){
            this.response = new BWC_DirectoryTool.AddFeedbackResponse();
            this.response = (BWC_DirectoryTool.AddFeedbackResponse) this.deserialize(BWC_DirectoryTool.AddFeedbackResponse.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);
            return this.response;
        }
    }
    
    
    
    //Search Contact API

    // /list
    public class GetSearchResultsCallout extends BWC_Callout{
       
        BWC_DirectoryTool.DTSearchResultsResponse response;
        
        public GetSearchResultsCallout(String queryString){
            this.setCallout(API_DT_Get_Search_Results,null,null,queryString,null);
        }
        
        public override Object buildResponse(){
            String body = this.httpResponse?.getBody()?.replace('"number"', '"contactNumber"');
            this.httpResponse.setBody(body);
            this.response = new BWC_DirectoryTool.DTSearchResultsResponse();
            this.response.searchListResponse = (List<BWC_DirectoryTool.DTSearchListResponse>)this.deserialize(List<BWC_DirectoryTool.DTSearchListResponse>.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);
            return this.response;
        }
    }
    
    // /showquicklist
    public class GetSearchResultsbyQLIdCallout extends BWC_Callout{
       
        BWC_DirectoryTool.DTSearchResultsResponse response;
        
        public GetSearchResultsbyQLIdCallout(String queryString){
            this.setCallout(API_DT_Get_Search_Results_byQLId,null,null,queryString,null);
        }
        
        public override Object buildResponse(){
            String body = this.httpResponse?.getBody()?.replace('"number"', '"contactNumber"');
            this.httpResponse.setBody(body);
            this.response = new BWC_DirectoryTool.DTSearchResultsResponse();
            this.response.searchListResponse = (List<BWC_DirectoryTool.DTSearchListResponse>)this.deserialize(List<BWC_DirectoryTool.DTSearchListResponse>.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);
            return this.response;
        }
    }
    
    // get Contact Details
    public class GetContactDetailsCallout extends BWC_Callout{
        BWC_DirectoryTool.GetContactDetailsResponse response;
        
        public GetContactDetailsCallout(String queryString){
            this.setCallout(API_DT_GET_CONTACTDETAILS,null,null,queryString,null);
        }
        
        public override Object buildResponse(){
            this.response = new BWC_DirectoryTool.GetContactDetailsResponse();
            this.response = (BWC_DirectoryTool.GetContactDetailsResponse) this.deserialize(BWC_DirectoryTool.GetContactDetailsResponse.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);
            return this.response;
        }
    }
}
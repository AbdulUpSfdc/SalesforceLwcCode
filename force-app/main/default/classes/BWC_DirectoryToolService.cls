public class BWC_DirectoryToolService {
    
    public Employee__c empRecord;
	public static final String ERR_CHANNEL_ID = 'Channel ID is Required';    
    public static final String ERR_CHANNEL_NAME = 'Channel Name is Required'; 
    public static final String ERR_ROLE_ID = 'Role ID is Required';
    public static final String ERR_OFFSET = 'Offset is Required';
    public static final String ERR_SEARCH_LIMIT = 'Search Limit is Required';
    public static final String ERR_QUICKLIST_ID = 'Quicklist ID is Required';
    public static final String ERR_CONTACT_ID = 'Contact ID is Required';
    public static final String ERR_CONTACT_NAME = 'Contact Name is Required';
    public static final String ERR_LOCATION = 'Location is Required';
    public static final String ERR_LOCATION_ID = 'Location Id is Required';
    public static final String ERR_FEEDBACK = 'Feedback is Required';
    //GET Settings
    public class GetEditSettings extends BWC_AsyncServiceBase{
        public BWC_DirectoryTool.DTEditSettingsResponse response;
        
        public GetEditSettings(String attuid,String channelid, String channelName,String roleId, String roleName){
            this.buildRequest(attuid,channelid,channelName,roleId,roleName);
        }
        
        public void buildRequest(String attuid,String channelid, String channelName,String roleId, String roleName){
            String queryString = '';
            if(String.isEmpty(channelid)){
                throw new BWC_Exception(ERR_CHANNEL_ID);
            }
            if(String.isEmpty(channelName)){
                throw new BWC_Exception(ERR_CHANNEL_NAME);
            }
            if(String.isEmpty(roleId)){
                throw new BWC_Exception(ERR_ROLE_ID);
            }
            
            
            queryString += 'attuid='+attuid;
            queryString += '&channelid='+channelid;//Change Below Response dynamically
            queryString += '&channelname=' + EncodingUtil.urlEncode(channelName,'UTF-8');
            queryString += '&roleid=' + roleId;
            queryString += '&rolename=';
                        
            this.callout = new BWC_DirectoryToolCallout.GetEditSettingsCallout(queryString); 
        }
        
        public override Object buildResponse(){
            this.response = (BWC_DirectoryTool.DTEditSettingsResponse) this.callout.getResponse();
            return this.response;
        }
        
    }
    
    //SAVE SETTINGS
    public class SaveEditSettings extends BWC_AsyncServiceBase{
        public BWC_DirectoryTool.DTSaveSettingsResponse response;
        
        public SaveEditSettings(String locationid, String quicklistid, String stateid,String attuid){
            BWC_DirectoryTool.DTSaveSettingsRequest request = new BWC_DirectoryTool.DTSaveSettingsRequest();
            request.attuid = attuid;
            request.locationid = locationid;
            request.quicklistid = quicklistid != null?quicklistid:'';
            request.stateid = stateid;
            request.userid = attuid;
            request.username = UserInfo.getName();
            String requestBody = JSON.serialize(request);
            this.buildRequest(requestBody);
        }
        
        public void buildRequest(String requestBody){          
            this.callout = new BWC_DirectoryToolCallout.SaveSettingsCallout(requestBody);           
        }
        
        public override Object buildResponse(){
            this.response = (BWC_DirectoryTool.DTSaveSettingsResponse) this.callout.getResponse();
            return this.response;
        }
        
    }
    
    
    //GET Quicklist 
    public class GetQuickLists extends BWC_AsyncServiceBase{
        public BWC_DirectoryTool.DTQuickListsChannelResponse response;
        
        public GetQuickLists(String attuid,String channelid){
            this.buildRequest(attuid,channelid);
        }
        
        public void buildRequest(String attuid,String channelid){
            if(channelid == null || channelid == ''){
                throw new BWC_Exception(ERR_CHANNEL_ID);
            }
            String queryString = '';
            queryString += 'attuid='+attuid;
            queryString += '&channelid='+channelid;
            
            this.callout = new BWC_DirectoryToolCallout.GetQuickListsCallout(queryString); 
        }
        
        public override Object buildResponse(){
            this.response = (BWC_DirectoryTool.DTQuickListsChannelResponse) this.callout.getResponse();
            return this.response;
        }
        
    }
    
    //Search Contacts
    // /list
    public class GetSearchResults extends BWC_AsyncServiceBase{
        public BWC_DirectoryTool.DTSearchResultsResponse response;

        public GetSearchResults(String attuid,String channelid,String codeid,String offset, String searchlimit){
            this.buildRequest(attuid,channelid, codeid, offset, searchlimit);
        }

        public void buildRequest(String attuid,String channelid,String codeid,String offset, String searchlimit){          
            
            if(String.isEmpty(offset)){
                throw new BWC_Exception(ERR_OFFSET);
            }
            if(String.isEmpty(channelid)){
                throw new BWC_Exception(ERR_CHANNEL_ID);
            }
            if(String.isEmpty(searchlimit)){
                throw new BWC_Exception(ERR_SEARCH_LIMIT);
            }
            
            String queryString = '';
            queryString += 'attuid='+attuid;
            queryString += '&channelid='+channelid;
            if(!String.isEmpty(codeid)){
                if(codeid.isNumeric()){
                    queryString += '&codeid='+codeid;
                    queryString += '&codename=';
                }else{
                    queryString += '&codeid=';
                    queryString += '&codename='+EncodingUtil.urlEncode(codeid,'UTF-8');
                }
            }else{
                queryString += '&codeid=';
                queryString += '&codename=';
            }
            queryString += '&limit='+searchlimit;
            queryString += '&rolename=';
            queryString += '&offset='+offset;
            this.callout = new BWC_DirectoryToolCallout.GetSearchResultsCallout(queryString);
            
            
            
        }
        
        public override Object buildResponse(){
            this.response = (BWC_DirectoryTool.DTSearchResultsResponse) this.callout.getResponse();
            return this.response;
        }

    }
    
    //showquicklist
     public class GetSearchResultsbyQLId extends BWC_AsyncServiceBase{
        public BWC_DirectoryTool.DTSearchResultsResponse response;

         public GetSearchResultsbyQLId(String quicklistId,String attuid, String channelid){
             this.buildRequest(quicklistId,attuid,channelid);
         }
         
         public void buildRequest(String quicklistId,String attuid, String channelid){
             
             if(String.isEmpty(quicklistId)){
                 throw new BWC_Exception(ERR_QUICKLIST_ID);
             }
             if(String.isEmpty(channelid)){
                 throw new BWC_Exception(ERR_CHANNEL_ID);
             }
             String queryString = '';
             queryString += 'attuid='+attuid;
             queryString += '&channelid='+channelid;
             queryString += '&quicklistid='+quicklistId;
             this.callout = new BWC_DirectoryToolCallout.GetSearchResultsbyQLIdCallout(queryString);
             
             
             
         }
         
         public override Object buildResponse(){
             this.response = (BWC_DirectoryTool.DTSearchResultsResponse) this.callout.getResponse();
             return this.response;
         }
         
     }    
    
    //Feedback Service
    //Get Feedback
    public class GetFeedback extends BWC_AsyncServiceBase{
        public BWC_DirectoryTool.GetFeedbackResponse response;

        public GetFeedback(String contactId,String attuid, String channelId,String channelName, String contactName){
            this.buildRequest(contactId,attuid,channelId,channelName,contactName);
        }

        public void buildRequest(String contactId,String attuid, String channelId,String channelName, String contactName){
            if(String.isEmpty(contactId)){
                throw new BWC_Exception(ERR_CONTACT_ID);
            }
            if(String.isEmpty(channelName)){
                throw new BWC_Exception(ERR_CHANNEL_NAME);
            }
            if(String.isEmpty(channelId)){
                throw new BWC_Exception(ERR_CHANNEL_ID);
            }
            if(String.isEmpty(contactName)){
                throw new BWC_Exception(ERR_CONTACT_NAME);
            }
            
            String queryString = '';
            queryString += 'contactid='+contactId;
            queryString += '&attuid='+attuid;
            queryString += '&channelid='+channelId;
            queryString += '&channelname=' + EncodingUtil.urlEncode(channelName, 'UTF-8');
            queryString += '&contactname='+ EncodingUtil.urlEncode(contactName, 'UTF-8');
            this.callout = new BWC_DirectoryToolCallout.GetFeedbackCallout(queryString);                  
        }

        public override Object buildResponse(){
            this.response = (BWC_DirectoryTool.GetFeedbackResponse) this.callout.getResponse();
            return this.response;
        }

    }


    public class AddFeedback extends BWC_AsyncServiceBase{

        public BWC_DirectoryTool.AddFeedbackResponse response;

        public AddFeedback(String attuid,String contactName,String userName,String contactId,
            String location,String locationId,String channel, String channelId,String feedback){
            this.buildRequest(attuid,contactName,userName,contactId,location,locationId,channel,channelId,feedback);
        }

        public void buildRequest(String attuid,String contactName,String userName,String contactId,
                                 String location,String locationId,String channel, String channelId,String feedback){
                                     if(String.isEmpty(contactId)){
                                         throw new BWC_Exception(ERR_CONTACT_ID);
                                     }
                                     if(String.isEmpty(channel)){
                                         throw new BWC_Exception(ERR_CHANNEL_NAME);
                                     }
                                     if(String.isEmpty(channelId)){
                                         throw new BWC_Exception(ERR_CHANNEL_ID);
                                     }
                                     if(String.isEmpty(contactName)){
                                         throw new BWC_Exception(ERR_CONTACT_NAME);
                                     } 
                                     if(String.isEmpty(location)){
                                         throw new BWC_Exception(ERR_LOCATION);
                                     } 
                                     if(String.isEmpty(locationId)){
                                         throw new BWC_Exception(ERR_LOCATION_ID);
                                     }
                                     if(String.isEmpty(feedback)){
                                         throw new BWC_Exception(ERR_FEEDBACK);
                                     }
             
  
            BWC_DirectoryTool.AddFeedbackRequest request = new BWC_DirectoryTool.AddFeedbackRequest();
            request.attuid = attuid;
            request.contactname = contactName;
            request.username = userName;
            request.contactid = contactId;
            request.location = location;
            request.locationid = locationId;
            request.channel = channel;
            request.channelid = channelId;
            request.feedback = feedback;   
            this.callout = new BWC_DirectoryToolCallout.AddFeedbackCallout(request);                    
        }

        public override Object buildResponse(){
            this.response = (BWC_DirectoryTool.AddFeedbackResponse) this.callout.getResponse();
            return this.response;
        }

    }
    
    // get Contact Deatils
    public class GetContactDetails extends BWC_AsyncServiceBase{
        public BWC_DirectoryTool.GetContactDetailsResponse response;

        public GetContactDetails(String attuid,String codeName){
            this.buildRequest(attuid,codeName);
        }

        public void buildRequest(String attuid,String codeName){                                
            String queryString = '';
            queryString += 'attuid='+attuid;
            queryString += '&codename='+codeName;            
            
            this.callout = new BWC_DirectoryToolCallout.GetContactDetailsCallout(queryString);                  
        }

        public override Object buildResponse(){
            this.response = (BWC_DirectoryTool.GetContactDetailsResponse) this.callout.getResponse();
            return this.response;
        }

    }
}
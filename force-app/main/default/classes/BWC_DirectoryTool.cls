public class BWC_DirectoryTool {

    public class DTEditSettingsResponse extends BWC_Callout.CalloutResponse {
        public String attuid;
        public String channel;
        public String rolename;
        public List<StateResponse> state;
        public List<LocationResponse> location;
        public List<QuickLinksResponse> quicklinks;
        public String defaultstate;
        public Integer defaultstateid;
        public String defaultlocation;
        public Integer defaultlocationid;
        public Integer defaultqlid;
        public String message;
    }
    
    public class DTSaveSettingsRequest {
        public String userid;
        public String attuid;
        public String username;
        public String locationid;
        public String quicklistid;
        public String stateid; 
    }
    
    public class DTSaveSettingsResponse extends BWC_Callout.CalloutResponse {
		public String referencecode;
        public String message;         
    }
    
    public class DTQuickListsChannelResponse extends BWC_Callout.CalloutResponse{
        public List<QuickListsResponse> quicklists;
        public String defaultqlid;
    }
    
    public class DTSearchResultsResponse extends BWC_Callout.CalloutResponse {
        public List<DTSearchListResponse> searchListResponse;
    }
    
    public class DTSearchListResponse {
        public List<SearchResultResponse> searchresult;
        public List<QuickLinksResponse> quickLinks;
        public String totalrecords;
        public String message;
    }
     public class SearchResultResponse{
        public String contactName;
        public String contactNumber;
        public String codeName;
        public String extension;
        public Integer maininternal;
        public String status;
        public List<SpeedDialResponse> speeddial;
    }
    
    public class SpeedDialResponse{
        public List<RegionOrTypeResponse> regionortype;
    }
    public class RegionOrTypeResponse{
        public String regiontype;
        public String labelname;
        public List<LangNumResponse> langnum;
    }
    public class LangNumResponse{
        public String lang;
        public String num;
    }
    
     public class AddFeedbackRequest {
        public String attuid;
        public String contactname;
        public String username;        
        public String contactid;
        public String location;        
        public String locationid;
        public String channel;     
        public String channelid;
        public String feedback;
    }
    
    public class AddFeedbackResponse extends BWC_Callout.CalloutResponse {
        public String referencecode;
		public String Message;
        //public String description;
    }
    
    public class GetFeedbackResponse extends BWC_Callout.CalloutResponse {
        public String attuid;
        public String usernname;
        public String locationid;        
        public String locationname;
        public String channelid;        
        public String channelname;
        public String contactname;     
        public String createdate;
        public String updatedate;
        public String message;
    }
    
    public class StateResponse{
        public Integer stateid;
        public String statename;
    }
    
    public class LocationResponse{
        public Integer locationid;
        public String locationname;
        public Integer stateid;
    }
    
    public class QuickLinksResponse{
        public Integer qlid;
        public String qlname;
        public Integer locationid;
        public String linkname;
    }
    
    public class QuickListsResponse {
        public String quicklistid;
        public String quicklistname;
        public String channelid;
    }
    
    public class GetContactDetailsResponse extends BWC_Callout.CalloutResponse {       
        public String message;	
        public Integer cntid;	
        public String cntname;	
        public String grptype;	
        public String mainnumber;	
        public String mainext;	
        public Integer maininternal;
        public String createdate;	
        public String updatedate;	
        public String adlnum;	
        public String adlext;	
        public Integer adlinternal;	
        public String website;	
        public Integer websiteinternal;	
        public String email;	
        public Integer emailinternal;	
        public String description;	
        public String keywords;	
        public String notes;	
        public String normalhours;	
        public String region;	
        public String loctype;	
        public String acna;	
        public String cic;	
        public String createdby;	
        public String updatedby;	
        public String adlnum2;	
        public String adlnum3;	
        public String adlnum4;	
        public String adlnum5;	
        public String adlext2;	
        public String adlext3;	
        public String adlext4;	
        public String adlext5;	
        public Integer adlinternal2;	
        public Integer adlinternal3;	
        public Integer adlinternal4;	
        public Integer adlinternal5;	
        public String adldesc1;	
        public String adldesc2;	
        public String adldesc3;	
        public String adldesc4;	
        public String adldesc5;	
        public String contentlinkname;	
        public String contenturl;	
        public String contentlinkname1;	
        public String contenturl1;	
        public String contentlinkname2;	
        public String contenturl2;	
        public String contentlinkname3;	
        public String contenturl3;	
        public String adminnotes;	
        public String channels;	
        public List<ContactDayTimeResponse> contactdaytime;
    }
    
    public class ContactDayTimeResponse{
        public String totalhours;
        public String noHours;
        public List<specificHoursResponse> specifichours;
        
    }
    
    public class specificHoursResponse{
        public String Monday;
        public String Tuesday;
        public String Wednesday;
        public String Thursday;
        public String Friday;
        public String Saturday;
        public String Sunday;
    }
}
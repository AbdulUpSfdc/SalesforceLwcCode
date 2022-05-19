public with sharing class BWC_Kodiak {
    public static final String API_KODIAK = 'Kodiak_Search';
	public static final String ORIGINATOR_SFCCKM = 'SFCCKM';
	public static final String KM_BCSS_Advanced_Solutions_CS = 'KM_BCSS_Advanced_Solutions_CS';
	public static final String KM_BCSS_Adv_Tech_Support = 'KM_BCSS_Adv_Tech_Support';
    public static final String KM_BCSS_FirstNet = 'KM_BCSS_FirstNet';

	public class KodiakSearchRequest {
        public String attuid;
        public String originator;
        public String currentTimeStamp;
        public String defaultChannelId;
    }
    
    public class KodiakSearchResponse extends BWC_Callout.CalloutResponse{
        public String redirectLink;
        public String message;
        public String description;
        
    }
}
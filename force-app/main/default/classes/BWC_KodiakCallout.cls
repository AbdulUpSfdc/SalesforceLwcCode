public with sharing class BWC_KodiakCallout {
	public static final String API_Kodiak = 'Kodiak_Search';
    
    public class GetKodiakSearchCallout extends BWC_Callout{
        BWC_Kodiak.kodiakSearchRequest request;
        BWC_Kodiak.kodiakSearchResponse response;
        
        public GetKodiakSearchCallout(String queryString){
            this.setCallout(API_Kodiak,null,null,queryString,null);
        }
        
        public override Object buildResponse(){

            this.response = new BWC_Kodiak.kodiakSearchResponse();
            this.response = (BWC_Kodiak.kodiakSearchResponse) this.deserialize(BWC_Kodiak.kodiakSearchResponse.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);
            return this.response;
        }
    }
}
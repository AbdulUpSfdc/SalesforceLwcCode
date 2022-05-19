public with sharing class BWC_IMEISearchService {

    public static BWC_IMEISearch.IMEISearchResponse IMEISearch(String Imei){
        
        String queryString = getRequest(Imei);
        BWC_IMEISearch.IMEISearchResponse response = BWC_IMEISearchCallout.IMEISearch(queryString);
        return response;
    }
    
    public static String getRequest(String Imei){
        String params = '';
        BWC_IMEISearch.IMEISearchRequest request = new BWC_IMEISearch.IMEISearchRequest();
        String attuid = BWC_Utils.getCurrentUserAttId();
        if(attuid == null || attuid == ''){
            throw new BWC_Exception('ATTUID is empty on user record');
        }
        
        params += 'attuid=' + attuid + '&';
        params += 'imei=' + Imei;
        
        return params;
    }
}
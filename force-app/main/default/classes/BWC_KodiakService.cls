public with sharing class BWC_KodiakService {
    public class GetKodiakSearch extends BWC_AsyncServiceBase{
        
        public BWC_Kodiak.KodiakSearchRequest request;
        public BWC_Kodiak.KodiakSearchResponse response;
        
        public GetKodiakSearch(String localTime){
            
            //super(null, null);
            this.buildRequest(localTime);
            
        }
        
        public void buildRequest(String localTime){
            String params = '';
            BWC_Kodiak.KodiakSearchRequest request = new BWC_Kodiak.KodiakSearchRequest();
            String attuid = BWC_Utils.getCurrentUserAttId();
            if(attuid == null || attuid == ''){
                throw new BWC_Exception('ATTUID is empty on user record');
            }
            Employee__c employeeRecord = getEmployeeRecord(attuid);
            if(employeeRecord == null){
                throw new BWC_Exception('Employee Record Not Found for ' + attuid);
             }
            if(employeeRecord.BWDefaultKMChannel__c ==null){
                throw new BWC_Exception('No Default KM Channel is found for ' + attuid);
            }
            
            String localDateTimeFormatted = EncodingUtil.urlEncode(localTime, 'UTF-8').replaceAll('\\+','%20');
            params += 'attuid=' + attuid  + '&';
            params += 'originator=' + BWC_Kodiak.ORIGINATOR_SFCCKM + '&';
            params += 'currentTimeStamp=' +localDateTimeFormatted+ '&';
            params += 'defaultChannelId=' + employeeRecord.BWDefaultKMChannel__c ;     
            //params += 'defaultChannelId=324' ;     
            this.callout = new BWC_KodiakCallout.GetKodiakSearchCallout(params);
            
        }
        
        public override Object buildResponse(){
            
            this.response = (BWC_Kodiak.KodiakSearchResponse) this.callout.getResponse();
            return this.response;
        }
    }
    
    
    private static Employee__c getEmployeeRecord(String attuid){
        
        List<Employee__c> employeeRecords = [Select Id,BWDefaultKMChannel__c,BWDefault_KM_Master__c,User_Role__c,Employee_Type_Id__c from Employee__c WHERE EmployeeId__c =:attuid];
        if(employeeRecords.size() > 0){
            return employeeRecords[0];
        }
        
        return null;
    }
}
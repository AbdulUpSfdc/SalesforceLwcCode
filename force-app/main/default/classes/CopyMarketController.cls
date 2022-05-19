/********
    Name            : CopyMarketController
    Description     : This is the controller class to the LWC CopyMarketComponent.
********/

public class CopyMarketController{
    
    @auraEnabled
    public static ResponseHandler copyMarket(String recordId){
        try{
            CloneMarkets.cloneMarkets(recordId);
            return new ResponseHandler(true);
        }catch(Exception e){
             BWC_ExceptionUtils.handleException(e, true);
            return new ResponseHandler(e.getMessage());
        }
    }
    
    public class ResponseHandler{
        @AuraEnabled public boolean isSuccess{get;set;}
        @AuraEnabled public String errorMessage{get;set;}
        
        public ResponseHandler(boolean isSuccess){
            this.isSuccess = isSuccess;
            this.errorMessage = '';
        }
        
        public ResponseHandler(String errorMessage){
            this.isSuccess = false;
            this.errorMessage = errorMessage;
        }
    }
}
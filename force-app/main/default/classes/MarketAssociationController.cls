public class MarketAssociationController {

/********
    Name            : MarketAssociationController
    Description     : Controller class to the LWC ArticleAssociateMarket and ArticleDisassociateMarket Components.
********/
  
    @auraEnabled
    public static ResponseHandler associateMarkets(String recordId) {
        try{
            Markethelper.associateAllMarkets(recordId);
            return new ResponseHandler(true);
        }catch(Exception e){
            BWC_ExceptionUtils.handleException(e, true);
            return new ResponseHandler(e.getMessage());
        }
    }
    
    @auraEnabled
    public static ResponseHandler disassociateMarkets(String recordId) {
        try{
            Markethelper.disassociateAllMarkets(recordId);
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
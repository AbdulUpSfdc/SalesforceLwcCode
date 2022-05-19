public with sharing class BWC_PromotionDetailsService {

    /*
Service API to get user associations for one billing account. Note -- can expose API to get for multiple at one time, when needed.
*/
    
    public inherited sharing class GetPromotionDetailsService extends BWC_InteractionServiceBase{

        public List<BWC_PromotionDetails.PromotionDetailsRequest> request;
        public BWC_PromotionDetails.PromotionDetailsResponse response;
       

         /*
            Construct the service object from caller arguments.
        */
        public GetPromotionDetailsService(Id recordId,Id InteractionId) {

            super(InteractionId,recordId);
            this.buildRequest();

        }

        public void buildRequest() {
            
            List<Asset> listOfSubscribers = [
                SELECT
                Group_ID__c,Name, Status, ContractStart__c, ContractEnd__c, Contract_Type__c,
                ContractLength__c, Installment__c, Device_Pay_Off_Amount__c, Is_Primary__c
                FROM 
                Asset
                WHERE 
                Billing_Account__c =: this.billingAccounts
            ];

            // Build request list
            List<BWC_PromotionDetails.PromotionDetailsRequest> requests = new List<BWC_PromotionDetails.PromotionDetailsRequest>();
            
            List<BWC_PromotionDetails.Asset> bpdAssetList = new List<BWC_PromotionDetails.Asset>();
            
            for (Billing_Account__c billingAccount : this.billingAccounts) {
                if(billingAccount.Account_Type__c != 'wireless'){
                    requests.add(new BWC_PromotionDetails.PromotionDetailsRequest(billingAccount.Billing_Account_Number__c,billingAccount.Billing_Account_Number__c, billingAccount.Account_Type__c));
                }
                else {
                    BWC_PromotionDetails.PromotionDetailsRequest pdr = new BWC_PromotionDetails.PromotionDetailsRequest(
                    billingAccount.Billing_Account_Number__c,
                    billingAccount.Billing_Account_Number__c, 
                    billingAccount.Account_Type__c
                    );
                    
                    
                    if(listOfSubscribers.size()>=1){
                
                        for(Asset asst: listOfSubscribers){
                        BWC_PromotionDetails.Asset bpdAsset = new BWC_PromotionDetails.Asset();
                        bpdAsset.groupId = asst.Group_ID__c;
                        bpdAsset.subscriberId = asst.Name;
                        bpdAsset.status = asst.Status;
                        bpdAsset.contractType = asst.Contract_Type__c;
                        bpdAsset.contractStartDate = asst.ContractStart__c != null? String.valueOf(asst.ContractStart__c): null;
                        bpdAsset.contractEndDate = asst.ContractEnd__c != null? String.valueOf(asst.ContractEnd__c): null;
                        bpdAsset.contractTermInMonths = asst.ContractLength__c != null? String.valueOf(asst.ContractLength__c): null;
                        bpdAsset.monthsRemaining = asst.Installment__c != null ? String.valueOf(asst.Installment__c): null;
                        bpdAsset.earlyPayOffAmount = asst.Device_Pay_Off_Amount__c != null? String.valueOf(asst.Device_Pay_Off_Amount__c): null;
                        bpdAsset.isPrimarySubscriber = asst.Is_Primary__c;
                        bpdAssetList.add(bpdAsset);
                        }
                    }
                    if(bpdAssetList.size()>=1){
                        pdr.subscribers=bpdAssetList;
                    }
                    
                    requests.add(pdr);
                }
            }
                   
                    this.callout = new BWC_PromotionDetailsCallout.GetPromotionDetailsCallout(requests);
            
            
        }
    
        /*
            Builds and returns final response.
        */
         public override Object buildResponse() {

            this.response = (BWC_PromotionDetails.PromotionDetailsResponse)this.callout.getResponse();
            return this.response;

        }  
    }
}
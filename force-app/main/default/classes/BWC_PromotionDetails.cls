/*
Last Modified - 03/22/2021 - Added logic to add Asset details to callout request based on Account type of Billing Accounts. Story: 4214
*/
public with sharing class BWC_PromotionDetails {
    
    public class Asset{
        public String groupId;
        public String subscriberId;
        public String status;
        public String contractType;
        public String contractStartDate;
        public String contractEndDate;
        public String contractTermInMonths;
        public String monthsRemaining;
        public String earlyPayOffAmount;
        public Boolean isPrimarySubscriber;
        
    }
    public class PromotionDetailsRequest {
        
        public String customerId;
        public String accountId;
        public String accountType;
        public List<Asset> subscribers{get;set;}
        
        public PromotionDetailsRequest(String customerId, String accountId,String accountType){
            this.customerId = customerId;
            this.accountId = accountId;
            this.accountType =  accountType;
        }
        public PromotionDetailsRequest(String customerId, String accountId,String accountType, String promotionStatus){
            this.customerId = customerId;
            this.accountId = accountId;
            this.accountType =  accountType;
        }
        
    }


    public class PromotionDetailsResponse extends BWC_Callout.CalloutResponse {
        public List<PromotionDetailsResponseList> responses;
    }
    
    public class PromotionDetailsResponseList{
        public String accountNumber;
        public String accountType;
        public List<PromotionDetailsResponseItem> promotions;
    }

    public class PromotionDetailsResponseItem {
        public String promotionID;
        public String promotionCode;
        public String promotionAmount;
        public String promotionName;
        public String promotionDesc;
        public String promotionType;
        public String promotionStartDate;
        public String promotionEndDate;
        public String promotionStatus;
        public String promotionDuration;
        public Integer productId;
        public String productType;
        public String wirelessSubscriberNumber;
        public String wirelessPromotionLevel;
        public String promotionPlanLevel;
    } 

}
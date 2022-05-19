/*
    Shared code for Adjustments API.
*/
public with sharing class BWC_Adjustments {
    
    /*
        PostedAdjustmentsRequest Wrappers
    */
    public class PostedAdjustmentsRequest {
        public String accountNumber;
        public String accountType;
        public String market;
        public String agentId;
        public String adjLevel;
        public Boolean reqBilledInd;
        public String fromDate;
        public PaginationInfo paginationInfo;
    }

    public class PaginationInfo {
        public Integer pageNo;
        public Integer pageSize;
    }

    // Default Request Values
    public static final String DEFAULT_ADJ_LEVEL = 'A';
    public static final Boolean DEFAULT_REQ_BILLED_IND = true;
    public static final String DEFAULT_FROM_DATE = '1960-01-01';
    public static final Integer DEFAULT_PAGE_NO = 0;
    public static final Integer DEFAULT_PAGE_SIZE = 600;

    /*
        PostedAdjustments Response Wrappers
    */
    public class PostedAdjustmentsResponse extends BWC_Callout.CalloutResponse {
        public List<PostedAdjustment> response;
    }

    public class PostedAdjustment {
        public String accountNumber;
        public String accountType;
        public List<AdjustmentHistoryView> adjHistView;
        public String amountToCorrect;
        public String amountToSatisfy;
        public String lastAdjustmentDate;
        public String moreRows;
        public String numAdjToCorrect;
        public String numAdjToSatisfy;
        public String rowCount;
        public String sumAllActvAmt;
        public String sumAllTax;
        public String sumAllTotal;
        public String sumNumAdjToCorrectAndToSatisfy;
        public String sumAmountToCorrectAndToSatisfy;
    }

    public class AdjustmentHistoryView {
        public String adjGroupId;
        public String adjReversed;
        public String amount;
        public String amsProduct;
        public String balanceImpact;
        public String billDate;
        public String billedInd;
        public String billPeriod;
        public String chgGroupId;
        public String adjCreationDate {
            public get { return formatApiDate(adjCreationDate); }
            public set;
        }
        public String displayOnBill;
        public String level;
        public String pricePerUnit;
        public String productType;
        public String quantity;
        public String reason;
        public String source;
        public String sourceBan;
        public String subscriberNo;
        public String tax;
        public String total;
        public String userId;
        public String userLoginID;
        public String userOrSystemBillText;
    }

    /*
        PendingAdjustments Request Wrappers
    */
    public class PendingAdjustmentsRequest {
        public String accountNumber;
        public String accountType;
        public String market;
    }

    /* 
        PendingAdjustments Response Wrappers
    */
    public class PendingAdjustmentsResponse extends BWC_Callout.CalloutResponse {
        public List<PendingAdjustmentsResponseNode> response;
    }

    public class PendingAdjustmentsResponseNode {
        public String accountNumber;
        public String accountType;
        public List<PendingAdjustment> pendingAdjCredits;
    }

    public class PendingAdjustment {
        public String transactionType;
        public String transactionCode;
        public String description;
        public String transactionDate {
            public get { return formatApiDate(transactionDate); }
            public set;
        }
        public String nextBillDate {
            public get { return formatApiDate(nextBillDate); }
            public set;
        }
        public String subscriberNumber;
        public String amount;
        public String taxAmount;
        public String totalAmount;
        public String balanceImpacting;
        public String entSeqNo;
        public String type;
    }
    
    // API for PostedAdjustments does not return an ISO date, so we need to format theirs with String methods.
    private static String formatApiDate(String dateString) {
        String[] split = dateString.split('-');
        
        // Fail to Parse
        if(split.size() != 3) {
            return dateString;
        }

        return split[1] + '/' + split[2] + '/' + split[0];
    }

    /*
        CdeRecommendations Request Wrappers
    */
    public class CdeRecommendationsRequest {
        public String accountNumber;
        public String accountType;
        public String agentId; // This was also called agentId in other requests
        public String requestorAttuid; // This was also called agentId in other requests
        public String tlgProfileId;
        public List<CdeProductRequest> product;
    }

    public class CdeProductRequest {
        public Boolean isGoodwill;
        public String adjustmentReasonId;
        public String requestCreditAmount;
        public String adjustmentExplanationCode;
        public String linelevelOverrideIndicator;
        public String overrideApproversId;
        public String chargeCode;
        public String chargeDate;
        public String chargeAmount;
        public String billStatementDate;
        public String billStartDate;
        public String billEndDate;
        public String sequenceNumber;
    }

    /*
        CdeRecommendations Response Wrappers
    */
    public class CdeRecommendationsResponse extends BWC_Callout.CalloutResponse {
        public String transactionId;
        public String timeStamp;
        public String accountNumber;
        public String overallCDEStatus;
        public String overallCDERequestedAmount;
        public String overallCDEApprovedAmount;
        public String decisionOverrideProfiles;
        public String displayTextForCustomer;
        public String displayTextForReps;
        public String overrideProfileType;
        public List<CdeProductResponse> product;
    }

    public class CdeProductResponse {
        public String isGoodwill;
        public String requestCreditAmount;
        public String adjustmentExplanationCode;
        public String sequenceNumber;
        public String productLevelId;
        public String decisionStatus;
        public String approvedAmount;
        public String displayTextForCustomer;
        public String displayTextForReps;
        public String rulesApplied;
    }

    /*
        PostAdjustments Request Wrappers
    */
    public class PostAdjustmentsRequest {
        public String accountNumber;
        public String accountType;
        public String caseId;
        public String decisionUpdateTrnsId;
        public String marketCode;
        public String externalUserId;
        public String SOALimitExceeded;
        public String transBillerAdjustmentStatus;
        public String interactionId;
        public String requestingAgentId;
        public List<PostAdjustmentsLineItem> lineItems;
    }

    public static final String DEFAULT_TRANS_BILLER_ADJUSTMENT_STATUS = 'POSTED';

    public class PostAdjustmentsLineItem {
        public Boolean isGoodwill;
        public String productLevelId;
        public String billerAdjustmentStatus;
        public String billDate;
        public String billSeqNo;
        public String billChrgSeqNo;
        public String adjustedAmount;
        public String effectiveDate;
        public Boolean overridden;
        public String adjAmountType;
        public String chargeLevel;
        public String subscriberNbr;
        public String adjustmentReasonCode;
    }

    /*
        PostAdjustments Response Wrappers
    */

    public class PostAdjustmentsResponse extends BWC_Callout.CalloutResponse {
        public List<PostAdjustmentsResponseNode> adjOutputInfo;
    }

    public class PostAdjustmentsResponseNode {
        public String billSeqNo;
        public String billChrgSeqNo;
        public String adjAmount;
        public String adjReasonCode;
        public String chgSeqNo;
        public String effectiveDate;
    }

    /*
        ReverseAdjustment Request Wrappers
    */
    public class ReverseAdjustmentRequest {
        public String accountNumber;
        public String accountType;
        public String market;
        public String agentId;
        public String agentName;
        public String revAdjAmount;
        public String reasonCode;
        public String adjSeqNumber;
        public Boolean isBillIgnore;
        public String chargeLevel;
        public String productType;
        public String userText;
        public String subscriberNumber;
    }
    
    /*
        ReverseAdjustment Response Wrappers
    */
    public class ReverseAdjustmentResponse extends BWC_Callout.CalloutResponse {
        public ReverseAdjustmentResponseInfo adjRevOutInfo;
    }

    public class ReverseAdjustmentResponseInfo {
        public String adjTotalAmount;
    }

}
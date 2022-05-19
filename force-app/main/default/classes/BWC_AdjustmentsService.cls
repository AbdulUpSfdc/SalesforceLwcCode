public with sharing class BWC_AdjustmentsService {

    /*
        Call Posted Adjustments Service Synchronously
    */
    public static List<BWC_Adjustments.PostedAdjustment> getPostedAdjustments(
        String recordId, List<BWC_Adjustments.PostedAdjustmentsRequest> requests
    ) {
        
        BWC_AdjustmentsService.GetPostedAdjustmentsService service = 
            new BWC_AdjustmentsService.GetPostedAdjustmentsService(recordId, requests);
        
        BWC_Adjustments.PostedAdjustmentsResponse response = 
            (BWC_Adjustments.PostedAdjustmentsResponse) service.call();
        
        return response.response;
    }

    /*
        Full Posted Adjustments Service Class with Async & Sync Callout Methods
    */
    public class GetPostedAdjustmentsService extends BWC_InteractionServiceBase {

        // Request & Response State
        public String attUID;
        public List<BWC_Adjustments.PostedAdjustmentsRequest> requests;
        public BWC_Adjustments.PostedAdjustmentsResponse response;

        public GetPostedAdjustmentsService(
            String interactionId, List<BWC_Adjustments.PostedAdjustmentsRequest> requests
        ) {

            super(interactionId, null);

            // Save State of Requests
            this.requests = requests;

            this.attUID = BWC_Utils.getCurrentUserAttId();

            this.buildRequest();

            // Create Callout for Posted Adjustments
            this.callout = new BWC_AdjustmentsCallout.GetPostedAdjustmentsCallout(this.requests);

        }

        /*
            Prepare the request for Callout
        */
        public void buildRequest() {
            
            // Initialize default values if needed
            for(BWC_Adjustments.PostedAdjustmentsRequest r : this.requests) {

                r.agentId = this.attUID;
                if(r.adjLevel == null) { 
                    r.adjLevel = BWC_Adjustments.DEFAULT_ADJ_LEVEL; 
                }
                if(r.reqBilledInd == null) { 
                    r.reqBilledInd = BWC_Adjustments.DEFAULT_REQ_BILLED_IND; 
                }
                if(r.fromDate == null) { 
                    r.fromDate = BWC_Adjustments.DEFAULT_FROM_DATE; 
                }
                if(r.paginationInfo == null) {
                    r.paginationInfo = new BWC_Adjustments.PaginationInfo();
                }
                if(r.paginationInfo.pageNo == null) { 
                    r.paginationInfo.pageNo = BWC_Adjustments.DEFAULT_PAGE_NO; 
                }
                if(r.paginationInfo.pageSize == null) { 
                    r.paginationInfo.pageSize = BWC_Adjustments.DEFAULT_PAGE_SIZE; 
                }
            }
        }

        /*
            Prepare the response for Controller
        */
        public override Object buildResponse() {

            this.response = (BWC_Adjustments.PostedAdjustmentsResponse) this.callout.getResponse();

            return this.response;
        }
    }

    /*
        Call Pending Adjustments Service Synchronously
    */
    public static List<BWC_Adjustments.PendingAdjustmentsResponseNode> getPendingAdjustments(
        String recordId, List<BWC_Adjustments.PendingAdjustmentsRequest> requests
    ) {
        
        BWC_AdjustmentsService.GetPendingAdjustmentsService service = 
            new BWC_AdjustmentsService.GetPendingAdjustmentsService(recordId, requests);
        
        BWC_Adjustments.PendingAdjustmentsResponse response = 
            (BWC_Adjustments.PendingAdjustmentsResponse) service.call();
        
        return response.response;
    }

    /*
        Full Pending Adjustments Service Class with Async & Sync Callout Methods
    */
    public class GetPendingAdjustmentsService extends BWC_InteractionServiceBase {

        // Request & Response State
        public String attUID;
        public List<BWC_Adjustments.PendingAdjustmentsRequest> requests;
        public BWC_Adjustments.PendingAdjustmentsResponse response;

        public GetPendingAdjustmentsService(
            String interactionId, List<BWC_Adjustments.PendingAdjustmentsRequest> requests
        ) {

            super(interactionId, null);

            // Save State of Requests
            this.requests = requests;

            this.attUID = BWC_Utils.getCurrentUserAttId();

            // Create Callout for Pending Adjustments
            this.callout = new BWC_AdjustmentsCallout.GetPendingAdjustmentsCallout(this.requests);

        }

        /*
            Prepare the response for Controller
        */
        public override Object buildResponse() {

            this.response = (BWC_Adjustments.PendingAdjustmentsResponse) this.callout.getResponse();

            return this.response;
        }
    }

    /*
        Call CDE Recommendations Service Synchronously
    */
    public static BWC_Adjustments.CdeRecommendationsResponse getCdeRecommendations(
        String recordId, BWC_Adjustments.CdeRecommendationsRequest request
    ) {
        
        BWC_AdjustmentsService.GetCdeRecommendationsService service = 
            new BWC_AdjustmentsService.GetCdeRecommendationsService(recordId, request);
        
        BWC_Adjustments.CdeRecommendationsResponse response = 
            (BWC_Adjustments.CdeRecommendationsResponse) service.call();
        
        return response;
    }

    /*
        Full CDE Recommendations Service Class with Async & Sync Callout Methods
    */
    public class GetCdeRecommendationsService extends BWC_InteractionServiceBase {

        // Request & Response State
        public String attUID;
        public Employee__c employee;
        public BWC_Adjustments.CdeRecommendationsRequest request;
        public BWC_Adjustments.CdeRecommendationsResponse response;

        public GetCdeRecommendationsService(
            String interactionId, BWC_Adjustments.CdeRecommendationsRequest request
        ) {

            super(interactionId, null);

            this.attUID = BWC_Utils.getCurrentUserAttId();

            // Save State of Request
            this.request = request;

            buildRequest();

            // Create Callout for CDE Recommendations
            this.callout = new BWC_AdjustmentsCallout.GetCdeRecommendationsCallout(this.request);

        }

        public void buildRequest() {

            this.request.agentId = this.attUID;
            this.request.requestorAttuid = this.attUID;

            this.employee = BWC_Employee_Selector.getEmployeeByUID(this.attUID);

            if(this.employee == null || this.employee.SFProfileId__c == null) {
                throw new BWC_Exception('Missing Employee Record ATTUid');
            }
    
            if(this.employee.SOA_Level__c == null) {
                throw new BWC_Exception('Missing SOA Level in Employee Record.');
            }

            this.request.tlgProfileId = this.employee.SOA_Level__c;

        }

        /*
            Prepare the response for Controller
        */
        public override Object buildResponse() {

            this.response = (BWC_Adjustments.CdeRecommendationsResponse) this.callout.getResponse();

            // After successful response increment use count.
            for(BWC_Adjustments.CdeProductRequest r : this.request.product) {
                BWC_ChargeCodeService.incrementReasonCodeUseCount(r.adjustmentReasonId);
            }

            return this.response;
        }
    }

    /*
        Call Post Adjustments Service Synchronously
    */
    public static BWC_Adjustments.PostAdjustmentsResponse postAdjustments(
        String recordId, BWC_Adjustments.PostAdjustmentsRequest request
    ) {
        
        BWC_AdjustmentsService.GetPostAdjustmentsService service = 
            new BWC_AdjustmentsService.GetPostAdjustmentsService(recordId, request);
        
        BWC_Adjustments.PostAdjustmentsResponse response = 
            (BWC_Adjustments.PostAdjustmentsResponse) service.call();
        
        return response;
    }

    /*
        Full Post Adjustment Service Class with Async & Sync Callout Methods 
    */
    public class GetPostAdjustmentsService extends BWC_InteractionServiceBase {

        // Request & Response State
        public String attUID;
        public BWC_Adjustments.PostAdjustmentsRequest request;
        public BWC_Adjustments.PostAdjustmentsResponse response;

        public GetPostAdjustmentsService(
            String interactionId, BWC_Adjustments.PostAdjustmentsRequest request
        ) {

            super(interactionId, null);

            this.attUID = BWC_Utils.getCurrentUserAttId();

            // Save State of Request
            this.request = request;

            buildRequest();

            // Create Callout for CDE Recommendations
            this.callout = new BWC_AdjustmentsCallout.GetPostAdjustmentsCallout(this.request);

        }

        public void buildRequest() {

            this.request.requestingAgentId = this.attUID;
            this.request.externalUserId = this.attUID;

            // Set Defaults
            request.transBillerAdjustmentStatus = String.isBlank(request.transBillerAdjustmentStatus) ? BWC_Adjustments.DEFAULT_TRANS_BILLER_ADJUSTMENT_STATUS : request.transBillerAdjustmentStatus;

            Billing_Account__c a = BWC_AccountService.getBillingAccountForBan(request.accountNumber);

            if(a.Billing_Market__c == null) {
                throw new BWC_Exception('The Account does not have a Billing Market specified.');
            }

            request.marketCode = a.Billing_Market__c;
        }

        /*
            Prepare the response for Controller
        */
        public override Object buildResponse() {

            this.response = (BWC_Adjustments.PostAdjustmentsResponse) this.callout.getResponse();

            return this.response;
        }
    }

    /*
        Call Reverse Adjustment Service Synchronously
    */
    public static BWC_Adjustments.ReverseAdjustmentResponse reverseAdjustment(
        String recordId, BWC_Adjustments.ReverseAdjustmentRequest request
    ) {
        
        BWC_AdjustmentsService.GetReverseAdjustmentService service = 
            new BWC_AdjustmentsService.GetReverseAdjustmentService(recordId, request);
        
        BWC_Adjustments.ReverseAdjustmentResponse response = 
            (BWC_Adjustments.ReverseAdjustmentResponse) service.call();
        
        return response;
    }

    /*
        Full Reverse Adjustment Service Class with Async & Sync Callout Methods 
    */
    public class GetReverseAdjustmentService extends BWC_InteractionServiceBase {

        // Request & Response State
        public String attUID;
        public BWC_Adjustments.ReverseAdjustmentRequest request;
        public BWC_Adjustments.ReverseAdjustmentResponse response;

        public GetReverseAdjustmentService(
            String interactionId, BWC_Adjustments.ReverseAdjustmentRequest request
        ) {

            super(interactionId, null);

            this.attUID = BWC_Utils.getCurrentUserAttId();

            // Save State of Request
            this.request = request;

            buildRequest();

            // Create Callout for CDE Recommendations
            this.callout = new BWC_AdjustmentsCallout.GetReverseAdjustmentCallout(this.request);

        }

        public void buildRequest() {

            this.request.agentId = this.attUID;
            this.request.agentName = UserInfo.getUserName();

        }

        /*
            Prepare the response for Controller
        */
        public override Object buildResponse() {

            this.response = (BWC_Adjustments.ReverseAdjustmentResponse) this.callout.getResponse();

            return this.response;
        }
    }
}
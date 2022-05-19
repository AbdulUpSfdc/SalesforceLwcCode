public with sharing class BWC_CommunicationHistory {

    public class HistoryDetailRequest{
        public NhQryEvent nhQryEvent;
    }

    public class NhQryEvent{
        public String category;
        public String fromTime;
    }
    
    public class HistoryDetailResponse{
        public Boolean resendFlag;
        public String uniqueId;
        public String mode;
        public String email;
        // TODO: ms to change from
        public String fromEmail;
    }

    public class ResendRequest{
        public ResendDetails resendDetails;
    }

    public class ResendDetails{
        public String uniqueId;
        public String category;
    }

    public class ResendResponse{
        public String statusCode;
        public String message;
    }

}
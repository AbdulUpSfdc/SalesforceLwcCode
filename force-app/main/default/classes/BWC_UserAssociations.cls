/*
    Shared code for UserAssociations api.
*/
public with sharing class BWC_UserAssociations {

    /*
        Request and response wrappers.
    */

    public class UserAssociationsRequest {

        public String accountId;
        public String accountType;
        public String authUserType;
        
        public UserAssociationsRequest(String accountId, String accountType) {
            this.accountId = accountId;
            this.accountType = accountType;
        }

    }

    public class UserAssociationsResponse extends BWC_Callout.CalloutResponse {
           public List<UserAssociationsResponseListResponse> responses;
      }
  
      public class UserAssociationsResponseListResponse{
          public String accountId;
          public String accountType;
          public String authUserType;
          public Record record;
      }

    public class Record {
        public List<UserAssociation> users;
        public String systemOfRecord;
        public Integer code;
        public String message;
        public String description;
        public String transactionId;
        public String traceId;
        public ErrorPayload errorPayload;
    }

    public class UserAssociation {

        public String slid;
        public String firstName;
        public String middleName;
        public String lastName;
        public String suffix;
        public String associationType;

        // Retrieve Only
        public String authUserType;

        // Used for Add only
        public String id;
        public String userType;
        public String accountId;
        public String accountType;

    }

    public class AddDeleteUserAssociationsResponse {
        public String id;
        public AddDeleteUserAssociateResult result;
        public BWC_MuleServiceError error;
    }

    public class AddDeleteUserAssociateResult {
        public String status;
    }

    public class ErrorPayload {
        public Error error;
    }

    public class Error {
        public String errorId;
        public String message;
        public List<ErrorDetail> details;
    }

    public class ErrorDetail {
        public String code;
        public String message;
    }

}
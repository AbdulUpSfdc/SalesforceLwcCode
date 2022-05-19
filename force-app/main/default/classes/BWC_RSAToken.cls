public with sharing class BWC_RSAToken {

    public class RSATokenRequest {
        public String attuid;
        public String firstName;
        public String lastName;
        public String channel;
        public String market;
        public String role;
        public String employeeType;
        
    }
    
    public class RSATokenResponse{
        public String attuid;
        public String token;
        public String serialnum;
        public String timestamp;
        public String message;
    }
}
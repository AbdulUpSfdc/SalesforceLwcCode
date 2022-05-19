/*
    Shared code for OPUS api request.
*/
// TODO: Explain that this class is used to serialize the data into JSON for the JavaScript window.postMessage() to OPUS
public with sharing class BWC_LIC_OpusMsgRequest {
    /*
        Request and response wrappers.
        // TODO: need comments on each sub-class explaining what that object is used for
    */
    public class OPUSInitRequest{
        // TODO: add comments for each public attribute explaining what it is used for and what a sample value would be
        // TODO: should a constructor be added?
        // TODO: What about initializing the sfCustomInfo to a new List<>() so you don't have to new/put it in code? Or add an 'add()' helper method?
        public String sysId;
        public String repDetails;
        public String trackingIdent;
        public String storeLocationId;
        public String callerFirstName;
        public String callerLastName;
        public String callIntent;
        public String campaignCode;
        public String relaunch;
        public String launchIntent ;
        public String sfLeadRecordId; //US-5046
        public String orderID ;
        public String sfRecordId;
        public List<SfCustomerInfo> sfCustomerInfo;
    }

    public class SfCustomerInfo {
		public String customerType;
		public String AddressId;
		public String LOBType;
		public String AccNumber;
		public String CTN;
		public String isVerified;
        public String primarySearchAccount;
        public String cssIdForAvertack;
        public String customerLastName;
        public String customerFirstName;
        public String email;
        public String cbr; // can be reach phone number
    }
    
    public class OpusMessage{
        public String task;
        public OPUSInitRequest data;
    }

    public class OpusPost {
        public OpusMessage msg;
    }

}
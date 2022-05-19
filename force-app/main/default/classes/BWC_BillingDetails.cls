/*
    Shared code for Billing Details api.
*/
public with sharing class BWC_BillingDetails {
    /*
        Request and response wrappers.
    */
    public class BillingDetailsResponse {
        public BillingDetailsContent content;
    }

    public class BillingDetailsContent {
		public BillInfo billInfo;
		public BillSummary billSummary;
        public Service acctChrgs;
        public Service uverseTvChrgs;
        public Service direcTvChrgs;
        public List<Service> combinedDtvChrgsList;
        public Service hsiaChrgs;
        public Service voipChrgs;
        public Service wllVoiceChrgs;
        public Service wllIntrntChrgs;
        public WirelessService wirelessChrgs;
        public Boolean billFound;
    }

    public class BillInfo {
		public String cycleStDate;
		public String cycleEndDate;
        public String statementID;
		public Address address;
        public String ban;
		public String fanID;
		public String bbInstance;
		public String billngSystem;
		public String marketZone;
		public String billingMethod;
		public String paperBillInd;
        public String autoPayInd;
        public String billSeqNbr;
    }

    public class Address {
		public String name;
        public List<String> addressLines;
    }

    public class BillSummary {
        public String hdr;
        public List<Amount> pmtList;
        public List<Amount> adjList;
		public Amount prevBal;
		public Amount newChrgs;
		public Amount totChrgs;
		public Amount rmningBal;
        public List<String> amountDueMsg;
        public Amount totalPayments;
		public Amount totalAdjustments;
		public Amount prevRmningBal;
    }

    public class WirelessService {
		public String wirelessServiceDesc;
		public Amount totalWirelessServiceAmt;
		public Amount prevWirelessServiceAmt;
		public Amount varWirelessServiceAmt;
        public List<SubscriberService> wirelessServiceList;
    }

    public class Service {
		public String serviceDesc;
		public Amount totalServiceAmt;
		public Amount prevServiceAmt;
        public Amount varServiceAmt;
        public List<SectionBean> sectionBeanList;
    }

    public class SubscriberService {
		public String serviceDesc;
		public Amount totalServiceAmt;
		public Amount prevServiceAmt;
		public Amount varServiceAmt;
		public String ctn;
		public String ctnUser;
        public String groupId;
		public List<SectionBean> sectionBeanList;
        public Boolean group_z;// in json: group
        public Integer nbrOfDevices;
    }

    public class SectionBean {
		public String sectionDesc;
		public Amount totalSectAmt;
		public Amount prevSectAmt;
		public Amount varSectAmt;
		public List<Amount> chargeList;
        public List<Section> subSectionList;
        public String type;
    }

    public class Section {

    }

    public class Amount {
		public String date1;
		public String date2;
		public String amt;
		public List<String> descList;
		public String amtInd;
        public String type;// in json: type
        public String chrgSeqNbr;
    }

    public class BillPdfResponse {
        public BillPdfContent content;
        public Error error;
    }

    public class BillPdfContent {

        public String pdfData;
        public Boolean pdfReturned;
        public String ContentType;
        public String SOR;
        public String ErrorCode;

    }

    public class Error {

        public String errorId;
        public String message;

    }

    /**
     * Response with Eligible for Adjustment Line Items
    */
    public class AdjustableLineItemsResponse {
        public List<AdjustableLineItem> adjustableLineItems;
    }

    public class AdjustableLineItem {
        public String service;
        public String lineItemGroup;
        public String description;
        public String selectedBillAmount;
        public String billSequenceNumber;
        public Boolean isBANLevel;
        public String chargeSequenceNumber;
        public String ctn;
        public String chargeCode;
    }

    /**
     * Request for Charge Codes API
    */
    public class ChargeCodesRequest {
        public String accountNumber;
        public String accountType;
        public String customerType;
        public String agentId;
        public String callingSystemId;
        public String originatorSystemId;
        public String originatorSessionId;
        public String marketCode;
        public List<BillData> billData;
    }

    public class BillData {
        public String billSequenceNumber;
        public Boolean isBANLevel;
        public String chargeSequenceNumber;
        public String chargeCode;
        public String ctn;
    }

    /**
     * Response for Charge Codes API
    */
    public class ChargeCodesResponse {
        public String transactionId;
        public String originatorSessionId;
        public List<BillData> billData;
    }

}
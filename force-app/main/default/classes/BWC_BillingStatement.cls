/*
    Shared code for Billing Statement api.
*/
public with sharing class BWC_BillingStatement {
    
    public static final String BILLINGACCOUNT_WIRELINE = 'Wireline';

    /*
        Request and response wrappers.
    */
    public class BillingStatementRequest {
        public String product;
        public String ban;

        public BillingStatementRequest() { 
        }
        
        public BillingStatementRequest(String ban, String product) {
            this.ban = ban;
            this.product = product;
        }
    }

    public class BillingStatementResponse extends BWC_Callout.CalloutResponse{
        public List<StatementSummary> Wireline;
        public List<StatementSummary> Wireless;
    }

    public class StatementSummary {
		public String statementID;
		public String cycleStartDate;
		public String cycleEndDate;
		public String billDueDate;
		public TotalAmountDue totalAmountDue;
		public String ban;
		public String billType;
	}

	public class TotalAmountDue {
		public String amt;
	}
}
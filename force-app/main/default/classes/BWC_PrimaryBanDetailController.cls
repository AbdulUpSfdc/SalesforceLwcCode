/* This class will the help the LWC component bwcPrimaryBanDetail to show 
* details. The <Wireless> Detail component on the person account page  will
* get populated by the below component.
*
* The below queries are need as we are on person account page and we have the
* person account Id. From person account we need to tranverse to Billing 
* account via a junction object Customer Account Relationship.
*/
public with sharing class BWC_PrimaryBanDetailController {
    
    @AuraEnabled
    public static String getPrimaryBanDetails(String recordId){
        PrimanyBanDetail pbd = new PrimanyBanDetail();
        Account acct;
        List<String> baIdLst = new List<String>();
        List<Billing_Account__c> baLst;
        Billing_Account__c ba;
        RecordDetailsWrapper result = new RecordDetailsWrapper();
        try{

            // Convert to Person Account id if recordId passed is Interaction__c Id
            recordId = BWC_Utils.getAccountIdFromInteractionId(recordId);
            
            acct = [SELECT Id,Primary_Product__c,Primary_BAN__c,isFirstNet__c,
                        
                            (SELECT Id,Billing_Account__c 
                            FROM Customer_Account_Relation__r) FROM Account WHERE id=:recordId];
            List<Customer_Account_Relation__c>  csrList =   acct.Customer_Account_Relation__r;
            
            for(Customer_Account_Relation__c car : csrList) {
                baIdLst.add(car.Billing_Account__c);
            } 
         
  
            if(baIdLst.size()>0){
                baLst = [SELECT Id,Customer_Since__c,Billing_Address_Line_1__c,
                    Billing_Address_Line_2__c,Billing_City__c,Billing_State__c,
                    Billing_Country__c,toLabel(Account_Type__c),Billing_Zipcode__c,
                    Service_Address_Line_1__c,Service_Address_Line_2__c,
                    Service_City__c,Service_State__c,Visually_Impaired__c,
                    Language_Preference__c,Enrolled_in_Large_Print__c,Customer_Type__c,
                    Service_Zipcode__c,CPNI_Preference__c ,Service_Start_Date__c 
                    FROM Billing_Account__c
                    WHERE Id in :baIdLst
                    AND Billing_Account_Number__c=:acct.Primary_BAN__c];
                
            }
            if(baIdLst.size()>0 && baLst.size()>0){
                ba = baLst[0];      
                //pbd.header = acct.Primary_Product__c +' Details';
                pbd.header = ba.Account_Type__c +' Details';
                String dateFormatString = 'MM/dd/yyyy';
                if(ba.Service_Start_Date__c!=null){
                    Date d = ba.Service_Start_Date__c;
                    Datetime dt = Datetime.newInstance(d.year(), d.month(),d.day());
                    pbd.customerSince = dt.format(dateFormatString);
                }
                //pbd.billAddr1 = '';
                pbd.billAddr  = concatenateAddress(pbd.billAddr,ba.Billing_Address_Line_1__c );
                pbd.billAddr  = concatenateAddress(pbd.billAddr,ba.Billing_Address_Line_2__c, true);
                pbd.billAddr1 = concatenateAddress(pbd.billAddr1,ba.Billing_City__c );
                pbd.billAddr1 = concatenateAddress(pbd.billAddr1,ba.Billing_State__c, true);
                pbd.billAddr1 = concatenateAddress(pbd.billAddr1,ba.Billing_Zipcode__c);

                pbd.servAddr  = concatenateAddress(pbd.servAddr,ba.Service_Address_Line_1__c );
                pbd.servAddr  = concatenateAddress(pbd.servAddr,ba.Service_Address_Line_2__c, true);
                pbd.servAddr1 = concatenateAddress(pbd.servAddr1,ba.Service_City__c );
                pbd.servAddr1 = concatenateAddress(pbd.servAddr1,ba.Service_State__c, true);
                pbd.servAddr1 = concatenateAddress(pbd.servAddr1,ba.Service_Zipcode__c );
                
                pbd.acctType = ba.Customer_Type__c;
                pbd.cpniInd = ba.CPNI_Preference__c;
                pbd.langPref = ba.Language_Preference__c;
                pbd.visuallyimp = String.valueOf(ba.Visually_Impaired__c);
                pbd.enrllinlarprt = String.valueOf(ba.Enrolled_in_Large_Print__c);
                pbd.isFirstNet = acct.isFirstNet__c;
                if(ba.Customer_Type__c == 'Business' || ba.Customer_Type__c == 'Government'){
                    pbd.isBusinessCustomer = true;
                }
            } 
            result.success = true;
            result.recordDetails = pbd;           
        } catch (Exception e){          
            System.debug('BWC_PrimaryBanDetailController.getPrimaryBanDetails() :'+e.getMessage());
            BWC_ExceptionUtils.handleException(e, 'personAccountId: ' + recordId, null);
            result.message = e.getMessage();
            result.success = false;
        }  
        return JSON.serialize(result);
    }

    public class PrimanyBanDetail{
        public String header;
        public String customerSince;
        public String billAddr;
        public String billAddr1;
        public String servAddr;
        public String servAddr1;
        public String acctType;
        public String cpniInd;
        public String langPref;
        public String visuallyimp;
        public String enrllinlarprt;
        public Boolean isFirstNet;
        public Boolean isBusinessCustomer;
    }

    public class RecordDetailsWrapper {

        public Boolean success {get; set;}
        public String message {get; set;}

        public PrimanyBanDetail recordDetails;

    }

    private static String  concatenateAddress(String main,String toadd){
        return concatenateAddress(main, toadd, false);
    }

    private static String  concatenateAddress(String main,String toadd, Boolean useComma){
       String addr = '';
        if(main != null && main != ''){
            if(toadd != null && toadd != ''){
                addr = main + (useComma == true ? ', ' : ' ') + toadd;
            } else {
                addr = main;
            }
        } else {
            if(toadd != null && toadd != ''){
                addr = toadd;
            }
        }
       return addr;
   }
}
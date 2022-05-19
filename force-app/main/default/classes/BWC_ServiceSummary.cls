/* This class will the help the LWC component bwcSersumAcctdet to show
* details. The service summary component on the person account page  will
* get populated by the below component.
*
* The below queries are needed as we are on person account page and we have the
* person account Id. From person account we need to tranverse to Billing
* account via a junction object Customer Account Relationship.
*
* TestClassName : BWC_ServiceSummary_Test.cls
*/
public with sharing class BWC_ServiceSummary {

    private static String BUSINESS_CUSTOMER_TYPE = 'Business';
    private static String GOVERNMENT_CUSTOMER_TYPE = 'Government';

    @AuraEnabled
    public static String getServiceDetails(String recordId){
        ServiceSummaryWrapper response = new ServiceSummaryWrapper();
        List<ServSumm> srvsumLst = new List<ServSumm>();
        Account acct;
        Interaction__c interaction = BWC_Interaction.getInteraction(recordId);
        BWC_AuthorizationCallout.AuthorizationStatusContent authorizationData =
            (BWC_AuthorizationCallout.AuthorizationStatusContent)JSON.deserialize(interaction.Authorization_Json__c, BWC_AuthorizationCallout.AuthorizationStatusContent.class);

        Map<String, String> banAuthLevelMap = new Map<String, String>();
        for(BWC_AuthorizationCallout.AssociatedAccount acc : authorizationData.associatedAccounts){
            banAuthLevelMap.put(acc.accountBan, acc.authorizationLevel);
        }

        try{
            // Convert to Person Account id if recordId passed is Interaction__c Id
            recordId = BWC_Utils.getAccountIdFromInteractionId(recordId);

            acct = [SELECT Id,
                        Primary_BAN__c,
                        isFirstNet__c,
                        (SELECT Billing_Account__c
                        FROM Customer_Account_Relation__r)
                    FROM Account
                    WHERE Id=:recordId
                    WITH SECURITY_ENFORCED];
        } catch (Exception e){
            System.debug('BWC_ServiceSummary.getServiceDetails() :'+e.getMessage());
        }

        if(acct!=null){
            List<Id> billacctId = new List<Id>();
            for(Customer_Account_Relation__c car :acct.Customer_Account_Relation__r){
                billacctId.add(car.Billing_Account__c);
            }
            List<Billing_Account__c> baLst = [SELECT Id, Service_Type_Name__c,
                                Customer_Type__c,
                                Billing_Account_Number__c,
                                Service_Start_Date__c,
                                toLabel(Account_Status__c),
                                Suspension_Status__c
                            FROM Billing_Account__c
                            WHERE Id in :billacctId
                            WITH SECURITY_ENFORCED
                            ORDER BY Service_Start_Date__c DESC];
            for(Billing_Account__c ba : baLst){
                ServSumm ss= new ServSumm();
                ss.lob = ba.Service_Type_Name__c;
                ss.suspensionStatus = ba.Suspension_Status__c;

                String authLevel =banAuthLevelMap.get(ba.Billing_Account_Number__c);
                String ban = ba.Billing_Account_Number__c;
                if(!BWC_Constants.AUTHORIZATION_LEVELS_L1_PRIVILEGED.contains(authLevel)){
                    ban = '****'+ba.Billing_Account_Number__c.right(4);
                }
                ss.ban = ban;
                String dateFormatString = 'MM/dd/yyyy';
                if(ba.Service_Start_Date__c!=null){
                    Date d = ba.Service_Start_Date__c;
                    Datetime dt = Datetime.newInstance(d.year(), d.month(),d.day());
                    ss.serstart = dt.format(dateFormatString);
                }
                ss.acctStatus = ba.Account_Status__c;
                if(ba.Account_Status__c==BWC_Constants.STATUS_SUSPENDED){
                    ss.redfont = BWC_Constants.SLDS_ERROR ;
                }

                if(ba.Billing_Account_Number__c.equals(acct.Primary_BAN__c)){
                    if(GOVERNMENT_CUSTOMER_TYPE.equals(ba.Customer_Type__c) || BUSINESS_CUSTOMER_TYPE.equals(ba.Customer_Type__c)){
                        response.isBusinessCustomer = true;
                    }
                }
                srvsumLst.add(ss);
            }
            response.services = srvsumLst;
            response.isFirstNet = acct.isFirstNet__c;

            return JSON.serialize(response);
        }
        return null;
    }

    public class ServSumm{
        public String lob;
        public String serstart;
        public String acctStatus;
        public String redfont;
        public String ban;
        public String suspensionStatus;
    }

    public class ServiceSummaryWrapper{
        public List<ServSumm> services;
        public Boolean isFirstNet=false;
        public Boolean isBusinessCustomer=false;
    }

}
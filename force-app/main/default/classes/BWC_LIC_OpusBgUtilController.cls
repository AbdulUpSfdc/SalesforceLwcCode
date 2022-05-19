/*
 *  Exposes methods to allow Aura to get constant variable.
 */
public with sharing class BWC_LIC_OpusBgUtilController
{

    public static final String CLASS_NAME = 'BWC_LIC_OpusBgUtilController';
    // constant strings
    private static final String OPT_Y = 'Y';
    private static final String OPT_N = 'N';
    private static final String REP_DETAILS_FORMAT = '{0}|{1}';
    private static final String AVERTACK_ID_FORMAT = '{0}-{1}';
    private static final String CUSTOMER_TYPE_CONSUMER = 'Consumer';
    private static final String LOB_WLS = 'WLS';
    private static String parentTransactionId;
    private static String OFFLINE_RT_INTERACTION='Offline';

    /*
     *  Method used to fetch all the parameter from Custom Metadata and store
     *  in Aura component. This method will call only once when the component
     *  is initilized.
     */
    @AuraEnabled(cacheable = true)
    public static Map<String, String> getInitDetails()
    {
        Map<String, String> initParam = new Map<String, String>();
        // // the following variables are no longer used, but left commented out for reference
        // String hostname = Url.getSalesforceBaseUrl().getHost();
        // String myDomain = hostname.split('\\.')[0];
        try
        {
            // get the OPUS Config and initialize the config mpa
            BWC_OpusLIC__mdt opusdata = BWC_LIC_OpusMsgController.getOpusConfig();
            String recIdPrefix = Interaction__c.sobjecttype.getDescribe().getKeyPrefix();
            initParam.put('KeepAlive', String.ValueOf(opusdata.KeepAlive__c));
            initParam.put('PageURL', Page.BWCOpusLICMessage.getUrl());
            initParam.put('WindowName', opusdata.WindowName__c);
            initParam.put('RecordIdPrefix', recIdPrefix);
            initParam.put('RetryOPUS', String.ValueOf(opusdata.RetryOPUS__c));
            initParam.put('DestURL', opusdata.OPUS_URL__c);
            initParam.put('Enabled', String.valueOf(opusdata.Enabled__c));
            initParam.put('Attempt', String.ValueOf(opusdata.NoOfAttempt__c));
            initParam.put('XsecWaiting', String.ValueOf(opusdata.XsecWaiting__c));
            initParam.put('PopUpUrl', String.ValueOf(opusdata.Redirected_URL__c));

            List<Object> params = new List<Object>{'OPUS',  null, JSON.serialize(initParam)};
            LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
            Logger.info(logMessage).setTopics(BWC_Constants.LIC_TOPICS);
            Logger.saveLog();
        }
        catch (System.Exception e)
        {
            // TODO: Does this re-throw the exception? I don't think we want this to fail silently.
            System.debug('Exception :' + e.getStackTraceString());


            List<Object> params = new List<Object>{'OPUS',  null, e.getMessage()+'-'+e.getCause()};
            LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
            Logger.error(logMessage).setTopics(BWC_Constants.LIC_TOPICS);
            Logger.saveLog();


            // BWC_ExceptionUtils.handleException(e, 'BWC_OpusLICBgUtilController: ', null);
        }


        return (initParam);
    }

    // TODO: add comment and explain parameters and return value
    @AuraEnabled
    public static Map<String, String> canLaunchOpus(String recordId)
    {
        String METHOD_NAME = 'canLaunchOpus';

        //TODO: Create method to get recordtypeId from any object
        Id offLineRT = Schema.SObjectType.Interaction__c.getRecordTypeInfosByDeveloperName().get(OFFLINE_RT_INTERACTION).getRecordTypeId();

        Map<String, String> canlaunchOpusMap = new Map<String, String>();
        // TODO: explain why this is defaulted to false
        Boolean status = false;
        List<Billing_Account__c> baLst = new List<Billing_Account__c>();
        List<String> baIdLst = new List<String>();
        canlaunchOpusMap.put('status', 'false');
        try
        {
            // TODO: add comments explaining what you are querying for and why
            Interaction__c interaction = BWC_LIC_OpusMsgController.getInteraction(recordId);

            // Checking if the interaction tab can be closed. This applies to all users.
            // does not matter if they don't have special permissions (LIC) or required information for opus (storeLocationId or ATTUID)
            String canCloseTab = interaction.CompletedDate__c != null ? 'true' : 'false';
            canlaunchOpusMap.put('CanCloseTab', canCloseTab);
            // get the current user
            User currentUser = BWC_LIC_OpusMsgController.getCurrentUser();

            // get the OPUS config
            BWC_OpusLIC__mdt opusConfig = BWC_LIC_OpusMsgController.getOpusConfig();

            System.debug('interaction :' + interaction);
            System.debug('currentUser :' + currentUser);
            System.debug('currentUser :' + currentUser.ATTUID__c);
            // if (String.isBlank(interaction.Customer__c))
            // {
            //     canlaunchOpusMap.put('Exception', 'Current Interaction is not related to an Account yet');
            //     throw new IllegalArgumentException('Current Interaction is not related to an Account yet');
            // }

            // TODO: Create a story to clean up this method
            if(interaction!=null && interaction.RecordTypeId!=offLineRT){
                Account acct = null;
                try
                {
                    // retrieve the Account and Billing Accounts for the Customer on the Interaction
                    acct = BWC_LIC_OpusMsgController.getAccountWithBillingAccounts(interaction.Customer__c);
                }
                catch (Exception e)
                {
                    // canlaunchOpusMap.put('Exception', 'No Account was found');
                    throw e;
                }

                // TODO: see comments from other class
                List<Customer_Account_Relation__c> csrList = acct.Customer_Account_Relation__r;
                for (Customer_Account_Relation__c car : csrList)
                {
                    baIdLst.add(car.Billing_Account__c);
                }
                if (!baIdLst.isEmpty())
                {
                    baLst = [
                        SELECT Id, Customer_Type__c,
                        LOB_Type__c, Billing_Account_Number__c
                        FROM Billing_Account__c
                        WHERE Id in :baIdLst
                        AND Billing_Account_Number__c =:interaction.User_Account_Number__c
                    ];
                }
            }

            String hasPermission = FeatureManagement.checkPermission('LIC_Permission') ? 'true' : 'false';
            if (((interaction != null)
                    && (interaction.Customer__c != null)
                    && (currentUser != null)
                    && !String.isEmpty(currentUser.ATTUID__c)
                    && !String.isEmpty(currentUser.StoreLocationId__c)
                    && (!baLst.isEmpty())
                )
                || (interaction!=null && interaction.RecordTypeId==offLineRT))
            {
                status = true;
                canlaunchOpusMap.put('status', 'true');
                canlaunchOpusMap.put('ban', interaction.User_Account_Number__c);
                canlaunchOpusMap.put('hasPermission', hasPermission);

                List<Object> params = new List<Object>{'OPUS',  recordId, JSON.serialize(canlaunchOpusMap)};
                LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);

                // Builder pattern allow us to chain methods
                Logger.info(logMessage).setRecordId(recordId).setTopics(BWC_Constants.LIC_TOPICS);

                Logger.saveLog();
            }
            else
            {
                status = false;
                canlaunchOpusMap.put('Exception',
                                     'Either ATTID/StorelocationId  is missing in USER/Interaction record or Incomplete Interaction rec');

                List<Object> params = new List<Object>{'OPUS',  recordId, JSON.serialize(canlaunchOpusMap)};
                LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);

                Logger.info(logMessage).setRecordId(recordId).setTopics(BWC_Constants.LIC_TOPICS);

                Logger.saveLog();

                throw new IllegalArgumentException(
                          'Either ATTID/StorelocationId is missing in USER/Interaction record or Incomplete Interaction rec');
            }
            System.debug('status :' + status);
        }
        catch (Exception e)
        {
            System.debug('Exception :' + e.getStackTraceString());
            System.debug('Exception :' + e.getCause());

            List<Object> params = new List<Object>{'OPUS',  recordId, e.getMessage()+'-'+e.getCause()};
            LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);

            Logger.error(logMessage).setRecordId(recordId).setTopics(BWC_Constants.LIC_TOPICS);

            Logger.saveLog();
            // BWC_ExceptionUtils.handleException(e, 'BWC_OpusLICBgUtilController: ', null);
            // throw new AuraHandledException(e.getMessage());
        }
        return canlaunchOpusMap;
    }

    // TODO: add comment and make sure to explain parameters and return variable
    @AuraEnabled
    public static string getInitMessage(String messageType, String recordId, Boolean relaunch)
    {

        String METHOD_NAME = 'getInitMessage';
        Map<String, Object> paramsMethod = new Map<String, Object>{
            'messageType'=>messageType,
            'recordId'=>recordId,
            'relaunch'=>relaunch
        };


        System.debug('task : ' + messageType);
        System.debug('recordId : ' + recordId);
        // TODO: explain what these are for
        BWC_LIC_OpusMsgRequest.OPUSInitRequest req = new BWC_LIC_OpusMsgRequest.OPUSInitRequest();
        BWC_LIC_OpusMsgRequest.OpusMessage msg = new BWC_LIC_OpusMsgRequest.OpusMessage();
        BWC_LIC_OpusMsgRequest.OpusPost postmsg = new BWC_LIC_OpusMsgRequest.OpusPost();
        List<Billing_Account__c> baLst = null;
        List<String> baIdLst = new List<String>();
        try
        {
            // get OPUS config
            BWC_OpusLIC__mdt opusConfig = BWC_LIC_OpusMsgController.getOpusConfig();

            // empty check
            if (String.isBlank(recordId))
            {
                throw new BWC_Exception('Interaction record Id is null: ' + recordId);
            }

            // get the current user
            User currentUser = BWC_LIC_OpusMsgController.getCurrentUser();

            // get interaction record
            Interaction__c interaction = BWC_LIC_OpusMsgController.getInteraction(recordId);

            // retrieve the Account and Billing Accounts for the Customer on the Interaction
            Account acct = BWC_LIC_OpusMsgController.getAccountWithBillingAccounts(interaction.Customer__c);

            // TODO: clean up double/triple spaces
            // TODO: is there a reason you copy this into a local variable rather than just running the for loop against
            // the source field?
            List<Customer_Account_Relation__c> csrList = acct.Customer_Account_Relation__r;
            // TODO: explain what you are doing, naming that you are building a list of Billing Account Id's
            for (Customer_Account_Relation__c car : csrList)
            {
                baIdLst.add(car.Billing_Account__c);
            }
            System.debug('baIdLst :' + baIdLst);
            System.debug('interaction.User_Account_Number__c :' + interaction.User_Account_Number__c);
            // TODO: explaion what you are doing here
            if (!baIdLst.isEmpty())
            {
                baLst = [
                    SELECT Id, Customer_Type__c,
                    LOB_Type__c, Billing_Account_Number__c
                    FROM Billing_Account__c
                    WHERE Id in :baIdLst
                    WITH SECURITY_ENFORCED
                ];
            }
            // TODO: explain what you are doing and why, why is this just the first record?
            if (baIdLst.isEmpty() || baLst.isEmpty())
            {
                throw new BWC_Exception('No matching Billing Account Found!');
            }
            // TODO: This looks like duplicate code to what we have above? Let's move this code into a private static method and
            // pass in the needed values so we don't have to have dupe code.
            // everything is good now lets process.
            // TODO: We need to save the trackingIdent string and only re-generate it for Trigger 1. I don't see where
            // that is happening.
            Datetime dt = Datetime.now();
            String tokenDate = dt.formatGMT(opusConfig.TOKEN_FORMAT__c);
            String attId = currentUser.ATTUID__c;
            // start populating the OPUS LIC object
            req.sysId = opusConfig.SYSTEM_ID__c;
            req.repDetails = String.format(REP_DETAILS_FORMAT, new Object[] {attId, tokenDate});
            req.storeLocationId = currentUser.StoreLocationId__c;
            req.trackingIdent = interaction.trackingIdent__c;
            // TODO: set relaunch based on verified ban
            req.relaunch = OPT_N; // default to 'N'
            req.sfCustomerInfo = new List<BWC_LIC_OpusMsgRequest.SfCustomerInfo>();
            for (Billing_Account__c ba : baLst)
            {
                BWC_LIC_OpusMsgRequest.SfCustomerInfo custInfo = new BWC_LIC_OpusMsgRequest.SfCustomerInfo();
                custInfo.AccNumber = ba.Billing_Account_Number__c; // get from CTI/IVR
                // custInfo.customerType = ba.Customer_Type__c ;
                // Hardcoding as told me to do so.
                if (opusConfig.HardCode_CustomerType__c)
                {
                    custInfo.customerType = CUSTOMER_TYPE_CONSUMER;
                }
                else
                {
                    custInfo.customerType = ba.Customer_Type__c;
                }
                custInfo.LOBType = ba.LOB_Type__c;
                // CTN will be populated only when LobType=WLS
                // if (LOB_WLS.equals(custInfo.LOBType))
                // {
                //     custInfo.CTN = interaction.User_Telephone_Number__c;
                // }
                custInfo.isVerified = OPT_N;
                if (interaction.Is_Authorized__c)
                {
                    BWC_AuthorizationCallout.AuthorizationStatusContent resp;
                    resp = (BWC_AuthorizationCallout.AuthorizationStatusContent) JSON.deserialize(
                        interaction.Authorization_Json__c, BWC_AuthorizationCallout.AuthorizationStatusContent.class);
                    for (BWC_AuthorizationCallout.AssociatedAccount assAct : resp.associatedAccounts)
                    {
                        if (
                            custInfo.AccNumber.equals(assAct.accountBan) &&
                            ( BWC_Constants.AUTHORIZATION_LEVEL_L1.equals(assAct.authorizationLevel)
                            || BWC_Constants.AUTHORIZATION_LEVEL_BYPASS.equals(assAct.authorizationLevel) )
                            )
                        {
                            custInfo.isVerified = OPT_Y;

                            // if the primary ban is verified, we can use the passed in relaunch attribute
                            if(interaction.User_Account_Number__c.equals(assAct.accountBan)){
                                req.relaunch = (relaunch ? OPT_Y : OPT_N );
                            }
                        }
                    }
                }
                custInfo.primarySearchAccount = interaction.User_Account_Number__c;
                custInfo.cssIdForAvertack = String.format(AVERTACK_ID_FORMAT, new Object[] {interaction.Id, ba.Billing_Account_Number__c});
                req.sfCustomerInfo.add(custInfo);
            }

            System.debug('task : ' + messageType);
            if (messageType == null)
            {
                msg.task = 'opus_sf_init';
            }
            else
            {
                msg.task = messageType;
            }

            msg.data = req;
            postmsg.msg = msg;
            String param = JSON.serialize(postmsg, true);

            List<Object> params = new List<Object>{'OPUS',  JSON.serialize(paramsMethod), param};
            LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
            Logger.info(logMessage).setRecordId(recordId).setTopics(BWC_Constants.LIC_TOPICS);
            Logger.saveLog();

            return (param);
        }
        catch (Exception e)
        {
            System.debug('Exception ' + e.getStackTraceString());

            List<Object> params = new List<Object>{'OPUS',  JSON.serialize(paramsMethod), e.getMessage()+'-'+e.getCause()};
            LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
            Logger.info(logMessage).setRecordId(recordId).setTopics(BWC_Constants.LIC_TOPICS);
            Logger.saveLog();
            // BWC_ExceptionUtils.handleException(e, 'BWC_OpusLICBgUtilController: ', null);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getTrackingIdent(String recordId)
    {
        String METHOD_NAME = 'getTrackingIdent';
        String trackIdent;
        try
        {
            // TODO: This query could be put into a private static method and called above too (even though the other
            // query is for fewer fields, it should be fine as the fields it needs are included here)
            Interaction__c interaction = BWC_LIC_OpusMsgController.getInteraction(recordId);
            trackIdent = interaction.trackingIdent__c;

            //
            List<Object> params = new List<Object>{'OPUS',  recordId, trackIdent};
            LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
            Logger.info(logMessage).setRecordId(recordId).setTopics(BWC_Constants.LIC_TOPICS);
            Logger.saveLog();
        }
        catch (Exception e)
        {
            //
            List<Object> params = new List<Object>{'OPUS',  recordId, e.getMessage()+'-'+e.getCause()};
            LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
            Logger.info(logMessage).setRecordId(recordId).setTopics(BWC_Constants.LIC_TOPICS);
            Logger.saveLog();
            // BWC_ExceptionUtils.handleException(e, 'BWC_OpusLICBgUtilController: ', null);
            // throw new AuraHandledException(e.getMessage());
        }
        return (trackIdent);
    }

    @AuraEnabled
    public static void logOpusResponse(String detail, String recordId, boolean isError){

        String METHOD_NAME = 'logOpusResponse';

        try {

            List<Object> params = new List<Object>{'OPUS',  detail, null};
            LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);

            if(isError){
                Logger.error(logMessage).setRecordId(recordId).setTopics(BWC_Constants.LIC_TOPICS);
            }else{
                Logger.info(logMessage).setRecordId(recordId).setTopics(BWC_Constants.LIC_TOPICS);
            }

            Logger.saveLog();

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}